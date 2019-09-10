#!/usr/bin/wish
#
# edled.tcl - Simple EDL editor 
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

foreach {a b} {
    "*Button.font"		"Helvetica 8 bold"
    "*Button.takeFocus"		0
    "*Entry.takeFocus"		0
    "*Menubutton.font"		"Helvetica 8 bold"

    "*toolbar.borderWidth"	1
    "*toolbar.relief"		"flat"
    "*main.borderWidth"		2
    "*main.relief"		"sunken"
    "*mctrl.borderWidth"	1
    "*mctrl.relief"		"flat"

    "*main.mv.borderWidth"	0
    "*main.pw.borderWidth"	1
    "*main.pw.relief"		"sunken"

    "*main.mv.bf.borderWidth"	0
    "*main.mv.bf.background"	"black"
    "*main.mv.zb.borderWidth"	1
    "*main.mv.zb.relief"	"raised"

    "*mctrl.play.text"		"#>"
    "*mctrl.prev60.text"	"<<"
    "*mctrl.prev10.text"	"<"
    "*mctrl.nextframe.text"	">|"
    "*mctrl.next10.text"	">"
    "*mctrl.next60.text"	">>"
    "*mctrl.gotoa.text"		">A"
    "*mctrl.gotob.text"		"B<"

    "*toolbar.openmenu.text"	"Open..."
    "*toolbar.openmenu.borderWidth" 1
    "*toolbar.openmenu.relief"	"raised"

    "*toolbar.open_m.text"	"Open Media"
    "*toolbar.open_l.text"	"Open EDL"


    "*toolbar.save.text"	"Save"
    "*toolbar.seta.text"	"A\[_"
    "*toolbar.setb.text"	"_\]B"
    "*toolbar.mute.text"	"Mute"
    "*toolbar.cut.text"		"XCut"

    "*main.pw.lframe.text"	"Frame"
    "*main.pw.lframe.anchor"	"w"
    "*main.pw.ltimepos.text"	"Time Pos"
    "*main.pw.ltimepos.anchor"	"w"
    "*main.pw.ctimepos.text"	"<"
    "*main.pw.cframe.text"	"<"
    

    "*main.pw.ldemuxer.text"	"De-muxer"
    "*main.pw.ldemuxer.anchor"	"w"
    "*main.pw.llength.text"	"Length"
    "*main.pw.llength.anchor"	"w"
    "*main.pw.laudio_codec.text"	"Audio Codec"
    "*main.pw.laudio_codec.anchor"	"w"
    "*main.pw.lsamplerate.text"	"Sample Rate"
    "*main.pw.lsamplerate.anchor"	"w"
    "*main.pw.lchannels.text"	"Channels"
    "*main.pw.lchannels.anchor"	"w"
    "*main.pw.lvideo_codec.text"	"Video Codec"
    "*main.pw.lvideo_codec.anchor"	"w"
    "*main.pw.lwidth.text"	"Width"
    "*main.pw.lwidth.anchor"	"w"
    "*main.pw.lheight.text"	"Height"
    "*main.pw.lheight.anchor"	"w"
    "*main.pw.lfps.text"	"FPS"
    "*main.pw.lfps.anchor"	"w"
    "*main.pw.laspect.text"	"Aspect"
    "*main.pw.laspect.anchor"	"w"


} {
    if {[regexp "^#" $a]} continue
    option add $a $b widgetDefaul
}


