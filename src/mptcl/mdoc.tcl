#!/usr/bin/env tclsh

    
#
#
proc handle_proc {kw pname params pbody} {
    #   @param kw - keyword being handled (for multi keyword handlers)
    #	@param pname - passed proc name
    #	@param params - list of arguments to pass to proc
    #   @param pbody - text for proc body
    # DESC
    #    Handles a TCL "proc" definition

    set pargs [list]

    foreach argval $params {
	if {[llength $argval] == 1} {
	    set argval [lindex $argval 0]
	    if {$argval == "args"} {
		lappend pargs [list $argval "optional arguments"]
	    } else {
		lappend pargs [list $argval ""]
	    }
	} elseif {[llength $argval] == 2} {
	    foreach {argname argdeft} $argval break
	    if {$argdeft == ""} {
		lappend pargs [list $argname "(optional)"]
	    } else {
		lappend pargs [list $argname "Defaults to: $argdeft"]
	    }
	} else {
	    error "proc: $pname has a invalid argument $argval"
	}
    }

    set last {}
    array set text [list "SUMMARY" $pname]
    set sects [list]

    foreach line [split $pbody "\n"] {
	set line [string trim $line]
	if {[regexp "^#\\s*\[-*\]?\\s*@param\\s+(\\S+)\\s+(.*)" \
		 $line -> argnam desc]} {
	    set desc [regsub {^-\s*} $desc {}]
	    set last param,$argnam
	    set text($last) $desc
	    continue
	}
	if {[regexp "^#\\s*(\[A-Z \]+)\$" $line -> sect]} {
	    lappend sects $sect
	    set last $sect
	    set text($last) ""
	    continue
	}
	if {$line == "" || $line == "#"} {
	    if {$last == ""} continue
	    if {$text($last) == ""} continue
	    append text($last) "\n"
	    continue
	}
	if {[regexp "^#" $line]} {
	    set line [regsub "^#" $line {}]
	    if {$last == ""} {
		set text(SUMMARY) $line
		set last "DESC"
		set text($last) ""
	    } else {
		if {$text($last) == ""} {
		    set text($last) $line
		} else {
		    append text($last) "\n" $line
		}
	    }
	    continue
	}
	break
    }

    puts "NAME"
    puts "\t$pname - [string trim $text(SUMMARY)]"
    puts "SYNOPSIS"
    puts -nonewline "\t$pname"
    foreach line $pargs {
	foreach {a b} $line break
	if {$b == ""} {
	    puts -nonewline " $a"
	} else {
	    puts -nonewline " \[$a\]"
	}
    }
    puts ""
    if {[llength $pargs]} {
	puts "ARGS"
	if {[info exists text(ARGS)]} {
	    puts $text(ARGS)
	}
	foreach arg $pargs {
	    foreach {a b} $arg break
	    puts -nonewline "\t- $a"
	    if {$b != ""} {
		puts ": $b"
		puts "\t"
	    }
	    if {[info exists text(param,$a)]} {
		if {$b == ""} {
		    puts -nonewline ": "
		}
		puts $text(param,$a)
	    } else {
		puts ""
	    }
	}
    }
    foreach ss $sects {
	if {![info exists text($ss)]} continue
	if {$text($ss) != ""} {
	    puts $ss
	    puts $text($ss)
	}
    }

    
    puts "\n==\n"
}

proc handle_variable {kw vname args} {
    #    Document variable specifications
    # ARGS
    #    @param kw - keyword being processed
    #    @param vname - variable name
    #    @param args - either default definition or description

    set default [list]
    set desc ""

    while {[llength $args]} {
	if {[lindex $args 0] == ";#"} {
	    set desc [lrange $args 1 end]
	    break
	} else {
	    lappend default [lindex $args 0]
	    set args [lrange $args 1 end]
	}
    }

    puts "NAME"
    puts "\t$vname - global variable"
    if {$default != ""} {
	puts "DEFAULT"
	puts "\t[join $default { }]"
    }
    if {$desc != ""} {
	puts "DESC"
	puts "\t$desc"
    }
    puts "\n==\n"
}

variable handlers	;# Array with registered handlers

proc process_command {line} {
    #    Process a TCL command
    # ARGS
    #    @param line - command line to process
    # DESC
    #    Dispatches the appropriate handler depending on the keyword
    #    by checking all the TCL procs that start with "handle_"
    #
    if {$line == ""} return

    global handlers
    if {![info exists handlers]} {
	foreach procname [info procs handle_*] {
	    set kw [regsub {^handle_} $procname {}]
	    set handlers($kw) $procname
	}
    }
    if {[info exists handlers([lindex $line 0])]} {
	handle_[lindex $line 0] {*}$line
    }
}


proc check_eol_slash {line} {
    #    Check if line ends with backslash
    # ARGS
    #    - @param line - input line 
    # DESC
    #    Simply check if a line ends with slash (so the command
    #    continues on the next line).
    # RETN
    #    boolean, true if the line continues otherwise false.

    set mw {}
    if {![regexp {(\\*)\\$} $line -> mv]} { return 0 }
    if {[string length $mw] % 2 == 1} { return 0 }
    return 1
}

proc process_file {fdname cb} {
    #    Process a single file
    # ARGS
    #    @param fdname - opened file descriptor or filename
    #    @param cb - callback function to process commands
    if {[catch {fconfigure $fdname} err]} {
	set fd [open $fdname "r"]
	set fname $fdname
	set close 1
    } else {
	set fd $fdname
	set fname "<input>"
	set close 0
    }

    set line {}

    set lc 0
    while {[gets $fd inp] >= 0} {
	incr lc
	if {$line == ""} {
	    set line $inp
	} else {
	    append line "\n" $inp
	}
	if {![check_eol_slash $line] && [info complete $line]} {
	    set line [string trim $line]
	    if {$line == ""}  continue
	    if {[catch {{*}$cb $line} err]} {

		puts stderr "$fname,$lc: $err"
	    }
	    set line {}
	}
    }
    if {$close} {close $fd}
}




process_file stdin process_command
