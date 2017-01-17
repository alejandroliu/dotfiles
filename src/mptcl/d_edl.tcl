#!/usr/bin/wish
set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir mplayer.tcl]
source [file join $scriptdir zoekbar.tcl]
source [file join $scriptdir edled.tcl]

proc main {{mediafile {}} {edlfile {}}} {
    if {$mediafile == ""} {
	set edlfile ""
    } else {
	if {$edlfile == ""} {
	    set pedl "[file rootname $mediafile].edl"
	    if {[file exists $pedl]} {
		set edlfile $pedl
	    }
	}
    }
    edled . -mediafile $mediafile -edlfile $edlfile
}

main {*}$argv
