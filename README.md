# QuakeEnhancedQC
A QuakeC base intended to be used for modding Quake Enhanced specificaly.
It attempts to replicate most of the changes that were introduced in Quake Enhanced as well as fix some of the issues that old bases have with the new version.

* Originally based off on QuakeC 1.06 source (This is not GPL)
* Meant to be used with FTEQCC compiler
* All warnings have been fixed
* Some utilities related to Quake Enhanced have been added
* Quake Enhanced specific things like built-ins, flags, packets, etc.. have been added.

## New Features / Utilities

### Multiplayer mod name
Quake Enhanced doesn't officially support multiplayer mods, but unofficially it's possible to develop them. However, right now, the only way to show that a lobby is running a mod it's to change the map name.
For this effect, the base contains a file: `maps.qc` which contains code that will automatically append the mod name to any of the official maps.

If you have any custom map and you want the mod name to apply, you need to register it with this file.
