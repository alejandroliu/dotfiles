#!/bin/sh
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
op=editor.tcl

# Figure the location of the mptcl library
script_dir=$(cd $(dirname $0) ; pwd)
for target in . ../lib ../lib/mptcl ../mptcl
do
  if [ -f $script_dir/$target/$op ] ; then
    mptcl_lib="$(cd $script_dir/$target ; pwd)"
    break
  fi
done
if [ -z "$mptcl_lib" ] ; then
  echo "Unable to determine mptcl_lib location" 1>&2
  exit 1
fi

exec wish $mptcl_lib/$op
