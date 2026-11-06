set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir bonus.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

set STATE   0xC003
set SCORE   0xC006
set REDLEFT 0xC00E
set SECS    0xC00F
set BARPX   0xC017
set LEVEL   0xC00D

proc snap {tag} {
    global basedir STATE SCORE REDLEFT SECS BARPX LEVEL
    L [format "%-12s state=%d lvl=%d red=%2d secs=%2d bar=%3d score=%02X%02X%02X" $tag \
        [debug read memory $STATE] [debug read memory $LEVEL] \
        [debug read memory $REDLEFT] [debug read memory $SECS] \
        [expr {[debug read memory $BARPX] + 256*[debug read memory [expr {$BARPX+1}]]}] \
        [debug read memory [expr {$SCORE+2}]] [debug read memory [expr {$SCORE+1}]] \
        [debug read memory $SCORE]]
    if {$tag ne ""} { screenshot -force [file join $basedir $tag.png] }
}

set throttle off

after time 6    "keymatrixdown 8 1"
after time 6.2  "keymatrixup 8 1"
after time 9    "snap b1-play"
after time 9.2  "debug write memory $REDLEFT 0"
after time 10   "snap b2-roll1"
after time 12   "snap b3-roll2"
after time 14   "snap b4-roll3"
after time 18   "snap b5-lvl2"
after time 20   "exit"
