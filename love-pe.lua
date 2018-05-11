--love-icon-changer library by RamiLego4Game (Rami Sabbagh)
--[[
- Usage:
local lovePE = require("love-pe")

local icodata = lovePE.extractIcon(exeFile)

- Reference:
Version File Resource: https://msdn.microsoft.com/en-us/library/ms647001(v=vs.85).aspx
Icons:
https://msdn.microsoft.com/en-us/library/ms997538.aspx
]]

local bit = require("bit")
local utf8 = require("utf8")

local bor,band,lshift,rshift,tohex = bit.bor,bit.band,bit.lshift,bit.rshift,bit.tohex

local resourcesTypes = {
  "CURSOR",
  "BITMAP",
  "ICON",
  "MENU",
  "DIALOG",
  "STRING_TABLE",
  "FONT_DIRECTORY",
  "FONT",
  "ACCELERATORS",
  "UNFORMATTED_RESOURCE_DATA",
  "MESSAGE_TABLE",
  "GROUP_CURSOR",
  "13",
  "GROUP_ICON",
  "15",
  "VERSION_INFORMATION",
  "17","18","19","20","21","22","23",
  "MANIFEST"
}

--==Internal Functions==--

local function decodeNumber(str,littleEndian)
  local num = 0
  
  if littleEndian then str = str:reverse() end
  
  for char in string.gmatch(str,".") do
    local byte = string.byte(char)
    
    num = lshift(num,8)
    num = bor(num, byte)
  end
  
  return num
end

