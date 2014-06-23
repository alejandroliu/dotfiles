dotfiles
========

My personal dotfile collection (yeah, a me too!)

## Install

    git clone https://github.com/alejandroliu/dotfiles.git $HOME/.dotfiles
    $HOME/.dotfiles/dfm install
	$HOME/.dotfiles/dfm -x install

## Usage

Place/move your `dotfiles` in `$HOME/.dotfiles/etc`.  The following
conventions are recognized:

- Files beginning with `dot` will be changed to `.`.  For example,
  `dotbashrc` will be installed as `.bashrc`.
- Files ending with `=(hostname)` will only be used if the current
  system's name matches `hostname`.

## References

This is not the only dotfile manager around.  I wanted one that was
written in nasty `bash`.  Other dotfile managers in `bash`  that I
found are:

* [rcm](https://github.com/thoughtbot/rcm)
* [dot-files](https://github.com/bartman/dot-files)

## TODO

* Implement `^` to `/` translations.

## LICENSE

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see
    <http://www.gnu.org/licenses/>.

# NOTES

- On dnla we should use the toyproxy?
- figure out how to make mftx more general
  - ./mftx is still a script with the #! line pointing to general
    script


* * *

- /tmp/emacs$(id -u)/<ID> : running?
- emacs --daemon=<ID>
- emacsclient -s <ID> [--no-wait]
- emacsclient --eval "(kill-emacs)"
- emacsclient --eval "(interactive) (save-some-buffers) (kill-emacs)"
- Identifying emacs
  - netstat --unix -lp : shows path and PID
  - wmctrl -l -p : list windows and PID

