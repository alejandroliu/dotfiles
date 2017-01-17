#!/usr/bin/wish

source mplayer.tcl
source zoekbar.tcl

#source console.tcl ; console show

bind . <Key> [list puts "Keysym is %K"]

set edl [list \
	     {5.0 20.0 0} \
	     {40.0 45.0 1} \
	     {70.0 80.0 0}]

zoekbar .b -player .f -edl $edl
mplayer .f -seekbar .b

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

