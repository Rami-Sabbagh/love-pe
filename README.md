# love-pe

LOVE-PE is a WIP program for hacking some resources inside exe files (and possibly .dll files) using love and lua only, with no native lua libraries dependencies (So it can run on Windows, Linux, Mac, Android and even iOS) !

![Demonstaion GIF](DemoGif.gif)

## Current Achievements:
- Parses the DataDirectory and the Sections Table of a PE (exe/dll) file.
- Parses the resources directory and extracts it.
- Parses the `ICON_GROUP` and converts it into viewable .ICO
- Rebuild the resources table.
- Convert an .ICO into it's resources format.
- Rebuild the executable.
- Patch the .ICO without rebuilding the whole executable.

## Operating Instructions:
1. Install LÖVE 11.1.
2. Download `IconPatcher-V0.2.love` (Attached below).
3. Download LÖVE for Windows (32-bit or 64-bit, both supported), from https://love2d.org.
4. Create a new icon using your favorite image editor.
5. Run the downloaded .love using LÖVE.
6. Drop the `.exe` and `.ico` files
7. A folder with open with the patched `.exe` in.
8. Enjoy.

## Note:
The tool will mostly fail on any other executable than love, that's because I've done all my testing on `love.exe`, and the result `love.exe` hasn't been tested if it's completely functioning or would crash on some tasks.

Also do note that I'm not recalculating the checksum (which look like a dummy value for most executables), nor the `ImageSize`, so that some "Antiviruses" may find it as suspicious file.

I did find a problem myself that 7-ZIP can no longer read the resources section of the patched .exe (Yes, 7-ZIP can browse the `.exe`, at least on windows)

When reporting a non working `.exe`, please upload the `.exe` and `.ico` and create a github issue: https://github.com/RamiLego4Game/love-pe/issues

## Usable API:

Copy the love-pe.lua file from this repo into your own project, and here's the API documentation (It's available at the top of the script):
```lua
local lovePE = require("love-pe")

local icodata = lovePE.extractIcon(exeFile)
local success = lovePE.replaceIcon(exeFile,icoFile,newFile)
local success = lovePE.patchIcon(exeFile,icoFile,newFile)

local icodata = lovePE.extractIcon(exeString)
local success, newString = lovePE.replaceIcon(exeString,icoString)
local success, newString = lovePE.patchIcon(exeString,icoString)

- Arguments:
exeFile -> A LÖVE File object open in read mode and seaked at 0, The source exe file.
icoFile -> A LÖVE File object open in read mode and seaked at 0, The new ico file.
newFile -> A LÖVE File object open in write mode and seaked at 0, The new patched exe file.

exeString -> The source exe data as a string.
icoString -> The new ico data as a string.
newString -> The new patched exe data as a string.
```