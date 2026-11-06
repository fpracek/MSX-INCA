# messages must only touch their own characters, and the wall under them
# must come back untouched afterwards
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir msg.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }
proc shot {n} { global basedir; catch {screenshot [file join $basedir $n]} }

set MAP    0xC114
set STATE  0xC003
set LIVES  0xC00C
set MSGROW 10

# the 32 characters of the message row, as they are on screen
proc vrow {} {
    global MSGROW
    set l {}
    for {set i 0} {$i < 32} {incr i} {
        lappend l [format %02X [debug read VRAM [expr {0x1800 + $MSGROW*32 + $i}]]]
    }
    return $l
}
proc mrow {} {
    global MAP MSGROW
    set l {}
    for {set i 0} {$i < 32} {incr i} {
        lappend l [format %02X [debug read memory [expr {$MAP + $MSGROW*32 + $i}]]]
    }
    return $l
}
proc diffcols {} {
    set v [vrow] ; set m [mrow] ; set d {}
    for {set i 0} {$i < 32} {incr i} {
        if {[lindex $v $i] ne [lindex $m $i]} { lappend d $i }
    }
    return $d
}

after time 6   "keymatrixdown 8 1"
after time 6.2 "keymatrixup 8 1"
# READY is up right after the level starts
after time 6.8 {
    L "READY   colonne diverse dal muro: [diffcols]   (atteso 13..18)"
    L "  riga a video: [vrow]"
    shot m1-ready.png
}
# and must be gone once play begins
after time 9 {
    L "dopo    colonne diverse dal muro: [diffcols]   (atteso vuoto)"
    shot m2-restored.png
}
# burn the lives to reach GAME OVER and catch it while it is on screen
after time 9.5 "debug write memory $LIVES 1"

proc waitover {n} {
    global STATE
    if {[debug read memory $STATE] == 5} {
        L "OVER    colonne diverse dal muro: [diffcols]   (atteso 11..19)"
        L "  riga a video: [vrow]"
        shot m3-over.png
        after time 1 exit
        return
    }
    if {$n > 200} { L "game over non raggiunto" ; after time 1 exit ; return }
    after time 0.2 "waitover [expr {$n+1}]"
}
after time 10 "waitover 0"
