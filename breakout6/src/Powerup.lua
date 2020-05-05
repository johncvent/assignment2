--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Represents an item that will descend after a certain amount of time or
    when a block is hit a certain number of times.  When the item hits the 
    paddle, a new ability will be released for the player
]]

Powerup = Class{}

function Powerup:init(x,y,mstatus,lstatus)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.initx=x
    self.inity=y
    self.x=self.initx
    self.y=self.inity
    self.quad=math.random(1,10)
    self.multiQuad=9
    self.lockQuad=10
    self.mstatus=mstatus
    self.lstatus=lstatus

    -- these variables are for keeping track of our velocity on the
    -- Y axis, since the powerup simply falls
    self.dy = 20
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    if self.lstatus==1 then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.lockQuad], self.x, self.y)
    else 
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.multiQuad], self.x, self.y)
    end
end