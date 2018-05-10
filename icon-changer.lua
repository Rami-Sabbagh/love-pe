--love-icon-changer library by RamiLego4Game (Rami Sabbagh)
--[[
- Usage:
local iconChanger = require("icon-changer")

local icodata = iconChanger.extractIcon(exeFile)
]]

local bit = require("bit")

local bor,band,lshift,rshift = bit.bor,bit.band,bit.lshift,bit.rshift

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
  
  exeFile:read(12) --Skip 3 long values (12 bytes).
  
  local SizeOfOptionalHeader = decodeNumber(exeFile:read(2))
  
  exeFile:read(2) --Skip a short value (2 bytes) (Characteristics).
  
  
end

return icapi