proc edled {w args} {
    upvar #0 $w data
    
    set specs {
	{ -menu		""	""	""			}
	{ -mediafile	""	""	""			}
	{ -edlfile	""	""	""			}
    }
    
    tclParseConfigSpec $w $specs "" $args
    if {[winfo exist $w]} {
	if {[winfo toplevel $w] != $w} {
	    error "Can only apply to an existing toplevel window"
	}
	$w config \
	    -menu	$data(-menu)
    } else {
	toplevel $w \
	    -menu	$data(-menu)
    }
    rename $w _${w}_wcmd

    proc $w {cmd args} [format {mptcl_EdlCmd_$cmd %s {*}$args} $w]

    set c $w
    if {$w == "."} { set c ""}

    # Main GUI layout
    set tb [frame $c.toolbar]	;# toolbar
    set mm [frame $c.main]	;# main work area
    set bt [frame $c.mctrl]	;# media playing controls

    pack $tb -side top -fill x -expand no
    pack $bt -side bottom -fill x -expand no
    pack $mm -side top -fill both -expand yes

    # Main work area layout
    set mv [frame $mm.mv]	;# Main viewing area
    set pw [frame $mm.pw]	;# Properties window

    pack $pw -side right -fill y -expand no
    pack $mv -side left -fill both -expand yes

    # Main viewer area
    set data(seekbar) [zoekbar $mv.zb -player $mv.player]
    set data(backframe) [frame $mv.bf]
    set data(player) [mplayer $mv.player -seekbar $mv.zb \
			  -callback [list $w mpcb]]

    pack $data(seekbar) -side bottom -fill x -expand no
    pack $data(backframe) -side top -fill both -expand yes
    pack $data(player) -in $mv.bf -fill none -expand no

    # Populate media controler
    button $bt.play -command [list $w mcmd pause]
    button $bt.prev60 -command [list  $w mcmd seek -60]
    button $bt.prev10 -command [list  $w mcmd seek -10]
    button $bt.nextframe -command [list $w mcmd frame_step]    
    button $bt.next10 -command [list $w mcmd seek 10]
    button $bt.next60 -command [list $w mcmd seek 60]

    button $bt.gotoa -command [list $w mcmd gotoa]
    button $bt.gotob -command [list $w mcmd gotob]

    pack \
	$bt.play $bt.prev60 $bt.prev10 \
	$bt.nextframe $bt.next10 $bt.next60 \
	$bt.gotoa $bt.gotob \
	-side left -fill y -expand no

    # Populate toolbar commands
    menubutton $tb.openmenu -menu $tb.openmenu.m
    button $tb.save -command [list $w tool save]

    set m [menu $tb.openmenu.m -tearoff 0]
    $m add command -label "Media" -underline 0 -command [list $w tool openMedia]
    $m add command -label "EDL" -underline 0 -command [list $w tool openEdl]

    button $tb.seta -command [list $w tool seta]
    button $tb.setb -command [list $w tool setb]
    button $tb.mute -command [list $w tool mute]
    button $tb.cut -command [list $w tool xcut]
		      
    pack \
	$tb.openmenu $tb.save \
	$tb.seta $tb.setb $tb.mute $tb.cut \
	-side left -fill y -expand no

    # Properties window
    foreach v {
	demuxer 
	audio_codec samplerate channels 
	video_codec width height fps aspect
	length
    } {
	label $pw.l$v
	entry $pw.v$v -state readonly -textvariable ${w}(pw,$v)
	grid $pw.l$v $pw.v$v -sticky news
    }
    foreach v {
	frame timepos
    } {
	label $pw.l$v
	frame $pw.f$v
	set data(ct,$v) [entry $pw.v$v \
			     -takefocus 1 \
			     -state normal \
			     -textvariable ${w}(ew,$v)]
	button $pw.c$v -command [list $w seekto $v go]
	grid $pw.l$v $pw.f$v -sticky news
	pack $pw.c$v -in $pw.f$v -side right -expand no -fill y
	pack $pw.v$v -in $pw.f$v -side left -expand no -fill x
	set data(wi,$v) $pw.v$v

	bind $pw.v$v <FocusIn> [list $w seekto $v in]
	bind $pw.v$v <Key-Return> [format {
	    %s seekto %s go
	    break
	} $w $v]
    }
		      
    wm title $w "EDL Editor"

    set data(w) -1
    set data(h) -1

    mplayer_bindings $data(seekbar) $data(player)
    bind $data(seekbar) <Key-space> [list $w mcmd  pause]
    bind $data(seekbar) <Key-Left> [list $w mcmd seek -10]
    bind $data(seekbar) <Key-Right> [list $w mcmd seek 10]
    bind $data(seekbar) <Key-Down> [list $w mcmd seek -60]
    bind $data(seekbar) <Key-Up> [list $w mcmd seek 60]

    bind $data(seekbar) <Key-Return> [list $w mcmd frame_step]
    bind $data(seekbar) <Key-a>	[list $w mcmd gotoa]
    bind $data(seekbar) <Key-b>	[list $w mcmd gotob]
    bind $data(seekbar) <Key-A>	[list $w tool seta]
    bind $data(seekbar) <Key-B>	[list $w tool setb]
    bind $data(seekbar) <<SegmentEvent>> [list $w zbev %d]

    bind $data(backframe) <Configure> [list $w tryresize %w %h %W]

    bind $data(player) <<MediaStart>> [list $w mediastarting]
    bind $data(player) <<MediaEnd>> [list $w mediaending]
    bind $w <Destroy> [list mptcl_Edl_cleanup $w %%W]

    bind $w <FocusIn> [list $w seekto %W focus]

    if {$args != ""} {
	mptcl_EdlCmd_config $w {*}$args
    }
    focus $data(seekbar)
}

