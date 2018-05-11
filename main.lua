io.stdout:setvbuf("no")

local lovePE = require("love-pe")

function love.load(args)
  love.graphics.setBackgroundColor(1,1,1,1)
  
  local exeFile = assert(love.filesystem.newFile("love.exe","r"))
  
  local iconData = lovePE.extractIcon(exeFile)
  
  if iconData then
    love.filesystem.write("Extracted Icon.ico",iconData)
    love.system.openURL("file://"..love.filesystem.getSaveDirectory())
  end
  
  love.event.quit(0)
end

function love.draw()
  love.graphics.setColor(0,0,0,1)
  love.graphics.printf("Icon extracted",0,200/2-5,300,"center")
end

function love.update(dt)
  
end