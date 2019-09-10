#!/usr/bin/wish
#
# seekbar.tcl 
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

package provide seekbar 0.1.0
set _mptcl_seekbar_opts {-player}


# Initialise seekbar specs
proc seekbar {w args} {
    #1. default spec
    upvar #0 $w data
    global _mptcl_seekbar_opts
    
    array set arglst $args

    foreach opt $_mptcl_seekbar_opts {
	if {[info exists arglst($opt)]} {
	    set data($opt) $arglst($opt)
	    unset arglst($opt)
	}
    }

    scale $w {*}[array get arglst] \
	-command [list mptcl_seekbar_set $w]
    rename $w _${w}_scalecmd
    interp alias {} $w {} mptcl_seekbar_cmd $w

    bind $w <ButtonPress-1> [list mptcl_seekbar_start $w]
    bind $w <ButtonRelease-1> [list mptcl_seekbar_end $w]

    bind $w <Destroy> [list unset $w]

    return $w
}

proc mptcl_seekbar_cmd {w cmd args} {
    upvar #0 $w data
    switch $cmd {
	mediastart {
	    if {$args != ""} {
		error "Usage: $w mediastart"
	    }
	    set len [$data(-player) length]
	    mptcl_seekbar_cmd $w config \
		-from 0 \
		-to [expr {int($len*[$data(-player) fps]+0.5)}] \
		-resolution 1
	}
	mediaend {
	    return
	}
	mediastatus {
	    # AV aud vid avs ct
	    # V vid
	    # A aud
	    # pause
	    if {[llength $args] < 1} {
		error "Usage: $w mediastatus opts"
	    }
	    foreach {mode timepos} $args break
	    if {$mode == "pause"} return
	    if {![info exists data(seeking)]} {
		mptcl_seekbar_cmd $w mediaset $timepos
	    }
	}
	mediaset {
	    if {[llength $args] != 1} {
		error "Usage: $w mediaset pos"
	    }
	    set val [lindex $args 0]
	    _${w}_scalecmd set [expr {int([$data(-player) fps]*$val+0.5)}]
	}
	default {
	    return [_${w}_scalecmd $cmd {*}$args]
	}
    }
}

proc mptcl_seekbar_start {w} {
    upvar #0 $w data
    if {$data(-player) == ""} return
    if {[info exists data(seeking)]} return
    set data(seeking) [$data(-player) paused]
    # Force a pause...
    $data(-player) pause 1
}
proc mptcl_seekbar_end {w} {
    upvar #0 $w data

    if {![info exists data(seeking)]} return    

    set pos [$data(-player) time_pos]
    set oldpause $data(seeking)
    unset data(seeking)

    $w mediaset $pos

    $data(-player) pause $oldpause
}

proc mptcl_seekbar_set {w args} {
    upvar #0 $w data    

    if {[info exists data(seeking)]} {
	set frame [lindex $args 0]
	if {![string is double $frame]} return

	catch {
	    set time_pos [expr {$frame / [$data(-player) fps]}]
	    mptcl_MPRemote $data(-player) pausing seek $time_pos 2
	}
    }
}

