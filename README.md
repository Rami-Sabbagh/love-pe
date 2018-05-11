# love-pe

LOVE-PE is a WIP program for hacking some resources inside exe files (and possibly .dll files) using love and lua only, with no native lua libraries dependencies (So it can run on Windows, Linux, Mac, Android and even iOS) !

The current goal of the project is to make it possible to replace the icon.

## Current Achievements:
- Parses the DataDirectory and the Sections Table of a PE (exe/dll) file.
- Parses the resources directory and extracts it.
- Parses the `ICON_GROUP` and converts it into viewable .ICO

## What will it do when running it:

It will extract the resources of `love.exe` (11.1 32-bit), and save the main ICON as `Extracted Icon.ico`.
Once done it will open it's appdata folder with all this in it !

![Demonstaion GIF](DemoGif.gif)