# Check the title tune really drives the three PSG channels, and that the
# PSG is handed back to the effect player when the game starts.
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir music.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

L "debuggables: [lsearch -all -inline [debug list] *PSG*] [lsearch -all -inline [debug list] *AY*]"

set DBG ""
foreach cand {"PSG regs" "psg regs" "AY8910 regs"} {
    if {[lsearch -exact [debug list] $cand] >= 0} { set DBG $cand ; break }
}
L "uso debuggable: '$DBG'"

proc reg {n} { global DBG; return [debug read $DBG $n] }

proc snap {tag} {
    set a [expr {[reg 0] + 256*[reg 1]}]
    set b [expr {[reg 2] + 256*[reg 3]}]
    set c [expr {[reg 4] + 256*[reg 5]}]
    L [format "%-7s R7=%02X  A=%4d v%-2d  B=%4d v%-2d  C=%4d v%-2d" $tag \
        [reg 7] $a [reg 8] $b [reg 9] $c [reg 10]]
}

# sample the tune for a few seconds
for {set t 40} {$t < 100} {incr t 4} {
    after time [expr {$t / 10.0}] "snap t[expr {$t/10.0}]"
}
# start the game and check the PSG goes back to effects only
after time 10.5 "keymatrixdown 8 1"
after time 10.7 "keymatrixup 8 1"
after time 12   "snap gioco"
after time 13   "snap gioco2"
after time 14   exit
