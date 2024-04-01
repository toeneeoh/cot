if Debug then Debug.beginFile 'MissileEffect' end

OnInit.global("MissileEffect", function(require)
    require 'WorldBounds'

do
    MissileEffect = setmetatable({}, {})
    local mt = getmetatable(MissileEffect)
    mt.__index = mt

    function mt:destroy()
        local size = #self.array

        for i = 1, size do
            local this = self.array[i]
            DestroyEffect(this.effect)
            this = nil
        end
        DestroyEffect(self.effect)

        self = nil
    end

    function mt:scale(effect, scale)
        self.size = scale
        BlzSetSpecialEffectScale(effect, scale)
    end

    function mt:orient(yaw, pitch, roll)
        self.yaw   = yaw
        self.pitch = pitch
        self.roll  = roll
        BlzSetSpecialEffectOrientation(self.effect, yaw, pitch, roll)

        for i = 1, #self.array do
            local this = self.array[i]

            this.yaw   = yaw
            this.pitch = pitch
            this.roll  = roll
            BlzSetSpecialEffectOrientation(this.effect, yaw, pitch, roll)
        end
    end

    function mt:move(x, y, z)
        if not (x > WorldBounds.maxX or x < WorldBounds.minX or y > WorldBounds.maxY or y < WorldBounds.minY) then
            BlzSetSpecialEffectPosition(self.effect, x, y, z)
            for i = 1, #self.array do
                local this = self.array[i]
                BlzSetSpecialEffectPosition(this.effect, x - this.x, y - this.y, z - this.z)
            end

            return true
        end
        return false
    end

    function mt:attach(model, dx, dy, dz, scale)
        local this = {}

        this.x = dx
        this.y = dy
        this.z = dz
        this.yaw = 0
        this.pitch = 0
        this.roll = 0
        this.path = model
        this.size = scale
        this.effect = AddSpecialEffect(model, dx, dy)
        BlzSetSpecialEffectZ(this.effect, dz)
        BlzSetSpecialEffectScale(this.effect, scale)
        BlzSetSpecialEffectPosition(this.effect, BlzGetLocalSpecialEffectX(this.effect) - dx, BlzGetLocalSpecialEffectY(this.effect) - dy, BlzGetLocalSpecialEffectZ(this.effect) - dz)

        table.insert(self.array, this)

        return this.effect
    end

    function mt:detach(effect)
        for i = 1, #self.array do
            local this = self.array[i]
            if this.effect == effect then
                table.remove(self.array, i)
                DestroyEffect(effect)
                this = nil
                break
            end
        end
    end

    function mt:setColor(red, green, blue)
        BlzSetSpecialEffectColor(self.effect, red, green, blue)
    end

    function mt:timeScale(real)
        BlzSetSpecialEffectTimeScale(self.effect, real)
    end

    function mt:alpha(integer)
        BlzSetSpecialEffectAlpha(self.effect, integer)
    end

    function mt:playerColor(integer)
        BlzSetSpecialEffectColorByPlayer(self.effect, Player(integer))
    end

    function mt:animation(integer)
        BlzPlaySpecialEffect(self.effect, ConvertAnimType(integer))
    end

    function mt:create(x, y, z)
        local this = {}
        setmetatable(this, mt)

        this.path = ""
        this.size = 1
        this.yaw = 0
        this.pitch = 0
        this.roll = 0
        this.array = {}
        this.effect = AddSpecialEffect("", x, y)
        BlzSetSpecialEffectZ(this.effect, z)

        return this
    end
end

end)

if Debug then Debug.endFile() end
