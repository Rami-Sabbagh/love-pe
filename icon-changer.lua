--love-icon-changer library by RamiLego4Game (Rami Sabbagh)
--[[
- Usage:
local iconChanger = require("icon-changer")

local icodata = iconChanger.extractIcon(exeFile)
]]

local bit = require("bit")

local bor,band,lshift,rshift = bit.bor,bit.band,bit.lshift,bit.rshift

--==Internal Functions==--

local function readNumber(str,bigEndian)
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
  
  
end

return icapi