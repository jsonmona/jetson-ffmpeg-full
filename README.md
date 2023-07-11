## jetson-ffmpeg-full

A convinient script to build "full" ffmpeg (bundled with various libraries) with Jetson support.
Built upon [ffmpeg-build-script](https://github.com/markus-perl/ffmpeg-build-script).

Tested on Jetson Nano with stock firmware (Ubuntu 18.04).

### Usage
Install few tools first: `apt install build-essential autotools-dev pkg-config meson ninja curl`

Then, simply clone this repository (or download ZIP), and run `build.sh`.

It will build ffmpeg with GPL + nonfree license.
You can't distribute that binary.

Build should be done on Jetson itself.
If you really need cross-compile, try L4T (linux for tegra) docker container (not tested).

### License
GPL version 2 or (at your option) any later version provided by Free Software Foundation.

Full text of GPL 2 is provided at `LICENSE.txt`.

SPDX-License-Identifier: GPL-2.0-or-later

Note that this license applies only to files that are present in this repository.
For example, ffmpeg itself has other license attached to it.
