#!/usr/bin/wish
set scriptdir [file dirname [file normalize [info script]]]
source [file join $scriptdir mplayer.tcl]
source [file join $scriptdir mbrowse.tcl]
source [file join $scriptdir tk_getString.tcl]
source [file join $scriptdir seekbar.tcl]
# source [file join $scriptdir console.tcl] ; console show

proc do_exit {} {
    # Execute timers synchrnously...
    foreach id [after info] {
	foreach {task type} [after info $id] break
	after cancel $id
	eval $task
    }
}

proc main {args} {
    set flist [list]
    set shuffle {}
    set max 0
    set classify {}
    set keep 0

    foreach item $args {
	switch -glob -- $item {
	    --shuffle -
	    -S {
		set shuffle S
	    }
	    -t {
		set shuffle t
	    }
	    -T {
		set shuffle T
	    }
	    --keep -
	    -K {
		set keep 1
	    }
	    --classify=* {
		set classify [regsub {^--classify=} $item {}]
	    }
	    -C* {
		set classify [regsub {^-C} $item {}]
	    }
	    --fs -
	    -F {
		set max 1
	    }
	    default {
		mptcl_process $item flist
	    }
	}
    }
    switch -- $shuffle {
      S {
	set flist [mptcl_shuffle $flist]
      }
      t {
	set flist [mptcl_tsort $flist 1]
      }
      T {
	set flist [mptcl_tsort $flist -1]
      }
    }
    mbrowser . -files $flist -loop 0 -playing 0 -seekbar 1

    . fullscreen $max
    bind . <Key-Delete> [list delete_media .]

    if {$classify != ""} {
	bind . <Key-Tab> [list classify_media . .m $classify $keep]
    }

    bind . <Key> [list puts "Keysym is %K"]
    bind . <<PlaylistEnd>> do_exit
    bind . <Destroy> do_exit

}


proc pick_item {w} {
    set clst [$w cget -files]
    set current [$w cget -playing]
    if {![llength $clst] || $current == ""} {return [list {} {}]}

    # Delete this one...
    return [list [lindex $clst $current] $current]
}

proc remove_item {w current} {
    set clst [$w cget -files]
    set clst [lreplace $clst $current $current]

    if {$clst == ""} {
	set current ""
    } elseif {$current >= [llength $clst]} {
	set current [expr {[llength $clst] - 1}]
    }
    $w config -files "" -playing ""
    after 500 [list $w config -files $clst -playing $current]
}

proc replace_item {w current value} {
    set clst [$w cget -files]
    set clst [lreplace $clst $current $current $value]
    incr current

    if {$clst == ""} {
	set current ""
    } elseif {$current >= [llength $clst]} {
	set current [expr {[llength $clst] - 1}]
    }
    $w config -files "" -playing ""
    after 500 [list $w config -files $clst -playing $current]
}

proc delete_media {w} {
    foreach {name current} [pick_item $w] break
    if {$name == ""} return

    set r [tk_messageBox \
	       -default "yes" \
	       -icon "question" \
	       -message [format "Are you sure you want to delete\n%s\nfrom %s?" \
			     [file tail $name] [file dir $name]] \
	       -title "MediaPlay" \
	       -parent $w \
	       -type "yesno"]
    if {$r == "no"} return

    if {[catch {file delete $name} err]} {
	tk_messageBox \
	    -message $err \
	    -title "Error" \
	    -parent $w \
	    -type "ok" \
	    -icon "error"
	return
    }
    remove_item $w $current
}

proc dirmenu {m bdir cmd} {
    $m add command \
	-command [list {*}$cmd $m $bdir -place] \
	-label "Place here..."
    $m add separator
    
    set dirs [lsort -dictionary [glob \
			 -nocomplain \
			 -directory $bdir \
			 -tails \
			 -types d \
			 -- "*"]]
    if {$dirs != ""} {
	set id 0
	foreach d $dirs {
	    set sm "$m.m[incr id]"
	    menu $sm -tearoff 0
	    $m add cascade \
		-menu $sm \
		-label $d 
	    dirmenu $sm [file join $bdir $d] $cmd
	}
	$m add separator
    }
    $m add command \
	-command [list {*}$cmd $m $bdir -new] \
	-label "New item..."
}

proc classify_media {w m basedir keep} {
    foreach {name current} [pick_item $w] break
    if {$name == ""} return
    if {$w == "."} {
	set m ".m"
    } else {
	set m "$w.m"
    }
    catch {destroy $m}
    menu $m -tearoff 0
    dirmenu $m $basedir [list classify_target $w $keep $name $current]
    tk_popup $m [winfo rootx $w] [winfo rooty $w]
    after idle [list focus -force $m]
}

proc kwfilter {s} {
    return [expr {![regexp {[^-A-Za-z0-9_ ,.!#%_@~]} $s]}]
}

proc classify_target {w keep fname current menu bdir op} {
    if {$op == "-new"} {
	lassign [tk_getString \
		     -prompt {Enter word} \
		     -vcmd {kwfilter %P} \
		    ] ok kw
	if {$ok ne "ok"} return

	if {[catch {file mkdir [file join $bdir $kw]} err]} {
	    tk_messageBox \
		-title "MPlayer" \
		-message $err \
		-icon "error" \
		-parent . \
		-type "ok"
	    return
	} else {
	    set bdir [file join $bdir $kw]
	}
    }
    set newname [file join $bdir [file tail $fname]]
    if {[catch {file rename $fname $newname} err]} {
	tk_messageBox \
	    -title "MPlayer" \
	    -message $err \
	    -icon "error" \
	    -parent . \
	    -type "ok"
	return
    }
    if {$keep} {
	replace_item $w $current $newname
    } else {
	remove_item $w $current
    }
}


main {*}$argv

