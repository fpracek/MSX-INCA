set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir wav.log] w]
proc L {s} { global logf; puts $logf $s; flush $logf }
after time 4 {
    if {[catch {record start [file join $basedir title-theme.wav] -audioonly} e]} {
        L "record: $e"
        if {[catch {soundlog start [file join $basedir title-theme.wav]} e2]} { L "soundlog: $e2" }
    } else { L "record avviato" }
}
after time 24 {
    catch {record stop}
    catch {soundlog stop}
    L "stop"
}
after time 25 exit
