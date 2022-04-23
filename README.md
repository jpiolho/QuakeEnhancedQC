# QuakeEnhancedQC
A QuakeC base intended to be used for modding Quake Enhanced specifically.

This repo originally started in order to make a QuakeC base that was compatible with Quake Enhanced as well as replicating all the new changes.
Since then the [official QC has been released](https://github.com/id-Software/quake-rerelease-qc).
Both repositories have now been merged and this repo will continue with improvements and utilities on top of the official release.

* Meant to be used with [FTEQCC](https://www.fteqcc.org) compiler
* Compiler warnings have been fixed (`id1` and `mg1` so far)
* Some utilities related to Quake Enhanced have been added
* This code is released under the GPLv2 license. See `COPYING.txt` for more details.

## New Features / Utilities

### Multiplayer mod name
Quake Enhanced doesn't officially support multiplayer mods, but unofficially it's possible to develop them. However, right now, the only way to show that a lobby is running a mod it's to change the map name.
For this effect, the base contains a file: `maps.qc` which contains code that will automatically append the mod name to any of the official maps.

If you have any custom map and you want the mod name to apply, you need to register it with this file.