# ** GPLACER ** #
## A Source Mapping Utility ##
Gplacer is a simple tool for source mappers. Using gplacer, you can build by placing props in Garrysmod, and send them to hammer. This is useful for decorating maps quickly, and allows you to take advantage of pysics when decorating your maps.

## Installation ##
To install gplacer, clone this repository to your garysmod/garrysmod/addons folder, or subscribe to it on the workshop, here: https://steamcommunity.com/sharedfiles/filedetails/?id=873907162

## Usage ##
Using Gplacer is simple, the idea is that all props spawned after enabling a "gplacer mode" will automatically be sent to your map.

#### _Gplacer Mode_ ####
To enter Gplacer mode, enter in to console: GPLACER_TOGGLE

While in Gplacer mode, all props you spawn will be marked as being "Gplaced".

Hammer and Garrysmod must both be running at the same time and Steam must be running as administrator. Furthermore, this will only work if you are hosting the game off of your computer (singleplayer/listen server).

The map file's name name must be the exact same in Hammer as it is in Gmod!
To send all placed props to hammer, enter into console: GPLACER_UPDATE

You can make move the props, remove them, or add new ones and updating with GPLACER_UPDATE will reflect these changes into Hammer.

You can change the entity class with the command: 'GPLACER_CLASS class_name'
By default this is prop_static.

# Legal #
Copyright (c) 2017 Joseph Tomlinson All Rights Reserved.
