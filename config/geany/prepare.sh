#!/bin/sh
#
# This script will prepare geany.conf for commit
#

sed \
	-e 's/^treeview_position=.*$//' \
	-e 's/^geometry=.*$//' \
	-e 's/^position_.*$//' \
	-e 's/^recent_files=.*$//' \
	-e 's/^current_page=.*$//' \
	-e 's/^FILE_NAME.*$//'
