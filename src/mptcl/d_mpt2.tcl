#!/usr/bin/wish

source mplayer.tcl
source seekbar.tcl

# source console.tcl ; console show

bind . <Key> [list puts "Keysym is %K"]

mplayer .f -seekbar .b
seekbar .b -player .f -orient horizontal

pack .b -fill x -expand no -side bottom
pack .f -fill both -expand yes

mplayer_bindings . .f 
bind .f <<MediaEnd>> { pick_file .f }

proc pick_file {p} {
    global argv

    if {![llength $argv]} exit

    set f [lindex $argv 0]
    set argv [lreplace $argv 0 0]
    $p config -file $f
}
pick_file .f