local function encodeNumber(num,len,bigEndian)
  
  local chars = {}
  
  for i=1,len do
    chars[#chars+1] = string.char(band(num,255))
    num = rshift(num,8)
  end
  
  chars = table.concat(chars)
  
  if bigEndian then chars = chars:reverse() end
  
  return chars
end

local function decodeUTF16(str16)
  local giter = string.gmatch(str16,"..")
  local iter = function()
    local short = giter()
    if short then
      return decodeNumber(short,true)
    end
  end
  
  local nstr = {}
  
  local unicode = iter()
  
  while unicode do
    --Surrogate pairs
    if unicode >= 0xD800 and unicode <= 0xDBFF then
      local lowPair = iter()
      
      if lowPair and lowPair >= 0xDC00 and lowPair <= 0xDFFF then
        unicode = lshift(unicode-0xD800,10) + (lowPair-0xDC00)
        nstr[#nstr+1] = utf8.char(unicode)
        unicode = iter()
      else --Unpaired surrogate
        nstr[#nstr+1] = utf8.char(unicode)
        unicode = lowPair
      end
    else
      nstr[#nstr+1] = utf8.char(unicode)
      unicode = iter()
    end
  end
  
  return table.concat(nstr)
end

local function encodeUTF16(str8)
  
  local nstr ={}
  
  for pos, unicode in utf8.codes(str8) do
    if unicode >= 0x10000 then --Encode as surrogate pair
      unicode = unicode - 0x01000
      nstr[#nstr+1] = encodeNumber(rshift(unicode,10)+0xD800,2)
      nstr[#nstr+1] = encodeNumber(band(unicode,0x3FF)+0xDC00,2)
    else
      nstr[#nstr+1] = encodeNumber(unicode,2)
    end
  end
  
  return table.concat(nstr)
end

local function convertRVA2Offset(RVA,Sections)
  for id, Section in ipairs(Sections) do
    if (Section.VirtualAddress <= RVA) and (RVA < (Section.VirtualAddress + Section.VirtualSize)) then
      return Section.PointerToRawData + (RVA - Section.VirtualAddress)
    end
  end
  error("FAILED "..tohex(RVA))
end

local function readResourceDirectoryTable(exeFile,Sections,RootOffset,Level)
  local Tree = {}
  
  print("---readResourceDirectoryTable",RootOffset)
  
  local Characteristics = decodeNumber(exeFile:read(4))
  local TimeDateStamp = decodeNumber(exeFile:read(4))
  local MajorVersion = decodeNumber(exeFile:read(2))
  local MinorVersion = decodeNumber(exeFile:read(2))
  local NumberOfNameEntries = decodeNumber(exeFile:read(2))
  local NumberOfIDEntries = decodeNumber(exeFile:read(2))
  
  print("Entries:", NumberOfNameEntries+NumberOfIDEntries)
  
  --Parse Entries
  for i=1,NumberOfNameEntries+NumberOfIDEntries do
    print("Entry #"..i)
    
    local Name = decodeNumber(exeFile:read(4))
    local Offset = decodeNumber(exeFile:read(4))
    
    print("Offset",tohex(Offset))
    
    local ReturnOffset = exeFile:tell()
    
    --Parse name/id for entry
    if band(Name,0x80000000) ~= 0 then
      print("String Name")
      --Name is a string RVA
      local NameOffset = convertRVA2Offset(RootOffset + band(Name,0x7FFFFFFF), Sections)
      
      exeFile:seek(NameOffset)
      
      local NameLength = decodeNumber(exeFile:read(2))
      --Decode UTF-16LE string
      Name = decodeUTF16(exeFile:read(NameLength*2))
    else
      --Name is an ID
      Name = band(Name,0xFFFF)
      print("Number Name",Name)
      
      if Level == 0 then
        if resourcesTypes[Name] then
          Name = resourcesTypes[Name]
          print("# New name",Name)
        else
          print("Unkown type")
        end
      end
      
      Name = tostring(Name)
    end
    
    if band(Offset,0x80000000) ~= 0 then
      print("Another Directory")
      --Another directory
      exeFile:seek(RootOffset + band(Offset,0x7FFFFFFF))
      
      Tree[Name] = readResourceDirectoryTable(exeFile,Sections,RootOffset,Level+1)
    else
      print("Data Offset",RootOffset + band(Offset,0x7FFFFFFF))
      --Data offset
      exeFile:seek(RootOffset + band(Offset,0x7FFFFFFF))
      
      local DataRVA = decodeNumber(exeFile:read(4))
      local DataSize = decodeNumber(exeFile:read(4))
      local DataCodepage = decodeNumber(exeFile:read(4))
      
      print("Data",tohex(DataRVA),DataSize)
      
      local DataOffset = convertRVA2Offset(DataRVA,Sections)
      
      print("Data RVA Offset",DataRVA,DataOffset)
      
      print("Data Codepage",DataCodepage)
      
      exeFile:seek(DataOffset)
      
      Tree[Name] = exeFile:read(DataSize)
    end
    
    exeFile:seek(ReturnOffset)
  end
  
  print("--End of tree")
  
  return Tree
end

local function getAnyValue(t)
  for k,v in pairs(t) do
    return v
  end
end

local function extractGroupIcon(ResourcesTree,GroupID)
  --Icon extraction process
  local IconGroup = getAnyValue(ResourcesTree["GROUP_ICON"][tostring(GroupID)])
  
  local Icons = {""}
  
  local o = 5 --String Offset
  
  --Read the icon header
  local Count = decodeNumber(IconGroup:sub(o,o+1),true)
  
  o = o+2
  
  local DataOffset = 6 + 16*Count
  
  for i=1,Count do
    o = o+12
    
    local IcoID = decodeNumber(IconGroup:sub(o,o+1),true)
    
    Icons[#Icons+1] = getAnyValue(ResourcesTree["ICON"][tostring(IcoID)])
    
    local Length = #Icons[#Icons]
    
    IconGroup = IconGroup:sub(1,o-1) .. encodeNumber(DataOffset,4) .. IconGroup:sub(o+2,-1)
    
    o = o + 4
    
    DataOffset = DataOffset + Length
  end
  
  Icons[1] = IconGroup
  
  return table.concat(Icons)
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
    print("DataDirectory #"..i,DataDirectories[i][1],DataDirectories[i][2])
  end
  
  --Sections Table
  local Sections = {}
  
  for i=1, NumberOfSections do
    print("\n------=Section=------",i)
    
    local Section = {}
    
    Section.Name = ""
    for i=1,8 do
      local char = exeFile:read(1)
      if char ~= "\0" then
        Section.Name = Section.Name .. char
      end
    end
    
    Section.VirtualSize = decodeNumber(exeFile:read(4))
    Section.VirtualAddress = decodeNumber(exeFile:read(4))
    Section.SizeOfRawData = decodeNumber(exeFile:read(4))
    Section.PointerToRawData = decodeNumber(exeFile:read(4))
    Section.PointerToRelocations = decodeNumber(exeFile:read(4))
    Section.PointerToLinenumbers = decodeNumber(exeFile:read(4))
    Section.NumberOfRelocations = decodeNumber(exeFile:read(2))
    Section.NumberOfLinenumbers = decodeNumber(exeFile:read(2))
    Section.Characteristics = decodeNumber(exeFile:read(4))
    
    for k,v in pairs(Section) do
      print(k,v)
    end
    
    Sections[i] = Section
  end
  
  --Calculate the file offset to the resources data directory
  local ResourcesOffset = convertRVA2Offset(DataDirectories[3][1],Sections)
  
  --Seek into the resources data !
  exeFile:seek(ResourcesOffset)
  
  print("Offset",ResourcesOffset)
  
  local ResourcesTree = readResourceDirectoryTable(exeFile,Sections,ResourcesOffset,0)
  
  local IconKeys,FirstIcon = {}
  
  for k,v in pairs(ResourcesTree["GROUP_ICON"]) do
    IconKeys[#IconKeys+1] = k
    ResourcesTree["GROUP_ICON"][k] = extractGroupIcon(ResourcesTree,k)
    if not FirstIcon then FirstIcon = ResourcesTree["GROUP_ICON"][k] end
  end
  
  for k,v in pairs(IconKeys) do
    ResourcesTree["GROUP_ICON"][v..".ico"] = ResourcesTree["GROUP_ICON"][v]
    ResourcesTree["GROUP_ICON"][v] = nil
  end
  
  local function writeTree(tree,path)
    for k,v in pairs(tree) do
      if type(v) == "table" then
        love.filesystem.createDirectory(path..k)
        writeTree(v,path..k.."/")
      else
        love.filesystem.write(path..k,v)
      end
    end
  end
  
  writeTree(ResourcesTree,"/")
  
  return FirstIcon
  
end

return icapi