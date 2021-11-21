#!/usr/bin/wish
#
# mplayer.tcl
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
package provide mplayer 0.4.1

if {[catch {
    source [file join [file dirname [file normalize [info script]]] quote.tcl]
}]} {
    namespace eval HCLS {
	namespace eval quote {proc glob {x} { return $x }}
    }
}

proc rem {args} {}
interp alias {} debug {} puts

variable mptcl_mouse_timeout 3000	;# milli-seconds before hiding the mouse
variable mptcl_exe \
    [list /usr/bin/mplayer mplayer] 	;# path to mplayer executable
variable mptcl_proptout 250		;# time-out period to wait for property
variable mptcl_metatout 1000		;# time-out period to wait for meta data
variable mptcl_metaretry 3		;# Number of tries to load meta data
variable mptcl_meta			;# array containing meta data to load
array set mptcl_meta {
    demuxer		AV
    length		AV
    audio_codec		A
    audio_bitrate	A
    samplerate		A
    channels		A
    video_codec		V
    width		V
    height		V
    fps			V
    aspect		V
}

foreach i [array names mptcl_meta] {
    proc mptcl_MPCmd_${i} {w} [format {
	upvar #0 $w data
	return [dict get $data(meta) %s]
    } $i]
}
unset i

#########################
# mplayer command
#
proc mplayer { w args } {
    #    Embedded mplayer widget
    # ARGS
    #    @param w - widget path
    #    @param args - options (See [mptcl_MPCmd_config])
    # RETN
    #    Returns the widget path that was created
    # DESC
    #    Create a mplayer embedded widget.
    #
    #    Also creates a widget command that will call all procedures
    #    prefixed with mptcl_MPCmd_.  So any procedure with name
    #    starting with mptcl_MPCmd_ can be treated as a widget
    #    subcommand.
    upvar #0 $w data

    #1. default spec
    set specs {
	{-cursor	""		""	""	}
	{-width		""		""	320	}
	{-height	""		""	240	}
	{-file		""		""	""	}
	{-vo		""		""	""	}
	{-ao		""		""	""	}
	{-callback	""		""	""	}
	{-seekbar	""		""	""	}
    }
    tclParseConfigSpec $w $specs "" $args

    frame $w \
	-container yes \
	-width 	$data(-width) \
	-height $data(-height) \
	-bg 	"black"	\
	-cursor $data(-cursor) \
	-class MPlayer

    set data(wid) [winfo id $w]
    rename $w _${w}_wcmd
    proc $w {cmd args} "mptcl_MPCmd_\$cmd [list $w] {*}\$args"

    bind $w <Destroy> [list mptcl_MPCleanUp $w]
    bind $w <Motion> [list mptcl_MPMouse $w show]

    set data(fid) {}
    set data(meta) [dict create]

    if {$args != ""} {
	mptcl_MPCmd_config $w {*}$args
    }
    mptcl_MPMouse $w hide

    return $w
}

proc mptcl_MPRemote {w args} {
    #    Send remote commands to mplayer
    # ARGS
    #    @param w - mplayer widget
    #    @param args - command to send to mplayer

    upvar #0 $w data
    if {$data(fid) == ""} {return 0}

    debug "CMD: $args"
    if {[lindex $args 0] == "-c"} {
	catch { puts -nonewline $data(fid) [join [lreplace $args 0 0] " "] }
    } else {
	catch { puts $data(fid) [join $args " "]}
    }
    catch { flush $data(fid) }
}

proc mptcl_AbortTimers {w} {
    # Check running timers and abort them
    upvar #0 $w data

    foreach prop [array names data prop,*] {
	catch { after cancel data($prop) }
    }
    if {[info exists data(meta)]} {
	if {[dict exists $data(meta) loading]} {
	    catch {after cancel [dict get $data(meta) loading]}
	}
    }
}


proc stop_clean_up {victim} {
    if {[file isdir "/proc/$victim"]} {
	puts ">>> CLEANUP $victim <<<<"
	exec sh -c "sleep 10 ; kill -9 $victim >/dev/null 2>&1" &
	puts "YES KILL IT!"
    }
}


