# From Hume Smith's HCLS package
# From: http://wiki.tcl.tk/42261
#
# Examples:
# % HCLS::quote::glob {ab*[c%}
# ab\*\[c%
# % HCLS::quote::match {ab*[c%}
# ab\*\[c%
# % HCLS::quote::bind {ab*[c%}
# ab*[c%%
# % HCLS::quote::subst {ab*[c%}
# ab*\[c%
# % HCLS::quote::regexp {ab*[c%}
# ab\*\[c%
# % HCLS::quote::regsub {ab*[c%}


namespace eval HCLS {

#
# Quoters
#

namespace eval quote {
namespace export {[a-z]*}
variable cache
array set cache {}

#
# sigh... of course, some (not all! eg subst, new regsub) of these can be
# done simply by putting \ in front of everything.  but that's somehow not
# as elegent.  It's certainly not as much fun.
#

# 1999 Aug 26
# - reworked so that Backsolidus-guard creates the procs instead of being
#  called by them... which should speed them up noticeably

if {![catch {string map {} {}}]} {
# string map
proc Backsolidus-guard {name bag} {
        array set x {\\ \\\\}
        foreach c [split $bag {}] { set x($c) \\$c }
        proc $name str "string map [list [array get x]] \$str"
}} elseif {[catch {regexp {[\]} {}}]} {
# new REs
proc Backsolidus-guard {name bag} {
        # crickey... this is getting self-referential :)
        ::regsub -all {[\\\[\]\-\^]} \\$bag {\\&} bag
        proc $name str "[list ::regsub -all \[$bag\]] \$str {\\\\&} str\nset str"
}
} else {
# old REs
proc Backsolidus-guard {name bag} {
        array set x {- 0 ] 0 ^ 0 \\ 1}
        foreach c [split $bag {}] { set x($c) 1 }
        set pat \[
        if {$x(])} { append pat ] }
        unset x(])
        set tail {}
        if {$x(^)} { append tail ^ }
        unset x(^)
        if {$x(-)} { append tail - }
        unset x(-)
        append tail ]
        
        append pat [join [array names x] {}] $tail

        proc $name str "[list ::regsub -all $pat] \$str {\\\\&} str\nset str"
}}


# [string match [HCLS::quote::match $str1] $str2] == ![string compare $str1 $str2]
Backsolidus-guard match {\*?[}

# it's quite tricky to explain what this does,
# and tildes are probably still a problem
Backsolidus-guard glob {\*?[{}}

# regsub x x [HCLS::quote:regsub $str] x; set str
#        equivalent to
# set x $str
Backsolidus-guard regsub {\&}

# ![string compare $str1 $str2] == [regexp [HCLS::quote::regexp $str1] $str2]
Backsolidus-guard regexp {{$^.?+*\|()[]}}

# 0==[string compare [subst [subst-quote $str]] $str]
Backsolidus-guard subst {[\$}


# dunno how to describe this formally
proc bind str { string map {% %%} $str }
if {[catch {bind %}]} {
proc bind str {
        ::regsub -all % $str %% str
        set str
}}

# i wonder if i can do one for eval?


} ;# namespace quote
} ;# namespace HCLS
