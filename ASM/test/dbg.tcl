set basedir [file dirname [file normalize [info script]]]
set logf [open [file join $basedir dbg.log] w]

proc L {s} { global logf; puts $logf $s; flush $logf }

proc hexrange {space base n} {
    set s ""
    for {set i 0} {$i < $n} {incr i} {
        append s [format "%02X " [debug read $space [expr {$base + $i}]]]
    }
    return $s
}

proc dump {tag} {
    L "--- $tag ---"
    L "PC=[format %04X [reg pc]] SP=[format %04X [reg sp]]"
    L "state=[debug read memory 0xC003] frame=[debug read memory 0xC000]"
    L "VDPregs= [hexrange {VDP regs} 0 8]"
    L "name(6,9)= [hexrange VRAM [expr {0x1800 + 6*32 + 9}] 16]"
    L "coltab= [hexrange VRAM 0x2000 8]"
    L "pat60h= [hexrange VRAM 0x300 8]"
    L "pat08h= [hexrange VRAM 0x40 8]"
}

after time 3   "dump t3"
after time 6   "dump t6"
after time 6.1 "screenshot -force [file join $basedir dbg.png]"
after time 6.2 "exit"
