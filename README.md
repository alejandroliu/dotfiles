# dotfiles

My personal dotfile collection (yeah, a me too!)

## Install

This requires [rcm][rcm].

```
git clone --recursive https://github.com/alejandroliu/dotfiles.git $HOME/.dotfiles
env RCRC=$HOME/.dotfiles/rcrc rcup -v
```

## Usage

To add a file to the repository:

```
mkrc .file
```

To add a host specific file:

```
mkrc -o .file
```

To re-syncronise files:

```
rcup -v
```


## References

Other dotfile managers in `bash`  that I
found are:

* [dot-files](https://github.com/bartman/dot-files)


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

* * *

 [rcm]: https://github.com/thoughtbot/rcm "rc file (dotfile) management"

