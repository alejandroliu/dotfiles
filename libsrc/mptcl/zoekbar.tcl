#!/usr/bin/wish
#
# zoekbar.tcl 
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

package provide zoekbar 0.1.0

array set mptcl_ZBcfg {
    c,pad	 8
    c,bd	 2
    c,width	 2
    c,outline 	"black"
    c,fill 	"yellow"
    x,pad 	3
    s,fill	""
    s,outline	"darkgreen"
    m,fill	"blue"
    m,outline	""
    x,fill	"red"
    x,outline	""
}

proc zoekbar {w args} {
    upvar #0 $w data
    set specs {
	{ -background	""	""	"white"		}
	{ -bg		""	""	"white"		}
	{ -takefocus	""	""	0		}
	{ -height	""	""	16		}
	{ -borderwidth	""	""	2		}
	{ -bd		""	""	2		}
	{ -cursor	""	""	""		}
	{ -relief	""	""	"raised"	}
	{ -player	""	""	""		}
	{ -edl		""	""	""		}
    }
    tclParseConfigSpec $w $specs "" $args

    parray data
    if {$data(-bg) != "white"} { set data(-background) $data(-bg) }
    if {$data(-bd) != 2} { set data(-bd) $data(-bd) }

    canvas $w \
	-takefocus $data(-takefocus) \
	-background $data(-background) \
	-height $data(-height) \
	-borderwidth $data(-borderwidth) \
	-cursor $data(-cursor) \
	-relief $data(-relief)

    rename ${w} _${w}_cvcmd
    interp alias {} $w {} mptcl_ZBcmd $w

    bind <Destroy> [list unset $w]
    bind <Configure> [list mptcl_ZBdraw $w]

    $w bind cursor <ButtonPress-1> [list mptcl_ZBcmd_cmove $w begin %x %y]
    bind $w <ButtonRelease-1> [list mptcl_ZBcmd_cmove $w end %x %y]
    bind $w <B1-Motion> [list mptcl_ZBcmd_cmove $w drag %x %y]

    set data(seg_a) ""
    set data(seg_b) ""
    set data(edlcmds) "#"

    if {$args != ""} {mptcl_ZBcmd_config $w {*}$args}
    mptcl_ZBdraw $w

    return $w
}

proc mptcl_ZBdpos {w player basex baset x} {
    set x [$w canvasx $x]
    set cw [winfo width $w]
    set len [$player length]
    return [expr {$baset+($x-$basex)/$cw * $len}]
}
proc mptcl_sz {op w} {
    return [expr {[winfo $op $w]-2*[$w cget -bd]}]
}


proc mptcl_ZBcmd_cmove {w op x y} {
    upvar #0 $w data

    if {$data(-player) == "" || \
	    ![mptcl_in [$data(-player) status] "paused" "playing"]} {
	catch {unset data(seeking)}
	return
    }
    switch $op {
	"begin" {
	    if {[info exists data(seeking)]} return
	    set data(seeking) [list [$data(-player) paused] \
				   [$w canvasx $x] [$data(-player) time_pos]]
	    $data(-player) pause 1
	}
	"end" {
	    if {[info exists data(seeking)]} {
		foreach {oldpause basex basepos} $data(seeking) break
		set data(edlcmds) "#"
		$data(-player) pause $oldpause
		unset data(seeking)
	    }
	}
	"drag" {
	    if {[info exists data(seeking)]} {
		foreach {oldpause basex basepos} $data(seeking) break
		set newpos [mptcl_ZBdpos $w $data(-player) $basex $basepos $x]
		mptcl_MPRemote $data(-player) pausing seek $newpos 2
	    }
	}
    }
}

