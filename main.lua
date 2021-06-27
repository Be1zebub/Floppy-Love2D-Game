local file = require("src.file")

local highScore = 0
if file.Exists("gamedata.dat") then
	highScore = tonumber( love.data.decompress("string", "lz4", file.Read("gamedata.dat")) )
else
    file.Write("gamedata.dat", love.data.compress("string", "lz4", "0"))
end

local ScrW, ScrH = love.graphics.getWidth(), love.graphics.getHeight()
local one255 = 1 / 255

local type = type
local _istable = {["table"] = true}

function istable(v)
	return _istable[type(v)] or false
end

function table.Copy(t, lookup_table)
	if t == nil then return nil end

	local copy = {}
	setmetatable(copy, debug.getmetatable(t))
	for i, v in pairs(t) do
		if not istable(v) then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = table.Copy(v, lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

function setColor(r, g, b, a)
	love.graphics.setColor(r * one255, g * one255, b * one255, a and a * one255 or 1)
end

function drawRect(x, y, w, h)
	love.graphics.rectangle("fill", x, y, w, h)
end

local TEXT_ALIGN_CENTER = 1

function drawText(str, font, x, y, alignX, alignY)
	if alignX == TEXT_ALIGN_CENTER then
		x = x - font:getWidth(str) * 0.5
	end

	if alignY == TEXT_ALIGN_CENTER then
		y = y - font:getHeight(str) * 0.5
	end

	love.graphics.setFont(font)
	love.graphics.print(str, x, y)
end

local music = love.audio.newSource("assets/sound/ambient.mp3", "static")
music:setLooping(true)
music:play()
music:setVolume(0.2)


game = {}
game.upcomingPipe = 1
game.enableBot = true
game.menuName = love.graphics.newImage("assets/image/name.png")
game.backgroundSky = love.graphics.newImage("assets/image/background_sky.png")
game.backgroundGround = love.graphics.newImage("assets/image/background_ground.png")
game.backgroundX = 0
game.speed = 60
game.playText = "PLAY"
game.score = 0
game.highScore = highScore

local floppy = require("src.floppy")

local pipe = {}
pipe.W = 64
pipe.SpaceY = 100
pipe.SpaceH = 150
pipe.SpaceYMin = 54
pipe.X = ScrW
pipe.id = 1
pipe.ImageBottom = love.graphics.newImage("assets/image/pipe_bottom.png")
pipe.ImageTop = love.graphics.newImage("assets/image/pipe_top.png")

function pipe:Reset(isupdate)
    self.SpaceY = math.random(self.SpaceYMin, ScrH - self.SpaceH - self.SpaceYMin)
    self.X = ScrW
end

local rad_180 = math.rad(180)

function pipe:Draw()
	setColor(255, 255, 255)
	love.graphics.draw(self.ImageTop, self.X, self.SpaceY - 200)
	love.graphics.draw(self.ImageBottom, self.X, self.SpaceY + self.SpaceH)
end

function pipe:Update(dt)
	if self.X + self.W < 0 then
        self:Reset(true)
	else
		self.X = self.X - game.speed * dt
    end

	self:CalcCollide()
	self:CalcPass()
end

function pipe:CalcPass()
	if game.upcomingPipe == self.id and floppy.X > self.X + self.W then
		game.score = game.score + 1
		game.upcomingPipe = game.upcomingPipe + 1
		if game.upcomingPipe > 2 then
			game.upcomingPipe = 1
		end
	end
end

function pipe:CalcCollide()
	if floppy.X < self.X + self.W and floppy.X + floppy.W > self.X and floppy.Y < self.SpaceY
	or floppy.X < self.X + self.W and floppy.X + floppy.W > self.X and (floppy.Y < self.SpaceY or floppy.Y + floppy.H > self.SpaceY + self.SpaceH) then
		love.load()
	end
end

local pipe2 = table.Copy(pipe)
pipe2.X = pipe2.X + 160
pipe2.id = 2

function pipe2:Reset(isupdate)
    self.SpaceY = math.random(self.SpaceYMin, ScrH - self.SpaceH - self.SpaceYMin)
	if isupdate then
		self.X = ScrW
	else
    	self.X = ScrW + (ScrW + self.W) * 0.5
	end
end



local draw = {}

function draw.sky()
	setColor(255, 255, 255)
	love.graphics.draw(game.backgroundSky, game.backgroundX, 0)
	love.graphics.draw(game.backgroundSky, game.backgroundX + 624, 0)
end

function draw.ground()
	setColor(255, 255, 255)
	love.graphics.draw(game.backgroundGround, game.backgroundX, ScrH - 34)
	love.graphics.draw(game.backgroundGround, game.backgroundX + 624, ScrH - 34)
end

function draw.floppy()
	love.graphics.draw(floppy.Image, floppy.X, floppy.Y, math.rad(floppy.Speed * 0.2))
end

function draw.pipes()
	pipe:Draw()
	pipe2:Draw()
end

local scoreFont = love.graphics.newFont("assets/fonts/Roboto-Medium.ttf", 32)
local menuFont = love.graphics.newFont("assets/fonts/Roboto-Medium.ttf", 16)
local menuFontBold = love.graphics.newFont("assets/fonts/Roboto-Bold.ttf", 16)
local buttonFont = love.graphics.newFont("assets/fonts/Roboto-Bold.ttf", 22)

function draw.score()
	setColor(255, 255, 255)
	drawText(game.score, buttonFont, ScrW * 0.5, 16, TEXT_ALIGN_CENTER)
end

local buttonW, buttonH = 100, 32
local buttonX = ScrW * 0.5 - buttonW * 0.5
local buttonY = ScrH * 0.55 - buttonH * 0.55

local function buttonHover()
	local x, y = love.mouse.getX(), love.mouse.getY()
	return x >= buttonX and x <= buttonX + buttonW
	and y >= buttonY and y <= buttonY + buttonH + 6
end

local hand = love.mouse.getSystemCursor("hand")
local arrow = love.mouse.getSystemCursor("arrow")

function draw.menu()
	setColor(0, 0, 0, 100)
	drawRect(0, 0, ScrW, ScrH)

	setColor(255, 255, 255)
	love.graphics.draw(game.menuName, ScrW * 0.5 - game.menuName:getWidth() * 0.5, ScrH * 0.3)

	if game.scoreLast then
		setColor(255, 255, 255)
		drawText("Score: ".. game.scoreLast, menuFont, ScrW * 0.5, ScrH * 0.65, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		drawText("Highscore: ".. game.highScore, menuFont, ScrW * 0.5, ScrH * 0.7, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if game.newHighScore then
			drawText("New record!", menuFontBold, ScrW * 0.5, ScrH * 0.75, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	setColor(44, 62, 80)
	drawRect(buttonX, buttonY + 6, buttonW, buttonH)

	if buttonHover() then
		setColor(211, 84, 0)
		love.mouse.setCursor(hand)
	else
		setColor(230, 126, 34)
		love.mouse.setCursor(arrow)
	end
	drawRect(buttonX, buttonY, buttonW, buttonH)

	setColor(255, 255, 255)
	drawText(game.playText, buttonFont, buttonX + buttonW * 0.5, buttonY + buttonH * 0.5, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end



function love.load()
    floppy:Reset()
	pipe:Reset()
	pipe2:Reset()

	if game.enableBot == false then
		game.playText = "RETRY"
		game.scoreLast = game.score
	end

	game.newHighScore = false

	if game.enableBot == false and game.score > game.highScore then
		game.highScore = game.score
		game.newHighScore = true
		file.Write("gamedata.dat", love.data.compress("data", "lz4", tostring(game.highScore)))
	end

	game.score = 0
	game.upcomingPipe = 1
	game.enableBot = true
end

function love.draw()
    draw.sky()
	draw.floppy()
	draw.pipes()
	draw.ground()

	if game.enableBot then
		draw.menu()
		return
	end

	draw.score()
end

function love.update(dt)
	if game.enableBot then
		local upcomingPipe = game.upcomingPipe == 1 and pipe or pipe2
		
		if floppy.Y + floppy.H + math.random(16, 48) >= upcomingPipe.SpaceY + upcomingPipe.SpaceH then
			floppy:Flop()
		end
	end

	floppy:Update(dt)
	pipe:Update(dt)
	pipe2:Update(dt)

	game.backgroundX = game.backgroundX - game.speed * dt
	if game.backgroundX < -625 then
		game.backgroundX = 0
	end
end

function love.mousepressed(x, y, button)
	if button ~= 1 then return end

	if game.enableBot then
		if buttonHover() then
			love.load()
			game.enableBot = false
		end
	else
		floppy:Flop()
	end
end

function love.keypressed(key)
	if game.enableBot then return end

	floppy:Flop()
end