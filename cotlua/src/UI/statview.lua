--[[
    statview.lua

    This module defines the stat window for detailed information on heroes / units
]]

OnInit.final("StatView", function()
    STAT_WINDOW = {}

    do
        local frame = BlzCreateFrame("ListBoxWar3", BlzGetFrameByName("ConsoleUIBackdrop", 0), 0, 0)
        local title = BlzCreateFrame("TitleText", frame, 0, 0)
        local text = BlzCreateFrameByType("TEXT", "", frame, "", 0)
        local number = BlzCreateFrameByType("TEXT", "", frame, "", 0)
        local viewing = {}

        STAT_WINDOW.frame = frame
        BlzFrameSetAbsPoint(frame, FRAMEPOINT_TOPLEFT, -0.05, 0.55)
        BlzFrameSetSize(frame, 0.3, 0.375)
        BlzFrameSetEnable(frame, false)

        BlzFrameSetPoint(title, FRAMEPOINT_TOP, frame, FRAMEPOINT_TOP, 0., -0.013)
        BlzFrameSetEnable(title, false)

        BlzFrameSetPoint(number, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.113, -0.04)
        BlzFrameSetTextAlignment(number, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
        BlzFrameSetScale(number, 1.)
        BlzFrameSetEnable(number, false)

        BlzFrameSetPoint(text, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.015, -0.04)
        BlzFrameSetTextAlignment(text, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
        BlzFrameSetScale(text, 1.)
        BlzFrameSetEnable(text, false)

        local function RefreshStatWindowOnStatChange()
            local U = User.first

            while U do
                --if a player is viewing the stat window of a unit, refresh it
                if viewing[U.id] then
                    RefreshStatWindow(U.id)
                end

                U = U.next
            end
        end

        local close = function(pid)
            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetVisible(frame, false)
            end

            --no longer viewing stat window
            if viewing[pid] then
                EVENT_STAT_CHANGE:unregister_unit_action(viewing[pid], RefreshStatWindowOnStatChange)
                viewing[pid] = nil
            end
        end
        STAT_WINDOW.close = close

        local onClose = function()
            local f = BlzGetTriggerFrame()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if GetLocalPlayer() == Player(pid - 1) then
                BlzFrameSetEnable(f, false)
                BlzFrameSetEnable(f, true)
            end

            close(pid)

            return false
        end

        FrameAddButton(frame, "ReplaceableTextures\\CommandButtons\\BTNCancel.blp", 0.015, 0.015, FRAMEPOINT_TOPRIGHT, FRAMEPOINT_TOPRIGHT, -0.02, -0.02, onClose, "Close 'ESC'", FRAMEPOINT_BOTTOM, FRAMEPOINT_TOP, 0., 0.01)
        BlzFrameSetVisible(frame, false)

        function RefreshStatWindow(pid)
            local u = viewing[pid]
            local tpid = GetPlayerId(GetOwningPlayer(u)) + 1
            local stat_number = ""
            local stat_tag = ""
            local name = (u == Hero[tpid] and User[tpid - 1].nameColored) or GetUnitName(u)
            local ishero = (u == Hero[tpid] and 3) or 2

            -- fill out stats
            for type = 1, ishero do
                for i = 1, #STAT_TAG do
                    local v = STAT_TAG[i]

                    if v.type == type then
                        local num = v.getter(u)
                        stat_number = stat_number .. num .. (v.suffix or "") .. "|n"
                        stat_tag = stat_tag .. (v.alternate or v.tag) .. "|n"

                        if v.breakdown then
                            if not v.breakdown_frame then
                                v.breakdown_backdrop = BlzCreateFrameByType("BACKDROP", "", number, "", 0)
                                v.breakdown_frame = BlzCreateFrameByType("FRAME", "", number, "", 0)
                                BlzFrameSetTexture(v.breakdown_backdrop, "war3mapImported\\question.blp", 0, true)
                                BlzFrameSetScale(v.breakdown_backdrop, 0.6)
                                BlzFrameSetSize(v.breakdown_backdrop, 0.016, 0.016)
                                BlzFrameSetAllPoints(v.breakdown_frame, v.breakdown_backdrop)
                                v.breakdown_tooltip = FrameAddSimpleTooltip(v.breakdown_frame, "", "", true, FRAMEPOINT_BOTTOMLEFT, FRAMEPOINT_TOPRIGHT, 0., 0.008, 0.01)
                            end

                            if GetLocalPlayer() == Player(pid - 1) then
                                BlzFrameSetText(v.breakdown_tooltip.tooltip, v.breakdown(u))
                                BlzFrameSetPoint(v.breakdown_backdrop, FRAMEPOINT_TOPLEFT, number, FRAMEPOINT_TOPLEFT, num:len() * 0.012, -i * 0.014)
                            end
                        end
                    end
                end
            end

            if GetLocalPlayer() == Player(pid - 1) then
                --set text and size
                BlzFrameSetText(title, name)
                BlzFrameSetText(number, stat_number)
                BlzFrameSetText(text, stat_tag)
            end
        end

        function DisplayStatWindow(u, pid)
            if u and not BlzGetUnitBooleanField(u, UNIT_BF_IS_A_BUILDING) then
                close(pid)
                viewing[pid] = u
                EVENT_STAT_CHANGE:register_unit_action(u, RefreshStatWindowOnStatChange)
                RefreshStatWindow(pid)

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(frame, true)
                end
            end
        end
    end
end, Debug and Debug.getLine())
