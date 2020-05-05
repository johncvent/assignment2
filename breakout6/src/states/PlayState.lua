--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
    self.mstatus = 0
    
    self.paddleTarget = params.paddleTarget
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    if self.score >= self.paddleTarget then

        --INCREMENT PADDLE SIZE WHEN REACH TARGET SCORE
        if self.paddle.size + 1 >= 4 then 
            self.paddle.size = 4
        else
            self.paddle.size = self.paddle.size + 1
        end
        self.paddleTarget = self.paddleTarget * 2
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)
    if self.mstatus==1 then
        self.multiball:update(dt)
    end

    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end
    if self.mstatus==1 then
        if self.multiball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.multiball.y = self.paddle.y - 8
            self.multiball.dy = -self.multiball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.multiball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.multiball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.multiball.x))
        
            -- else if we hit the paddle on its right side while moving right...
            elseif self.multiball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.multiball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    else
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        --detect collision of powerup with paddle
        if brick.mstatus==1 and brick:powerupCollides(self.paddle) then
            --initialize a multiball
            self.multiball=Ball(self.ball.skin)
            self.multiball.x = self.paddle.x + (self.paddle.width / 2) - 4
            self.multiball.y = self.paddle.y - 8
            -- give ball random starting velocity
            self.multiball.dx = math.random(-200, 200)
            self.multiball.dy = math.random(-50, -60)
            self.mstatus=1
            brick.mstatus=0
            gSounds['powerup']:play()
        end    

         --remove lock from brick
        if brick.lstatus==1 and brick:powerupCollides(self.paddle) then
            brick.lstatus=0
            self.score = self.score + (1000*(math.floor(self.level/15)+1))
            gSounds['powerup']:play()
        end

        -- only check collision if we're in play
        if (brick.inPlay and self.ball:collides(brick))
        then

            -- add to score
            if brick.lstatus == 0 then
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    paddleTarget = self.paddleTarget
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end
            -- only allow colliding with one brick, for corners
            break
        end

        if (brick.inPlay and self.mstatus==1 and self.multiball:collides(brick))
        then

            if brick.lstatus == 0 then
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    paddleTarget = self.paddleTarget
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips

            if self.mstatus==1 then
                if self.multiball.x + 2 < brick.x and self.multiball.dx > 0 then
                
                   -- flip x velocity and reset position outside of brick
                   self.multiball.dx = -self.multiball.dx
                   self.multiball.x = brick.x - 8
            
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.multiball.x + 6 > brick.x + brick.width and self.multiball.dx < 0 then
                
                    -- flip x velocity and reset position outside of brick
                    self.multiball.dx = -self.multiball.dx
                    self.multiball.x = brick.x + 32
            
                -- top edge if no X collisions, always check
                elseif self.multiball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    self.multiball.dy = -self.multiball.dy
                    self.multiball.y = brick.y - 8
            
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    self.multiball.dy = -self.multiball.dy
                    self.multiball.y = brick.y + 16
                end
            else    
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if self.mstatus==1 then
                if math.abs(self.multiball.dy) < 150 then
                    self.multiball.dy = self.multiball.dy * 1.02
                end
            else
            end
            -- only allow colliding with one brick, for corners
            break
        end

    end

    -- if both balls goes below bounds, revert to serve state and decrease health
    if self.mstatus==1 then
        if self.multiball.y >= VIRTUAL_HEIGHT and self.ball.y >= VIRTUAL_HEIGHT then
            self.health = self.health - 1
            gSounds['hurt']:play()

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                --DECREMENT PADDLE SIZE WHEN LOSE A HEART
                if self.health == 2 then
                    if self.paddle.size - 1 <= 1 then 
                        self.paddle.size = 1
                    else
                        self.paddle.size = self.paddle.size - 1
                    end
                end
                if self.health == 1 then
                    if self.paddle.size - 1 <= 1 then
                        self.paddle.size = 1 
                    else
                        self.paddle.size = self.paddle.size - 1
                    end
                end
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    paddleTarget = self.paddleTarget
                })
            end
        end
    else
        -- if ball goes below bounds, revert to serve state and decrease health
        if self.ball.y >= VIRTUAL_HEIGHT then
            self.health = self.health - 1
            gSounds['hurt']:play()

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                --DECREMENT PADDLE SIZE WHEN LOSE A HEART
                if self.health == 2 then
                    if self.paddle.size - 1 <= 1 then 
                        self.paddle.size = 1
                    else
                        self.paddle.size = self.paddle.size - 1
                    end
                end
                if self.health == 1 then
                    if self.paddle.size - 1 <= 1 then
                        self.paddle.size = 1 
                    else
                        self.paddle.size = self.paddle.size - 1
                    end
                end
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    paddleTarget = self.paddleTarget
                })
            end
        end
    end
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()
    if self.mstatus==1 then
        self.multiball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end