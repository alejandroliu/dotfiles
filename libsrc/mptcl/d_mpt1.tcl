#!/usr/bin/wish

source mplayer.tcl
#source console.tcl ; console show

mplayer .f
pack .f  -fill both -expand yes

mplayer_bindings . .f 
bind . <Key> [list puts "Keysym is %K"]
bind .f <<MediaEnd>> [list pick_file .f]
bind .f <<MediaStart>> {
    puts stderr MediaStart
    parray .f
}

proc pick_file {p} {
    global argv

    if {![llength $argv]} exit

    set f [lindex $argv 0]
    set argv [lreplace $argv 0 0]
    $p config -file $f
}
pick_file .f

