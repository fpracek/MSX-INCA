# exercise the whole flow fast: start, drain some time, force a level
# clear to watch the bonus roll, then let the clock kill the player
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir flow.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

set STATE   0xC003
set SCORE   0xC006
set LIVES   0xC00C
set REDLEFT 0xC00E
set SECS    0xC00F

proc snap {tag} {
    global basedir STATE SCORE LIVES REDLEFT SECS
    L [format "%-12s state=%d lives=%d red=%2d secs=%2d score=%02X%02X%02X" $tag \
        [debug read memory $STATE] [debug read memory $LIVES] \
        [debug read memory $REDLEFT] [debug read memory $SECS] \
        [debug read memory [expr {$SCORE+2}]] [debug read memory [expr {$SCORE+1}]] \
        [debug read memory $SCORE]]
    screenshot -force [file join $basedir $tag.png]
}

set throttle off

after time 6    "keymatrixdown 8 1"
after time 6.2  "keymatrixup 8 1"
after time 9    "snap f1-start"
after time 25   "snap f2-running"
# force the level clear -> bonus roll
after time 25.5 "debug write memory $REDLEFT 0"
after time 27   "snap f3-bonus"
after time 34   "snap f4-nextlevel"
# now sit still until the clock runs out and kills us
after time 130  "snap f5-timeout"
after time 132  "exit"
