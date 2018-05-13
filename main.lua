io.stdout:setvbuf("no")

local lovePE = require("love-pe")

function love.load(args)
  love.graphics.setBackgroundColor(1,1,1,1)
  
  local exeFile = assert(love.filesystem.newFile("love.exe","r"))
  local icoFile = assert(love.filesystem.newFile("Icon.ico","r"))
  local newFile = assert(love.filesystem.newFile("Patched-"..os.time()..".exe","w"))
  
  local success = lovePE.replaceIcon(exeFile,icoFile,newFile)
  
  if success then
    newFile:flush()
    newFile:close()
    love.system.openURL("file://"..love.filesystem.getSaveDirectory())
  end
  
  love.event.quit(0)
end

function love.draw()
  love.graphics.setColor(0,0,0,1)
  love.graphics.printf("Replaced Icon Successfully",0,200/2-5,300,"center")
end

function love.update(dt)
  
end