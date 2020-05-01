--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Represents an item that will descend after a certain amount of time or
    when a block is hit a certain number of times.  When the item hits the 
    paddle, a new ability will be released for the player
]]

Powerup = Class{}

function Powerup:init(x,y)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.x=x
    self.y=y
    self.quad=math.random(1,10)
    self.multiQuad=9

    -- these variables are for keeping track of our velocity on the
    -- Y axis, since the powerup simply falls
    self.dy = 20
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:render()
	love.graphics.draw(gTextures['main'], gFrames['powerups'][self.multiQuad], self.x, self.y)
end