proc mptcl_ZBcmd {w cmd args} {
    upvar #0 $w data

    switch $cmd {
	config {
	    mptcl_ZBcmd_config $w {*}$args
	}
	cget {
	    mptcl_ZBcmd_cget $w {*}$args
	}
	seg {
	    if {[llength $args] == 0} {
		return [list $data(seg_a) $data(seg_b)]
	    } elseif {[llength $args] == 2} {
		foreach {data(seg_a) data(seg_b)} $args break
		mptcl_ZBdraw $w
	    } else {
		error "Usage: $w seg \[A B\]"
	    }
	}
	gotoa -
	gotob {
	    if {$cmd == "gotob"} {
		set goto seg_b
	    } else {
		set goto seg_a
	    }
	    if {$data($goto) != ""} {
		mptcl_MPRemote $data(-player) pausing_keep seek $data($goto) 2
		set data(edlcmds) "#"
	    }
	}

	seta -
	setb {
	    if {$data(-player) == ""} return
	    if {![winfo exists $data(-player)]} return
	    if {![mptcl_in [$data(-player) status] "paused" "playing"]} return

	    set len [$data(-player) length]
	    if {[llength $args] == 0} {
		set pos [$data(-player) time_pos]
	    } else {
		set pos [lindex $args 0]
		if {$pos < 0} {
		    set pos 0.0
		} elseif {$pos > $len} {
		    set pos $len
		}
	    }

	    if {$cmd == "seta"} {
		if {$data(seg_b) == ""} {
		    set data(seg_b) [$data(-player) length]
		}
		set data(seg_a) $pos
	    } else {
		if {$data(seg_a) == ""} {
		    set data(seg_a) 0.0
		}
		set data(seg_b) $pos
	    }
	    if {$data(seg_a) > $data(seg_b)} {
		foreach {data(seg_a) data(seg_b)} \
		    [list $data(seg_b) $data(seg_a)] break
	    }
	    mptcl_ZBdraw $w
	}
	mediastart {
	    set data(edlcmds) "#"
	    mptcl_ZBdraw $w
	}
	mediastatus {
	    set token [lindex $args 0]
	    puts "MEDIASTATUS $args"
	    if {$token == "pause"} {
		set timepos ""
	    } else {
		set timepos [lindex $args 1]

		if {![info exists data(seeking)] && $data(-edl) != ""} {
		    # OK we are in playback...
		    if {$data(edlcmds) == "#"} {
			set data(edlcmds) \
			    [mptcl_compile_edl $data(-edl) $timepos]
		    }
		    # Handle EDL commands
		    while {[llength $data(edlcmds)]} {
			foreach {tm cmd} [lindex $data(edlcmds) 0] break
			if {$tm > $timepos} break
			# EDL triggered...
			set data(edlcmds) [lreplace $data(edlcmds) 0 0]
			$data(-player) {*}$cmd
		    }
		}
	    }
	    mptcl_ZBdraw $w $timepos
	}
	mediaend {
	    return
	}
	edl {
	    return [mptcl_ZBedl $w {*}$args]
	}
	default {
	    return [_${w}_cvcmd $cmd {*}$args]
	}
    }
}
 
proc mptcl_ZBcmd_cget {w attr} {
    switch -- $attr {
	-edl	-
	-player	{ 
	    upvar #0 $w data
	    return $data($attr) 
	}
    }
    return [_${w}_cvcmd cget $attr]
}

proc mptcl_ZBcmd_config {w args} {
    upvar #0 $w data
    if {$args == ""} {
	error "Arguments \"$w\" Umpty!"
    }
    set wargs [list]

    foreach {param value} $args {
	switch -- $param {
	    -bg { set param -background }
	    -bd { set param -borderwidth }
	}
	set data($param) $value
	switch -- $param {
	    -player	{ 
		set data(seg_a) ""
		set data(seg_b) ""
		set data(edlcmds) "#"
		mptcl_ZBdraw $w
	    }
	    -edl	{
		set data(edlcmds) "#"
		mptcl_ZBdraw $w
	    }
	    -takefocus 	-
	    -background -
	    -bg		-
	    -height	-
	    -borderwidth -
	    -bd		-
	    -cursor	-
	    -relief	{
		lappend wargs $param $value
	    }
	}
    }
    if {$wargs != ""} {
	_${w}_cvcmd config {*}$wargs
    }
}

proc mptcl_ZBedl {w op args} {
    upvar #0 $w data
    
    switch -- "$op" {
	add {
	    # Add segment
	    if {[llength $args] != 3} {
		error "Usage: $w edl add {start} {end} {1|0}"
	    }
	    foreach {start end opcode} $args break
	    lappend data(-edl) [list $start $end $opcode]
	    set data(-edl) [mptcl_clean_edl $data(-edl)]

	    set data(edlcmds) "#"
	}

	get {
	    if {[llength $args] != 1} {	    
		error "Usage: $w edl get {seg}"
	    }
	    set id [lindex $args 0]
	    if {$id < 0 || $id >= [llength $data(-edl)]} {return ""}
	    return [lindex $data(-edl) $id]
	}

	del {
	    if {[llength $args] != 1} {	    
		error "Usage: $w edl del {seg}"
	    }
	    set id [lindex $args 0]
	    if {$id < 0 || $id >= [llength $data(-edl)]} return
	    set data(-edl) [lreplace $data(-edl) $id $id]
	}
	toggle {
	    if {[llength $args] != 1} {	    
		error "Usage: $w edl toggle {seg}"
	    }
	    set id [lindex $args 0]	    
	    if {$id < 0 || $id >= [llength $data(-edl)]} return
	    foreach {st en op} [lindex $data(-edl) $id] break
	    set op [expr {1-$op}]
	    set data(-edl) [lreplace $data(-edl) $id $id [list $st $en $op]]
	}
	default {
	    error "Invalid cmd: $w edl $op"
	}
    }
    mptcl_ZBdraw $w

}