proc mtcl_Edl_cleanup {w ww} {
    if {$w != $ww} return
    uplevel "#0" [list unset $w]
}

proc mptcl_EdlCmd_config {w args} {
    upvar #0 $w data

    if { $args=="" } { 
	error "Arguments \"$w\" Umpty!" 
	return 1
    }
    set wargs [list]
    foreach { param value } $args {
	set data($param) $value
	switch -- $param {
	    "-mediafile" {
		if {$data(-mediafile) == ""} {
		    if {[$data(player) status] == "nomedia"} return
		    wm title $w "EDL Editor"
		    $data(player) config -file ""

		    foreach var [array names data "pw,*"] {
			set data($var) ""
		    }
		    foreach var {frame timepos} {
			set data($var) ""
		    }
		    $data(seekbar) config -edl ""
		    return
		}
		if {[$data(player) cget -file] != $data(-mediafile)} {
		    $data(player) config -file $data(-mediafile)
		    wm title $w \
			[format "%s: EDL Editor" [file tail $data(-mediafile)]]
		}
		mptcl_Edl_FileLoad $w
	    }
	    "-edlfile" {
		if {$data(-mediafile) != ""} {
		    mptcl_Edl_FileLoad $w
		}
	    }
	    "-menu"	{ lappend wargs $param $value }
	    default { 
		error "Argument \"$param\" Error"
		return 1
	    }
	}
    }
    if {$wargs != ""} {
	_${w}_wcmd config {*}$wargs
    }
}


proc mptcl_EdlCmd_tryresize {w wi he ww} {
    # Try to resize the window
    upvar #0 $w data
    if {$data(backframe) != $ww} return
    if {$data(w) == $wi && $data(h) == $he} return
    if {[info exists data(resize)]} {
	after cancel $data(resize)
    }
    set data(resize) [after 250 [list mptcl_EdlResize_apply $w $wi $he]]

}

proc mptcl_EdlResize_apply {w wi he} {
    upvar #0 $w data

    set data(w) $wi
    set data(h) $he
    if {[mptcl_in [$data(player) status] "loading" "nomedia"]} return

    mptcl_Edl_FitView $data(player) $wi $he
}

proc mptcl_Edl_FitView {p wi he} {
    set mwi [$p width]
    set mhe [$p height]
    foreach {nwi nhe} [mptcl_scaleview $wi $he $mwi $mhe] break
    $p config -width $nwi -height $nhe
}

