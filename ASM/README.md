# THE INCA WALL — MSX1, SCREEN 1, ROM 32K

Arena arcade. Lo schermo e' un muro a secco inca fatto di blocchi di
pietra 16x16; dentro il muro sono ricavate delle stanze nere con dentro le
chakana rosse da raccogliere. Il giocatore e 4 guardiani si muovono
liberamente su tutta l'area (nessuna collisione con la mappa). 90 secondi
a livello, 3 vite.

* +100 punti per ogni chakana
* +10 punti per ogni secondo risparmiato a fine livello (barra che cala in
  fretta con rullata di monetine)
* **una vita in regalo ogni 10000 punti**, ma solo se se ne hanno meno di
  tre, con un arpeggio ascendente che si fa sentire
* musichetta andina sul title
* barra del tempo verde -> gialla -> rossa
* high score di sessione

## Build / run

```
build.cmd      sjasmplus -> build\kanji.rom  (32768 byte esatti)
run.cmd        build + lancia openMSX (Sony_HB-55P)
```

Su hardware reale: cartuccia ROM 32K standard, `4000h-BFFFh`, header `AB`.
Nessun mapper. Le variabili stanno in `C000h-C392h`, quindi gira anche su
macchine con 16K di RAM.

## Struttura

| file | contenuto |
|---|---|
| `kanji.asm`  | header ROM, costanti, mappa RAM, init, main loop, dispatch di stato |
| `vdp.asm`    | accesso VDP diretto a porte (niente BIOS: FILVRM/LDIRVM hanno bug su alcune macchine), setup SCREEN 1, upload grafica, `print` |
| `level.asm`  | RNG, generazione procedurale del livello, disegno mappa, raccolta chakana |
| `actors.asm` | input, giocatore, 4 comportamenti nemico, movimento a virgola fissa 8.8, collisioni, costruzione sprite attribute table |
| `hud.asm`    | punteggio BCD, hi-score, vite, livello, barra del tempo, clock di gioco |
| `sound.asm`  | player effetti PSG su canale A + gli effetti |
| `music.asm`  | player a 3 canali e tema del title |
| `states.asm` | title, ready, play, morte, bonus di fine livello, game over |
| `data.asm`   | pattern muro e chakana, barra, icona vita, tabella colori, sprite, stringhe |

## Grafica in SCREEN 1

Il colore è per gruppi di 8 pattern, quindi la mappa caratteri è:

| codici | contenuto | colore |
|---|---|---|
| `00-07` | vuoto | nero su nero |
| `08-0F` | quadrante TL delle 8 pietre | nero su giallo chiaro |
| `10-17` | quadrante TR delle 8 pietre | nero su giallo chiaro |
| `18-1F` | quadrante BL delle 8 pietre | nero su rosso scuro |
| `20-27` | quadrante BR delle 8 pietre | nero su rosso scuro |
| `28-2F` | la chakana da raccogliere (4 caratteri) | rosso chiaro su nero |
| `30-37` | 8 livelli di riempimento della barra | riscritto a runtime |
| `38-77` | font ASCII `20h-5Fh` copiato dal BIOS (codice = ascii + 18h) | bianco |
| `78`    | icona vita | giallo chiaro |

## Il muro

Muratura a secco inca: **8 motivi da 16x16 pixel**, ognuno un blocco di
**2x2 caratteri**. Malta di 1 px su tutti e quattro i lati del blocco,
quindi fra due pietre vicine viene 2 px uniformi.

**Il rilievo.** Un carattere SCREEN 1 ha due soli colori e sono condivisi
da tutto un gruppo di 8 pattern, quindi una singola pietra non puo' avere
luce, faccia e ombra. Il trucco: i quattro quadranti di ogni pietra stanno
in **quattro gruppi colore diversi**. L'inchiostro resta nero ovunque e
cambia solo il tono della FACCIA - giallo chiaro sopra, rosso scuro sotto -
cosi' ogni pietra si legge come illuminata dall'alto. Percio' i pattern
sono disposti per quadrante: prima tutti gli 8 TL, poi tutti gli 8 TR, ecc.
Il motivo i sta a `CH_TILE + i`, i suoi quadranti a 8 caratteri di distanza.

Due cose imparate provandole:

* il tono d'ombra **deve** essere il rosso scuro (6), non il giallo scuro
  (10): su MSX vero 10 e 11 hanno quasi la stessa luminosita' e il rilievo
  sparisce;
* fare la malta piu' spessa in basso a destra non serve a niente: fra due
  pietre adiacenti e' una linea nera continua, l'asimmetria non si vede.
  Solo il tono della faccia puo' portare il rilievo.

I motivi: pietra liscia, greca, greca rovesciata, chakana, doppia pietra
orizzontale, doppia pietra verticale, terrazza, nicchia trapezoidale.

La chakana da raccogliere e' **piena, rossa su nero, senza malta**: sta
sciolta dentro una stanza nera, non incastonata nel muro, ed e' sempre la
stessa forma (un motivo di muro a caso a volte era troppo esile per
leggersi come raccoglibile).

Il disegno "sorgente" sta in `tools\tiles.py` come ASCII art, dove `#` e'
un solco inciso e `.` la faccia della pietra:

