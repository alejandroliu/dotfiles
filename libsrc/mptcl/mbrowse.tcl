#!/usr/bin/wish
#
# mbrowse.tcl 
# Copyright (C) 2012 Alejandro Liu Ly
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are 
# met:
#
#    * Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright 
#      notice, this list of conditions and the following disclaimer in the 
#      documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
#
package provide mpbrowser 0.1.0

#
# File type filter
#
foreach i {avi flv mkv mp4 mpg wmv mpeg mov webm} {
    set _mptcllib_mfilter(.$i) 1
}
unset i

#
# Shuffle list
#
proc mptcl_shuffle { lst } {
    set retval [list]
    while {[llength $lst]} {
	set j [expr {int(rand()*[llength $lst])}]
	lappend retval [lindex $lst $j]
	set lst [lreplace $lst $j $j]
    }
    return $retval
}

proc mptcl_tcmp {dir a b} {
  set ma [file mtime $a]
  set mb [file mtime $b]
  return [expr {($ma - $mb)*$dir}]
}


proc mptcl_tcmp1 {a b} {
  return [mptcl_tcmp 1 $a $b]
}
proc mptcl_tcmp-1 {a b} {
  return [mptcl_tcmp -1 $a $b]
}

# Sort files by mtime
proc mptcl_tsort { lst {dir 1} } {
  return [lsort -command mptcl_tcmp$dir $lst]
}


#
# Process file items
#
proc mptcl_process {item list_ref} {
    upvar $list_ref flist
    if {[file isdir $item]} {
	foreach f [lsort -dictionary [glob -directory $item -nocomplain "*"]] {
	    mptcl_process $f flist
	}
	return
    }
    if {![file isfile $item]} return
    global _mptcllib_mfilter
    set ext [string tolower [file extension $item]]
    if {[info exists _mptcllib_mfilter($ext)]} {
	lappend flist $item
    }
}

######################################################################
#
# Media rbowser gui
#
######################################################################