proc mptcl_Edl_FileLoad {w} {
    upvar #0 $w data
    
    if {$data(-edlfile) == ""} {
	$data(seekbar) config -edl ""
	return
    }
    if {[mptcl_in [$data(player) status] "loading" "nomedia"]} {
	# Not loaded... try again in a few moments...
	after 100 [list mptcl_Edl_FileLoad $w]
	return
    }
    set len [$data(player) length]
    foreach {lst errs} [mptcl_load_edl $data(-edlfile) $len] break
    if {$errs != ""} {
	tk_messageBox \
	    -type "ok" \
	    -icon "info" \
	    -message [format "Error Reading EDL file\n\t%s\n" \
			  [join $errs "\n\t"]] \
	    -title [format "%s: EDL Editor" $data(-edlfile)] \
	    -parent $w
    }
    $data(seekbar) config -edl [mptcl_clean_edl $lst]
}

proc mptcl_EdlCmd_zbev {w detail} {
    upvar #0 $w data
    # Seekbar clicking on segments
    foreach {ev bn id} $detail break
    switch -- $ev {
	"<ButtonPress>" {
	    foreach {a b op} [$data(seekbar) edl get $id] break
	    $data(seekbar) seg $a $b
	    if {$bn == 3} {
		$data(seekbar) edl toggle $id
	    }
	}
	"<Double-ButtonPress>" {
	    if {$bn == 1} {
		$data(seekbar) edl del $id
	    }
	}
    }
}

proc mptcl_EdlCmd_mpcb {w op args} {
    # MPlayer callback handler
    upvar #0 $w data
    set novideo 0
    switch -- $op {
	"V"	{
	    set pos [lindex $args 0]
	}
	"AV" 	{
	    set pos [lindex $args 1]
	}
	"A" 	{
	    set pos [lindex $args 0]
	    set novideo 1
	}
	"pause" {
	    #
	    return
	}
	default {
	    puts stderr "Internal error; MEDIACALLBACK $op $args"
	    return
	}
    }
    set f [focus]
    if {$f != $data(ct,timepos)} {
	set data(ew,timepos) $pos
    }
    if {$f != $data(ct,frame)} {
	if {$novideo} {
	    set data(ew,frame) ""
	    $data(ct,frame) -state readonly
	} else {
	    set data(ew,frame) [expr {int([$data(player) fps]*$pos+0.5)}]
	}
    }
}
proc mptcl_EdlCmd_mcmd {w op args} {
    upvar #0 $w data

    set status [$data(player) status]
    if {[mptcl_in $status "nomedia" "loading"]} return
    if {$status == "stopped"} {
	$data(player) play
	return
    }

    # Media Control commands
    switch -- $op {
	pause {
	    $data(player) pause
	}
	seek {
	    mptcl_MPRemote $data(player) pausing_keep seek [lindex $args 0]
	}
	frame_step {
	    $data(player) frame_step
	}
	gotoa {
	    $data(seekbar) gotoa
	}
	gotob {
	    $data(seekbar) gotob
	}
    }
}

