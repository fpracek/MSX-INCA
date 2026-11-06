# 1) extra life on crossing 10000 when lives < 3, and the jingle must
#    survive the end of level coin roll
# 2) no extra life when already at 3
# 3) levels keep producing different layouts well past the 2 digit counter
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir extra.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

set MAP     0xC112
set STATE   0xC003
set SCORE   0xC006
set LEVEL   0xC00D
set REDLEFT 0xC00E
set LIVES   0xC00C
set SFXPTR  0xC10E
set SFXPRIO 0xC111

proc score {} {
    global SCORE
    return [format "%02X%02X%02X" [debug read memory [expr {$SCORE+2}]] \
        [debug read memory [expr {$SCORE+1}]] [debug read memory $SCORE]]
}
proc st {} {
    global STATE LIVES LEVEL
    return [format "state=%d lives=%d lv=%3d score=%s" [debug read memory $STATE] \
        [debug read memory $LIVES] [debug read memory $LEVEL] [score]]
}
proc setscore {hi mid lo} {
    global SCORE
    debug write memory $SCORE $lo
    debug write memory [expr {$SCORE+1}] $mid
    debug write memory [expr {$SCORE+2}] $hi
}
proc mapsig {} {
    global MAP
    set h 0
    for {set i 0} {$i < 640} {incr i} {
        set h [expr {(($h * 31) + [debug read memory [expr {$MAP + $i}]]) & 0xFFFFFF}]
    }
    return [format %06X $h]
}
proc inplay {} { global STATE; return [expr {[debug read memory $STATE] == 2}] }

# drive the score across a 10000 boundary using the end of level bonus roll:
# deterministic, and it is exactly the moment the coin roll could drown the
# extra life jingle
proc crossing {lives hi mid lo next} {
    global LIVES REDLEFT
    if {![inplay]} { after time 0.3 "crossing $lives $hi $mid $lo $next" ; return }
    debug write memory $LIVES $lives
    setscore $hi $mid $lo
    L "  prima     [st]"
    debug write memory $REDLEFT 0
    after time 0.8 "watchprio $next 0"
}

# sample sfx_prio during the roll: non zero means the jingle is protected
proc watchprio {next n} {
    global SFXPRIO
    if {[debug read memory $SFXPRIO] != 0} {
        L "  jingle protetto (sfx_prio=[debug read memory $SFXPRIO])"
        after time 8 $next
        return
    }
    if {$n > 40} { L "  nessun jingle protetto visto" ; after time 8 $next ; return }
    after time 0.1 "watchprio $next [expr {$n+1}]"
}

proc t1 {} { L "T1 una vita, si attraversa 010000 -> attese 2 vite" ; crossing 1 0x00 0x99 0x00 t1b }
proc t1b {} { L "  dopo      [st]" ; after time 0.5 t2 }

proc t2 {} { L "T2 tre vite, si attraversa 030000 -> devono restare 3" ; crossing 3 0x02 0x99 0x00 t2b }
proc t2b {} { L "  dopo      [st]" ; after time 0.5 "t3 0" }

set sigs {}
proc t3 {n} {
    global LEVEL REDLEFT sigs
    if {![inplay]} { after time 0.3 "t3 $n" ; return }
    if {$n == 0} { L "T3 livelli oltre il contatore a 2 cifre" ; debug write memory $LEVEL 150 }
    lappend sigs [mapsig]
    L "  lv=[debug read memory $LEVEL] mapsig=[lindex $sigs end]"
    if {$n >= 5} {
        L "  firme distinte: [llength [lsort -unique $sigs]] su [llength $sigs]"
        after time 0.5 done
        return
    }
    debug write memory $REDLEFT 0
    after time 9 "t3 [expr {$n+1}]"
}

proc done {} { L "fine: [st]" ; after time 0.5 exit }

after time 6   "keymatrixdown 8 1"
after time 6.2 "keymatrixup 8 1"
after time 9   t1
