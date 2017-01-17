#
# See: http://wiki.tcl.tk/28723
#
#
# Copyright (c) 2011 by Michael Thomas Greer
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

package require Tk 8.5

#-----------------------------------------------------------------------------
namespace eval ::tk::tk_getString:: {

    proc refocus args {
	# Used to force the modal dialog to have focus after
	# evaluating any of the user command option scripts.
	# (Since the script could do just about anything...)
	focus -force [lindex $args 0]
    }

}

#-----------------------------------------------------------------------------
proc ::tk::tk_getString args {
    if {[llength $args] % 2} {
	return -code error {wrong # args: must be "tk_getString ?option value ...?"}
    }

    array set options {
	#-default         {this must not exist unless specified by the user}
	-fractionx       .50
	-fractiony       .425
	-height          10
	-helpcommand     {}
	-invalidcommand  {}
	-parent          {}
	-prompt          {}
	-show            {}
	-state           normal
	#-title           {this must not exist unless specified by the user}
	-validatecommand {}
	-values          {}
	-variable        {}
	-width           0
    }
    array set options $args
    foreach {name abbreviations} {
	-helpcommand     {-hcmd -helpcmd}
	-invalidcommand  {-icmd -invalidcmd}
	-validatecommand {-vcmd -validatecmd}
    } {
	foreach abbreviation $abbreviations {
	    if {[info exists options($abbreviation)]} {
		set options($name) $options($abbreviation)
	    } } }

    # Validate options .........................................................
    if {($options(-parent) ne {}) && ![winfo exists $options(-parent)]} {
	error "bad window path name \"$options(-parent)\""
    }
    foreach opt {fractionx fractiony} {
	set v $options(-$opt)
	if {![string is double -strict $v] || ($v < 0) || ($v > 1)} {
	    error "expected floating-point $opt in \[0.0, 1.0\] but got \"$v\""
	} }
    foreach opt {height width} {
	if {![string is integer -strict $options(-$opt)]} {
	    error "expected integer $opt but got \"$options(-$opt)\""
	} }
    if {$options(-state) ni {normal readonly}} {
	error "bad state \"$options(-state)\": must be normal or readonly"
    }

    if {![info exist options(-title)]} {  # we must have a -title
	if {$options(-parent) ne {}} \
	    then { set options(-title) [wm title $options(-parent)] } \
	    else { set options(-title) [wm title .]                 }
    }
    if {$options(-show) ne {}} {          # -show beats -values
	set options(-values) {}
    }

    # Create and populate the dialog window ....................................
    set w [string map {.. .} $options(-parent).[clock microseconds]]

    toplevel $w -relief flat -class TkGetStringDialog
    variable ::tk::$w.buttonpressed
    variable ::tk::$w.refocus {}
    trace add variable ::tk::$w.refocus write [list ::tk::tk_getString::refocus $w.entry]

    wm title     $w $options(-title)
    wm iconname  $w $options(-title)
    wm protocol  $w WM_DELETE_WINDOW [list set ::tk::$w.buttonpressed cancel]
    wm transient $w [winfo toplevel [winfo parent $w]]

    set prev_focus   [focus -displayof $w]
    set prev_grab    [grab current $w]

    # (The text variable)
    if {$options(-variable) eq {}} \
	then { set varname ::$w.value; set $varname {} } \
	else { set varname $options(-variable)         }
    upvar #0 $varname var
    if {![info exists var]} {
	set var {}
    }
    if {[info exists options(-default)]} {
	set var $options(-default)
    }

    # (The prompt message, if any)
    if {$options(-prompt) ne {}} {
	ttk::label $w.prompt -text $options(-prompt)
	pack $w.prompt -side top -expand yes -fill x
    }

    # (Command options)
    foreach cmd {-helpcommand -invalidcommand -validatecommand} {
	if {[llength $options($cmd)] != 0} {
	    set options($cmd) "set ::tk::$w.refocus \[ $options($cmd) \]"
	} }

    # (Entry widget)
    if {[llength $options(-values)]} \
	then {
	    ttk::combobox $w.entry \
		-height          $options(-height) \
		-invalidcommand  $options(-invalidcommand) \
		-state           $options(-state) \
		-textvariable    $varname \
		-validate        [expr {[llength $options(-validatecommand)] ? {key} : {none}}] \
		-validatecommand $options(-validatecommand) \
		-values          $options(-values) \
		-width           $options(-width)
	} \
	else {
	    ttk::entry $w.entry \
		-invalidcommand  $options(-invalidcommand) \
		-show            $options(-show) \
		-textvariable    $varname \
		-validate        [expr {[llength $options(-validatecommand)] ? {key} : {none}}] \
		-validatecommand $options(-validatecommand) \
		-width           $options(-width)
	}
    if {$var ne {}} { $w.entry selection range 0 end }
    pack $w.entry -side top -padx 10 -pady 5 -expand yes -fill x

    # (Buttons)
    ttk::frame  $w.buttons
    ttk::button $w.buttons.ok     -text Ok     -command [list set ::tk::$w.buttonpressed ok]
    ttk::button $w.buttons.cancel -text Cancel -command [list set ::tk::$w.buttonpressed cancel]
    ttk::button $w.buttons.help   -text Help   -command $options(-helpcommand)
    pack $w.buttons.ok     -side left -expand yes -fill x
    pack $w.buttons.cancel -side left -expand yes -fill x
    if {[llength $options(-helpcommand)] != 0} {
	pack $w.buttons.help -side left -expand yes -fill x
    }
    pack $w.buttons -expand yes -fill x

    # (Global bindings)
    bind $w <Return>   [list set ::tk::$w.buttonpressed ok]
    bind $w <KP_Enter> [list set ::tk::$w.buttonpressed ok]
    bind $w <Destroy>  [list set ::tk::$w.buttonpressed cancel]
    bind $w <Escape>   [list set ::tk::$w.buttonpressed cancel]
    bind $w <F1>       $options(-helpcommand)
    bind $w <Help>     $options(-helpcommand)

    # Properly position it on the display ......................................
    # See "Total Window Geometry" http://wiki.tcl.tk/11291
    wm withdraw $w
    update idletasks
    focus -force $w.entry
    if {$options(-parent) eq {}} \
	then {
	    # (Position on the user's screen/vroot)
	    lassign [split [winfo geometry $w] +] foo dtop dleft
	    set dw [expr {[winfo rootx $w] - $dleft}]
	    set dh [expr {[winfo rooty $w] - $dtop }]
	    set x [expr {round( ([winfo vrootwidth  $w] - [winfo reqwidth  $w] - $dw) * $options(-fractionx) )}]
	    set y [expr {round( ([winfo vrootheight $w] - [winfo reqheight $w] - $dh) * $options(-fractiony) )}]
	} \
	else {
	    # (Position on the parent widget)
	    set p $options(-parent)
	    set x [expr {round( (([winfo width  $p] - [winfo reqwidth  $w]) * $options(-fractionx)) + [winfo x $p] )}]
	    set y [expr {round( (([winfo height $p] - [winfo reqheight $w]) * $options(-fractiony)) + [winfo y $p] )}]
	}
    incr x -[winfo vrootx $w]
    incr y -[winfo vrooty $w]
    wm geometry $w +$x+$y
    wm deiconify $w
    wm resizable $w 0 0
    grab $w

    # Run the dialog ...........................................................
    tkwait variable ::tk::$w.buttonpressed

    set result [list [set ::tk::$w.buttonpressed] $var]

    # Clean up .................................................................
    grab release $w
    destroy $w
    focus -force $prev_focus
    if {$prev_grab ne {}} { grab $prev_grab }
    update idletasks

    unset ::tk::$w.refocus
    unset ::tk::$w.buttonpressed
    if {$options(-variable) eq {}} { unset var }

    return $result
}

namespace eval ::tk:: { namespace export tk_getString }
namespace import ::tk::tk_getString