proc mbrowser {w args} {
    #1. default spec
    upvar #0 $w data
    
    set specs {
	{ -relief	""	""	raised 			}
	{ -background	""	""	#000000 		}
	{ -bg		""	""	#000000 		}
	{ -borderwidth	""	""	0 			}
	{ -bd		""	""	0 			}
	{ -menu		""	""	""			}
	{ -files	""	""	""			}
	{ -playing	""	""	""			}
	{ -loop		""	""	0			}
	{ -seekbar	""	""	0			}
    }

    tclParseConfigSpec $w $specs "" $args

    if { $data(-bg)!="#000000" } {
	set data(-background) $data(-bg)
    }
    if { $data(-bd) } {
	set data(-borderwidth) $data(-bd) 
    }

    if {[winfo exist $w]} {
	if {[winfo toplevel $w] != $w} {
	    error "Can only apply to an existing toplevel window"
	}
	$w config \
	    -bd 	$data(-borderwidth) \
	    -bg 	$data(-background) \
	    -menu	$data(-menu) \
	    -relief	$data(-relief)
    } else {
	toplevel $w \
	    -bd 	$data(-borderwidth) \
	    -bg 	$data(-background) \
	    -menu	$data(-menu) \
	    -relief	$data(-relief)
    }
    rename $w _${w}_wcmd

    proc $w {cmd args} [format {mptcl_BrowserCmd_$cmd %s {*}$args} $w]

    set c $w
    if {$w == "."} { set c ""}

    set xargs [list]
    if {$data(-seekbar)} {
	lappend xargs -seekbar $c.bar
    }

    set data(player) $c.player
    mplayer $data(player) {*}$xargs
    if {$data(-seekbar)} {
	set seekbar $data(-seekbar)
	if {[info commands $seekbar] == {}} {
	    set seekbar seekbar
	}
	set data(seekbar) $c.bar
	$seekbar $data(seekbar)	-player $data(player) -orient horizontal

	# Defaults to hidden..
	# pack $data(seekbar) -fill x -expand no -side bottom
	pack $data(player) -fill both -expand yes
    } else {
	pack $data(player)
    }
    wm title $w "MediaPlay"

    if {$args != ""} {
	mptcl_BrowserCmd_config $w {*}$args
    }

    set data(w) -1
    set data(h) -1

    bind $w <Configure> [list mptcl_resize_test $w $data(player) %w %h %W]
    mplayer_bindings $w $data(player)
    bind $data(player) <<MediaEnd>> [list mptcl_BrowserCmd_next $w]
    bind $data(player) <<MediaStart>> [list mptcl_mediastart $w]

    bind $w <Key-Next> [list $w next]
    bind $w <Key-period> [list $w next]
    bind $w <Key-greater> [list $w next]
    bind $w <Key-Return> [list $w next]
    bind $w <Key-Prior> [list $w prev]
    bind $w <Key-comma> [list $w prev]
    bind $w <Key-less> [list $w prev]
    bind $w <Key-f> [list $w fullscreen]
    bind $w <Key-q> [list after 100 destroy $w ]
    if {$data(-seekbar)} {
	bind $w <Key-b> [list $w toggle_seekbar]
    }
}

proc mptcl_resize_test {w p wi he W} {
    upvar #0 $w data
    if {($data(w) == $wi && $data(h) == $he) || $W != $w} return
    if {[info exists data(resize)]} {
	after cancel $data(resize)
    }
    set data(resize) [after 400 [list mptcl_resize_apply $w $p $wi $he]]
}

proc mptcl_fit_view {p wi he} {
    set mwi [$p width]
    set mhe [$p height]

    foreach {nwi nhe} [mptcl_scaleview $wi $he $mwi $mhe] break
    $p config -width $nwi -height $nhe
}

proc mptcl_resize_apply {w p wi he} {
    upvar #0 $w data
    
    set data(w) $wi
    set data(h) $he

    if {[mptcl_in [$p status] "nomedia" "loading"]} return
    mptcl_fit_view $p $wi $he
}

#
# Media Player commands...
#
proc mptcl_BrowserCmd_toggle_seekbar {w args} {
    upvar #0 $w data
    if {[winfo viewable $data(seekbar)]} {
	pack forget $data(seekbar)
    } else {
	pack forget $data(player)
	pack $data(seekbar) -fill x -expand no -side bottom
	pack $data(player) -fill both -expand yes
    }
}

proc mptcl_BrowserCmd_fullscreen {w args} {
    if {[llength $args] == 0} {
	# Toggle...
	set now [wm attributes $w -fullscreen]
	if {$now} {
	    wm attributes $w -fullscreen 0
	} else {
	    wm attributes $w -fullscreen 1
	}
    } elseif {[llength $args] == 1} {
	wm attributes $w -fullscreen [lindex $args 0]
    } else {
	error "Usage: $w fullscreen \[bool\]"
    }
}

proc mptcl_BrowserCmd_config {w args} {
    upvar #0 $w data

    if { $args=="" } { 
	error "Arguments \"$w\" Umpty!" 
	return 1
    }
    set wargs [list]
    foreach { param value } $args {
	set data($param) $value
	switch -- $param {
	    "-files"	{
		set data(-playing) ""
		$data(player) stop
	    }
	    "-playing"	{
		if {$value == ""} {
		    $data(player) stop
		    wm title $w "MediaPlay"
		} else {
		    set fn [lindex $data(-files) $value]
		    $data(player) config -file $fn
		    wm title $w [format "%s -- %s" [file tail $fn] "MediaPlay"]
		}
	    }
	    "-seekbar" {
		continue
	    }
	    "-loop"	{
		# Not much to do...
		continue
	    }
	    "-relief"	-
	    "-bg"	-
	    "-background" -
	    "-bd"	-
	    "-menu"	-
	    "-borderwidth" { lappend wargs $param $value }
	    default { 
		error "Argument \"$param\" Error"
		return 1
	    }
	}
    }
    if {$wargs != ""} {
	_${w}_wcmd config {*}$labelargs
    }
}

proc mptcl_BrowserCmd_cget {w option} {
    upvar #0 $w data
    return $data($option)
}

proc mptcl_BrowserCmd_next {w} {
    upvar #0 $w data
    if {$data(-files) == ""} return

    set next [expr {$data(-playing)+1}]
    if {[llength $data(-files)] <= $next} {
	if {!$data(-loop)} {
	    event generate $w <<PlaylistEnd>>
	    return
	}
	set next 0
    }
    $w config -playing $next
}

proc mptcl_BrowserCmd_prev {w} {
    upvar #0 $w data
    if {$data(-files) == ""} return

    set next [expr {$data(-playing)-1}]
    if {$next < 0} {
	if {$data(-loop)} {
	    set next [expr {[llength $data(-files)]-1}]
	} else {
	    return
	}
    }
    $w config -playing $next
}

proc mptcl_BrowserCmd_player {w args} {
    upvar #0 $w data
    if {[llength $args] == 0} {
	return $data(player)
    }
    return $data(player) {*}$args
}

proc mptcl_mediastart {w} {
    upvar #0 $w data
    set mwi [$data(player) width]
    set mhe [$data(player) height]

    if {[wm attributes . -fullscreen]} {
	# Full screen... fit player to window
	mptcl_fit_view $data(player) $data(w) $data(h)
	mptcl_MPRemote $data(player) osd_show_property_text {${filename}}
    } else {
	# Windowed... fit window to player...
	$data(player) config -width $mwi -height $mhe
	wm geometry $w "${mwi}x${mhe}"
    }
}

