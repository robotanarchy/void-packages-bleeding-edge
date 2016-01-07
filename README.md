## Inofficial Bleeding Edge Package Templates for [Void Linux](https://voidlinux.eu)

This repository allows you to build the latest version of software, directly from the upstream repositories.
Currently, this repository only has the i3-compatible window manager [sway](https://github.com/SirCmpwn/sway) for Wayland (and its dependency [wlc](https://github.com/Cloudef/wlc)).

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

#### Why?
* Void Linux doesn't *accept any packages containing non-release versions such as specific git- or svn-revisions anymore.* [(source)](https://github.com/voidlinux/void-packages/blob/master/CONTRIBUTING.md#getting-your-packages-into-void-by-yourself)
* `xbps-src` is not able to set package template versions to the their current git versions

**NOTE:** Upstream discussion of XBPS overlays is [here](https://github.com/voidlinux/void-packages/issues/3218).

#### How does it work?

[`overlay.sh`](https://github.com/robotanarchy/void-packages-bleeding-edge/blob/master/overlay.sh) wraps the whole [void-packages](https://github.com/voidlinux/void-packages) repository. Whenever you call it, it updates that void-packages repository (inside the `cache` folder) and merges [`shlibs`](https://github.com/robotanarchy/void-packages-bleeding-edge/blob/master/shlibs) (with `cache/void-packages/common/shlibs`) as well as the [`srcpkgs`](https://github.com/robotanarchy/void-packages-bleeding-edge/tree/master/srcpkgs) folders.

For each package template, git repositories (if you need svn etc, make a pull-request!) can be defined in the [`sources`](https://github.com/robotanarchy/void-packages-bleeding-edge/blob/master/sources) file. `overlay.sh` automatically checks out these repos to the `cache`-folder, updates the repositories, sets the right version in the template files and copies the contents of the `cache`-folder to `masterdir/sources`, so the upstream-repositories are available at build time and don't need to be downloaded again.

Go ahead and read the source code of `overlay.sh`, it is actually very short.

#### How can I create my own overlay repository?
Fork this one and modify it to your needs :smile: You'll need at least the `overlay.sh`, `sources` and `srcpkgs` folder (put your own templates in there). The [`xbps-src`](https://github.com/robotanarchy/void-packages-bleeding-edge/blob/master/xbps-src)-wrapper is useful, too.

If you have more bleeding edge packages, `xlint` them and make a pull request, so they can be added here.

Don't forget to add non-bleeding-edge packages to [void-packages](https://github.com/voidlinux/void-packages) instead, where it makes sense.
