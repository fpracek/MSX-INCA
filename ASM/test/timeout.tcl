# shorten the clock and check that running out of time kills the player
set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir timeout.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }

set STATE 0xC003
set LIVES 0xC00C
set SECS  0xC00F
set TICK  0xC011
set BARPX 0xC017

proc st {tag} {
    global STATE LIVES SECS TICK BARPX
    L [format "%-10s state=%d lives=%d secs=%2d tick=%4d bar=%3d" $tag \
        [debug read memory $STATE] [debug read memory $LIVES] [debug read memory $SECS] \
        [expr {[debug read memory $TICK] + 256*[debug read memory [expr {$TICK+1}]]}] \
        [expr {[debug read memory $BARPX] + 256*[debug read memory [expr {$BARPX+1}]]}]]
}
proc shot {name} { global basedir; catch {screenshot [file join $basedir $name]} }

after time 6   "keymatrixdown 8 1"
after time 6.2 "keymatrixup 8 1"
after time 8   "st play"
# 4 seconds of clock left, and pretend the bar is nearly empty too
after time 8.1 "debug write memory $TICK 200 ; debug write memory [expr {$TICK+1}] 0 ; debug write memory $SECS 4 ; debug write memory $BARPX 12 ; debug write memory [expr {$BARPX+1}] 0"
after time 9   "st t9 ; shot t1-lowtime.png"
after time 11  "st t11"
after time 12  "st t12 ; shot t2-dead.png"
after time 16  "st t16 ; shot t3-after.png"
after time 17  "exit"
