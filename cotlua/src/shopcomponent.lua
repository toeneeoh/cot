--[[
    shopcomponent.lua

    A module that provides button and tooltip functionality for shop.lua UI.
]]

OnInit.final("ShopComponent", function()

    -- Credits:
    --      Taysen: FDF file
    --      Chopinski: Original vJass

    local TOOLTIP_SIZE               = 0.2 ---@type number 
    local SCROLL_DELAY               = 0.01 ---@type number 
    local DOUBLE_CLICK_DELAY         = 0.25 ---@type number 
    local HIGHLIGHT                  = "UI\\Widgets\\Glues\\GlueScreen-Button-KeyboardHighlight" ---@type string 
    local CHECKED_BUTTON             = "UI\\Widgets\\EscMenu\\Human\\checkbox-check.blp" ---@type string 
    local UNAVAILABLE_BUTTON         = "ui\\widgets\\battlenet\\chaticons\\bnet-squelch" ---@type string 

    ---@class Tooltip
    ---@field text function
    ---@field name function
    ---@field icon function
    ---@field point function
    ---@field frame framehandle
    ---@field pointType framepointtype
    ---@field create function
    ---@field destroy function
    Tooltip = {}
    do
        local thistype = Tooltip
        local mt = { __index = Tooltip }
        thistype.box=nil ---@type framehandle 
        thistype.line=nil ---@type framehandle 
        thistype.tooltip=nil ---@type framehandle 
        thistype.iconFrame=nil ---@type framehandle 
        thistype.nameFrame=nil ---@type framehandle 
        thistype.parent=nil ---@type framehandle 
        thistype.pointType=nil ---@type framepointtype 
        thistype.widthSize=nil ---@type number 
        thistype.texture='' ---@type string 
        thistype.isVisible=nil ---@type boolean 
        thistype.simple=nil ---@type boolean 

        thistype.frame=nil ---@type framehandle 

        ---@type fun(self: Tooltip, description:string):string
        function thistype:text(description)
            if description ~= nil then
                BlzFrameSetText(self.tooltip, description)
            end

            return BlzFrameGetText(self.tooltip)
        end

        ---@type fun(self: Tooltip, newName:string):string
        function thistype:name(newName)
            if newName ~= nil then
                BlzFrameSetText(self.nameFrame, newName)
            end

            return BlzFrameGetText(self.nameFrame)
        end

        ---@type fun(self: Tooltip, texture:string):string
        function thistype:icon(texture)
            if texture ~= nil then
                self.texture = texture
                BlzFrameSetTexture(self.iconFrame, texture, 0, false)
            end

            return self.texture
        end

        ---@type fun(self: Tooltip, newWidth: number):number
        function thistype:width(newWidth)
            if newWidth ~= nil then
                self.widthSize = newWidth

                if not self.simple then
                    BlzFrameClearAllPoints(self.tooltip)
                    BlzFrameSetSize(self.tooltip, newWidth, 0)
                end
            end

            return self.widthSize
        end

        ---@type fun(self: Tooltip, newPoint: framepointtype):framepointtype
        function thistype:point(newPoint)
            if newPoint ~= nil then
                self.pointType = newPoint

                if not self.simple then
                    BlzFrameClearAllPoints(self.tooltip)

                    if newPoint == FRAMEPOINT_TOPLEFT then
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_TOPRIGHT, 0.005, -0.05)
                    elseif newPoint == FRAMEPOINT_TOPRIGHT then
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_TOPLEFT, -0.005, -0.05)
                    elseif newPoint == FRAMEPOINT_BOTTOMLEFT then
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_BOTTOMRIGHT, 0.005, 0.0)
                    elseif newPoint == FRAMEPOINT_BOTTOM then
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_TOP, 0.0, 0.005)
                    elseif newPoint == FRAMEPOINT_TOP then
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_BOTTOM, 0.0, -0.05)
                    else
                        BlzFrameSetPoint(self.tooltip, newPoint, self.parent, FRAMEPOINT_BOTTOMLEFT, -0.005, 0.0)
                    end
                end
            end

            return self.pointType
        end

        ---@type fun(self: Tooltip, visibility: boolean):boolean
        function thistype:visible(visibility)
            if visibility ~= nil then
                self.isVisible = visibility
                BlzFrameSetVisible(self.box, visibility)
            end

            return self.isVisible
        end

        function thistype:destroy()
            BlzDestroyFrame(self.nameFrame)
            BlzDestroyFrame(self.iconFrame)
            BlzDestroyFrame(self.tooltip)
            BlzDestroyFrame(self.line)
            BlzDestroyFrame(self.box)
            BlzDestroyFrame(self.frame)
            self = nil
        end

        ---@type fun(owner: framehandle, width: number, point: framepointtype, simpleTooltip: boolean):Tooltip
        function thistype.create(owner, width, point, simpleTooltip)
            local self = setmetatable({}, mt)

            self.parent = owner
            self.simple = simpleTooltip
            self.widthSize = width
            self.pointType = point
            self.isVisible = true

            if simpleTooltip then
                self.frame = BlzCreateFrameByType("FRAME", "", owner, "", 0)
                self.box = BlzCreateFrame("Leaderboard", self.frame, 0, 0)
                self.tooltip = BlzCreateFrameByType("TEXT", "", self.box, "", 0)

                BlzFrameSetPoint(self.tooltip, FRAMEPOINT_BOTTOM, owner, FRAMEPOINT_TOP, 0, 0.008)
                BlzFrameSetPoint(self.box, FRAMEPOINT_TOPLEFT, self.tooltip, FRAMEPOINT_TOPLEFT, -0.008, 0.008)
                BlzFrameSetPoint(self.box, FRAMEPOINT_BOTTOMRIGHT, self.tooltip, FRAMEPOINT_BOTTOMRIGHT, 0.008, -0.008)
            else
                self.frame = BlzCreateFrame("TooltipBoxFrame", owner, 0, 0)
                self.box = BlzGetFrameByName("TooltipBox", 0)
                self.line = BlzGetFrameByName("TooltipSeperator", 0)
                self.tooltip = BlzGetFrameByName("TooltipText", 0)
                self.iconFrame = BlzGetFrameByName("TooltipIcon", 0)
                self.nameFrame = BlzGetFrameByName("TooltipName", 0)

                if point == FRAMEPOINT_TOPLEFT then
                    BlzFrameSetPoint(self.tooltip, point, owner, FRAMEPOINT_TOPRIGHT, 0.005, -0.05)
                elseif point == FRAMEPOINT_TOPRIGHT then
                    BlzFrameSetPoint(self.tooltip, point, owner, FRAMEPOINT_TOPLEFT, -0.005, -0.05)
                elseif point == FRAMEPOINT_BOTTOMLEFT then
                    BlzFrameSetPoint(self.tooltip, point, owner, FRAMEPOINT_BOTTOMRIGHT, 0.005, 0.0)
                else
                    BlzFrameSetPoint(self.tooltip, point, owner, FRAMEPOINT_BOTTOMLEFT, -0.005, 0.0)
                end

                BlzFrameSetPoint(self.box, FRAMEPOINT_TOPLEFT, self.iconFrame, FRAMEPOINT_TOPLEFT, -0.005, 0.005)
                BlzFrameSetPoint(self.box, FRAMEPOINT_BOTTOMRIGHT, self.tooltip, FRAMEPOINT_BOTTOMRIGHT, 0.005, -0.005)
                BlzFrameSetSize(self.tooltip, width, 0)
            end

            return self
        end
    end

    local doubleTime = array2d(0)

    ---@class Button
    ---@field icon function
    ---@field tooltip Tooltip
    ---@field frame framehandle
    ---@field clicked trigger
    ---@field scrolled trigger
    ---@field rightClicked trigger
    ---@field timer timer[]
    ---@field play function
    ---@field enabled function
    ---@field isEnabled boolean
    ---@field click trigger
    ---@field scroll trigger
    ---@field doubleClick trigger
    ---@field rightClick trigger
    ---@field time table
    ---@field create function
    ---@field destroy function
    ---@field onClick function
    ---@field onScroll function
    ---@field onRightClick function
    ---@field onDoubleClick function
    ---@field visible function
    ---@field available function
    ---@field tag function
    ---@field display function
    ---@field checked function
    ---@field isChecked boolean
    ---@field table Button[]
    ---@field canScroll boolean[]
    Button = {}
    do
        local thistype = Button
        local mt = { __index = Button }
        thistype.clicked         = CreateTrigger()
        thistype.scrolled         = CreateTrigger()
        thistype.rightClicked         = CreateTrigger()
        thistype.double       = CreateTimer() ---@type timer 
        thistype.timer={} ---@type timer[] 
        thistype.table={} ---@type table 
        thistype.time={} ---@type table 
        thistype.canScroll = {} ---@type boolean[] 

        thistype.click=nil  
        thistype.scroll=nil  
        thistype.doubleClick=nil  
        thistype.rightClick=nil
        thistype.iconFrame=nil ---@type framehandle 
        thistype.availableFrame=nil ---@type framehandle 
        thistype.checkedFrame=nil ---@type framehandle 
        thistype.highlightFrame=nil ---@type framehandle 
        thistype.spriteFrame=nil ---@type framehandle 
        thistype.displayFrame=nil ---@type framehandle 
        thistype.tagFrame=nil ---@type framehandle 
        thistype.parent=nil ---@type framehandle 
        thistype.isVisible=nil ---@type boolean 
        thistype.isAvailable=nil ---@type boolean 
        thistype.isChecked=nil ---@type boolean 
        thistype.isHighlighted=nil ---@type boolean 
        thistype.isEnabled=nil ---@type boolean 
        thistype.texture="" ---@type string 
        thistype.widthSize=nil ---@type number 
        thistype.heightSize=nil ---@type number 
        thistype.xPos=nil ---@type number 
        thistype.yPos=nil ---@type number 

        thistype.frame=nil ---@type framehandle 
        thistype.tooltip=nil ---@type Tooltip 

        function thistype:x(newX)
            if newX ~= nil then
                self.xPos = newX

                BlzFrameClearAllPoints(self.iconFrame)
                BlzFrameSetPoint(self.iconFrame, FRAMEPOINT_TOPLEFT, self.parent, FRAMEPOINT_TOPLEFT, self.xPos, self.yPos)
            end

            return self.xPos
        end

        function thistype:y(newY)
            if newY ~= nil then
                self.yPos = newY

                BlzFrameClearAllPoints(self.iconFrame)
                BlzFrameSetPoint(self.iconFrame, FRAMEPOINT_TOPLEFT, self.parent, FRAMEPOINT_TOPLEFT, self.xPos, self.yPos)
            end

            return self.yPos
        end

        function thistype:icon(texture)
            if texture ~= nil then
                self.texture = texture
                BlzFrameSetTexture(self.iconFrame, texture, 0, true)
            end

            return self.texture
        end

        function thistype:width(newWidth)
            if newWidth ~= nil then
                self.widthSize = newWidth

                BlzFrameClearAllPoints(self.iconFrame)
                BlzFrameSetSize(self.iconFrame, newWidth, self.heightSize)
            end

            return self.widthSize
        end

        function thistype:height(newHeight)
            if newHeight ~= nil then
                self.heightSize = newHeight

                BlzFrameClearAllPoints(self.iconFrame)
                BlzFrameSetSize(self.iconFrame, self.widthSize, newHeight)
            end

            return self.heightSize
        end

        ---@type fun(self: Button, visibility: boolean):boolean
        function thistype:visible(visibility)
            if visibility ~= nil then
                self.isVisible = visibility
                BlzFrameSetVisible(self.iconFrame, visibility)
            end

            return self.isVisible
        end

        function thistype:available(flag)
            if flag ~= nil then
                self.isAvailable = flag

                if flag then
                    BlzFrameSetVisible(self.availableFrame, false)
                else
                    BlzFrameSetVisible(self.availableFrame, true)
                    BlzFrameSetTexture(self.availableFrame, UNAVAILABLE_BUTTON, 0, true)
                end
            end

            return self.isAvailable
        end

        function thistype:checked(flag)
            if flag ~= nil then
                self.isChecked = flag

                if flag then
                    BlzFrameSetVisible(self.checkedFrame, true)
                    BlzFrameSetTexture(self.checkedFrame, CHECKED_BUTTON, 0, true)
                    BlzFrameSetVisible(self.availableFrame, false)
                else
                    BlzFrameSetVisible(self.checkedFrame, false)
                end
            end

            return self.isChecked
        end

        function thistype:highlighted(flag)
            if flag ~= nil then
                self.isHighlighted = flag

                if flag then
                    BlzFrameSetVisible(self.highlightFrame, true)
                    BlzFrameSetTexture(self.highlightFrame, HIGHLIGHT, 0, true)
                else
                    BlzFrameSetVisible(self.highlightFrame, false)
                end
            end

            return self.isHighlighted
        end

        function thistype:enabled(flag)
            if flag ~= nil then
                local t = self.texture ---@type string 

                self.isEnabled = flag

                if flag == false then
                    t = (t:sub(1, 34) .. "Disabled\\DIS" .. t:sub(36, t:len()))
                end

                BlzFrameSetTexture(self.iconFrame, t, 0, true)
            end

            return self.isEnabled
        end

        function thistype:onClick(c)
            DestroyTrigger(self.click)
            self.click = nil

            if c ~= nil then
                self.click = CreateTrigger()
                TriggerAddCondition(self.click, Condition(c))
            end
        end

        function thistype:onScroll(c)
            DestroyTrigger(self.scroll)
            self.scroll = nil

            if c ~= nil then
                self.scroll = CreateTrigger()
                TriggerAddCondition(self.scroll, Condition(c))
            end
        end

        function thistype:onDoubleClick(c)
            DestroyTrigger(self.doubleClick)
            self.doubleClick = nil

            if c ~= nil then
                self.doubleClick = CreateTrigger()
                TriggerAddCondition(self.doubleClick, Condition(c))
            end
        end

        function thistype:onRightClick(c)
            DestroyTrigger(self.rightClick)
            self.rightClick = nil

            if c ~= nil then
                self.rightClick = CreateTrigger()
                TriggerAddCondition(self.rightClick, Condition(c))
            end
        end

        function thistype:destroy()
            thistype.table[(self.frame)] = nil
            DestroyTrigger(self.click)
            DestroyTrigger(self.scroll)
            DestroyTrigger(self.doubleClick)
            DestroyTrigger(self.rightClick)
            BlzDestroyFrame(self.displayFrame)
            BlzDestroyFrame(self.spriteFrame)
            BlzDestroyFrame(self.tagFrame)
            BlzDestroyFrame(self.frame)
            BlzDestroyFrame(self.iconFrame)
            BlzDestroyFrame(self.availableFrame)
            BlzDestroyFrame(self.checkedFrame)
            self.tooltip:destroy()
            self = nil
        end

        ---@param model string
        ---@param scale number
        ---@param animation integer
        function thistype:play(model, scale, animation)
            if model ~= "" and model ~= nil then
                BlzFrameClearAllPoints(self.spriteFrame)
                BlzFrameSetPoint(self.spriteFrame, FRAMEPOINT_CENTER, self.frame, FRAMEPOINT_CENTER, 0, 0)
                BlzFrameSetSize(self.spriteFrame, self.widthSize, self.heightSize)
                BlzFrameSetModel(self.spriteFrame, model, 0)
                BlzFrameSetScale(self.spriteFrame, scale)
                BlzFrameSetSpriteAnimate(self.spriteFrame, animation, 0)
            end
        end

        ---@type fun(self: Button, model: string, width: number, height: number, scale: number, point: framepointtype, relativePoint: framepointtype, offsetX: number, offsetY: number)
        function thistype:display(model, width, height, scale, point, relativePoint, offsetX, offsetY)
            if model ~= "" and model ~= nil then
                BlzFrameClearAllPoints(self.displayFrame)
                BlzFrameSetPoint(self.displayFrame, point, self.frame, relativePoint, offsetX, offsetY)
                BlzFrameSetSize(self.displayFrame, width, height)
                BlzFrameSetScale(self.displayFrame, scale)
                BlzFrameSetModel(self.displayFrame, model, 0)
                BlzFrameSetVisible(self.displayFrame, true)
            else
                BlzFrameSetVisible(self.displayFrame, false)
            end
        end

        ---@param model string
        ---@param width number
        ---@param height number
        ---@param scale number
        ---@param point framepointtype
        ---@param relativePoint framepointtype
        ---@param offsetX number
        ---@param offsetY number
        function thistype:tag(model, width, height, scale, point, relativePoint, offsetX, offsetY)
            if model ~= "" and model ~= nil then
                BlzFrameClearAllPoints(tagFrame)
                BlzFrameSetPoint(tagFrame, point, frame, relativePoint, offsetX, offsetY)
                BlzFrameSetSize(tagFrame, width, height)
                BlzFrameSetScale(tagFrame, scale)
                BlzFrameSetModel(tagFrame, model, 0)
                BlzFrameSetVisible(tagFrame, true)
            else
                BlzFrameSetVisible(tagFrame, false)
            end
        end

        ---@type fun(owner: framehandle, width: number, height: number, x: number, y: number, simpleTooltip: boolean): Button
        function thistype.create(owner, width, height, x, y, simpleTooltip)
            local self = setmetatable({}, mt)

            self.parent = owner
            self.xPos = x
            self.yPos = y
            self.widthSize = width
            self.heightSize = height
            self.isVisible = true
            self.isAvailable = true
            self.isChecked = false
            self.isHighlighted = false
            self.iconFrame = BlzCreateFrameByType("BACKDROP", "", owner, "", 0)
            self.availableFrame = BlzCreateFrameByType("BACKDROP", "", self.iconFrame, "", 0)
            self.checkedFrame = BlzCreateFrameByType("BACKDROP", "", self.iconFrame, "", 0)
            self.highlightFrame = BlzCreateFrame("HighlightFrame", self.iconFrame, 0, 0)
            self.frame = BlzCreateFrame("IconButtonTemplate", self.iconFrame, 0, 0)
            self.displayFrame = BlzCreateFrameByType("SPRITE", "", self.frame, "WarCraftIIILogo", 0)
            self.tagFrame = BlzCreateFrameByType("SPRITE", "", self.frame, "WarCraftIIILogo", 0)
            self.spriteFrame = BlzCreateFrameByType("SPRITE", "", self.frame, "", 0)
            self.tooltip = Tooltip.create(self.frame, TOOLTIP_SIZE, FRAMEPOINT_TOPLEFT, simpleTooltip)
            thistype.table[(self.frame)] = self

            BlzFrameSetPoint(self.iconFrame, FRAMEPOINT_TOPLEFT, owner, FRAMEPOINT_TOPLEFT, x, y)
            BlzFrameSetSize(self.iconFrame, width, height)
            BlzFrameSetAllPoints(self.frame, self.iconFrame)
            BlzFrameSetTooltip(self.frame, self.tooltip.frame)
            BlzFrameSetAllPoints(self.availableFrame, self.iconFrame)
            BlzFrameSetVisible(self.availableFrame, false)
            BlzFrameSetAllPoints(self.checkedFrame, self.iconFrame)
            BlzFrameSetVisible(self.checkedFrame, false)
            BlzFrameSetPoint(self.highlightFrame, FRAMEPOINT_TOPLEFT, self.iconFrame, FRAMEPOINT_TOPLEFT, - 0.0040000, 0.0045000)
            BlzFrameSetSize(self.highlightFrame, width + 0.0085, height + 0.0085)
            BlzFrameSetVisible(self.highlightFrame, false)
            BlzTriggerRegisterFrameEvent(self.clicked, self.frame, FRAMEEVENT_CONTROL_CLICK)
            BlzTriggerRegisterFrameEvent(self.scrolled, self.frame, FRAMEEVENT_MOUSE_WHEEL)
            BlzTriggerRegisterFrameEvent(self.rightClicked, self.frame, FRAMEEVENT_MOUSE_UP)

            return self
        end

        function thistype.onExpire()
            thistype.canScroll[GetPlayerId(GetLocalPlayer())] = true
        end

        function thistype.onScrolled()
            local self = thistype.table[(BlzGetTriggerFrame())] ---@type Button
            local i = GetPlayerId(GetLocalPlayer()) ---@type integer 

            if self then
                if thistype.canScroll[i] and self.scroll ~= nil then
                    if SCROLL_DELAY > 0 then
                        thistype.canScroll[i] = false
                    end

                    TriggerEvaluate(self.scroll)
                end
            end

            if SCROLL_DELAY > 0 then
                TimerStart(thistype.timer[i], TimerGetRemaining(thistype.timer[i]), false, thistype.onExpire)
            end
        end

        function thistype.onRightClicked()
            local self = thistype.table[(BlzGetTriggerFrame())] ---@type Button

            if self then
                if BlzGetTriggerPlayerMouseButton() == MOUSE_BUTTON_TYPE_RIGHT and self.rightClick ~= nil then
                    TriggerEvaluate(self.rightClick)
                end
            end
        end

        function thistype.onClicked()
            local i = GetPlayerId(GetTriggerPlayer()) ---@type integer 
            local j = (BlzGetTriggerFrame()) ---@type integer 
            local self = thistype.table[j] ---@type Button

            if self then
                if not self.time[i] then
                    self.time[i] = {}
                end
                self.time[i][j] = TimerGetElapsed(thistype.double)

                if self.click ~= nil then
                    TriggerEvaluate(self.click)
                end

                if self.time[i][j] - doubleTime[i][j] <= DOUBLE_CLICK_DELAY then
                    doubleTime[i][j] = 0

                    if self.doubleClick ~= nil then
                        TriggerEvaluate(self.doubleClick)
                    end
                else
                    doubleTime[i][j] = self.time[i][j]
                end
            end
        end

        for i = 0, PLAYER_CAP - 1 do
            Button.timer[i] = CreateTimer()
            Button.canScroll[i] = true
        end

        TimerStart(thistype.double, 10000000., false, nil)
        TriggerAddAction(thistype.clicked, thistype.onClicked)
        TriggerAddAction(thistype.scrolled, thistype.onScrolled)
        TriggerAddAction(thistype.rightClicked, thistype.onRightClicked)
    end

end, Debug and Debug.getLine())