# gets the stack up to the caller
proc get_stack {} {
    set result {}
    for {set i [expr {[info level] -1}]} {$i >0} {incr i -1} {
        lappend result [info level $i]
    }
    return $result
}
proc mptcl_MPCmd_stop {w} {
    #    stop playback (widget sub-command)
    # DESC
    #    Will stop playback and quit the running mplayer sub-process
    upvar #0 $w data
    if {$data(fid) == ""} return
    parray data
    mptcl_MPRemote $w quit
    set vic [pid $data(fid)]
    close $data(fid)
    after 1000 [list stop_clean_up $vic]
    # check timers if they are running
    mptcl_AbortTimers $w
    puts [after info]
    foreach id [after info] {
      puts "$id [after info $id]"
    }

    catch {unset data(time_pos)}
    catch {unset data(pause)}

    set data(fid) ""
    puts [get_stack]
}

proc mptcl_MPCmd_play {w} {
    #    start playback (widget sub-command)
    # DESC
    #    Will start a stopped player.

    upvar #0 $w data
    if {$data(fid) != ""} return
    mptcl_MPLaunchPlayer $w
}

proc mptcl_MPCmd_config {w args} {
    #    configure widget (widget sub-command)
    # OPTS
    #    - -file : Media file to load
    #    - -cursor : mouse cursor.
    #    - -callback : callback function used when parsing MPlayer status line
    #    - -seekbar : seekbar widget associated with this mplayer widget
    #    - -width : window width
    #    - -height : window height


    upvar #0 $w data

    if { $args=="" } {
	error "Arguments \"$w\" Umpty!"
	return 1
    }
    set labelargs [list]
    foreach { param value } $args {
	set data($param) $value
	switch -- $param {
	    "-file" 	{
		set data(meta) [dict create]

		if {$data(-file) == ""} {
		    $w stop
		} else {
		    mptcl_MPLaunchPlayer $w
		}
	    }
	    "-cursor"	{
		mptcl_MPMouse $w show
	    }
	    "-callback" -
	    "-seekbar"	{}
	    "-width" 	-
	    "-height" 	{ lappend labelargs $param $value }
	    default {
		error "Argument \"$param\" Error"
		return 1
	    }
	}
    }
    if {$labelargs != ""} {
	_${w}_wcmd config {*}$labelargs
    }
}

proc mptcl_MPMouse {w mode} {
    #    Handle mouse
    # ARGS
    #    @w - mplayer widget
    #    @mode - either "hide" or "show"
    # DESC
    #    Handles mouse movement by either showing or hiding the mouse.
    #
    #    Essentially will hide the mouse until the user moves it,
    #    which will cause the mouse cursor to be shown.  It will
    #    then hide cursor after a few seconds of no mouse movement
    upvar #0 $w data

    if {[info exists data(mousehide)]} {
	after cancel $data(mousehide)
    }
    global mptcl_mouse_timeout
    set data(mousehide) [after $mptcl_mouse_timeout \
			     [list mptcl_MPMouse $w hide]]

    switch $mode {
	show {
	    set next $data(-cursor)
	}
	hide {
	    set next "none"
	}
	default {
	    error" Invalid cursor mode $mode"
	}
    }
    if {[_${w}_wcmd cget -cursor] != $next} {
	_${w}_wcmd config -cursor $next
    }
}

proc mptcl_MPCleanUp {w} {
    #    Release resources
    # DESC
    #    Will clean-up a mplayer widget.  Normally trigerred by the <Destroy>
    #    event.
    upvar #0 $w data
    $w stop
    if {[info exists data(mousehide)]} {
	after cancel $data(mousehide)
    }
    uplevel "#0" [list unset $w]
}

proc mptcl_MPLaunchPlayer {w} {
    #    Start a mplayer sub-process
    # DESC
    #    Start a new mplayer sub-process
    upvar #0 $w data

    if {$data(-file) == ""} return
    if {![file exists $data(-file)]} {
	error "$data(-file): does not exists"
    }

    if {$data(fid) == ""} {
	global mptcl_exe
	set arglst [list \
			-zoom \
			-slave \
			-wid $data(wid) \
		       ]
	foreach {cc evkey} {-vo MPT_VO -ao MPT_AO} {
	    if {$data($cc) != ""} {
		lappend arglst $cc $data($cc)
	    } else {
	      global env
	      if {[info exists env($evkey)]} {
		lappend arglst $cc $env($evkey)
	      }
	    }
	}
	if {$data(-callback) == "" && $data(-seekbar) == ""} {
	    lappend arglst "-quiet"
	}
	# Handle additional sub files...
	set rr [file rootname $data(-file)]
	set sub [glob -nocomplain "[HCLS::quote::glob $rr].*.srt"]
	puts "RR=$rr SUB: $sub"
	if {$sub != ""} {
	    set sub [lindex $sub 0]
	    lappend arglst -sub $sub
	}
	lappend arglst $data(-file)
	foreach cmd $mptcl_exe {
	    if {![catch {open "|$cmd $arglst 2>@1" r+} fd]} {
		# mplayer started...
		set data(fid) $fd

		# Set pipe
		fconfigure $data(fid) -blocking 0 -buffering line
		fileevent $data(fid) readable [list mptcl_MPReadPipe $w]
		return
	    }
	 }
	error "Error launching mplayer ($mptcl_exe)"
    } else {
	$w loadfile $data(-file)
    }
    # Check if timers are running
    mptcl_AbortTimers $w

    catch {unset data(time_pos)}
    catch {unset data(pause)}
}