proc mptcl_ZBdraw_edl {w} {
    upvar #0 $w data
    global mptcl_ZBcfg

    if {$data(-edl) == ""} return

    set fps [$data(-player) fps]
    set len [$data(-player) length]
    set cw [mptcl_sz width $w]
    set ch [mptcl_sz height $w]
    set off [$w cget -bd]

    set id 0
    foreach line $data(-edl) {
	foreach {apos bpos mode} $line break

	set ax [expr {$off+$apos*$cw/$len}]
	set bx [expr {$off+$bpos*$cw/$len}]

	if {$mode == 0} {
	    set p "x"
	} elseif {$mode == 1} {
	    set p "m"
	} else {
	    continue
	}

	$w create rectangle \
	    $ax [expr {$mptcl_ZBcfg(x,pad)+$off}] \
	    $bx [expr {$ch-$mptcl_ZBcfg(x,pad)}] \
	    -width $mptcl_ZBcfg(x,pad) \
	    -fill $mptcl_ZBcfg($p,fill) \
	    -outline $mptcl_ZBcfg($p,outline) \
	    -tags [list edl obj$id]

	foreach ev {<ButtonPress> <Double-ButtonPress> <ButtonRelease>} {
	    $w bind obj$id $ev [list mptcl_ZBedlev $w $ev $id %b]
	}
	incr id
    }
}

proc mptcl_ZBedlev {w ev id bn} {
    upvar #0 $w data    
    event generate $w <<SegmentEvent>> -data [list $ev $bn $id]
}

proc mptcl_ZBdraw_segment {w} {
    upvar #0 $w data
    global mptcl_ZBcfg

    if {$data(seg_a) == "" || $data(seg_b) == ""} return

    set fps [$data(-player) fps]
    set len [$data(-player) length]
    set cw [mptcl_sz width $w]
    set ch [mptcl_sz height $w]

    set off [$w cget -bd]
    set ax [expr {$off+$data(seg_a)*$cw/$len}]
    set bx [expr {$off+$data(seg_b)*$cw/$len}]

    $w create rectangle \
	$ax [expr {$mptcl_ZBcfg(x,pad)+$off}] \
	$bx [expr {$ch-$mptcl_ZBcfg(x,pad)}] \
	-width $mptcl_ZBcfg(x,pad) \
	-fill $mptcl_ZBcfg(s,fill) \
	-outline $mptcl_ZBcfg(s,outline) \
	-tags edseg
	
}

proc mptcl_ZBdraw_pointer {w pos} {
    upvar #0 $w data
    global mptcl_ZBcfg

    set fps [$data(-player) fps]
    set len [$data(-player) length]
    set cw [mptcl_sz width $w]
    set ch [mptcl_sz height $w]
    set off [$w cget -bd]

    set center [expr {$off+$pos*$cw/$len}]
    $w create polygon \
	$center [expr {$ch-$mptcl_ZBcfg(c,bd)}] \
	[expr {$center-$mptcl_ZBcfg(c,pad)}] [expr {$off+$mptcl_ZBcfg(c,bd)}] \
	[expr {$center+$mptcl_ZBcfg(c,pad)}] [expr {$off+$mptcl_ZBcfg(c,bd)}] \
	$center $ch \
	-width $mptcl_ZBcfg(c,width) \
	-outline $mptcl_ZBcfg(c,outline) \
	-fill $mptcl_ZBcfg(c,fill) \
	-tags cursor
}


proc mptcl_ZBdraw {w {timepos {}}} {
    upvar #0 $w data

    $w delete all

    if {$data(-player) == ""} return
    if {![winfo exists $data(-player)]} return
    if {[mptcl_in [$data(-player) status] "nomedia" "loading"]} return

    mptcl_ZBdraw_edl $w
    mptcl_ZBdraw_segment $w

    if {[mptcl_in [$data(-player) status] "paused" "playing"]} {
	if {$timepos == ""} {
	    set timepos [$data(-player) time_pos]
	}
	mptcl_ZBdraw_pointer $w $timepos
    }
}

