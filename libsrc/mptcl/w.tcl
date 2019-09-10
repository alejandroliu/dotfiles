#!/usr/bin/wish

image create photo _mptcllib_smgray -data {
    R0lGODdhOAAYAPAAALi4uAAAACwAAAAAOAAYAAACI4SPqcvtD6OctNqLs968+w+G4kiW5omm
    6sq27gvH8kzX9m0VADv/
}

#frame .f -container yes
label .f  -image _mptcllib_smgray -width 320 -height 240
pack .f -fill both -expand yes

set files [glob *.mp4]
set f [lindex $files [expr {int(rand()*[llength $files])}]]

puts $f
set cmd [list mplayer \
	    -wid [winfo id .f] -quiet -slave \
	    $f \
	   ] 

set fd [open |$cmd r+]

fconfigure $fd -blocking 0 -buffering line
fconfigure stdin -blocking 0 -buffering line

fileevent $fd readable [list readpipe $fd]
fileevent stdin readable [list readcmd stdin]

wm title . "Test MPLAYER"
wm protocol . WM_DELETE_WINDOW Exit

proc Exit {} {
    global fd
    catch { puts $fd quit }
    flush $fd
    exit 1
}

proc readpipe {fd} {
    set d [read $fd]
    foreach line [split $d \n] {
	set line [string trim $line]
	if {$line == ""} continue
	if {[regexp {^ANS_([_/a-z]+)='?(.*)'?$} $line -> prop val]} {
	    puts "ANS_MATCHED: <$prop> <$val>"
	}
	puts ">> ($line)"
    }
    if {[eof $fd]} {
	exit
    }
}
proc readcmd {inp} {
    set d [read $inp]
    global fd

    foreach line [split $d \n] {
	set line [string trim $line]
	puts $fd $line
    }
    if {[eof $inp]} {
	Exit
    }
}
