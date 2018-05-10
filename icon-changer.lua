--love-icon-changer library by RamiLego4Game (Rami Sabbagh)
--[[
- Usage:
local iconChanger = require("icon-changer")

local icodata = iconChanger.extractIcon(exeFile)
]]

local bit = require("bit")

local bor,band,lshift,rshift,tohex = bit.bor,bit.band,bit.lshift,bit.rshift,bit.tohex

--==Internal Functions==--

local function decodeNumber(str,bigEndian)
  local num = 0
  
  if bigEndian then str = str:reverse() end
  
  for char in string.gmatch(str,".") do
    local byte = string.byte(char)
    
    num = lshift(num,8)
    num = bor(num, byte)
  end
  
  return num
end

--==User API==--

local icapi = {}

function icapi.extractIcon(exeFile)
  
  --DOS Header
  if exeFile:read(2) ~= "MZ" then return error("This is not an executable file !") end
  
  exeFile:read(58) --Skip 58 bytes
  
  local PEHeaderOffset = decodeNumber(exeFile:read(4),true) --Offset to the 'PE\0\0' signature relative to the beginning of the file
  
  exeFile:seek(PEHeaderOffset) --Seek into the PE Header
  
  --PE Header
  if exeFile:read(4) ~= "PE\0\0" then return error("Corrupted executable file !") end
  
  --COFF Header
  exeFile:read(2) --Skip Machine.
  
  local NumberOfSections = decodeNumber(exeFile:read(2))
  
  exeFile:read(16) --Skip 3 long values (12 bytes) and 2 short values (4 bytes).
  
  --PE Optional Header
  local PEOptionalHeaderSignature = decodeNumber(exeFile:read(2))
  
  local x86, x64 --Executable arch
  
  if PEOptionalHeaderSignature == 267 then --It's x86
    x86 = true
  elseif PEOptionalHeaderSignature == 523 then --It's x64
    x64 = true
  else
    return error("ROM images are not supported !")
  end
  
  exeFile:read(x64 and 106 or 90) --Skip 106 bytes for x64, and 90 bytes for x86
  
  local NumberOfRvaAndSizes = decodeNumber(exeFile:read(4))
  
  local DataDirectories = {}
  
  for i=1, NumberOfRvaAndSizes do
    DataDirectories[i] = {decodeNumber(exeFile:read(4)), decodeNumber(exeFile:read(4))}
  end
  
  --Sections Table
  local Sections = {}
  
  for i=1, NumberOfSections do
    print("Section",i)
    
    local Section = {}
    
    Section.Name = ""
    for i=1,8 do
      local char = exeFile:read(1)
      if char ~= "\0" then
        Section.Name = Section.Name .. char
      end
    end
    print("Name",Section.Name)
    
    Section.VirtualSize = decodeNumber(exeFile:read(4))
    Section.VirtualAddress = decodeNumber(exeFile:read(4))
    Section.SizeOfRawData = decodeNumber(exeFile:read(4))
    Section.PointerToRawData = decodeNumber(exeFile:read(4))
    Section.PointerToRelocations = decodeNumber(exeFile:read(4))
    Section.PointerToLinenumbers = decodeNumber(exeFile:read(4))
    Section.NumberOfRelocations = decodeNumber(exeFile:read(2))
    Section.NumberOfLinenumbers = decodeNumber(exeFile:read(2))
    Section.Characteristics = decodeNumber(exeFile:read(4))
    
    Sections[i] = Section
  end
end

return icapi