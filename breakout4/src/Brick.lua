--[[
    GD50
    Breakout Remake

    -- Brick Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a brick in the world space that the ball can collide with;
    differently colored bricks have different point values. On collision,
    the ball will bounce away depending on the angle of collision. When all
    bricks are cleared in the current map, the player should be taken to a new
    layout of bricks.
]]

Brick = Class{}

-- some of the colors in our palette (to be used with particle systems)
paletteColors = {
    -- blue
    [1] = {
        ['r'] = 99,
        ['g'] = 155,
        ['b'] = 255
    },
    -- green
    [2] = {
        ['r'] = 106,
        ['g'] = 190,
        ['b'] = 47
    },
    -- red
    [3] = {
        ['r'] = 217,
        ['g'] = 87,
        ['b'] = 99
    },
    -- purple
    [4] = {
        ['r'] = 215,
        ['g'] = 123,
        ['b'] = 186
    },
    -- gold
    [5] = {
        ['r'] = 251,
        ['g'] = 242,
        ['b'] = 54
    }
}

function Brick:init(x, y, mstatus)
    -- used for coloring and score calculation
    self.tier = 0
    self.color = 1
    
    self.x = x
    self.y = y
    self.width = 32
    self.height = 16
    
    -- used to determine whether this brick should be rendered
    self.inPlay = true
    self.hitCount = 0

    -- particle system belonging to the brick, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward 
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- spread of particles; normal looks more natural than uniform
    self.psystem:setAreaSpread('normal', 10, 10)

    -- status show whether multiball should be active (0 not active, 1 active)
    self.mstatus = mstatus
    
    -- assign a powerup to a brick instance 
    self.powerup = Powerup(self.x, self.y)
end

--[[
    Triggers a hit on the brick, taking it out of play if at 0 health or
    changing its color otherwise.
]]
function Brick:hit()
    -- set the particle system to interpolate between two colors; in this case, we give
    -- it our self.color but with varying alpha; brighter for higher tiers, fading to 0
    -- over the particle's lifetime (the second color)
    self.psystem:setColors(
        paletteColors[self.color].r,
        paletteColors[self.color].g,
        paletteColors[self.color].b,
        55 * (self.tier + 1),
        paletteColors[self.color].r,
        paletteColors[self.color].g,
        paletteColors[self.color].b,
        0
    )
    self.psystem:emit(64)

    -- sound on hit
    gSounds['brick-hit-2']:stop()
    gSounds['brick-hit-2']:play()

    --increment hit count
    self.hitCount = self.hitCount + 1

    -- if we're at a higher tier than the base, we need to go down a tier
    -- if we're already at the lowest color, else just go down a color
    if self.tier > 0 then
        if self.color == 1 then
            self.tier = self.tier - 1
            self.color = 5
        else
            self.color = self.color - 1
        end
    else
        -- if we're in the first tier and the base color, remove brick from play
        if self.color == 1 then
            self.inPlay = false
        else
            self.color = self.color - 1
        end
    end

    -- play a second layer sound if the brick is destroyed
    if not self.inPlay then
        gSounds['brick-hit-1']:stop()
        gSounds['brick-hit-1']:play()
    end
end

function Brick:update(dt)
    self.psystem:update(dt)

    --begin dropping powerup when multiball status is enabled
    --and brick is hit by a ball
    if self.hitCount>=1 and self.mstatus == 1 then
        self.powerup:update(dt)
    end
end

function Brick:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], 
            -- multiply color by 4 (-1) to get our color offset, then add tier to that
            -- to draw the correct tier and color brick onto the screen
            gFrames['bricks'][1 + ((self.color - 1) * 4) + self.tier],
            self.x, self.y)
    end
    
    --renders powerup only if multiball status is enabled
    if self.mstatus == 1 then
        self.powerup:render()
    end
end

--[[
    Need a separate render function for our particles so it can be called after all bricks are drawn;
    otherwise, some bricks would render over other bricks' particle systems.
]]
function Brick:renderParticles()
    love.graphics.draw(self.psystem, self.x + 16, self.y + 8)
end

function Brick:powerupCollides(paddle)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.powerup.x > paddle.x + paddle.width or paddle.x > self.powerup.x + self.powerup.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.powerup.y > paddle.y + paddle.height or paddle.y > self.powerup.y + self.powerup.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end