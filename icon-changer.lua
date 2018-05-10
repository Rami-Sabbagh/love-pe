--love-icon-changer library by RamiLego4Game (Rami Sabbagh)
--[[
- Usage:
local iconChanger = require("icon-changer")

local icodata = iconChanger.extractIcon(exeFile)
]]

local bit = require("bit")

local bor,band,lshift,rshift,tohex = bit.bor,bit.band,bit.lshift,bit.rshift,bit.tohex

local resourcesTypes = {
  "Cursors",
  "Bitmaps",
  "Icons",
  "Menus",
  "Dialogs",
  "String Tables",
  "Font Directories",
  "Fonts",
  "Accelerators",
  "Unformatted Resource Datas",
  "Message Tables",
  "Group Cursors",
  "13",
  "Group Icons",
  "15",
  "Version Information"
}

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

local function convertUTF16(str16)
  return str16--return str16:gsub("..","%1")
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
      --Name = exeFile:read(NameLength*2)
      Name = string.char(math.random(65,90),math.random(65,90),math.random(65,90),math.random(65,90))
      
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
      
      local ok, DataOffset = pcall(convertRVA2Offset,DataRVA,Sections)
      
      if ok then
        print("RVA OK")
        exeFile:seek(DataOffset)
        Tree[Name.."_P_"..tohex(DataCodepage)] = convertUTF16(exeFile:read(DataSize))
      else
        print("RVA Failed",DataOffset)
        Tree[Name] = ""
      end
    end
    
    exeFile:seek(ReturnOffset)
  end
  
  print("--End of tree")
  
  return Tree
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
  
  return "MEH"
end

return icapi