local ScrW, ScrH = love.graphics.getWidth(), love.graphics.getHeight()

local jump = love.audio.newSource("assets/sound/jump.mp3", "static")
jump:setVolume(0.5)

local floppy = {}
floppy.X = 62
floppy.Y = 200
floppy.W = 32
floppy.H = 24
floppy.Speed = 0
floppy.Image = love.graphics.newImage("assets/image/floppy.png")

function floppy:Reset()
	self.Y = math.random(120, 280)
    self.Speed = 0
end

function floppy:Update(dt)
	self.Speed = self.Speed + 300 * dt
    self.Y = self.Speed + 10 * dt

	if self.Y + self.H >= ScrH then
		love.load()
	end
end

function floppy:Flop()
	if self.Y > 0 then
    	self.Speed = self.Speed - game.speed
		jump:setPitch(math.random(0.9, 1.1))
		jump:play()
	end
end

return floppy