```
python tools\tiles.py            preview PNG dei motivi e del muro
python tools\tiles.py --asm      i db pronti da incollare in data.asm
```

Colori degli sprite: giocatore **bianco** (e' il colore col miglior
contrasto peggiore-caso su giallo chiaro, rosso scuro e nero insieme),
guardiani magenta / ciano / verde chiaro / blu chiaro. Niente rosso addosso
a nessuno: il rosso vuol dire solo "raccoglimi".

Il primo tentativo era una parete di kanji ricavati da una strip di
riferimento (`tools\ref-tiles.png`); il downsampling automatico da 21x22
a 8x8 dava poltiglia, vedi `tools\extract_ref.py` e
`tools\tiles_kanji_old.py` se serve tornarci.

## Livelli infiniti

I livelli non esistono in ROM: sono costruiti dall'RNG a ogni cambio
schermo. **L'RNG non viene re-inizializzato per livello** - il seme si
prende una volta sola in `game_start`, da `JIFFY` nell'istante in cui il
giocatore preme il grilletto, quindi due partite non vedono mai la stessa
sequenza di schemi e i livelli non finiscono mai.

Attenzione se si tocca questa parte: la versione precedente derivava il
seme dal numero di livello. Con il contatore fermo a 99 il risultato era
che dal livello 99 in poi si rigenerava all'infinito lo **stesso identico
schema**. Il contatore adesso serve solo alla rampa di difficolta' (che
comunque si satura molto prima) e alla scritta `LV`, che viene bloccata a
99 in `hud_build` perche' ha solo due cifre.

## Vita extra

In `add_score` si guarda il byte alto del punteggio BCD, che conta le
decine di migliaia: se cambia, il punteggio ha appena attraversato un
multiplo di 10000. Nessun premio singolo vale 10000, quindi non puo' mai
saltarne uno.

`award_life` regala la vita solo sotto le tre e suona `sfx_extra` tramite
`sfx_play_hi`: quella variante blocca il canale per `SFX_PRIO_LEN` frame,
altrimenti la rullata di monetine di fine livello - che ritriggera un
effetto ogni 4 frame - se lo mangerebbe subito.

## Scritte sopra il muro

`msg_show` / `msg_hide` in `states.asm` scrivono e ritirano un messaggio
toccando **solo le celle che occupa**, non tutta la riga. Non serve
cancellare niente prima: il gruppo colore del font e' bianco su nero,
quindi ogni carattere si porta dietro il proprio riquadro nero e il muro
attorno resta intatto. `msg_hide` rimette a posto esattamente quel tratto
ripescandolo dalla `map`, che e' la copia in RAM del livello.

## La musichetta del title

`music.asm` e' un player a tre canali: uno stream per canale, ciascuno una
lista di coppie (nota, frame). `0FFh` e' una pausa, `0FEh` fa ripartire
quello stream dall'inizio. Il byte della nota ha nel nibble alto le ottave
sopra la terza e nel nibble basso il semitono, cosi' il periodo si trova
con una lookup di 12 valori piu' uno shift per ottava.

Ogni nota fa ripartire il volume del canale dal suo livello di attacco e
poi cala di un passo ogni 4 frame fino al livello di tenuta: e' quello che
da' il pizzicato tipo charango invece di un organo piatto.

Il pezzo e' in **la minore pentatonica**, 24 battute che girano in loop:
melodia da quena che scende, basso che cammina **la - sol - fa - mi**, e un
terzo canale che tiene una nota dell'accordo sotto. Il giro discendente del
basso e' la cosa che piu' di tutte lo fa suonare andino.

Effetti e musica non si contendono mai il PSG: `mus_start` prende il
controllo (R7 = 0B8h, tono sui tre canali) e azzera l'effetto in corso,
`mus_stop` restituisce tutto agli effetti (R7 = 0BEh) e viene chiamata
appena si preme il grilletto, in cima a `game_start`.

## Manopole (in cima a `kanji.asm`)

```
P_SPEED     2       pixel/frame del giocatore
EN_SPD0     A0h     velocità nemici al livello 1 (8.8 fisso: A0h = 0.625 px/frame)
EN_SPDINC   10h     incremento per livello
EN_SPDMAX   F0h     tetto
HIT_DIST    12      semilato del box di collisione
GAME_SECS   90      secondi per livello
BONUS_MULT  15      tick bruciati per frame durante il conteggio bonus
```

Numero di chakana: `4 + livello`, massimo 9 (in `gen_level`).
Numero di stanze nere: 3-5, misurate in blocchi (in `gen_level`).

## Gancio per il muro solido

`map_solid` in `level.asm` oggi risponde sempre "libero". Se vuoi rendere
il nero invalicabile (o letale) si tocca solo quella funzione più la
chiamata dal movimento — il resto del gioco non cambia.

## Test

`test\*.tcl` sono script openMSX per verifiche non interattive
(screenshot, flusso di gioco, raccolta chakana, bonus, timeout, vita
extra e varieta dei livelli). Esempio:

```
openmsx.exe -machine Sony_HB-55P -carta build\kanji.rom -script test\shot.tcl
```
