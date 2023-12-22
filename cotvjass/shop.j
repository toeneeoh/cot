library Shop requires Table, RegisterPlayerUnitEvent, Components, Ascii, Functions
    /* --------------------------------------- Shop v1.0 --------------------------------------- */
    // Credits:
    //      Taysen: FDF file and A2S function
    //      Bribe: Table library
    //      Magtheridon: RegisterPlayerUnitEvent library
    //      Hate: Frame border effects
    /* -------------------------------------- By Chopinski ------------------------------------- */

    /* ----------------------------------------------------------------------------------------- */
    /*                                       Configuration                                       */
    /* ----------------------------------------------------------------------------------------- */
    globals
        // Main window 
        private constant real X                         = -0.04
        private constant real Y                         = 0.52
        private constant real WIDTH                     = 0.6
        private constant real HEIGHT                    = 0.35
        private constant real TOOLBAR_BUTTON_SIZE       = 0.02
        private constant integer ROWS                   = 4
        private constant integer COLUMNS                = 10
        private constant integer DETAILED_ROWS          = 4
        private constant integer DETAILED_COLUMNS       = 5
        private constant string CLOSE_ICON              = "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"
        private constant string CLEAR_ICON              = "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"
        private constant string HELP_ICON               = "UI\\Widgets\\EscMenu\\Human\\quest-unknown.blp"
        private constant string LOGIC_ICON              = "ReplaceableTextures\\CommandButtons\\BTNMagicalSentry.blp"
        private constant string UNDO_ICON               = "ReplaceableTextures\\CommandButtons\\BTNReplay-Loop.blp"
        private constant string DISMANTLE_ICON          = "UI\\Feedback\\Resources\\ResourceUpkeep.blp"

        // Buyer Panel - Nope
        private constant real BUYER_WIDTH               = 0.234
        private constant real BUYER_HEIGHT              = 0.0398 * 4
        private constant real BUYER_SIZE                = 0.
        private constant real BUYER_GAP                 = 0.
        private constant real BUYER_SHIFT_BUTTON_SIZE   = 0.
        private constant integer BUYER_COUNT            = 0
        private constant string BUYER_RIGHT             = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedDown.blp"
        private constant string BUYER_LEFT              = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedUp.blp"

        // Inventory Panel
        private constant real INVENTORY_WIDTH           = 0.1981
        private constant real INVENTORY_HEIGHT          = 0.0312 * 4
        private constant real INVENTORY_SIZE            = 0.0266
        private constant real INVENTORY_GAPX            = 0.0333
        private constant real INVENTORY_GAPY            = 0.03042
        private constant integer INVENTORY_COUNT        = 24
        private constant string INVENTORY_TEXTURE       = "inventory2.blp"
        
        // Details window
        private constant real DETAIL_WIDTH              = 0.3125
        private constant real DETAIL_HEIGHT             = HEIGHT
        private constant integer DETAIL_USED_COUNT      = 6
        private constant real DETAIL_BUTTON_SIZE        = 0.028
        private constant real DETAIL_BUTTON_GAP         = 0.045
        private constant real DETAIL_CLOSE_BUTTON_SIZE  = 0.02
        private constant real DETAIL_SHIFT_BUTTON_SIZE  = 0.012
        private constant string USED_RIGHT              = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedDown.blp"
        private constant string USED_LEFT               = "ReplaceableTextures\\CommandButtons\\BTNReplay-SpeedUp.blp"
        
        // When true, a click in a component in the
        // detail panel will detail the clicked component
        private constant boolean DETAIL_COMPONENT       = true

        // Side Panels
        private constant real SIDE_WIDTH                = 0.075
        private constant real SIDE_HEIGHT               = HEIGHT
        private constant real EDIT_WIDTH                = 0.15
        private constant real EDIT_HEIGHT               = 0.0285

        // Category and Favorite buttons
        private constant integer CATEGORY_COUNT         = 15
        private constant real CATEGORY_SIZE             = 0.0255
        private constant real CATEGORY_GAP              = 0.00225

        // Favorite key 
        // LSHIT, LCONTROL are buggy on KeyDown event, 
        // complain to blizzard, not me
        private constant oskeytype FAVORITE_KEY         = OSKEY_TAB

        // Item slots
        private constant real SLOT_WIDTH                = 0.0375
        private constant real SLOT_HEIGHT               = 0.0375
        private constant real ITEM_SIZE                 = 0.0375
        private constant real GOLD_SIZE                 = 0.008
        private constant real COST_WIDTH                = 0.06
        private constant real COST_HEIGHT               = 0.005
        private constant real COST_SCALE                = 0.7
        private constant real COST_GAP                  = 0.0135
        private constant real COSTICON_GAP              = 0.009
        private constant real SLOT_GAP_X                = 0.015
        private constant real SLOT_GAP_Y                = 0.038
        private constant real COMPONENT_GAP             = SLOT_WIDTH * 0.61

        // Selected item highlight
        private constant string ITEM_HIGHLIGHT          = "blue_energy_sprite.mdx"
        private constant real HIGHLIGHT_WIDTH           = 0.00001
        private constant real HIGHLIGHT_HEIGHT          = 0.00001
        private constant real HIGHLIGHT_SCALE           = 0.675
        private constant real HIGHLIGHT_XOFFSET         = -0.0052
        private constant real HIGHLIGHT_YOFFSET         = -0.0048

        // Tagged item highlight
        private constant string TAG_HIGHLIGHT          = "blue_energy_sprite.mdx"
        private constant real TAG_HIGHLIGHT_WIDTH      = 0.00001
        private constant real TAG_HIGHLIGHT_HEIGHT     = 0.00001
        private constant real TAG_HIGHLIGHT_SCALE      = 0.675
        private constant real TAG_HIGHLIGHT_XOFFSET    = -0.0052
        private constant real TAG_HIGHLIGHT_YOFFSET    = -0.0048

        // Scroll
        private constant real SCROLL_DELAY              = 0.01

        // Update time
        private constant real UPDATE_PERIOD             = 0.2

        // Buy / Sell sound, model and scale
        private constant string SPRITE_MODEL            = "UI\\Feedback\\GoldCredit\\GoldCredit.mdl"
        private constant real SPRITE_SCALE              = 0.0005
        private constant string SUCCESS_SOUND           = "Abilities\\Spells\\Other\\Transmute\\AlchemistTransmuteDeath1.wav"
        private constant string ERROR_SOUND             = "Sound\\Interface\\Error.wav"

        // Dont touch
        private HashTable table
    endglobals 

    /* ----------------------------------------------------------------------------------------- */
    /*                                          JASS API                                         */
    /* ----------------------------------------------------------------------------------------- */
    function IsBuyable takes integer id returns boolean
        local integer i = 0
        local boolean buyable = false

        loop
            exitwhen i == CURRENCY_COUNT

            if ItemPrices[id][i] > 0 then
                set buyable = true
            endif

            set i = i + 1
        endloop

        return buyable
    endfunction

    function CreateShop takes integer id, real aoe, real returnRate returns Shop
        return Shop.create(id, aoe, returnRate)
    endfunction

    function ShopSetStock takes integer id, integer itm, integer num returns nothing
        call Shop.setStock(id, itm, num)
    endfunction
    
    function ShopAddCategory takes integer id, string icon, string description returns integer
        return Shop.addCategory(id, icon, description)
    endfunction

    function ShopAddItem takes integer id, integer itemId, integer categories returns nothing
        call Shop.addItem(id, itemId, categories)
    endfunction

    function ItemAddComponents takes integer whichItem, string compstring returns nothing
        call ShopItem.addComponents(whichItem, compstring)
    endfunction

    function UnitHasItemOfType takes unit u, integer id returns boolean
        return ShopItem.hasType(u, id)
    endfunction

    function UnitCountItemOfType takes unit u, integer id returns integer
        return ShopItem.countType(u, id)
    endfunction

    /* ----------------------------------------------------------------------------------------- */
    /*                                           System                                          */
    /* ----------------------------------------------------------------------------------------- */
    struct ShopItem
        //private static unit shop
        //private static rect rect
        private static trigger trigger = CreateTrigger()
        private static player player = Player(bj_PLAYER_NEUTRAL_EXTRA)
        readonly static Table itempool
        readonly static HashTable unit

        private integer componentCount
        integer array currency[CURRENCY_COUNT]

        string name
        string icon
        string tooltip
        integer id
        integer recharge
        integer charges
        integer categories
        Table component
        Table counter
        Table relation
        
        method destroy takes nothing returns nothing
            call component.destroy()
            call relation.destroy()
            call counter.destroy()
            call deallocate()
        endmethod

        method operator components takes nothing returns integer
            return componentCount
        endmethod

        method count takes integer id returns integer
            return counter[id]
        endmethod

        static method get takes integer id returns thistype
            return itempool[id]
        endmethod

        private static method save takes integer id, integer comp returns nothing
            local thistype this
            local thistype part
            local integer i = 0

            if comp > 0 and comp != id then
                set this = create(id, 0)
                set part = create(comp, 0)
                set component[componentCount] = comp
                set componentCount = componentCount + 1
                set counter[comp] = counter[comp] + 1

                loop
                    exitwhen part.relation[i] == id
                        if not part.relation.has(i) then
                            set part.relation[i] = id
                            exitwhen true
                        endif
                    set i = i + 1
                endloop
            endif
        endmethod

        static method addComponents takes integer id, string compstring returns nothing
            local thistype this
            local integer i = 0
            local integer i2 = 1
            local integer start = 0
            local integer end = 0
            local string tag = ""

            if id > 0 then
                set this = create(id, 0)
                set componentCount = 0

                call component.flush()
                call counter.flush()
    
                loop
                    exitwhen i2 > StringLength(compstring) + 1
                    if SubString(compstring, i, i2) == " " or i2 > StringLength(compstring) then
                        set end = i
                        set tag = SubString(compstring, start, end)
                        if String2Id(tag) != 0 then
                            call save(id, String2Id(tag))
                        endif
                        set start = i2
                    endif
                
                    set i = i + 1
                    set i2 = i2 + 1
                endloop
            endif
        endmethod

        private static method clear takes nothing returns nothing
            call RemoveItem(GetEnumItem())
        endmethod

        static method hasType takes unit u, integer id returns boolean
            return unit[GetHandleId(u)][id] > 0
        endmethod

        static method countType takes unit u, integer id returns integer
            return unit[GetHandleId(u)][id]
        endmethod

        static method create takes integer id, integer category returns thistype
            local thistype this
            local Item i
            local integer j = 0

            if itempool.has(id) then
                set this = itempool[id]

                if category > 0 then
                    set categories = category
                endif

                return this
            else
                set i = Item.create(id, 30000., 30000., 0.)

                if i != 0 then
                    set this = thistype.allocate()
                    set .id = id
                    set categories = category
                    set name = GetItemName(i.obj)
                    set icon = BlzGetItemIconPath(i.obj)
                    set tooltip = i.alt_tooltip
                    set charges = GetItemCharges(i.obj)
                    set recharge = -1

                    if charges == 0 then
                        set charges = 1
                    endif

                    loop
                        exitwhen j == CURRENCY_COUNT

                        set currency[j] = ItemPrices[id][j]

                        set j = j + 1
                    endloop

                    set componentCount = 0
                    set component = Table.create()
                    set counter = Table.create()
                    set relation = Table.create()
                    set itempool[id] = this

                    call i.destroy()

                    return this
                else
                    return 0
                endif
            endif
        endmethod

        private static method onPickup takes nothing returns nothing
            local integer u = GetHandleId(GetManipulatingUnit())
            local integer i = GetItemTypeId(GetManipulatedItem())

            set unit[u][i] = unit[u][i] + 1
        endmethod

        private static method onDrop takes nothing returns nothing
            local integer u = GetHandleId(GetManipulatingUnit())
            local integer i = GetItemTypeId(GetManipulatedItem())

            set unit[u][i] = unit[u][i] - 1
        endmethod

        private static method onInit takes nothing returns nothing
            //set rect = Rect(0, 0, 0, 0)
            set itempool = Table.create()
            set unit = HashTable.create()
            //set shop = CreateUnit(player, 'nmrk', 0, 0, 0)

            //call SetRect(rect, GetUnitX(shop) - 1000, GetUnitY(shop) - 1000, GetUnitX(shop) + 1000, GetUnitY(shop) + 1000)
            //call UnitAddAbility(shop, 'AInv')
            //call IssueNeutralTargetOrder(player, shop, "smart", shop)
            //call ShowUnit(shop, false)
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickup)
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function thistype.onDrop)
        endmethod
    endstruct

    private struct Slot
        private boolean isVisible
        private real xPos
        private real yPos

        readonly framehandle parent
        readonly framehandle slot
        readonly framehandle array costicon[CURRENCY_COUNT]
        readonly framehandle array cost[CURRENCY_COUNT]

        ShopItem item
        Button button

        method operator x= takes real newX returns nothing
            set xPos = newX

            call BlzFrameClearAllPoints(slot)
            call BlzFrameSetPoint(slot, FRAMEPOINT_TOPLEFT, parent, FRAMEPOINT_TOPLEFT, xPos, yPos)
        endmethod

        method operator x takes nothing returns real
            return xPos
        endmethod

        method operator y= takes real newY returns nothing
            set yPos = newY

            call BlzFrameClearAllPoints(slot)
            call BlzFrameSetPoint(slot, FRAMEPOINT_TOPLEFT, parent, FRAMEPOINT_TOPLEFT, xPos, yPos)
        endmethod

        method operator y takes nothing returns real
            return yPos
        endmethod

        method operator visible= takes boolean visibility returns nothing
            set isVisible = visibility
            call BlzFrameSetVisible(slot, visibility)
        endmethod

        method operator visible takes nothing returns boolean
            return isVisible
        endmethod

        method operator onClick= takes code c returns nothing
            set button.onClick = c
        endmethod

        method operator onScroll= takes code c returns nothing
            set button.onScroll = c
        endmethod

        method operator onRightClick= takes code c returns nothing
            set button.onRightClick = c
        endmethod

        method operator onDoubleClick= takes code c returns nothing
            set button.onDoubleClick = c
        endmethod

        method destroy takes nothing returns nothing
            local integer i = 0

            call BlzDestroyFrame(slot)

            call button.destroy()

            loop
                exitwhen i == CURRENCY_COUNT
                call BlzDestroyFrame(cost[i])
                call BlzDestroyFrame(costicon[i])
                set costicon[i] = null
                set cost[i] = null

                set i = i + 1
            endloop

            call deallocate()

            set slot = null
            set parent = null
        endmethod

        static method create takes framehandle parent, ShopItem i, real width, real height, real x, real y, framepointtype point, boolean simpleTooltip returns thistype
            local thistype this = thistype.allocate()
            local integer j = 0
            local integer k = 0

            set item = i
            set xPos = x
            set yPos = y
            set .parent = parent
            set slot = BlzCreateFrameByType("FRAME", "", parent, "", 0)
            set button = Button.create(slot, width, height, 0, 0, simpleTooltip)
            set button.tooltip.point = point
            
            call BlzFrameSetPoint(slot, FRAMEPOINT_TOPLEFT, parent, FRAMEPOINT_TOPLEFT, x, y)
            call BlzFrameSetSize(slot, width, height)

            if item != 0 then
                set button.icon = item.icon
                set button.tooltip.text = item.tooltip
                set button.tooltip.name = item.name
                set button.tooltip.icon = item.icon
            endif

            return this
        endmethod
    endstruct

    struct ShopSlot extends Slot
        Shop shop
        Slot next
        Slot prev
        Slot right
        Slot left
        integer row
        integer column

        method refresh takes ShopItem itm returns nothing
            local integer i = 0

            loop
                exitwhen i == CURRENCY_COUNT
                    if itm.currency[i] > 0 then
                        if shop.stock[itm.id] == 0 then
                            call BlzFrameSetVisible(costicon[i], false)
                            if i == 0 then
                                call BlzFrameSetVisible(cost[i], true)
                                call BlzFrameSetText(cost[i], "|cff999999SOLD OUT|r")
                            else
                                call BlzFrameSetVisible(cost[i], false)
                            endif
                        else
                            call BlzFrameSetVisible(cost[i], true)
                            call BlzFrameSetVisible(costicon[i], true)
                            call BlzFrameSetText(cost[i], "|cffffcc00    " + I2S(itm.currency[i]) + "|r")
                        endif
                    endif
                set i = i + 1
            endloop
        endmethod

        method destroy takes nothing returns nothing
            call table.remove(GetHandleId(button.frame))

            call deallocate()
        endmethod

        method move takes integer row, integer column returns nothing
            set .row = row
            set .column = column
            set x = 0.030000 + ((SLOT_WIDTH + SLOT_GAP_X) * column)
            set y = - (0.030000 + ((SLOT_HEIGHT + SLOT_GAP_Y) * row))

            call update()
        endmethod

        method update takes nothing returns nothing
            if column <= (shop.columns / 2) and row < 3 then
                set button.tooltip.point = FRAMEPOINT_TOPLEFT
            elseif column >= ((shop.columns / 2) + 1) and row < 3 then
                set button.tooltip.point = FRAMEPOINT_TOPRIGHT
            elseif column <= (shop.columns / 2) and row >= 3 then
                set button.tooltip.point = FRAMEPOINT_BOTTOMLEFT
            else
                set button.tooltip.point = FRAMEPOINT_BOTTOMRIGHT
            endif
        endmethod

        static method create takes Shop shop, ShopItem i, integer row, integer column returns thistype
            local thistype this = thistype.allocate(shop.main, i, ITEM_SIZE, ITEM_SIZE, 0.030000 + ((SLOT_WIDTH + SLOT_GAP_X) * column), - (0.030000 + ((SLOT_HEIGHT + SLOT_GAP_Y) * row)), FRAMEPOINT_TOPLEFT, false)
            local integer j = 0
            local integer k = 0

            set .shop = shop
            set next = 0
            set prev = 0
            set right = 0
            set left = 0
            set .row = row
            set .column = column
            set onClick = function thistype.onClicked
            set onScroll = function thistype.onScrolled
            set onDoubleClick = function thistype.onDoubleClicked
            set onRightClick = function thistype.onRightClicked
            set table[GetHandleId(button.frame)][0] = this

            //currencies
            loop
                exitwhen k == CURRENCY_COUNT

                set costicon[k] = BlzCreateFrameByType("BACKDROP", "", slot, "", 0)
                set cost[k] = BlzCreateFrameByType("TEXT", "", slot, "", 0)
                call BlzFrameSetPoint(costicon[k], FRAMEPOINT_TOPLEFT, slot, FRAMEPOINT_TOPLEFT, 0., - 0.04 - j * COSTICON_GAP)
                call BlzFrameSetSize(costicon[k], GOLD_SIZE, GOLD_SIZE)
                call BlzFrameSetTexture(costicon[k], CURRENCY_ICON[k], 0, true)
                //call BlzFrameSetEnable(costicon[k], false)

                call BlzFrameSetPoint(cost[k], FRAMEPOINT_TOPLEFT, slot, FRAMEPOINT_TOPLEFT, 0., - 0.06 - j * COST_GAP)
                call BlzFrameSetSize(cost[k], COST_WIDTH, COST_HEIGHT)
                //call BlzFrameSetEnable(cost[k], false)
                call BlzFrameSetScale(cost[k], COST_SCALE)
                call BlzFrameSetTextAlignment(cost[k], TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)

                if item.currency[k] > 0 then
                    call BlzFrameSetVisible(costicon[k], true)
                    call BlzFrameSetVisible(cost[k], true)

                    call BlzFrameSetText(cost[k], "|cffFFCC00    " + I2S(item.currency[k]) + "|r")

                    set j = j + 1
                else
                    call BlzFrameSetVisible(costicon[k], false)
                    call BlzFrameSetVisible(cost[k], false)
                endif

                set k = k + 1
            endloop

            //sold out
            if not IsBuyable(item.id) then
                call BlzFrameSetVisible(costicon[0], false)
                call BlzFrameSetVisible(cost[0], true)
                call BlzFrameSetText(cost[0], "|cff999999SOLD OUT|r")
            endif

            call update()

            return this
        endmethod

        static method onScrolled takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                if GetLocalPlayer() == GetTriggerPlayer() then
                    call shop.scroll(BlzGetTriggerFrameValue() < 0)
                endif
            endif
        endmethod

        static method onClicked takes nothing returns nothing
            local player p = GetTriggerPlayer()
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer id = GetPlayerId(p)

            if this != 0 then
                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)

                if Shop.tag[id] then
                    call shop.favorites.add(item, p)
                else
                    call shop.detail(item, p)

                    // if GetLocalPlayer() == p then
                    //     if shop.lastClicked[id] != 0 then
                    //         call Button(shop.lastClicked[id]).display(null, 0, 0, 0, null, null, 0, 0)
                    //     endif
        
                    //     call button.display(ITEM_HIGHLIGHT, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_SCALE, FRAMEPOINT_BOTTOMLEFT, FRAMEPOINT_BOTTOMLEFT, HIGHLIGHT_XOFFSET, HIGHLIGHT_YOFFSET)
                    //     set shop.lastClicked[id] = button
                    // endif
                endif
            endif

            set p = null
            set frame = null
        endmethod

        static method onDoubleClicked takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                if shop.buy(item, GetTriggerPlayer()) then
                    if GetLocalPlayer() == GetTriggerPlayer() then
                        call button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                    endif
                endif
            endif
        endmethod

        static method onRightClicked takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                if shop.buy(item, GetTriggerPlayer()) then
                    if GetLocalPlayer() == GetTriggerPlayer() then
                        call button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                    endif
                endif
            endif
        endmethod
    endstruct

    private struct Detail
        readonly static trigger trigger = CreateTrigger()

        private boolean isVisible

        Shop shop
        Table item
        Table main
        HashTable components
        Table count
        HashTable used
        HashTable button
        Button close
        Button left
        Button right
        framehandle frame
        framehandle tooltip
        framehandle topSeparator
        framehandle bottomSeparator
        framehandle usedIn
        framehandle scrollFrame
        framehandle horizontalRight
        framehandle horizontalLeft
        framehandle verticalMain
        framehandle verticalCenter
        framehandle verticalLeft1
        framehandle verticalLeft2
        framehandle verticalRight1
        framehandle verticalRight2

        method operator visible= takes boolean visibility returns nothing
            set isVisible = visibility
            call BlzFrameSetVisible(frame, visibility)
        endmethod

        method operator visible takes nothing returns boolean
            return isVisible
        endmethod

        method destroy takes nothing returns nothing
            local User u = User.first
            local integer i = 0

            loop
                exitwhen u == User.NULL
                    call table.remove(GetHandleId(Slot(main[u.id - 1]).button.frame))
                    call Slot(main[u.id - 1]).destroy()

                    set i = 0
                    loop
                        exitwhen i == INVENTORY_COUNT
                        call table.remove(GetHandleId(Slot(components[u.id - 1][i]).button.frame))
                        call Slot(components[u.id - 1][i]).destroy()

                        if i < DETAIL_USED_COUNT then
                            call table.remove(GetHandleId(Button(button[u.id - 1][i]).frame))
                            call Button(button[u.id - 1][i]).destroy()
                        endif

                        set i = i + 1
                    endloop

                    set i = 0

                    loop
                        exitwhen i == DETAIL_USED_COUNT
                        set i = i + 1
                    endloop

                    call button.remove(i)
                    call used.remove(i)
                set u = u.next
            endloop

            call main.destroy()
            call components.destroy()
            call count.destroy()
            call item.destroy()
            call used.destroy()
            call button.destroy()
            call BlzDestroyFrame(topSeparator)
            call BlzDestroyFrame(bottomSeparator)
            call BlzDestroyFrame(usedIn)
            call BlzDestroyFrame(scrollFrame)
            call BlzDestroyFrame(horizontalRight)
            call BlzDestroyFrame(horizontalLeft)
            call BlzDestroyFrame(verticalMain)
            call BlzDestroyFrame(verticalCenter)
            call BlzDestroyFrame(verticalLeft1)
            call BlzDestroyFrame(verticalLeft2)
            call BlzDestroyFrame(verticalRight1)
            call BlzDestroyFrame(verticalRight2)
            call BlzDestroyFrame(tooltip)
            call BlzDestroyFrame(frame)
            call deallocate()

            set frame = null
            set tooltip = null
            set topSeparator = null
            set bottomSeparator = null
            set usedIn = null
            set scrollFrame = null
            set horizontalRight = null
            set horizontalLeft = null
            set verticalMain = null
            set verticalCenter = null
            set verticalLeft1 = null
            set verticalLeft2 = null
            set verticalRight1 = null
            set verticalRight2 = null
        endmethod

        method update takes framehandle frame, framepointtype point, framehandle parent, framepointtype relative, real width, real height, real x, real y, boolean visible returns nothing
            if visible then
                call BlzFrameClearAllPoints(frame)
                call BlzFrameSetPoint(frame, point, parent, relative, x, y)
                call BlzFrameSetSize(frame, width, height)
            endif

            call BlzFrameSetVisible(frame, visible)
        endmethod

        method shift takes boolean left, player p returns nothing
            local ShopItem i
            local integer j
            local integer id = GetPlayerId(p)

            if left then
                if ShopItem(item[id]).relation.has(count[id]) and count[id] >= DETAIL_USED_COUNT then
                    set j = 0

                    loop
                        exitwhen j == DETAIL_USED_COUNT - 1
                            set used[id][j] = used[id][j + 1]

                            if GetLocalPlayer() == p then
                                set Button(button[id][j]).icon = ShopItem(used[id][j]).icon
                                set Button(button[id][j]).tooltip.text = ShopItem(used[id][j]).tooltip
                                set Button(button[id][j]).tooltip.name = ShopItem(used[id][j]).name
                                set Button(button[id][j]).tooltip.icon = ShopItem(used[id][j]).icon
                                set Button(button[id][j]).available = shop.has(ShopItem(used[id][j]).id)
                                set Button(button[id][j]).visible = true
                            endif
                        set j = j + 1
                    endloop

                    set i = ShopItem.get(ShopItem(item[id]).relation[count[id]])

                    if i != 0 then
                        set count[id] = count[id] + 1
                        set used[id][j] = i

                        if GetLocalPlayer() == p then
                            set Button(button[id][j]).icon = i.icon
                            set Button(button[id][j]).tooltip.text = i.tooltip
                            set Button(button[id][j]).tooltip.name = i.name
                            set Button(button[id][j]).tooltip.icon = i.icon
                            set Button(button[id][j]).available = shop.has(i.id)
                            set Button(button[id][j]).visible = true
                        endif
                    endif
                endif
            else
                if count.integer[id] > DETAIL_USED_COUNT then
                    set j = DETAIL_USED_COUNT - 1

                    loop
                        exitwhen j == 0
                            set used[id][j] = used[id][j - 1]

                            if GetLocalPlayer() == p then
                                set Button(button[id][j]).icon = ShopItem(used[id][j]).icon
                                set Button(button[id][j]).tooltip.text = ShopItem(used[id][j]).tooltip
                                set Button(button[id][j]).tooltip.name = ShopItem(used[id][j]).name
                                set Button(button[id][j]).tooltip.icon = ShopItem(used[id][j]).icon
                                set Button(button[id][j]).available = shop.has(ShopItem(used[id][j]).id)
                                set Button(button[id][j]).visible = true
                            endif
                        set j = j - 1
                    endloop
                    
                    set i = ShopItem.get(ShopItem(item[id]).relation[count[id] - DETAIL_USED_COUNT - 1])

                    if i != 0 then
                        set count[id] = count[id] - 1
                        set used[id][j] = i

                        if GetLocalPlayer() == p then
                            set Button(button[id][j]).icon = i.icon
                            set Button(button[id][j]).tooltip.text = i.tooltip
                            set Button(button[id][j]).tooltip.name = i.name
                            set Button(button[id][j]).tooltip.icon = i.icon
                            set Button(button[id][j]).available = shop.has(i.id)
                            set Button(button[id][j]).visible = true
                        endif
                    endif
                endif
            endif
        endmethod

        method showUsed takes player p returns nothing
            local ShopItem i
            local integer j = 0
            local integer id = GetPlayerId(p)
            
            if GetLocalPlayer() == p then
                loop
                    exitwhen j == DETAIL_USED_COUNT
                        set Button(button[id][j]).visible = false
                    set j = j + 1
                endloop
                set j = 0
                loop
                    exitwhen j == INVENTORY_COUNT
                        set Slot(components[id][j]).visible = false
                    set j = j + 1
                endloop
            endif

            set j = 0

            loop
                exitwhen not ShopItem(item[id]).relation.has(j) or j == DETAIL_USED_COUNT
                    set i = ShopItem.get(ShopItem(item[id]).relation[j])

                    if i != 0 then
                        set used[id][j] = i

                        if GetLocalPlayer() == p then
                            set Button(button[id][count[id]]).icon = i.icon
                            set Button(button[id][count[id]]).tooltip.text = i.tooltip
                            set Button(button[id][count[id]]).tooltip.name = i.name
                            set Button(button[id][count[id]]).tooltip.icon = i.icon
                            set Button(button[id][count[id]]).visible = true
                            set Button(button[id][count[id]]).available = shop.has(i.id)
                        endif

                        set count[id] = count[id] + 1
                    endif
                set j = j + 1
            endloop
        endmethod

        method refresh takes player p returns nothing
            local integer id = GetPlayerId(p)

            if isVisible and item[id] != 0 then
                call show(item[id], p)
            endif
        endmethod

        method show takes ShopItem i, player p returns nothing
            local ShopItem component
            local Slot slot
            local integer k = 0
            local integer l = 0
            local integer array cost
            local integer id = GetPlayerId(p)
            local Table counter = Table.create()

            if i != 0 then
                set item[id] = i
                set count[id] = 0
                loop
                    exitwhen l == CURRENCY_COUNT

                    set cost[l] = i.currency[l]

                    set l = l + 1
                endloop

                set Slot(main[id]).item = i
                set Slot(main[id]).button.icon = i.icon
                set Slot(main[id]).button.tooltip.text = i.tooltip
                set Slot(main[id]).button.tooltip.name = i.name
                set Slot(main[id]).button.tooltip.icon = i.icon
                set Slot(main[id]).button.available = shop.has(i.id)

                call showUsed(p)
                
                if i.components > 0 then
                    if GetLocalPlayer() == p then
                        call BlzFrameSetVisible(verticalCenter, true)
                    endif

                    loop
                        exitwhen k == i.components or k == INVENTORY_COUNT
                            set slot = components[id][k]
                            set component = ShopItem.get(i.component[k])

                            if GetLocalPlayer() == p then
                                call update(slot.slot, FRAMEPOINT_TOPLEFT, slot.parent, FRAMEPOINT_TOPLEFT, ITEM_SIZE, ITEM_SIZE, 0.1436 - (COMPONENT_GAP * 0.5 * (i.components - 1)) + k * COMPONENT_GAP, -0.09, true)
                            endif

                            set slot.item = component
                            set slot.button.icon = component.icon
                            set slot.button.tooltip.text = component.tooltip
                            set slot.button.tooltip.name = component.name
                            set slot.button.tooltip.icon = component.icon
                            set slot.button.available = shop.has(component.id)

                            if PlayerHasItemType(id + 1, component.id) then
                                if PlayerCountItemType(id + 1, component.id) >= i.count(component.id) then
                                    set slot.button.checked = true
                                else
                                    set counter[component.id] = counter[component.id] + 1
                                    set slot.button.checked = counter[component.id] <= PlayerCountItemType(id + 1, component.id)
                                endif
                            else
                                set slot.button.checked = false
                            endif

                            set l = 0
                            loop
                                exitwhen l == CURRENCY_COUNT

                                if component.currency[l] > 0 then
                                    //call BlzFrameSetText(slot.cost[l], "|cffFFCC00" + I2S(component.currency[l]) + "|r")

                                    if slot.button.checked then
                                        set cost[l] = cost[l] - component.currency[l]
                                    endif
                                endif

                                set l = l + 1
                            endloop
                            if GetLocalPlayer() == p then
                                set slot.visible = true
                            endif

                        set k = k + 1
                    endloop
                else
                    loop
                        exitwhen k == INVENTORY_COUNT
                            if GetLocalPlayer() == p then
                                set Slot(components[id][k]).visible = false
                            endif
                        set k = k + 1
                    endloop

                    if GetLocalPlayer() == p then
                        //call BlzFrameSetVisible(horizontalLeft, false)
                        //call BlzFrameSetVisible(horizontalRight, false)
                        //call BlzFrameSetVisible(verticalMain, false)
                        call BlzFrameSetVisible(verticalCenter, false)
                        //call BlzFrameSetVisible(verticalLeft1, false)
                        //call BlzFrameSetVisible(verticalLeft2, false)
                        //call BlzFrameSetVisible(verticalRight1, false)
                        //call BlzFrameSetVisible(verticalRight2, false)
                    endif
                endif

                set l = 0
                loop
                    exitwhen l == CURRENCY_COUNT

                    if cost[l] > 0 then
                        if GetLocalPlayer() == p then
                            //call BlzFrameSetText(Slot(main[id]).cost[l], "|cffFFCC00" + I2S(cost[l]) + "|r")
                        endif
                    endif

                    set l = l + 1
                endloop

                if GetLocalPlayer() == p then
                    call BlzFrameSetText(tooltip, i.tooltip)
                    set visible = true
                endif
            endif

            call counter.destroy()
        endmethod

        static method create takes Shop shop returns thistype
            local thistype this = thistype.allocate()
            local User u = User.first
            local integer i = 0
            local integer j

            set .shop = shop
            set isVisible = false
            set item = Table.create()
            set count = Table.create()
            set main = Table.create()
            set used = HashTable.create()
            set button = HashTable.create()
            set frame = BlzCreateFrame("EscMenuBackdrop", shop.main, 0, 0)
            set topSeparator = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            set bottomSeparator = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            set tooltip = BlzCreateFrame("DescriptionArea", frame, 0, 0)

            //components
            set components = HashTable.create()

            //funny lines
            //set horizontalLeft = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set horizontalRight = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set verticalMain = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            set verticalCenter = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set verticalLeft1 = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set verticalLeft2 = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set verticalRight1 = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //set verticalRight2 = BlzCreateFrameByType("BACKDROP", "", frame, "", 0)
            //
            call BlzFrameSetSize(verticalCenter, 0.001, 0.021)

            set scrollFrame = BlzCreateFrameByType("BUTTON", "", frame, "", 0)
            set usedIn = BlzCreateFrameByType("TEXT", "", scrollFrame, "", 0)
            set close = Button.create(frame, DETAIL_CLOSE_BUTTON_SIZE, DETAIL_CLOSE_BUTTON_SIZE, 0.26676, - 0.025000, true)
            set close.icon = CLOSE_ICON
            set close.onClick = function thistype.onClick
            set close.tooltip.text = "Close"
            set left = Button.create(scrollFrame, DETAIL_SHIFT_BUTTON_SIZE, DETAIL_SHIFT_BUTTON_SIZE, 0.0050000, - 0.0025000, true)
            set left.icon = USED_LEFT
            set left.onClick = function thistype.onClick
            set left.tooltip.text = "Scroll Left"
            set right = Button.create(scrollFrame, DETAIL_SHIFT_BUTTON_SIZE, DETAIL_SHIFT_BUTTON_SIZE, 0.24650, - 0.0025000, true)
            set right.icon = USED_RIGHT
            set right.onClick = function thistype.onClick
            set right.tooltip.text = "Scroll Right"
            set table[GetHandleId(close.frame)][0] = this
            set table[GetHandleId(left.frame)][0] = this
            set table[GetHandleId(right.frame)][0] = this
            set table[GetHandleId(scrollFrame)][0] = this

            call BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, shop.main, FRAMEPOINT_TOPLEFT, WIDTH - DETAIL_WIDTH, 0.0000)
            call BlzFrameSetPoint(scrollFrame, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.022500, - 0.28)
            call BlzFrameSetPoint(topSeparator, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.027500, - 0.13)
            call BlzFrameSetPoint(bottomSeparator, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.027500, - 0.28)
            call BlzFrameSetPoint(verticalCenter, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.155, - 0.0677)
            call BlzFrameSetPoint(usedIn, FRAMEPOINT_TOPLEFT, scrollFrame, FRAMEPOINT_TOPLEFT, 0.11500, - 0.0025000)
            call BlzFrameSetPoint(tooltip, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.027500, - 0.135)
            call BlzFrameSetSize(frame, DETAIL_WIDTH, DETAIL_HEIGHT)
            call BlzFrameSetSize(scrollFrame, 0.26750, 0.06100)
            call BlzFrameSetSize(topSeparator, 0.252, 0.001)
            call BlzFrameSetSize(bottomSeparator, 0.252, 0.001)
            call BlzFrameSetSize(usedIn, 0.04, 0.012)
            call BlzFrameSetSize(tooltip, 0.31, 0.16)
            call BlzFrameSetText(tooltip, "")
            call BlzFrameSetText(usedIn, "|cffFFCC00Used in|r")
            call BlzFrameSetEnable(usedIn, false)
            call BlzFrameSetScale(usedIn, 1.00)
            call BlzFrameSetTextAlignment(usedIn, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetTexture(bottomSeparator, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            call BlzFrameSetTexture(topSeparator, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(horizontalLeft, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(horizontalRight, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(verticalMain, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            call BlzFrameSetTexture(verticalCenter, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(verticalLeft1, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(verticalLeft2, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(verticalRight1, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            //call BlzFrameSetTexture(verticalRight2, "replaceabletextures\\teamcolor\\teamcolor08", 0, true)
            call BlzTriggerRegisterFrameEvent(trigger, scrollFrame, FRAMEEVENT_MOUSE_WHEEL)

            loop
                exitwhen u == User.NULL
                    set main[u.id - 1] = Slot.create(frame, 0, SLOT_WIDTH, SLOT_HEIGHT, 0.13625, - 0.030000, FRAMEPOINT_TOPRIGHT, false)
                    set Slot(main[u.id - 1]).visible = GetLocalPlayer() == u.toPlayer()
                    set Slot(main[u.id - 1]).onClick = function thistype.onClick
                    set Slot(main[u.id - 1]).onRightClick = function thistype.onRightClick
                    set Slot(main[u.id - 1]).onDoubleClick = function thistype.onDoubleClick

                    set table[GetHandleId(Slot(main[u.id - 1]).button.frame)][0] = this

                    set j = 0
                    loop
                        exitwhen j == INVENTORY_COUNT
                            set components[u.id - 1][j] = Slot.create(frame, 0, SLOT_WIDTH * 0.6, SLOT_HEIGHT * 0.6, 0.13625, 0., FRAMEPOINT_TOPRIGHT, false)
                            set Slot(components[u.id - 1][j]).visible = false
                            set Slot(components[u.id - 1][j]).onClick = function thistype.onClick
                            set Slot(components[u.id - 1][j]).onRightClick = function thistype.onRightClick
                            set Slot(components[u.id - 1][j]).onDoubleClick = function thistype.onDoubleClick

                            set table[GetHandleId(Slot(components[u.id - 1][j]).button.frame)][0] = this
                        set j = j + 1
                    endloop

                    set j = 0
                    loop
                        exitwhen j == DETAIL_USED_COUNT
                            set button[u.id - 1][j] = Button.create(scrollFrame, DETAIL_BUTTON_SIZE, DETAIL_BUTTON_SIZE, 0.0050000 + DETAIL_BUTTON_GAP*j, - 0.019, false)
                            set Button(button[u.id - 1][j]).visible = false
                            set Button(button[u.id - 1][j]).onClick = function thistype.onClick
                            set Button(button[u.id - 1][j]).onScroll = function thistype.onScroll
                            set Button(button[u.id - 1][j]).onRightClick = function thistype.onRightClick
                            set Button(button[u.id - 1][j]).tooltip.point = FRAMEPOINT_BOTTOMRIGHT
                            set table[GetHandleId(Button(button[u.id - 1][j]).frame)][0] = this
                            set table[GetHandleId(Button(button[u.id - 1][j]).frame)][1] = j
                        set j = j + 1
                    endloop
                set u = u.next
            endloop

            call BlzFrameSetVisible(frame, false)

            return this
        endmethod

        static method onScroll takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                call shift(BlzGetTriggerFrameValue() < 0, GetTriggerPlayer())
            endif
        endmethod

        static method onClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer j = 0
            local integer id = GetPlayerId(GetTriggerPlayer())
            local boolean found = false

            if this != 0 then
                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)

                if frame == close.frame then
                    call shop.detail(0, GetTriggerPlayer())
                elseif frame == left.frame then
                    call shift(false, GetTriggerPlayer())
                elseif frame == right.frame then
                    call shift(true, GetTriggerPlayer())
                elseif frame == Slot(main[id]).button.frame then
                    call shop.select(Slot(main[id]).item, GetTriggerPlayer())
                else
                    loop
                        exitwhen j == INVENTORY_COUNT
                            if frame == Slot(components[id][j]).button.frame then
                                set found = true
                                static if DETAIL_COMPONENT then
                                    call shop.detail(Slot(components[id][j]).item, GetTriggerPlayer())
                                endif
                            endif

                        set j = j + 1
                    endloop

                    if not found and frame != Slot(main[id]).button.frame then
                        call shop.detail(used[id][i], GetTriggerPlayer())
                    endif
                endif
            endif

            set frame = null
        endmethod

        static method onRightClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player p = GetTriggerPlayer()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer j = 0
            local integer id = GetPlayerId(p)
            local boolean found = false

            if this != 0 then
                if frame == Slot(main[id]).button.frame then
                    if shop.buy(Slot(main[id]).item, p) then
                        if GetLocalPlayer() == p then
                            call Slot(main[id]).button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                        endif
                    endif
                else
                    loop
                        exitwhen j == INVENTORY_COUNT
                            if frame == Slot(components[id][j]).button.frame then
                                set found = true
                                if shop.buy(Slot(components[id][j]).item, p) then
                                    if GetLocalPlayer() == p then
                                        call Slot(components[id][j]).button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                                    endif
                                endif
                            endif

                        set j = j + 1
                    endloop

                    if not found then
                        if shop.buy(used[id][i], p) then
                            if GetLocalPlayer() == p then
                                call Button(button[id][i]).play(SPRITE_MODEL, SPRITE_SCALE, 0)
                            endif
                        endif
                    endif
                endif
            endif

            set p =null
            set frame = null
        endmethod

        static method onDoubleClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player p = GetTriggerPlayer()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer j = 0
            local integer id = GetPlayerId(p)
            local boolean found = false

            if this != 0 then
                if frame == Slot(main[id]).button.frame then
                    if shop.buy(Slot(main[id]).item, p) then
                        if GetLocalPlayer() == p then
                            call Slot(main[id]).button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                        endif
                    endif
                else
                    loop
                        exitwhen j == INVENTORY_COUNT
                            if frame == Slot(components[id][j]).button.frame then
                                set found = true
                                if shop.buy(Slot(components[id][j]).item, p) then
                                    if GetLocalPlayer() == p then
                                        call Slot(components[id][j]).button.play(SPRITE_MODEL, SPRITE_SCALE, 0)
                                    endif
                                endif
                            endif

                        set j = j + 1
                    endloop

                    if not found then
                        if shop.buy(used[id][i], p) then
                            if GetLocalPlayer() == p then
                                call Button(button[id][i]).play(SPRITE_MODEL, SPRITE_SCALE, 0)
                            endif
                        endif
                    endif
                endif
            endif

            set p =null
            set frame = null
        endmethod

        static method onInit takes nothing returns nothing
            call TriggerAddAction(trigger, function thistype.onScroll)
        endmethod
    endstruct

    private struct Inventory
        private boolean isVisible

        Shop shop
        framehandle frame
        framehandle scrollFrame
        Table selected
        HashTable item
        HashTable button

        method operator visible= takes boolean visibility returns nothing
            set isVisible = visibility
            call BlzFrameSetVisible(frame, visibility)
        endmethod

        method operator visible takes nothing returns boolean
            return isVisible
        endmethod

        method destroy takes nothing returns nothing
            local integer i = 0
            local integer j

            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                    set j = 0

                    loop
                        exitwhen j == INVENTORY_COUNT
                            call table.remove(GetHandleId(Button(button[i][j]).frame))
                            call Button(button[i][j]).destroy()
                        set j = j + 1
                    endloop

                    call button.remove(i)
                    call item.remove(i)
                set i = i + 1
            endloop

            call BlzDestroyFrame(frame)
            call BlzDestroyFrame(scrollFrame)
            call selected.destroy()
            call button.destroy()
            call item.destroy()
            call deallocate()

            set frame = null
            set scrollFrame = null
        endmethod

        method move takes framepointtype point, framehandle relative, framepointtype relativePoint returns nothing
            call BlzFrameClearAllPoints(frame)
            call BlzFrameSetPoint(frame, point, relative, relativePoint, 0, 0.1425)
        endmethod

        method show takes integer id returns nothing
            local item i
            local integer j = 0

            loop
                exitwhen j == INVENTORY_COUNT
                    set i = Profile[id + 1].hero.items[j].obj

                    if i != null then
                        set item[id][j] = ShopItem.get(GetItemTypeId(i))

                        if item[id][j] == 0 then
                            if GetLocalPlayer() == Player(id) then
                                set Button(button[id][j]).icon = BlzGetItemIconPath(i)
                                set Button(button[id][j]).tooltip.icon = BlzGetItemIconPath(i)
                                set Button(button[id][j]).tooltip.name = GetItemName(i)
                                set Button(button[id][j]).tooltip.text = BlzGetItemExtendedTooltip(i)
                                set Button(button[id][j]).visible = true
                            endif
                        else
                            if GetLocalPlayer() == Player(id) then
                                set Button(button[id][j]).icon = ShopItem(item[id][j]).icon
                                set Button(button[id][j]).tooltip.icon = ShopItem(item[id][j]).icon
                                set Button(button[id][j]).tooltip.name = ShopItem(item[id][j]).name
                                set Button(button[id][j]).tooltip.text = ShopItem(item[id][j]).tooltip
                                set Button(button[id][j]).visible = true
                            endif
                        endif

                    else
                        set item[id][j] = 0

                        if GetLocalPlayer() == Player(id) then
                            set Button(button[id][j]).visible = false
                        endif
                    endif
                set j = j + 1
            endloop

            set i = null
        endmethod

        static method create takes Shop shop returns thistype
            local thistype this = thistype.allocate()
            local User u = User.first
            local integer i = 0
            local integer j = 0
            local integer k = 0

            set .shop = shop
            set isVisible = true
            set selected = Table.create()
            set item = HashTable.create()
            set button = HashTable.create()
            set frame = BlzCreateFrameByType("BACKDROP", "", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
            set scrollFrame = BlzCreateFrameByType("BUTTON", "", frame, "", 0)

            call BlzFrameSetPoint(frame, FRAMEPOINT_TOP, shop.buyer.frame, FRAMEPOINT_BOTTOM, 0, 0.0975)
            call BlzFrameSetSize(frame, INVENTORY_WIDTH, INVENTORY_HEIGHT)
            call BlzFrameSetTexture(frame, INVENTORY_TEXTURE, 0, false)
            call BlzFrameSetAllPoints(scrollFrame, frame)

            loop
                exitwhen u == User.NULL
                    set i = 0
                    set j = 0
                    set k = 0

                    loop
                        exitwhen j == INVENTORY_COUNT
                        set button[u.id - 1][j] = Button.create(scrollFrame, INVENTORY_SIZE, INVENTORY_SIZE, 0.0032000 + INVENTORY_GAPX*i, - 0.0033000 - INVENTORY_GAPY*k, false)
                        set Button(button[u.id - 1][j]).tooltip.point = FRAMEPOINT_BOTTOM
                        set Button(button[u.id - 1][j]).onClick = function thistype.onClick
                        set Button(button[u.id - 1][j]).onDoubleClick = function thistype.onDoubleClick
                        set Button(button[u.id - 1][j]).onRightClick = function thistype.onRightClick
                        set Button(button[u.id - 1][j]).visible = false
                        set table[GetHandleId(Button(button[u.id - 1][j]).frame)][0] = this
                        set table[GetHandleId(Button(button[u.id - 1][j]).frame)][1] = j

                        set i = i + 1
                        set j = j + 1

                        if i == 6 then
                            set k = k + 1
                            set i = 0
                        endif
                    endloop
                set u = u.next
            endloop

            return this
        endmethod

        static method onClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(GetTriggerPlayer())
            local ShopItem s

            if this != 0 then
                set selected[id] = i

                set s = ShopItem.get(Profile[id + 1].hero.items[i])
                
                if s != 0 then
                    call shop.detail(s, GetTriggerPlayer())
                endif
            endif

            set frame = null
        endmethod

        static method onDoubleClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player p = GetTriggerPlayer()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(p)

            set p = null
            set frame = null
        endmethod

        static method onRightClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player p = GetTriggerPlayer()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(p)

            set p = null
            set frame = null
        endmethod
    endstruct

    private struct Buyer
        private static Table current
        readonly static trigger trigger = CreateTrigger()

        private boolean isVisible

        Shop shop
        Inventory inventory
        Button left
        Button right
        Table last
        Table index
        Table size
        Table selected
        HashTable button
        HashTable unit
        framehandle frame
        framehandle scrollFrame

        method operator visible= takes boolean visibility returns nothing
            local integer i = 0
            local integer id = GetPlayerId(GetLocalPlayer())

            set isVisible = visibility
            set inventory.visible = visibility

            if isVisible then
                call inventory.move(FRAMEPOINT_TOP, .frame, FRAMEPOINT_BOTTOM)
            endif

            call BlzFrameSetVisible(frame, visibility)
        endmethod

        method operator visible takes nothing returns boolean
            return isVisible
        endmethod

        method destroy takes nothing returns nothing
            local integer i = 0
            local integer j

            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                    set j = 0

                    loop
                        exitwhen j == BUYER_COUNT
                            call table.remove(GetHandleId(Button(button[i][j]).frame))
                            call Button(button[i][j]).destroy()
                        set j = j + 1
                    endloop

                    call button.remove(i)
                    call unit.remove(i)
                set i = i + 1
            endloop

            call BlzDestroyFrame(frame)
            call BlzDestroyFrame(scrollFrame)
            call button.destroy()
            call unit.destroy()
            call last.destroy()
            call index.destroy()
            call size.destroy()
            call selected.destroy()
            call left.destroy()
            call right.destroy()
            call inventory.destroy()
            call deallocate()

            set frame = null
            set scrollFrame = null
        endmethod

        //deprecated
        method shift takes boolean left, player p returns nothing
            return
        endmethod

        method update takes integer id returns nothing
            if shop.current[id] != null and IsUnitInRange(Hero[id + 1], shop.current[id], shop.aoe) then
                call inventory.show(id)

                if GetLocalPlayer() == Player(id) then
                    //call shop.details.refresh(Player(id))
                    call BlzFrameSetVisible(frame, true)
                    set inventory.visible = true
                endif
            else
                if GetLocalPlayer() == Player(id) then
                    call BlzFrameSetVisible(frame, false)
                    set inventory.visible = false
                endif
            endif
        endmethod

        static method create takes Shop shop returns thistype
            local thistype this = thistype.allocate()
            local integer i = 0
            local integer j = 0

            set .shop = shop
            set isVisible = true
            set last = Table.create()
            set size = Table.create()
            set index = Table.create()
            set selected = Table.create()
            set button = HashTable.create()
            set unit = HashTable.create()
            set frame = BlzCreateFrame("EscMenuBackdrop", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
            set scrollFrame = BlzCreateFrameByType("BUTTON", "", frame, "", 0)
            //set left = Button.create(scrollFrame, BUYER_SHIFT_BUTTON_SIZE, BUYER_SHIFT_BUTTON_SIZE, 0.027500, - 0.032500, true)
            //set left.onClick = function thistype.onClick
            //set left.icon = BUYER_LEFT
            //set left.tooltip.text = "Scroll Left"
            //set right = Button.create(scrollFrame, BUYER_SHIFT_BUTTON_SIZE, BUYER_SHIFT_BUTTON_SIZE, 0.36350, - 0.032500, true)
            //set right.onClick = function thistype.onClick
            //set right.icon = BUYER_RIGHT
            //set right.tooltip.text = "Scroll Right"
            set inventory = Inventory.create(shop)
            //set table[GetHandleId(left.frame)][0] = this
            //set table[GetHandleId(right.frame)][0] = this
            set table[GetHandleId(scrollFrame)][0] = this

            call BlzFrameSetPoint(frame, FRAMEPOINT_TOP, shop.base, FRAMEPOINT_BOTTOM, 0.42, 0.1605)
            call BlzFrameSetSize(frame, BUYER_WIDTH, BUYER_HEIGHT)
            call BlzFrameSetAllPoints(scrollFrame, frame)
            //call BlzTriggerRegisterFrameEvent(trigger, scrollFrame, FRAMEEVENT_MOUSE_WHEEL)

            /*loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                    set j = 0

                    loop
                        exitwhen j == BUYER_COUNT
                            set button[i][j] = Button.create(scrollFrame, BUYER_SIZE, BUYER_SIZE, 0.015 + BUYER_GAP*j, - 0.023000, true)
                            set Button(button[i][j]).onClick = function thistype.onClick
                            set Button(button[i][j]).onScroll = function thistype.onScroll
                            set Button(button[i][j]).visible = false
                            set table[GetHandleId(Button(button[i][j]).frame)][0] = this
                            set table[GetHandleId(Button(button[i][j]).frame)][1] = j
                        set j = j + 1
                    endloop
                set i = i + 1
            endloop*/

            return this
        endmethod

        static method onScroll takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                call shift(BlzGetTriggerFrameValue() < 0, GetTriggerPlayer())
            endif
        endmethod

        static method onClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(GetTriggerPlayer())

            if this != 0 then
                if frame == left.frame then
                    call shift(false, GetTriggerPlayer())
                elseif frame == right.frame then
                    call shift(true, GetTriggerPlayer())
                else
                    set current[GetHandleId(shop.current[id])] = this
                    call inventory.show(id)
                    call inventory.selected.remove(id)

                    if GetLocalPlayer() == GetTriggerPlayer() then
                        set Button(last[id]).highlighted = false
                        set Button(button[id][i]).highlighted = true
                        set last[id] = button[id][i]
                        
                        //call inventory.move(FRAMEPOINT_TOP, Button(button[id][i]).frame, FRAMEPOINT_BOTTOM)
                        call shop.details.refresh(GetTriggerPlayer())
                    endif
                endif 

                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)
            endif

            set frame = null
        endmethod

        private static method onPickup takes nothing returns nothing
            local unit u = GetManipulatingUnit()
            local integer i = GetPlayerId(GetOwningPlayer(u))
            local thistype this = current[GetHandleId(u)]

            if this != 0 then
                if shop.current[i] != null then
                    if IsUnitInRange(u, shop.current[i], shop.aoe) then
                        call inventory.show(i)
                        call shop.details.refresh(GetOwningPlayer(u))
                    endif
                endif
            endif

            set u = null
        endmethod

        private static method onDrop takes nothing returns nothing
            local unit u = GetManipulatingUnit()
            local integer i = GetPlayerId(GetOwningPlayer(u))
            local thistype this = current[GetHandleId(u)]

            if this != 0 then
                if shop.current[i] != null then
                    if selected.unit[i] == u and IsUnitInRange(u, shop.current[i], shop.aoe) then
                        call shop.details.refresh(GetOwningPlayer(u))
                    endif
                endif
            endif

            set u = null
        endmethod

        static method onInit takes nothing returns nothing
            set current = Table.create()

            call TriggerAddAction(trigger, function thistype.onScroll)
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickup)
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function thistype.onDrop)
        endmethod
    endstruct

    private struct Favorites
        Shop shop
        Table count
        HashTable item
        HashTable button

        method destroy takes nothing returns nothing
            local integer i = 0
            local integer j

            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                    set j = 0

                    loop
                        exitwhen j == CATEGORY_COUNT
                            call table.remove(GetHandleId(Button(button[i][j]).frame))
                            call Button(button[i][j]).destroy()
                        set j = j + 1
                    endloop

                    call button.remove(i)
                    call item.remove(i)
                set i = i + 1
            endloop

            call count.destroy()
            call item.destroy()
            call button.destroy()
            call deallocate()
        endmethod

        method has takes integer id, player p returns boolean
            local integer i = 0
            local integer pid = GetPlayerId(p)

            loop
                exitwhen i > count.integer[pid]
                    if ShopItem(item[pid][i]).id == id then
                        return true
                    endif
                set i = i + 1
            endloop

            return false
        endmethod

        method clear takes player p returns nothing
            local integer id = GetPlayerId(p)

            loop
                exitwhen count[id] == -1
                    if GetLocalPlayer() == p then
                        set Button(button[id][count[id]]).visible = false
                        call ShopSlot(table[shop][ShopItem(item[id][count[id]]).id]).button.tag(null, 0, 0, 0, null, null, 0, 0)
                    endif
                set count[id] = count[id] - 1
            endloop
        endmethod

        method remove takes integer i, player p returns nothing
            local integer id = GetPlayerId(p)

            if GetLocalPlayer() == p then
                call ShopSlot(table[shop][ShopItem(item[id][i]).id]).button.tag(null, 0, 0, 0, null, null, 0, 0)
            endif

            loop
                exitwhen i >= count[id]
                    set item[id][i] = item[id][i + 1]

                    if GetLocalPlayer() == p then
                        set Button(button[id][i]).icon = ShopItem(item[id][i]).icon
                        set Button(button[id][i]).tooltip.text = ShopItem(item[id][i]).tooltip
                        set Button(button[id][i]).tooltip.name = ShopItem(item[id][i]).name
                        set Button(button[id][i]).tooltip.icon = ShopItem(item[id][i]).icon
                    endif
                set i = i + 1
            endloop

            if GetLocalPlayer() == p then
                set Button(button[id][count[id]]).visible = false
            endif
            
            set count[id] = count[id] - 1
        endmethod

        method add takes ShopItem i, player p returns nothing
            local integer id = GetPlayerId(p)

            if count.integer[id] < CATEGORY_COUNT - 1 then
                if not has(i.id, p) then
                    set count[id] = count[id] + 1
                    set item[id][count[id]] = i

                    if GetLocalPlayer() == p then
                        set Button(button[id][count[id]]).icon = i.icon
                        set Button(button[id][count[id]]).tooltip.text = i.tooltip
                        set Button(button[id][count[id]]).tooltip.name = i.name
                        set Button(button[id][count[id]]).tooltip.icon = i.icon
                        set Button(button[id][count[id]]).visible = true
                        call ShopSlot(table[shop][i.id]).button.tag(TAG_HIGHLIGHT, TAG_HIGHLIGHT_WIDTH, TAG_HIGHLIGHT_HEIGHT, TAG_HIGHLIGHT_SCALE, FRAMEPOINT_BOTTOMLEFT, FRAMEPOINT_BOTTOMLEFT, TAG_HIGHLIGHT_XOFFSET, TAG_HIGHLIGHT_YOFFSET)
                    endif
                endif
            endif
        endmethod

        static method create takes Shop shop returns thistype
            local thistype this = thistype.allocate()
            local User u = User.first
            local integer j

            set .shop = shop
            set count = Table.create()
            set item = HashTable.create()
            set button = HashTable.create()
            
            loop
                exitwhen u == User.NULL
                    set j = 0
                    set count[u.id - 1] = -1

                    loop
                        exitwhen j == CATEGORY_COUNT
                            set button[u.id - 1][j] = Button.create(shop.rightPanel, CATEGORY_SIZE, CATEGORY_SIZE, 0.024750, - (0.021500 + CATEGORY_SIZE*j + CATEGORY_GAP), false)
                            set Button(button[u.id - 1][j]).visible = false
                            set Button(button[u.id - 1][j]).onClick = function thistype.onClick
                            set Button(button[u.id - 1][j]).onDoubleClick = function thistype.onDoubleClick
                            set Button(button[u.id - 1][j]).tooltip.point = FRAMEPOINT_TOPRIGHT
                            set table[GetHandleId(Button(button[u.id - 1][j]).frame)][0] = this
                            set table[GetHandleId(Button(button[u.id - 1][j]).frame)][1] = j
        
                            if j > 6 then
                                set Button(button[u.id - 1][j]).tooltip.point = FRAMEPOINT_BOTTOMRIGHT
                            endif
                        set j = j + 1
                    endloop
                set u = u.next
            endloop

            return this
        endmethod

        static method onClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(GetTriggerPlayer())

            if this != 0 then
                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)

                if Shop.tag[id] then
                    call remove(i, GetTriggerPlayer())
                else
                    call shop.detail(item[id][i], GetTriggerPlayer())
                endif
            endif

            set frame = null
        endmethod

        static method onDoubleClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local player p = GetTriggerPlayer()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]
            local integer id = GetPlayerId(p)

            if this != 0 then
                if shop.buy(item[id][i], p) then
                    if GetLocalPlayer() == p then
                        call Button(button[id][i]).play(SPRITE_MODEL, SPRITE_SCALE, 0)
                    endif
                endif
            endif

            set p = null
            set frame = null
        endmethod
    endstruct

    private struct Category
        Shop shop
        integer count
        integer active
        boolean andLogic
        integer array value[CATEGORY_COUNT]
        Button array button[CATEGORY_COUNT]

        method destroy takes nothing returns nothing
            loop
                exitwhen count == -1
                    call table.remove(GetHandleId(button[count].frame))
                    call button[count].destroy()
                set count = count - 1
            endloop

            call deallocate()
        endmethod

        method clear takes nothing returns nothing
            local integer i = 0

            set active = 0

            loop
                exitwhen i == CATEGORY_COUNT
                    set button[i].enabled = false
                set i = i + 1
            endloop

            call shop.filter(active, andLogic)
        endmethod

        method add takes string icon, string description returns integer
            if count < CATEGORY_COUNT then
                set count = count + 1
                set value[count] = R2I(Pow(2, count))
                set button[count] = Button.create(shop.leftPanel, CATEGORY_SIZE, CATEGORY_SIZE, 0.024750, - (0.021500 + CATEGORY_SIZE*count + CATEGORY_GAP), true)
                set button[count].icon = icon
                set button[count].enabled = false
                set button[count].onClick = function thistype.onClick
                set button[count].tooltip.text = description
                set table[GetHandleId(button[count].frame)][0] = this
                set table[GetHandleId(button[count].frame)][1] = count

                return value[count]
            else
                call BJDebugMsg("Maximum number of categories reached.")
            endif

            return 0
        endmethod

        static method create takes Shop shop returns thistype
            local thistype this = thistype.allocate()

            set count = -1
            set active = 0
            set andLogic = true
            set .shop = shop

            return this
        endmethod

        static method onClick takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]
            local integer i = table[GetHandleId(frame)][1]

            if this != 0 then
                if GetLocalPlayer() == GetTriggerPlayer() then
                    set button[i].enabled = not button[i].enabled

                    if button[i].enabled then
                        set active = active + value[i]
                    else
                        set active = active - value[i]
                    endif

                    call shop.filter(active, andLogic)
                endif

                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)
            endif

            set frame = null
        endmethod
    endstruct
    
    struct Shop
        private static trigger trigger = CreateTrigger()
        private static trigger search = CreateTrigger()
        private static trigger keyPress = CreateTrigger()
        private static trigger escPressed = CreateTrigger()
        private static timer update = CreateTimer()
        private static integer count = -1
        private static HashTable itempool
        readonly static sound success
        readonly static sound error
        readonly static sound array noGold
        readonly static group array group
        readonly static timer array timer
        readonly static boolean array canScroll
        readonly static boolean array tag
        readonly static unit array current

        private boolean isVisible

        readonly framehandle base
        readonly framehandle main
        readonly framehandle edit
        readonly framehandle leftPanel
        readonly framehandle rightPanel
        readonly Category category
        readonly Favorites favorites
        readonly Detail details
        readonly Buyer buyer
        readonly Button close
        readonly Button break
        readonly Button revert
        readonly Button logic
        readonly Button clearCategory
        readonly Button clearFavorites
        readonly ShopSlot first
        readonly ShopSlot last
        readonly ShopSlot head
        readonly ShopSlot tail
        readonly integer id
        readonly integer index
        readonly integer size
        readonly integer rows
        readonly integer columns
        readonly boolean detailed
        readonly real aoe
        readonly real tax
        Table lastClicked
        Table stock

        static method setStock takes integer id, integer itemid, integer num returns nothing
            local thistype this = table[id][0]

            set this.stock[itemid] = num
        endmethod

        method operator visible= takes boolean visibility returns nothing
            set isVisible = visibility
            set buyer.visible = visibility

            if not visibility then
                set buyer.index = 0
            else
                if details.visible then
                    call details.refresh(GetLocalPlayer())
                endif
            endif

            call BlzFrameSetVisible(base, visibility)
        endmethod

        method operator visible takes nothing returns boolean
            return isVisible
        endmethod

        method destroy takes nothing returns nothing
            local integer i = 0
            local ShopSlot slot = itempool[this][0]

            loop
                exitwhen slot == 0
                    call slot.destroy()
                set slot = slot.next
            endloop

            call table.remove(id)
            call table.remove(this)
            call itempool.remove(this)
            call BlzDestroyFrame(rightPanel)
            call BlzDestroyFrame(leftPanel)
            call BlzDestroyFrame(main)
            call BlzDestroyFrame(base)
            call lastClicked.destroy()
            call stock.destroy()
            call break.destroy()
            call revert.destroy()
            call category.destroy()
            call favorites.destroy()
            call details.destroy()
            call buyer.destroy()
            call deallocate()

            set base = null
            set main = null
            set leftPanel = null
            set rightPanel = null
        endmethod

        method buy takes ShopItem i, player p returns boolean
            local ShopItem component = 0
            local integer array cost
            local integer gold
            local integer j = 0
            local integer k = 0
            local integer l = 0
            local integer id = GetPlayerId(p)
            local boolean canBuy = false
            local boolean hasMoney = true
            local Table counter = Table.create()

            if i != 0 and IsUnitInRange(Hero[id + 1], current[id], aoe) and stock[i.id] != 0 then
                if IsBuyable(i.id) then
                    set canBuy = true

                    set l = 0
                    loop
                        exitwhen l == CURRENCY_COUNT
                        set cost[l] = ItemPrices[i.id][l]

                        set l = l + 1
                    endloop

                    //determine if buyable and discount main item based off sum of components owned
                    if i.components > 0 then
                        loop
                            exitwhen j == i.components or not canBuy
                                set component = ShopItem.get(i.component[j])

                                if PlayerHasItemType(id + 1, component.id) and counter.integer[component.id] < PlayerCountItemType(id + 1, component.id) then
                                    //currency loop
                                    set l = 0
                                    loop
                                        exitwhen l == CURRENCY_COUNT

                                        set cost[l] = cost[l] - ItemPrices[component.id][l]

                                        set l = l + 1
                                    endloop
                                    set counter[component.id] = counter[component.id] + 1
                                else
                                    set canBuy = (has(component.id) and IsBuyable(component.id))
                                endif
                            set j = j + 1
                        endloop
                    endif

                    //currency loop
                    set l = 0
                    loop
                        exitwhen l == CURRENCY_COUNT

                        if GetCurrency(id + 1, l) < cost[l] then
                            set hasMoney = false
                            exitwhen true
                        endif

                        set l = l + 1
                    endloop

                    //special cases
                    //demon prince heart
                    if component.id == 'I04Q' then
                        set canBuy = HeartBlood[id + 1] >= 2000

                        if canBuy and hasMoney then
                            set HeartBlood[id + 1] = 0
                        endif
                    endif

                    if canBuy and hasMoney then
                        //currency loop
                        set l = 0
                        loop
                            exitwhen l == CURRENCY_COUNT

                            if cost[l] > 0 then
                                call AddCurrency(id + 1, l, - cost[l])
                            endif
                            //set t.currency[l] = cost[l]

                            set l = l + 1
                        endloop

                        set j = 0
                        set l = 0

                        //loop for each component - find owned components and either destroy or reduce charges
                        if i.components > 0 then
                            loop
                                exitwhen j == i.components
                                    set k = 0
                                    loop
                                        exitwhen k == INVENTORY_COUNT
                                            if Profile[id + 1].hero.items[k].id == i.component[j] and counter.integer[i.component[j]] > 0 then
                                                //call t.add(ShopItem.get(Profile[id + 1].hero.items[k].id))
                                                set l = Profile[id + 1].hero.items[k].charges

                                                if l > 1 then
                                                    set Profile[id + 1].hero.items[k].charge = Profile[id + 1].hero.items[k].charges - IMinBJ(l, counter.integer[i.component[j]])
                                                    if Profile[id + 1].hero.items[k].charges <= 0 then
                                                        call Profile[id + 1].hero.items[k].destroy()
                                                        set Profile[id + 1].hero.items[k] = 0
                                                    endif
                                                else
                                                    call Profile[id + 1].hero.items[k].destroy()
                                                    set Profile[id + 1].hero.items[k] = 0
                                                endif
                                                set counter[i.component[j]] = counter[i.component[j]] - l
                                                exitwhen true
                                            endif
                                        set k = k + 1
                                    endloop
                                set j = j + 1
                            endloop
                        endif

                        call PlayerAddItemById(id + 1, i.id)

                        if not GetSoundIsPlaying(success) then
                            call StartSoundForPlayerBJ(p, success)
                        endif

                        call buyer.inventory.show(id)
                        call details.refresh(p)

                        //reduce stock
                        if stock[i.id] != -1 then
                            set stock[i.id] = stock[i.id] - 1
                            call ShopSlot(table[this][i.id]).refresh(i)

                            //TODO timer to restock?
                        endif
                    else
                        if not hasMoney then
                            if not GetSoundIsPlaying(noGold[GetHandleId(GetPlayerRace(p))]) then
                                call StartSoundForPlayerBJ(p, noGold[GetHandleId(GetPlayerRace(p))])
                            endif
                        else
                            if not GetSoundIsPlaying(error) then
                                call StartSoundForPlayerBJ(p, error)
                            endif
                        endif
                    endif
                else
                    if not GetSoundIsPlaying(error) then
                        call StartSoundForPlayerBJ(p, error)
                    endif
                endif
            else
                if not GetSoundIsPlaying(error) then
                    call StartSoundForPlayerBJ(p, error)
                endif
            endif

            call counter.destroy()

            return (canBuy and hasMoney)
        endmethod

        //deprecated
        method sell takes ShopItem i, player p, integer slot returns boolean
            return true
        endmethod

        //deprecated
        method dismantle takes ShopItem i, player p, integer slot returns nothing
            return
        endmethod

        //deprecated
        method undo takes player p returns nothing
            return
        endmethod

        method scroll takes boolean down returns nothing
            local ShopSlot slot = first
            
            if (down and tail != last) or (not down and head != first) then
                loop
                    exitwhen slot == 0
                        if down then
                            call slot.move(slot.row - 1, slot.column)
                        else
                            call slot.move(slot.row + 1, slot.column)
                        endif

                        set slot.visible = slot.row >= 0 and slot.row <= rows - 1 and slot.column >= 0 and slot.column <= columns - 1

                        if slot.row == 0 and slot.column == 0 then
                            set head = slot
                        endif

                        if (slot.row == rows - 1 and slot.column == columns - 1) or (slot == last and slot.visible) then
                            set tail = slot
                        endif
                    set slot = slot.right
                endloop
            endif
        endmethod

        method filter takes integer categories, boolean andLogic returns nothing
            local ShopSlot slot = itempool[this][0]
            local string text = BlzFrameGetText(edit)
            local boolean process
            local integer i = -1

            set size = 0
            set first = 0
            set last = 0
            set head = 0
            set tail = 0

            loop
                exitwhen slot == 0
                    if andLogic then
                        set process = categories == 0 or BlzBitAnd(slot.item.categories, categories) >= categories
                    else
                        set process = categories == 0 or BlzBitAnd(slot.item.categories, categories) > 0
                    endif

                    if text != "" and text != null then
                        set process = process and find(StringCase(slot.item.name, false), StringCase(text, false))
                    endif

                    if process then
                        set i = i + 1
                        set size = size + 1
                        call slot.move(R2I(i/columns), ModuloInteger(i, columns))
                        set slot.visible = slot.row >= 0 and slot.row <= rows - 1 and slot.column >= 0 and slot.column <= columns - 1
                    
                        if i > 0 then
                            set slot.left = last
                            set last.right = slot
                        else
                            set first = slot
                            set head = first
                        endif

                        if slot.visible then
                            set tail = slot
                        endif

                        set last = slot
                    else
                        set slot.visible = false
                    endif
                set slot = slot.next
            endloop
        endmethod

        method select takes ShopItem i, player p returns nothing
            local integer id = GetPlayerId(p)

            if i != 0 and GetLocalPlayer() == p then
                if lastClicked[id] != 0 then
                    call Button(lastClicked[id]).display(null, 0, 0, 0, null, null, 0, 0)
                endif
                
                set lastClicked[id] = ShopSlot(table[this][i.id]).button
                call Button(lastClicked[id]).display(ITEM_HIGHLIGHT, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_SCALE, FRAMEPOINT_BOTTOMLEFT, FRAMEPOINT_BOTTOMLEFT, HIGHLIGHT_XOFFSET, HIGHLIGHT_YOFFSET)
            endif
        endmethod

        method detail takes ShopItem i, player p returns nothing
            if i != 0 then
                if GetLocalPlayer() == p then
                    set rows = DETAILED_ROWS
                    set columns = DETAILED_COLUMNS

                    if not detailed then
                        set detailed = true
                        call filter(category.active, category.andLogic)
                    endif
                endif

                call select(i, p)
                call details.show(i, p)
            else
                if GetLocalPlayer() == p then
                    set rows = ROWS
                    set columns = COLUMNS
                    set detailed  = false
                    set details.visible = false
                    call filter(category.active, category.andLogic)
                endif
            endif
        endmethod

        method has takes integer id returns boolean
            return table[this].has(id)
        endmethod

        private method find takes string source, string target returns boolean
            local integer sourceLength = StringLength(source)
            local integer targetLength = StringLength(target)
            local integer i = 0

            if targetLength <= sourceLength then
                loop
                    exitwhen i > sourceLength - targetLength
                        if SubString(source, i, i + targetLength) == target then
                            return true
                        endif
                    set i = i + 1
                endloop
            endif

            return false
        endmethod

        static method addCategory takes integer id, string icon, string description returns integer
            local thistype this = table[id][0]

            if this != 0 then
                return category.add(icon, description)
            endif

            return 0
        endmethod

        static method addItem takes integer id, integer itemId, integer categories returns nothing
            local thistype this = table[id][0]
            local ShopSlot slot
            local ShopItem i

            if this != 0 then
                if not table[this].has(itemId) then
                    set i = ShopItem.create(itemId, categories)
                    
                    if i != 0 then
                        set size = size + 1
                        set index = index + 1
                        set slot = ShopSlot.create(this, i, R2I(index/COLUMNS), ModuloInteger(index, COLUMNS))
                        set slot.visible = slot.row >= 0 and slot.row <= ROWS - 1 and slot.column >= 0 and slot.column <= COLUMNS - 1
                        set stock[itemId] = -1

                        if index > 0 then
                            set slot.prev = last
                            set slot.left = last
                            set last.next = slot
                            set last.right = slot
                        else
                            set first = slot
                            set head = slot
                        endif

                        if slot.visible then
                            set tail = slot
                        endif

                        set last = slot
                        set table[this][itemId] = slot
                        set itempool[this][index] = slot
                    else
                        call BJDebugMsg("Invalid item code: " + A2S(itemId))
                    endif
                else
                    call BJDebugMsg("The item " + GetObjectName(itemId) + " is already registered for the shop " + GetObjectName(id))
                endif
            endif
        endmethod

        static method create takes integer id, real aoe, real returnRate returns thistype
            local thistype this
            local User u = User.first

            if not table[id].has(0) then
                set this = thistype.allocate()
                set .id = id
                set .aoe = aoe
                set tax = returnRate
                set first = 0
                set last = 0
                set head = 0
                set tail = 0
                set size = 0
                set index = -1
                set rows = ROWS
                set columns = COLUMNS
                set count = count + 1
                set detailed = false
                set lastClicked = Table.create()
                set stock = Table.create()
                set base = BlzCreateFrame("EscMenuBackdrop", BlzGetFrameByName("ConsoleUIBackdrop", 0), 0, 0)
                set main = BlzCreateFrameByType("BUTTON", "main", base, "", 0)
                set edit = BlzCreateFrame("EscMenuEditBoxTemplate", main, 0, 0)
                set leftPanel = BlzCreateFrame("EscMenuBackdrop", base, 0, 0)
                //set rightPanel = BlzCreateFrame("EscMenuBackdrop", base, 0, 0)
                set category = Category.create(this)
                //set favorites = Favorites.create(this)
                set details = Detail.create(this)
                set buyer = Buyer.create(this)
                set close = Button.create(main, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, (WIDTH - 2*TOOLBAR_BUTTON_SIZE), 0.015000, true)
                set close.icon = CLOSE_ICON
                set close.onClick = function thistype.onClose
                set close.tooltip.text = "Close"
                //set break = Button.create(main, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, (WIDTH - 2*TOOLBAR_BUTTON_SIZE - 0.0205), 0.015000, true)
                //set break.icon = DISMANTLE_ICON
                //set break.onClick = function thistype.onDismantle
                //set break.tooltip.text = "Dismantle"
                //set revert = Button.create(main, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, (WIDTH - 2*TOOLBAR_BUTTON_SIZE - 0.0410), 0.015000, true)
                //set revert.icon = UNDO_ICON
                //set revert.onClick = function thistype.onUndo
                //set revert.tooltip.text = "Undo"
                set clearCategory = Button.create(leftPanel, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, 0.028000, 0.015000, true)
                set clearCategory.icon = CLEAR_ICON
                set clearCategory.onClick = function thistype.onClear
                set clearCategory.tooltip.text = "Clear Category"
                //set clearFavorites = Button.create(rightPanel, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, 0.027000, 0.015000, true)
                //set clearFavorites.icon = CLEAR_ICON
                //set clearFavorites.onClick = function thistype.onClear
                //set clearFavorites.tooltip.text = "Clear Favorites"
                set logic = Button.create(leftPanel, TOOLBAR_BUTTON_SIZE, TOOLBAR_BUTTON_SIZE, 0.049000, 0.015000, true)
                set logic.icon = LOGIC_ICON
                set logic.onClick = function thistype.onLogic
                set logic.enabled = false
                set logic.tooltip.text = "AND Logic"
                set table[id][0] = this
                set table[GetHandleId(main)][0] = this
                set table[GetHandleId(close.frame)][0] = this
                //set table[GetHandleId(break.frame)][0] = this
                //set table[GetHandleId(revert.frame)][0] = this
                set table[GetHandleId(clearCategory.frame)][0] = this
                //set table[GetHandleId(clearFavorites.frame)][0] = this
                set table[GetHandleId(logic.frame)][0] = this
                set table[GetHandleId(edit)][0] = this

                loop
                    exitwhen u == User.NULL
                        set timer[u.id - 1] = CreateTimer()
                        set group[u.id - 1] = CreateGroup()
                        set canScroll[u.id - 1] = true
                        set table[GetHandleId(u.toPlayer())][id] = this
                        set table[GetHandleId(u.toPlayer())][count] = id
                    set u = u.next
                endloop

                call BlzFrameSetAbsPoint(base, FRAMEPOINT_TOPLEFT, X, Y)
                call BlzFrameSetSize(base, WIDTH, HEIGHT)
                call BlzFrameSetPoint(main, FRAMEPOINT_TOPLEFT, base, FRAMEPOINT_TOPLEFT, 0.0000, 0.0000)
                call BlzFrameSetSize(main, WIDTH, HEIGHT)
                call BlzFrameSetPoint(edit, FRAMEPOINT_TOPLEFT, main, FRAMEPOINT_TOPLEFT, 0.021000, 0.020000)
                call BlzFrameSetSize(edit, EDIT_WIDTH, EDIT_HEIGHT)
                call BlzFrameSetPoint(leftPanel, FRAMEPOINT_TOPLEFT, base, FRAMEPOINT_TOPLEFT, -0.04800, 0.0000)
                call BlzFrameSetSize(leftPanel, SIDE_WIDTH, SIDE_HEIGHT)
                call BlzFrameSetPoint(rightPanel, FRAMEPOINT_TOPLEFT, base, FRAMEPOINT_TOPLEFT, (WIDTH - 0.027), 0.0000)
                call BlzFrameSetSize(rightPanel, SIDE_WIDTH, SIDE_HEIGHT)
                call BlzTriggerRegisterFrameEvent(trigger, main, FRAMEEVENT_MOUSE_WHEEL)
                call BlzTriggerRegisterFrameEvent(search, edit, FRAMEEVENT_EDITBOX_TEXT_CHANGED)

                set visible = false
            endif

            return this
        endmethod

        private static method onExpire takes nothing returns nothing
            set canScroll[GetPlayerId(GetLocalPlayer())] = true
        endmethod

        private static method onPeriod takes nothing returns nothing
            local thistype this
            local User u = User.first

            loop
                exitwhen u == User.NULL
                    set this = table[GetUnitTypeId(current[u.id - 1])][0]

                    if this != 0 then
                        call buyer.update(u.id - 1)
                    endif
                set u = u.next
            endloop
        endmethod

        private static method onSearch takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                if GetLocalPlayer() == GetTriggerPlayer() then
                    call filter(category.active, category.andLogic)
                endif
            endif
        endmethod

        private static method onLogic takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]

            if this != 0 then
                if GetLocalPlayer() == GetTriggerPlayer() then
                    set logic.enabled = not logic.enabled
                    set category.andLogic = not category.andLogic 

                    if category.andLogic then
                        set logic.tooltip.text = "AND Logic"
                    else
                        set logic.tooltip.text = "OR Logic"
                    endif

                    call filter(category.active, category.andLogic)
                endif

                call BlzFrameSetEnable(logic.frame, false)
                call BlzFrameSetEnable(logic.frame, true)
            endif
        endmethod

        private static method onClear takes nothing returns nothing
            local framehandle frame = BlzGetTriggerFrame()
            local thistype this = table[GetHandleId(frame)][0]

            if this != 0 then
                if frame == clearCategory.frame then
                    if GetLocalPlayer() == GetTriggerPlayer() then
                        call category.clear()
                    endif
                else
                    call favorites.clear(GetTriggerPlayer())
                endif

                call BlzFrameSetEnable(frame, false)
                call BlzFrameSetEnable(frame, true)
            endif

            set frame = null
        endmethod

        private static method onClose takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]
            local player p = GetTriggerPlayer()
            local integer id = GetPlayerId(p)

            if this != 0 then
                if GetLocalPlayer() == p then
                    set visible = false
                endif

                set current[id] = null
            endif

            set p = null
        endmethod

        //deprecated
        private static method onDismantle takes nothing returns nothing
            return
        endmethod

        //deprecated
        private static method onUndo takes nothing returns nothing
            return
        endmethod

        private static method onScroll takes nothing returns nothing
            local thistype this = table[GetHandleId(BlzGetTriggerFrame())][0]
            local integer i = GetPlayerId(GetLocalPlayer())

            if this != 0 then
                if GetLocalPlayer() == GetTriggerPlayer() then
                    if canScroll[i] then
                        if SCROLL_DELAY > 0 then
                            set canScroll[i] = false
                        endif
    
                        call scroll(BlzGetTriggerFrameValue() < 0)
                    endif
                endif
            endif

            if SCROLL_DELAY > 0 then
                call TimerStart(timer[i], TimerGetRemaining(timer[i]), false, function thistype.onExpire)
            endif
        endmethod

        private static method onSelect takes nothing returns nothing
            local thistype this = table[GetUnitTypeId(GetTriggerUnit())][0]
            local player p = GetTriggerPlayer()
            local integer id = GetPlayerId(p)

            if this != 0 then
                if GetLocalPlayer() == p then
                    set visible = GetTriggerEventId() == EVENT_PLAYER_UNIT_SELECTED
                endif

                if GetTriggerEventId() == EVENT_PLAYER_UNIT_SELECTED then
                    set current[id] = GetTriggerUnit()
                    if IsUnitInRange(Hero[id + 1], current[id], this.aoe) then
                        call buyer.inventory.show(id)
                    else
                        set buyer.visible = false
                    endif
                else
                    set current[id] = null
                endif
            endif

            set p = null
        endmethod

        private static method onKey takes nothing returns nothing
            set tag[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        endmethod

        private static method onEsc takes nothing returns nothing
            local thistype this
            local player p = GetTriggerPlayer()
            local integer id = GetPlayerId(p)

            set this = table[GetUnitTypeId(current[id])][0]

            if this != 0 then
                if GetLocalPlayer() == p then
                    set visible = false
                endif

                set current[id] = null
            endif

            set p = null
        endmethod

        private static method onInit takes nothing returns nothing
            local integer i = 0
            local integer id

            set table = HashTable.create()
            set itempool = HashTable.create()

            set success = CreateSound(SUCCESS_SOUND, false, false, false, 10, 10, "")
            call SetSoundDuration(success, 1600)
            set error = CreateSound(ERROR_SOUND, false, false, false, 10, 10, "")
            call SetSoundDuration(error, 614)
            set id = GetHandleId(RACE_HUMAN)
            set noGold[id] = CreateSound("Sound\\Interface\\Warning\\Human\\KnightNoGold1.wav", false, false, false, 10, 10, "")
            call SetSoundParamsFromLabel(noGold[id], "NoGoldHuman")
            call SetSoundDuration(noGold[id], 1618)
            set id = GetHandleId(RACE_ORC)
            set noGold[id] = CreateSound("Sound\\Interface\\Warning\\Orc\\GruntNoGold1.wav", false, false, false, 10, 10, "")
            call SetSoundParamsFromLabel(noGold[id], "NoGoldOrc")
            call SetSoundDuration(noGold[id], 1450)
            set id = GetHandleId(RACE_NIGHTELF)
            set noGold[id] = CreateSound("Sound\\Interface\\Warning\\NightElf\\SentinelNoGold1.wav", false, false, false, 10, 10, "")
            call SetSoundParamsFromLabel(noGold[id], "NoGoldNightElf")
            call SetSoundDuration(noGold[id], 1229)
            set id = GetHandleId(RACE_UNDEAD)
            set noGold[id] = CreateSound("Sound\\Interface\\Warning\\Undead\\NecromancerNoGold1.wav", false, false, false, 10, 10, "")
            call SetSoundParamsFromLabel(noGold[id], "NoGoldUndead")
            call SetSoundDuration(noGold[id], 2005)
            set id = GetHandleId(ConvertRace(11))
            set noGold[id] = CreateSound("Sound\\Interface\\Warning\\Naga\\NagaNoGold1.wav", false, false, false, 10, 10, "")
            call SetSoundParamsFromLabel(noGold[id], "NoGoldNaga")
            call SetSoundDuration(noGold[id], 2690)

            loop
                exitwhen i >= bj_MAX_PLAYER_SLOTS
                    set tag[i] = false
                    //call BlzTriggerRegisterPlayerKeyEvent(keyPress, Player(i), FAVORITE_KEY, 0, true)
                    //call BlzTriggerRegisterPlayerKeyEvent(keyPress, Player(i), FAVORITE_KEY, 0, false)
                    call TriggerRegisterPlayerEventEndCinematic(escPressed, Player(i))
                set i = i + 1
            endloop

            call BlzLoadTOCFile("Shop.toc")
            call TimerStart(update, UPDATE_PERIOD, true, function thistype.onPeriod)
            call TriggerAddAction(trigger, function thistype.onScroll)
            call TriggerAddCondition(search, Condition(function thistype.onSearch)) 
            //call TriggerAddCondition(keyPress, Condition(function thistype.onKey))
            call TriggerAddCondition(escPressed, Condition(function thistype.onEsc))
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SELECTED, function thistype.onSelect)
            call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DESELECTED, function thistype.onSelect)
        endmethod
    endstruct
endlibrary
