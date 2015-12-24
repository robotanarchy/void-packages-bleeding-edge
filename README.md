## Inofficial Bleeding Edge Package Templates for [Void Linux](https://voidlinux.eu)

This repository allows you to build the latest version of software, directly from the versioning control system.
Currently, this repository only has the i3-compatible window manager sway for Wayland (and its dependency wlc).

#### Usage

##### Install sway-git
```bash
git clone https://github.com/robotanarchy/void-packages-bleeding-edge/
cd void-packages-bleeding-edge
./overlay.sh sway-git
./xbps-src binary-bootstrap
./xbps-src pkg sway-git
sudo xbps-install --force --repository=binpkgs sway-git
```

##### Update sway-git and wlc-git
```bash
# you must be in the void-packages-bleeding-edge folder
./overlay.sh sway-git
./xbps-src pkg wlc-git sway-git
./xbps-src pkg sway-git
sudo xbps-install --repository=binpkgs wlc-git sway-git
```

#### How does it work?

`overlay.sh` wraps the whole void-packages repository. Whenever you call it, it updates that void-packages repository (inside the `cache` folder) and merges the `shlibs` file (with `cache/void-packages/common/shlibs`) as well as the `srcpkgs` folders.

For each package template, git repositories (if you need svn etc, make a pull-request!) can be defined in the `sources` file. `overlay.sh` automatically checks out these repos to the `cache`-folder, updates the repositories, sets the right version in the template files and copies the contents of the `cache`-folder to `masterdir/sources`, so the upstream-repositories are available at build time and don't need to be downloaded again.

Go ahead and read the source code of `overlay.sh`, it is actually very short.

#### How can I create my own overlay repository?
Fork this one and modify it to your needs :smile: You'll need at least the `overlay.sh`, `sources` and `srcpkgs` folder (put your own templates in there). The `xbps-src`-wrapper is useful, too.

If you have more bleeding edge packages, `xlint` them and make a pull request, so they can be added here.

Don't forget to add non-bleeding-edge packages to void-packages instead, where it makes sense.
