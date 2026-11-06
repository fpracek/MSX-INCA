# Walk the player over every chakana and check the pickup wipes the whole
# 16x16 block.  Teleports wait for ST_PLAY, otherwise the guardians catch
# the idle player and the pickup code never runs.
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir pick.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

set MAP     0xC112
set PX      0xC01E
set PY      0xC01F
set STATE   0xC003
set SCORE   0xC006
set REDLEFT 0xC00E
set LIVES   0xC00C

proc st {} {
    global SCORE REDLEFT STATE
    return [format "state=%d red=%2d score=%02X%02X%02X" \
        [debug read memory $STATE] [debug read memory $REDLEFT] \
        [debug read memory [expr {$SCORE+2}]] [debug read memory [expr {$SCORE+1}]] \
        [debug read memory $SCORE]]
}

proc reds {} {
    global MAP
    set l {}
    for {set i 0} {$i < 640} {incr i} {
        if {[debug read memory [expr {$MAP + $i}]] == 0x28} { lappend l $i }
    }
    return $l
}

# take the next chakana still on the map; retry until the game is in play
proc grab {n} {
    global PX PY LIVES STATE basedir
    debug write memory $LIVES 9
    if {[debug read memory $STATE] != 2} {
        after time 0.3 "grab $n"
        return
    }
    set l [reds]
    if {[llength $l] == 0} {
        L "all taken: [st]"
        after time 9 "L \"after bonus: [st]\"; catch {screenshot [file join $basedir p2-next.png]}"
        after time 10 "exit"
        return
    }
    set idx [lindex $l 0]
    debug write memory $PX [expr {($idx % 32) * 8}]
    debug write memory $PY [expr {($idx / 32) * 8}]
    after time 0.2 "check $n [expr {$idx % 32}] [expr {$idx / 32}]"
}

proc check {n col row} {
    global MAP
    set q {}
    foreach off [list 0 1 32 33] {
        lappend q [format %02X [debug read memory [expr {$MAP + $row*32 + $col + $off}]]]
    }
    L [format "grab %d block(%2d,%2d) leftover=%s  %s" $n $col $row $q [st]]
    after time 0.2 "grab [expr {$n+1}]"
}

after time 6   "keymatrixdown 8 1"
after time 6.2 "keymatrixup 8 1"
after time 9.5 "L \"start: [st] chakanas=[llength [reds]]\"; grab 1"
