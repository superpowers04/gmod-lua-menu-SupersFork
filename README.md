Superpowers04's fork of [Garry's Mod Lua Main Menu](https://github.com/robotboy655/gmod-lua-menu)
=============
A fork of [Garry's Mod Lua Main Menu](https://github.com/robotboy655/gmod-lua-menu) by robotboy655
The ONLY reason why this hasn't been pr'd is because I use a different programming style that doesn't entirely conform to the CONTRIBUTING.md

Main changes
* Addon list now supports sorting, searching, mass-toggling, and a display on the side showing the last selected addon's icon, description, and other information about it
* Completely custom addon pack implementation(Addonpacks are text files in `GarrysMod/garrysmod/data/addon_packs_smmenu/` containing `ID NAME` seperated by newlines)
* Saves, and Demos now have a search bar
* Hopefully better programming
<img width="1920" height="1078" alt="image" src="https://github.com/user-attachments/assets/dd9e61a9-165e-41f6-aecf-3dc2daba5d06" />




Garry's Mod Lua Main Menu
=============

A Lua powered ( No HTML ) main menu for Garry's Mod.
It is meant for those who do not have main menu in Garry's Mod by default.
Note that this is a personal project, and it is not going to be included into Garry's Mod.
It does not have some features that I don't use.
Some other features that are not part of the standard menu might be added in the future.

Missing/Broken Features
=============

* Server browser - This menu uses the default Source Engine server browser
* Limited Demos and Saves functionality - No workshop, sorting or filtering
* Good looks
* You can't browse through new/top rated/ect addons in main menu. You should use the Open Workshop button anyway.

New/Fixed Features
=============

* I think it's faster then the default one
* Achievements menu
* More functionality for New Game and Addons menus
* No HTML

Installing
=============

To install this, download the ZIP and extract contents of ```gmod-lua-menu-master``` folder ( folders ```lua``` and ```materials``` ) to your ```SteamApps/common/GarrysMod/garrysmod/``` folder.

Uninstalling
=============

To uninstall this, open ```SteamApps/common/GarrysMod/garrysmod/lua/menu/menu.lua``` and follow instructions inside.
Alternatively, you can simply verify game cache integrity of Garry's Mod and the custom menu will be gone.