proc mptcl_MPReadPipe {w} {
    #    pipe event handler
    # DESC
    #    Event handler that handles the mplayer sub-process pipe
    upvar #0 $w data
    if {$data(fid) == ""} return	;# Weird!

    set d [read $data(fid)]
    foreach line [split $d \n] {
	mptcl_MPhandleline $w $line
    }
    if {[eof $data(fid)]} {
	puts "EOF MPTCL REMOTE"
	close $data(fid)

	# Check if timers are running...
	mptcl_AbortTimers $w

	set data(fid) ""
	catch {unset data(time_pos)}
	catch {unset data(pause)}

	event generate $w <<MediaEnd>>
	if {$data(-seekbar) != ""} {
	    $data(-seekbar) mediaend
	}
    }

}

proc mptcl_MPhandleline {w line} {
    #    Handle a single line read from the mplayer pipe
    # ARGS
    #    @param w - mplayer widget
    #    @param line - line being processed
    # DESC
    #    Handle input from the mplayer process

    upvar #0 $w data

    set line [string trim $line]
    if {$line == ""} return

    if {($data(-callback) != "" || $data(-seekbar) != "") && \
	    $data(meta) != "" && ![dict exists $data(meta) loading]} {
	# MUXed Audio and Video
	if {[regexp {^A:\s*([0-9]+\.[0-9]+)\s+V:\s*([0-9]+\.[0-9]+)\s+A-V:\s+(-?[0-9]+\.[0-9]+)\s+ct:\s+(-?[0-9]+\.[0-9]+)} $line -> aud vid avs ct]} {
	    set data(time_pos) [expr {($aud+$vid)/2}]
	    set data(pause) 0

	    if {$data(-callback) != ""} {
		{*}$data(-callback) AV $aud $vid $avs $ct
	    }
	    if {$data(-seekbar) != ""} {
		$data(-seekbar) mediastatus AV $aud $vid $avs $ct
	    }
	    return
	}
	# Video Only file...
	if {[regexp {^V:\s*([0-9]+\.[0-9]+)\s[0-9]+} $line -> vid]} {
	    set data(time_pos) $vid
	    set data(pause) 0
	    if {$data(-callback) != ""} {
		{*}$data(-callback) V $vid
	    }
	    if {$data(-seekbar) != ""} {
		$data(-seekbar) mediastatus V $vid
	    }
	    return
	}
	# Audio only file
	if {[regexp {^A:\s*([0-9]+\.[0-9]+)\s\(} $line -> aud ]} {
	    set data(time_pos) $aud
	    set data(pause) 0
	    if {$data(-callback) != ""} {
		{*}$data(-callback) A $aud
	    }
	    if {$data(-seekbar) != ""} {
		$data(-seekbar) mediastatus A $aud
	    }
	    return
	}
	if {$line == "=====  PAUSE  ====="} {
	    set data(pause) 1
	    if {$data(-callback) != ""} {
		{*}$data(-callback) pause
	    }
	    if {$data(-seekbar) != ""} {
		$data(-seekbar) mediastatus pause
	    }
	    return
	}
    }
    #
    if {$line == "Video: no video"} {
	dict set data(meta) novideo 1
	return
    }
    if {$line == "Audio: no sound"} {
	dict set data(meta) noaudio 1
	return
    }
    if {$line == "Starting playback..."} {
	debug "## $line"
	# Loading meta...
	global mptcl_meta mptcl_metatout mptcl_metaretry
	dict set data(meta) loading \
	    [after $mptcl_metatout [list mptcl_MPLoadtout $w $mptcl_metaretry]]
	foreach {prop type} [array get mptcl_meta] {
	    if {$type == "A" && [dict exists $data(meta) "noaudio"]} continue
	    if {$type == "V" && [dict exists $data(meta) "novideo"]} continue
	    mptcl_MPRemote $w pausing_keep_force get_property $prop
	    dict set data(meta) .$prop $prop
	}
	return
    }
    if {[regexp {^ANS_([_/a-z]+)='?(.*)'?$} $line -> prop val]} {
	global mptcl_meta
	debug "(ANS) $line <$prop=$val>"

	if {[info exists mptcl_meta($prop)]} {
	    dict set data(meta) $prop $val
	    dict unset data(meta) .$prop

	    if {[dict keys $data(meta) .*] == "" \
		    && [dict exists $data(meta) loading]} {
		# OK.. managed to retrieve all meta tags
		after cancel [dict get $data(meta) loading]
		dict unset data(meta) loading

		_${w}_wcmd config -cursor ""
		_${w}_wcmd config -cursor "none"
		event generate $w <<MediaStart>>
		if {$data(-seekbar) != ""} {
		    $data(-seekbar) mediastart
		}
	    }
	} else {
	    set data(prop,$prop) $val
	}
	return
    }
    debug ">> ($line)"
}


proc mptcl_MPCmd_status {w} {
    #    Returns the mplayer status (widget sub-command)
    # RETN
    #    Status one of: "nomedia", "stopped", "active", "paused", "playing"
    # DESC
    #    Returns the status of a mplayer widget.  It can be one of the
    #    following:
    #    - nomedia : no media has been loaded/selected (-file is empty)
    #    - loading : media has been selected but the meta data is still being
    #      queried
    #    - stopped : media has stopped.  Usually mplayer process has exited.
    #      Meta data should still be available and queriable.
    #    - active : media is active and playing (or paused).  This status
    #      is used if -callback and/or -seekbar are not active.
    #    - paused - media is active but paused.  This status is only available
    #      if -callback and/or -seekbar are not empty
    #    - playing - media is active and being played.  This status is only
    #      available if -callback and/or -seekbar are not empty.
    #
    upvar #0 $w data

    if {$data(-file) == ""} { return "nomedia" }
    if {[dict size $data(meta)] == 0 || [dict exists $data(meta) loading]} {
	return "loading"
    }
    if {$data(fid) == ""} { return "stopped" }

    if {![info exists data(pause)]} { return "active" }
    if {$data(pause)} { return "paused" }
    return "playing"
}


# Oh no... timed out...
proc mptcl_MPLoadtout {w count} {
    #	Media loading timed out
    # ARGS
    #    @param w - mplayer widget
    #    @param count - number of on-going attempts
    # DESC
    #    Called when we fail to read or meta data properties

    upvar #0 $w data
    if {$data(fid) == ""} return

    debug "<<<MEDIASTART TIMEOUT $count>>>"
    if {[incr $count -1] > 0} {
	# Let's retry it again

	global mptcl_metatout
	dict set data(meta) loading \
	    [after $mptcl_metatout [list mptcl_MPLoadtout $w $count]]

	foreach dprop [dict keys $data(meta) .*] {
	    mptcl_MPRemote $w pausing_keep_force get_property \
		[dict get $data(meta) $dprop]
	}
	return
    }
    # OK... retried too many times...
    dict unset data(meta) loading

    _${w}_wcmd config -cursor ""
    _${w}_wcmd config -cursor "none"
    event generate $w <<MediaStart>>
    if {$data(-seekbar) != ""} {
	catch { $data(-seekbar) mediastart }
    }
}

proc mptcl_MPCmd_cget {w option} {
    #    Read widget options (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param option - option to read
    # RETN
    #    The value of option

    upvar #0 $w data
    return $data($option)
}

proc mptcl_MPCmd_prop {w prop args} {
    #    Access a mplayer property (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param prop - property to access
    #    @param args - if specified will write otherwise it will read
    # RETN
    #    Content of the property
    # DESC
    #    Access mplayer available properties.  It will either read (if
    #    no write value is specified) or write (if one was specified)
    #
    switch [llength $args] {
	0 {
	    return [mptcl_MPReadProp $w $prop]
	}
	1 {
	    mptcl_MPRemote $w set_property $prop \
		[mptcl_MPquote [lindex $args 0]]
	    return [lindex $args 0]
	}
	default {
	    error "wrong # args: should be \"$w prop key \[value\]\""
	}
    }
}

proc mptcl_MPReadProp {w prop} {
    #    Arrange for a property to be read
    # ARGS
    #    @param w - mplayer widget
    #    @param prop - property to read
    # RETN
    #    Value of the property being read

    upvar #0 $w data
    if {$data(fid) == ""} return
    global mptcl_proptout

    mptcl_MPRemote $w pausing_keep_force get_property $prop
    set data(prop,$prop) \
	    [set id [after $mptcl_proptout [list mptcl_MPPropTimeOut $w $prop]]]
    vwait "${w}(prop,$prop)"
    after cancel $id
    set rv $data(prop,$prop)
    unset data(prop,$prop)
    return $rv
}

proc mptcl_MPPropTimeOut {w prop} {
    #    Handler for timeout when reading properties
    # ARGS
    #    @param w - mplayer widget
    #    @param prop - property being read
    # DESC
    #    Will cause the "vwait" in [mptcl_MPReadProp] to exit and the
    #    subsequent read to throw an error.

    upvar #0 $w data
    if {[catch {unset data($prop)} err]} {
	puts stderr $err
    }
}

proc mptcl_MPCmd_time_pos {w} {
    #    Return the current mplayer playback position in seconds (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    # RETN
    #    Seconds
    # DESC
    #    Access mplayer time_pos value.  If -callback and/or -seekbar
    #    have been specified, the value from the status line will
    #    be used, otherwise, the time_pos property will be read.
    #

    upvar #0 $w data
    if {[info exists data(time_pos)]} {
	return $data(time_pos)
    }
    return [mptcl_MPReadProp $w time_pos]
}


proc mptcl_MPCmd_paused {w} {
    #    Return the current playback status (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    # RETN
    #    boolean true if paused, false if playback
    # DESC
    #    Access mplayer pause status.  If -callback and/or -seekbar
    #    have been specified, the value from the status line will
    #    be used, otherwise, the pause property will be read.
    upvar #0 $w data
    if {[info exists data(pause)]} {
	return $data(pause)
    }
    return [mptcl_MPReadProp $w pause]
}

proc mptcl_MPCmd_pause {w {val {}}} {
    #    pause or play (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param val - if specified a boolean to pause or play
    # DESC
    #    If no value has been specified, the pause status will be
    #    toggled.
    #
    #    If a value is specified it will pause (if val is true) or
    #    resume playback (if val is false)
    upvar #0 $w data

    if {$val == ""} {
	mptcl_MPRemote $w pause
    } else {
	if {$val} {
	    mptcl_MPRemote $w frame_step
	} else {
	    mptcl_MPRemote $w get_vo_fullscreen
	}
    }
}

proc mptcl_MPCmd_seek {w val {whence {}}} {
    #    seek to some place (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param val - seek value
    #    @param whence - Must be one of 0, relative seek of +/-
    #        seconds; 1 is a seek to a % value; 2 is a seek to
    #        an absolute position in seconds.  If not specified
    #        defaults to "0"
    mptcl_MPRemote $w seek $val $whence
}

proc mptcl_MPCmd_frame_step {w} {
    #    Play one frame and pause (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    mptcl_MPRemote $w frame_step
}

proc mptcl_MPCmd_mute {w {val {}}} {
    #    Enable/disable sound output
    # ARGS
    #    @param w - mplayer widget
    #    @param val - if set to 1, mute is on; if set to 0, mute is off;
    #        if not specified, mute will toggle
    mptcl_MPRemote $w mute $val
}

proc mptcl_MPCmd_abort {w} {
    $w stop
    $w play
}

proc mptcl_MPCmd_volume {w {val {}} {abs {}}} {
    #    Volume control (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param val - if provided, will change volume.  If not, volume
    #        value will be read
    #    @param abs - if provided, will set volume to an absolute value
    # RETN
    #    Current volume setting
    # DESC
    #    If no val is provided, will read the volume setting property.
    #
    #    If val is specified will change the volume by the "val" in
    #    percentage.
    #    If abs is not provided, then the change will be relative,
    #    otherwise, val is the percentage value to set the volume to.
    if {$val == ""} {
	return [mptcl_MPReadProp $w volume]
    }
    if {$abs == ""} {
	set current [mptcl_MPReadProp $w volume]
	set val [expr {$current + $val}]
	if {$val > 100.0} {
	    set val 100.0
	} elseif {$val < 0.0} {
	    set val 0.0
	}
    }
    mptcl_MPRemote $w volume $val 1
    return $val
}

proc mptcl_MPCmd_loadfile {w f} {
    #    Load a different media file (widget sub-command)
    # ARGS
    #    @param w - mplayer widget
    #    @param f - File to load
    mptcl_MPRemote $w loadfile [mptcl_MPquote $f]
}


proc mplayer_bindings {w player} {
    #    Define mplayer compatible bindings (Utility function)
    # ARGS
    #    @param w - widget that is capturing events
    #    @param player - mplayer widget
    # DESC
    #    Wil set-up keyboard bindings that are similar to the
    #    mplayer default bindings.  With some arbitrary changes
    #    made by me.
    bind $w <Key-space> [list $player pause]
    bind $w <Key-Left> [list $player seek -10]
    bind $w <Key-Right> [list $player seek 10]
    bind $w <Key-Down> [list $player seek -60]
    bind $w <Key-Up> [list $player seek 60]
    bind $w <Key-m> [list $player mute]
    bind $w <Key-plus> [list $player volume 10.0]
    bind $w <Key-equal> [list $player volume 10.0]
    bind $w <Key-KP_Add> [list $player volume 10.0]
    bind $w <Key-minus> [list $player volume -10.0]
    bind $w <Key-KP_Subtract> [list $player volume -10]
    bind $w <Key-slash> [list $player frame_step]

    bind $w <Key-grave> [list mptcl_MPRemote $player speed_set 0.5]
    bind $w <Key-1> [list mptcl_MPRemote $player speed_set 1.0]
    bind $w <Key-2> [list mptcl_MPRemote $player speed_set 1.25]
    bind $w <Key-3> [list mptcl_MPRemote $player speed_set 1.5]
    bind $w <Key-4> [list mptcl_MPRemote $player speed_set 2.0]

    bind $w <Key-o> [list mptcl_MPRemote $player osd_show_progression]
    bind $w <Key-i> [list mptcl_MPRemote $player osd_show_property_text {${filename}}]
    bind $w <Key-X> [list $player abort]
    bind $w <Key-s> [list mptcl_MPRemote $player sub_select]
    bind $w <Key-S> [list mptcl_MPRemote $player sub_select -1]
    bind $w <Key-l> [list mptcl_MPRemote $player switch_audio]
}

proc mptcl_scaleview {wi he mwi mhe} {
    #    Calculate scaled dimension (Utility function)
    # ARGS
    #    @param wi - Window width
    #    @param he - Window height
    #    @param mwi - Media width
    #    @param mhe - Media height
    # RETN
    #    list with two values corresponding to the calculated width and height
    # DESC
    #    Given a window size and a media size calculates a scaled viewport
    #    dimensions so the media can fit within the window while
    #    maintaining aspect ratio
    #

    set scale_x [expr {($wi+0.0)/$mwi}]
    set scale_y [expr {($he+0.0)/$mhe}]

    if {$scale_x > $scale_y} {
	set scale $scale_y
    } else {
	set scale $scale_x
    }

    set nwi [expr {int($scale*$mwi)}]
    set nhe [expr {int($scale*$mhe)}]

    return [list $nwi $nhe]
}

proc mptcl_in {f args} {
    #    test if "f" is part of a set  (Utility function)
    # ARGS
    #    @param f - string to test
    #    @param args - list of set
    # RETN
    #    Returns 1 if found, 0 if not
    # DESC
    #    Check if the value "f" is in the set listed in "args"
    #
    #    Used to check if the mplayer status is in a particular state
    foreach x $args {
	if {$f == $x} {
	    return 1
	}
    }
    return 0
}

proc mptcl_MPquote {str} {
    #    quote a string (Utility function)
    # ARGS
    #    @param str - string to qutoe
    # RETN
    #    Returns quoted string
    # DESC
    #    Will quote a string if needed for use by [mptcl_MPRemote]

    if {[string is integer $str] || [string is double $str]} { return $str }
    return \"[string map [list \" \\\" \\ \\\\] $str]\"
}
#proc mptcl_MPCmd_xx {w args} {}
#    upvar #0 $w data
