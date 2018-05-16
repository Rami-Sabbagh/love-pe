io.stdout:setvbuf("no")

local lovePE = require("love-pe")

local message = "Replaced Icon Successfully"

function love.load(args)
  love.graphics.setBackgroundColor(1,1,1,1)
  
  local exeFile = assert(love.filesystem.newFile("love.exe","r"))
  local icoFile = assert(love.filesystem.newFile("Icon.ico","r"))
  local newFile = assert(love.filesystem.newFile("Patched-"..os.time()..".exe","w"))
  
  local success = lovePE.patchIcon(exeFile,icoFile,newFile)
  
  if success then
    newFile:flush()
    newFile:close()
    love.system.openURL("file://"..love.filesystem.getSaveDirectory())
  end
  
  love.event.quit(0)
end

local exeFile, icoFile

--Override the testing function
function love.load()
  love.graphics.setBackgroundColor(1,1,1,1)
  
  message = "\nPlease drop the .exe and .ico files"
end

function love.filedropped(file)
  if file:getFilename():sub(-4,-1) == ".exe" then
    local ok, err = file:open("r")
    if not ok then
      message = "Failed to open the .exe file in read mode: "..(err or "unkown reason")
      return
    end
    message = exeFile and ".exe file updated successfully" or ""
    exeFile = file
  elseif file:getFilename():sub(-4,-1) == ".ico" then
    local ok, err = file:open("r")
    if not ok then
      message = "Failed to open the .ico file in read mode: "..(err or "unkown reason")
      return
    end
    message = icoFile and ".ico file updated successfully" or ""
    icoFile = file
  else return end
  
  if exeFile and icoFile then
    local filename = exeFile:getFilename():sub(1,-5):gsub("\\","/")
    local lastSlash = string.find(filename:reverse(),"/")
    if lastSlash then filename = filename:sub(#filename-lastSlash+2,-1) end
    
    local newFile = assert(love.filesystem.newFile(os.time().."_"..filename..".exe","w"))
    
    lovePE.patchIcon(exeFile,icoFile,newFile)
    
    newFile:flush() newFile:close()
    exeFile:close() icoFile:close()
    exeFile, icoFile = false,false
    
    message = "Replaced icon successfully\nDrop new .exe and .ico files"
    
    love.system.openURL("file://"..love.filesystem.getSaveDirectory())
  elseif icoFile then
    message = message.."\nPlease drop the .exe file"
  elseif exeFile then
    message = message.."\nPlease drop the .ico file"
  else
    message = message.."\nPlease drop the .exe and .ico files"
  end
end

function love.draw()
  love.graphics.setColor(0,0,0,1)
  love.graphics.printf(message,0,200/2-20,300,"center")
end

function love.quit()
  if exeFile then exeFile:close() end
  if icoFile then icoFile:close() end
end