proc mptcl_EdlCmd_tool {w op} {
    upvar #0 $w data
    # Toolbar cmd
    switch -- $op {
	openMedia {
	    # This will close the EDL too
	    if {$data(-mediafile) == ""} {
		set idir [pwd]
		set ifile ""
	    } else {
		set idir [file dirname $data(-mediafile)]
		set ifile [file tail $data(-mediafile)]
	    }
	    set open [tk_getOpenFile \
			  -filetypes {
			      { {All supported videos files} {
				  .avi .AVI .flv .FLV .mkv .MKV
				  .mp4 .MP4 .m4v .M4V
				  .mpg .MPG .mpeg .MPEG
				  .wmv .WMV .asf .ASF
			      } }
			      { {MS Video AVI} {.avi .AVI} }
			      { {Flash Video FLV} {.flv .FLV} }
			      { {Matroska MKV} {.mkv .MKV} }
			      { {MPEGv4 mp4} {.mp4 .MP4 .m4v .M4V} }
			      { {MPEGv1 mpg} {.mpg .MPG .mpeg .MPEG} }
			      { {Windows Media WMV} {.wmv .WMV .asf .ASF} }
			  } \
			  -initialdir $idir \
			  -initialfile $ifile \
			  -parent $w \
			  -title "Open Media file" \
			 ]
	    if {$open == ""} return
	    set pedl "[file rootname $open].edl"
	    if {![file exists $pedl]} {
		set pedl {}
	    }
	    $w config \
		-mediafile $open \
		-edlfile $pedl
	}
	openEdl {
	    # This will close the EDL too
	    if {$data(-mediafile) == ""} {
		tk_messageBox \
		    -type "ok" \
		    -icon "error" \
		    -message "Must specify a media file first" \
		    -title "EDL Editor" \
		    -parent $w
		return
	    }
	    set idir [file dirname $data(-mediafile)]
	    set ifil "[file rootname [file tail $data(-mediafile)]].ext"
	    set open [tk_getOpenFile \
			  -filetypes {
				  {{Edit Decision List} {.edl .EDL}}
			  } \
			  -initialdir $idir \
			  -initialfile $ifil \
			  -parent $w \
			  -title [format "%s: Open EDL" \
				      [file tail $data(-mediafile)]] \
			 ]
	    
	    if {$open == ""} return
	    $w config \
		-edlfile $open
	}
	save {
	    if {$data(-mediafile) == ""} return
	    if {$data(-edlfile) == ""} {
		set idir [file dirname $data(-mediafile)]
		set ifile "[file rootname [file tail $data(-mediafile)]].edl"
		set save [tk_getSaveFile \
			      -filetypes {
				  {{Edit Decision List} {.edl .EDL}}
			      } \
			      -initialdir $idir \
			      -initialfile $ifile \
			      -parent $w \
			      -title [format "%s: Save EDL file" \
					  [file tail $data(-mediafile)]] \
			     ]
		if {$save == ""} return
		set data(-edlfile) $save
	    }
	    mptcl_save_edl $data(-edlfile) \
		[mptcl_fix_edl [$data(seekbar) cget -edl] \
		     [$data(player) length]]
	}
	seta {
	    $data(seekbar) seta
	}
	setb {
	    $data(seekbar) setb
	}
	mute -
	xcut {
	    foreach {sa sb} [$data(seekbar) seg] break
	    if {$sa == "" || $sb == ""} return
	    if {$op == "mute"} {
		set c 1
	    } else {
		set c 0
	    }
	    $data(seekbar) edl add $sa $sb $c
	}
    }
}

proc mptcl_EdlCmd_seekto {w fld op} {
    upvar #0 $w data
    # Handle GOTO commands
    set status [$data(player) status]
    if {[mptcl_in $status "nomedia" "loading"]} return
    if {$status == "stopped"} {
	$data(player) play
	return
    }

    switch -- $op {
	focus {
	    if {[winfo class $fld] == "Entry"} {
		if {[mptcl_in $fld $data(ct,timepos) $data(ct,frame)]} return
		focus $data(seekbar)
	    }
	    if {$w == $fld} {
		focus $data(seekbar)
	    }
	}
	go {
	    # Jump to frame/timepos
	    set val $data(ew,$fld)
	    if {![string is double $val]} {
		# Not a valid value!
		$data(player) pause 0
		return
	    }
	    if {$fld == "frame"} {
		set val [expr {$val/[$data(player) fps]}]
	    }
	    focus $data(seekbar)
	    $data(player) seek $val 2
	    $data(player) pause 0
	}
	in {
	    # Got focus
	    $data(player) pause 1
	}
    }
}


proc mptcl_EdlCmd_mediastarting {w} {
    upvar #0 $w data

    # Complete meta data
    foreach var [array names data "pw,*"] {
	set tag [regsub {^pw,} $var {}]
	if {[catch {$data(player) $tag} tval]} {
	    puts stderr "$data(player) $tag: $tval"
	    set tval ""
	}
	set data($var) $tval
    }
    $data(player) pause 1
}
proc mptcl_EdlCmd_mediaending {w} {
    upvar #0 $w data
    $data(player) play
}

