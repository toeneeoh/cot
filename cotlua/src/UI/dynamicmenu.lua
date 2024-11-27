--[[
    dynamicmenu.lua

    An interface that replaces the original inventory UI with custom buttons that change depending on the selected unit.
    Item spells
    Inspect player stats
    Inspect player inventory
    Potion
]]

OnInit.final("DynamicMenu", function(Require)
    Require('Users')
    Require('Frames')

    local backdrop = BlzCreateFrameByType("BACKDROP", "", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    BlzFrameSetSize(backdrop, 0.001, 0.001)
    BlzFrameSetTexture(backdrop, "trans32.blp", 0, true)
    BlzFrameSetAbsPoint(backdrop, FRAMEPOINT_BOTTOM, 0.52, 0.11)
    BlzFrameSetEnable(backdrop, false)

    local slots = {}
    local gap_x = 0.036
    local gap_y = 0.036
    local icon_size = 0.03

    for i = 1, 6 do
        local x = math.fmod(i - 1, 2)
        local y = (i - 1) // 2
        slots[i] = Button.create(backdrop, icon_size, icon_size, gap_x * x, -gap_y * y, false)
        slots[i]:icon("ReplaceableTextures\\CommandButtons\\BTNCancel.blp")
        slots[i].tooltip:visible(false)
        slots[i]:visible(true)
        slots[i].index = i
        if x > 2 then
            slots[i].tooltip:point(FRAMEPOINT_TOPRIGHT)
        end
    end

end, Debug and Debug.getLine())