######################################################################
# Utility functions
proc mptcl_load_edl {fn {max {}}} {
    set fd [open $fn "r"]
    set lines [read $fd]
    close $fd

    set cmd [list]
    set lc 0

    set errors [list]

    # 1. Parse file
    foreach line [split $lines "\n"] {
	incr lc
	set line [string trim $line]
	if {$line == ""} continue
	if {![regexp {^\s*([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)\s+([0-1])} \
		  $line -> start end op]} {
	    lappend errors "Ignoring $line ($lc)"
	    continue
	}
	# 2. Make sure we don't go over the length of the clip
	if {$max != ""} {
	    foreach var {start end} {
		if {[set $var] > $max} {
		    lappend errors "$var point [set $var] > $max ($lc)"
		    set $var $max
		}
	    }
	}

	# 3. Make sure start is before end are OK
	if {$end < $start} {
	    foreach {start end} [list $end $start] break
	    lappend errors "Swapping $end < $start ($lc)"
	    continue
	}
	# 4. Make sure this is not a zero length segment
	if {$end == $start} {
	    lappend errors "single point segment: $start $end ($lc)"
	    continue
	}
	lappend cmd [list $start $end $op]
    }
    return [list $cmd $errors]
}

proc mptcl_sortedl {edlvar} {
    upvar $edlvar cmd
    set cmd [lsort -real -index 0 $cmd]
}

proc mptcl_clean_edl {cmd} {
    set oldsort [list]

    # keep things sorted order
    for {mptcl_sortedl cmd} {$oldsort != $cmd} {mptcl_sortedl cmd} {
	set oldsort $cmd

	# Check if there are any overlaps...
	for {set i 0} {$i < [llength $cmd]-1} {} {
	    set j $i
	    incr i
	    foreach {ast aen aop} [lindex $cmd $j] break
	    foreach {bst ben bop} [lindex $cmd $i] break
	    
	    if {$ast == $bst} {
		# A and B segments start at the same point!
		if {$ben < $aen} {
		    foreach {aen ben} [list $ben $aen] break
		    foreach {aop bop} [list $bop $aop] break
		}
		set bst $aen
		set cmd [lreplace $cmd $j $i \
			     [list $ast $aen $aop] \
			     [list $bst $ben $bop]]
		# Sort it again...
		break
	    }

	    # OK, no overlap...
	    if {$bst >= $aen} continue

	    # Yes... overlaps...
	    if {$aen > $ben} {
		# A ends after B ends =>  B is fully within A...
		set cst $ben
		set cen $aen
		set aen $bst
		
		# Split into three segments
		set cmd [lreplace $cmd $j $i \
			     [list $ast $aen $aop] \
			     [list $bst $ben $bop] \
			     [list $cst $cen $aop]]
		continue
	    }
	    # A ends before B...
	    set aen $bst
	    set cmd [lreplace $cmd $j $j [list $ast $aen $aop]]
	}
    }

    # Now merge consecutive segments...
    for {set i 0} {$i < [llength $cmd]-1} {} {
	set j $i
	incr i

	foreach {ast aen aop} [lindex $cmd $j] break
	foreach {bst ben bop} [lindex $cmd $i] break

	if {$aen == $bst && $aop == $bop} {
	    set cmd [lreplace $cmd $j $i [list $ast $ben $aop]]
	    set i $j
	}
    }
    
    return $cmd
}

proc mptcl_compile_edl {edl {cpos 0.0}} {
    set edlcmds [list]
    
    foreach {ln} $edl {
	foreach {st en op} $ln break
	if {$st < $cpos} continue ;# Skip long gone events...
	if {$op == 0} {
	    lappend edlcmds [list $st [list "seek" $en 2]]
	} elseif {$op == 1} {
	    lappend edlcmds \
		[list $st [list "mute" 1]] \
		[list $en [list "mute" 0]] 
	}
    }
    return $edlcmds
}

# HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK
# THIS IS NEEDED BECAUSE MPLAYER IS UNABLE TO POSITION
# TO END OF FILE FROM AN EDL
# HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK
proc mptcl_fix_edl {edl len} {
    set lst [list]

    set len1 [expr {$len - 1.0}]
    if {$len1 < 0} { return $edl }	;# Sorry can't be helped!

    foreach n $edl {
	foreach {a b op} $n break

	if {$b > $len1 && $op == 0} {
	    # Can't skip here!
	    set b $len1
	    if {$b < $a} continue
	    set n [list $a $b $op]
	}
	lappend lst $n
    }
    return $lst
}

proc mptcl_save_edl {fn edl} {
    set fd [open $fn "w"]
    puts $fd [join $edl "\n"]
    close $fd
}








