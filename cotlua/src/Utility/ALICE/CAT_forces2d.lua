if Debug then Debug.beginFile "CAT Forces2D" end ---@diagnostic disable: need-check-nil
do
    --[[
    =============================================================================================================================================================
                                                                Complementary ALICE Template
                                                                        by Antares

                                    Requires:
                                    ALICE                       https://www.hiveworkshop.com/threads/a-l-i-c-e-interaction-engine.353126/
                                    Data CAT
                                    Units CAT
                                    Interfaces CAT
                                    TotalInitialization         https://www.hiveworkshop.com/threads/total-initialization.317099/

    =============================================================================================================================================================
                                                                      F O R C E S   2 D
    =============================================================================================================================================================

    This is the simplified 2D version of the Forces CAT. It is recommended to only use either this or the 3D version.

    The forces library allows you to create interactions where objects are pushing or pulling other objects in the vicinity. A force can affect units and gizmos,
    but the source cannot be a unit. To enable a unit as the source of a force, create a class as the source of the force and anchor it to that unit. There are
    preset force functions packaged with this CAT that you can use, but you can also create your own force functions.

    To add a force to a class, use the corresponding AddForce function on your class on map initialization. The function will add the necessary entries to your
    class table to make the class instances a source of the force field. The AddForce functions modify the class's interaction tables. Make sure these changes 
    are preserved!
    
    To define your own force, you need to define three functions:
    
    InitFunc        This function is called when a pair is created for this force interaction. It can be used to precompute data and write it into the pair matrix.
    ForceFunc       This function determines the strength and direction of the force. It receives 8 input arguments:
                    (source, target, matrixData, distance, deltaX, deltaY, deltaVelocityX, deltaVelocityY). It returns two numbers: (forceX, forceY).
    IntervalFunc    This function determines the interaction interval of your force (the same as the ALICE interactionFunc interval). A lower interval makes the
                    force more accurate. It receives the same 8 input arguments and returns a number.

    The preset force functions can serve as a blueprint for your custom functions.

    =============================================================================================================================================================
                                                                L I S T   O F   F U N C T I O N S
    =============================================================================================================================================================

                        The pairsWith parameter is a string or a string sequence listing identifiers of objects that the force should affect.

    CAT_AddGravity2D(gizmo, pairsWith)                                      A long-range attraction that gets stronger as objects move closer together. Uses the
                                                                            mass field to determine the force strength.
    CAT_AddPressure2D(gizmo, pairsWith)                                     Pushes nearby objects away. The strength is determined by the .pressureStrength field.
                                                                            The coupling strength with objects is based on the .collisionRadius in the case of
                                                                            gizmos, and the collision radius and height in the case of units. The field
                                                                            .pressureMaxRange determines the maximum range of the force. The force will drop
                                                                            gradually until it hits zero at that range.
    CAT_AddWindField2D(gizmo, pairsWith)                                    A force that pushes objects into a certain direction. The .windFieldDensity field
                                                                            determines the strength of the wind field. The .windFieldSpeed field determines the
                                                                            speed of the wind, the field .windFieldAngle the direction of the wind. The 
                                                                            .windFieldMaxRange field determines the radius of the field. The wind density will
                                                                            drop gradually until it hits zero at that range.
    CAT_AddForce2D(gizmo, pairsWith, initFunc, forceFunc, intervalFunc)     Add a custom force to the gizmo.

    =============================================================================================================================================================
                                                                        C O N F I G
    =============================================================================================================================================================
    ]]

    --Multiplies the forces on a unit (compared to a gizmo) by this factor.
    local FORCE_UNIT_MULTIPLIER             = 0.5           ---@type number

    --Determines the strength of gravity.
    local GRAVITY_STRENGTH                  = 50000           ---@type number

    --Determines how often the force fields are updated for gravity. A greater accuracy requires more calculations. Use debug mode to gauge the appropriate accuracy.
    local GRAVITY_ACCURACY                  = 10            ---@type number

    --Avoids infinities by making the gravity strength not increase further when objects move closer to each other than this value. Can be overwritten with the
    --.minDistance field.
    local DEFAULT_GRAVITY_MIN_DISTANCE      = 128           ---@type number

    --Determines how often the force fields are updated for the pressure force. A greater accuracy requires more calculations. Use debug mode to gauge the
    --appropriate accuracy.
    local PRESSURE_ACCURACY                 = 0.05          ---@type number

    --Determines how often the force fields are updated for the wind force. A greater accuracy requires more calculations. Use debug mode to gauge the appropriate
    --accuracy.
    local WIND_FIELD_ACCURACY               = 2.0           ---@type number

    --===========================================================================================================================================================

    local sqrt                      = math.sqrt
    local cos                       = math.cos
    local sin                       = math.sin
    
    local INTERVAL                  = nil
    local unitForce                 = {}
    local Force2D                   = nil                   ---@type function

    local SPHERE_CROSS_SECTION      = 4 - 8/bj_PI
    local CYLINDER_CROSS_SECTION    = 2/bj_PI

    ---@class forceMatrix
    local forceMatrix = {
        Fx = 0,
        Fy = 0,
        Fxdt = 0,
        Fydt = 0,
        lastUpdate = nil,
        doUserInit = true
    }

    forceMatrix.__index = forceMatrix

    local function GetObjectCrossSection(object)
        if type(object) == "table" then
            if object.collisionRadius then
                return SPHERE_CROSS_SECTION*object.collisionRadius
            elseif object.anchor then
                if type(object.anchor) == "table" then
                    return SPHERE_CROSS_SECTION*object.anchor.collisionRadius
                elseif HandleType[object.anchor] == "unit" then
                    local collisionSize = BlzGetUnitCollisionSize(object.anchor)
                    return CYLINDER_CROSS_SECTION*collisionSize*(CAT_Data.WIDGET_TYPE_HEIGHT[GetUnitTypeId(object.anchor)] or CAT_Data.DEFAULT_UNIT_HEIGHT_FACTOR*collisionSize)
                else
                    return 0
                end
            else
                return 0
            end
        elseif HandleType[object] == "unit" then
            local collisionSize = BlzGetUnitCollisionSize(object)
            return CYLINDER_CROSS_SECTION*collisionSize*(CAT_Data.WIDGET_TYPE_HEIGHT[GetUnitTypeId(object)] or CAT_Data.DEFAULT_UNIT_HEIGHT_FACTOR*collisionSize)
        else
            return 0
        end
    end

    --===========================================================================================================================================================
    --2D Force Functions
    --===========================================================================================================================================================

    local function InitAccelerateGizmo2D(gizmo)
        gizmo.multiplier = INTERVAL/CAT_GetObjectMass(gizmo)
        if gizmo.multiplier == math.huge then
            error("Attempting to apply force to object for which no mass was assigned.")
        end
    end

    local function AccelerateGizmo2D(gizmo)
        if gizmo.Fx == 0 and gizmo.Fy == 0 then
            ALICE_PairPause()
            return
        end
        if gizmo.anchor then
            if type(gizmo.anchor) == "table" then
                gizmo.anchor.vx =  gizmo.anchor.vx + gizmo.Fx*gizmo.multiplier
                gizmo.anchor.vy =  gizmo.anchor.vy + gizmo.Fy*gizmo.multiplier
            else
                CAT_Knockback(gizmo.anchor, gizmo.Fx*gizmo.multiplier, gizmo.Fy*gizmo.multiplier, 0)
            end
        else
            gizmo.vx = gizmo.vx + gizmo.Fx*gizmo.multiplier
            gizmo.vy = gizmo.vy + gizmo.Fy*gizmo.multiplier
        end
        gizmo.Fx = gizmo.Fx + gizmo.Fxdt*INTERVAL
        gizmo.Fy = gizmo.Fy + gizmo.Fydt*INTERVAL
    end

    local function ResumForceCallback2D(source, target, forceTable)
        local data = ALICE_PairLoadData(forceMatrix)
        forceTable.Fx = forceTable.Fx + data.Fx
        forceTable.Fy = forceTable.Fy + data.Fy
        forceTable.Fxdt = forceTable.Fxdt + data.Fxdt
        forceTable.Fydt = forceTable.Fydt + data.Fydt
    end

    local function ResumForceGizmo2D(gizmo)
        gizmo.Fx, gizmo.Fy = 0, 0
        gizmo.Fxdt, gizmo.Fydt = 0, 0
        ALICE_ForAllPairsDo(ResumForceCallback2D, gizmo, Force2D, false, nil, gizmo)
        if gizmo.Fx == 0 and gizmo.Fy == 0 then
            ALICE_PairPause()
        end
        return 5.0
    end

    local function ClearUnitForce(unit, __, __)
        unitForce[unit] = nil
    end

    local function InitAccelerateUnit2D(unit)
        local data = ALICE_PairLoadData(forceMatrix)
        data.multiplier = INTERVAL/CAT_GetObjectMass(unit)
        if data.multiplier == math.huge then
            error("Attempting to apply force to unit with no mass.")
        end
    end

    local function AccelerateUnit2D(unit)
        local data = ALICE_PairLoadData(forceMatrix)
        local forceTable = unitForce[unit]
        if not forceTable or (forceTable.Fx == 0 and forceTable.Fy == 0) then
            ALICE_PairPause()
            return
        end
        CAT_Knockback(unit, forceTable.Fx*data.multiplier, forceTable.Fy*data.multiplier, 0)
        forceTable.Fx = forceTable.Fx + forceTable.Fxdt*INTERVAL
        forceTable.Fy = forceTable.Fy + forceTable.Fydt*INTERVAL
    end

    local function ResumForceUnit2D(unit)
        local forceTable = unitForce[unit]
        if forceTable == nil then
            ALICE_PairPause()
            return 5.0
        end
        forceTable.Fx, forceTable.Fy = 0, 0
        forceTable.Fxdt, forceTable.Fydt = 0, 0
        ALICE_ForAllPairsDo(ResumForceCallback2D, unit, Force2D, false, nil, forceTable)
        if forceTable.Fx == 0 and forceTable.Fy == 0 then
            ALICE_PairPause()
        end
        return 5.0
    end

    --===========================================================================================================================================================

    local function ClearForce2D(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        local FxOld = data.Fx + data.Fxdt*(ALICE_TimeElapsed - data.lastUpdate)
        local FyOld = data.Fy + data.Fydt*(ALICE_TimeElapsed - data.lastUpdate)
        local FxdtOld = data.Fxdt
        local FydtOld = data.Fydt

        local forceTable
        if data.targetIsGizmo then
            forceTable = target
        else
            forceTable = unitForce[target]
        end
        
        if forceTable then
            forceTable.Fx = forceTable.Fx - FxOld
            forceTable.Fy = forceTable.Fy - FyOld
            forceTable.Fxdt = forceTable.Fxdt - FxdtOld
            forceTable.Fydt = forceTable.Fydt - FydtOld
        end
    end

    local function InitForce2D(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        data.lastUpdate = ALICE_TimeElapsed
        data.targetIsGizmo = type(target) == "table"
        if data.targetIsGizmo then
            data.typeMultiplier = 1
            if target.Fx == nil then
                ALICE_AddSelfInteraction(target, AccelerateGizmo2D)
                ALICE_AddSelfInteraction(target, ResumForceGizmo2D)
                target.Fx, target.Fy = 0, 0
                target.Fxdt, target.Fydt = 0, 0
            end
        elseif HandleType[target] == "unit" then
            data.typeMultiplier = FORCE_UNIT_MULTIPLIER
            if unitForce[target] == nil then
                unitForce[target] = {}
                local forceTable = unitForce[target]
                ALICE_AddSelfInteraction(target, AccelerateUnit2D)
                ALICE_AddSelfInteraction(target, ResumForceUnit2D)
                forceTable.Fx, forceTable.Fy = 0, 0
                forceTable.Fxdt, forceTable.Fydt = 0, 0
            end
        end
    end

    Force2D = function(source, target)
        local data = ALICE_PairLoadData(forceMatrix)

        if data.doUserInit then
            if source.initForceFunc then
                source.initForceFunc(source, target)
            end
            data.doUserInit = false
        end

        local xf, yf, xo, yo = ALICE_PairGetCoordinates2D()
        local vxf, vyf = CAT_GetObjectVelocity2D(source)
        local vxo, vyo = CAT_GetObjectVelocity2D(target)
        local dx, dy = xf - xo, yf - yo
        local dvx, dvy = vxf - vxo, vyf - vyo
        local dist = sqrt(dx*dx + dy*dy)

        local forceX, forceY = source.forceFunc(source, target, data, dist, dx, dy, dvx, dvy)

        local interval = (source.intervalFunc(source, target, data, dist, dx, dy, dvx, dvy) / INTERVAL + 1)*INTERVAL
        if interval > ALICE_Config.MAX_INTERVAL then
            interval = ALICE_Config.MAX_INTERVAL
        end

        --Force at next step.
        local dxNS = dx + 0.5*dvx*interval
        local dyNS = dy + 0.5*dvy*interval
        local distNS = sqrt(dxNS*dxNS + dyNS*dyNS)

        local forceXNS, forceYNS = source.forceFunc(source, target, data, distNS, dxNS, dyNS, dvx, dvy)

        local forceXdt = 2*(forceXNS - forceX)/interval
        local forceYdt = 2*(forceYNS - forceY)/interval

        local lastInterval = (ALICE_TimeElapsed - data.lastUpdate)

        local forceTable
        if data.targetIsGizmo then
            forceTable = target
        else
            forceTable = unitForce[target]
        end

        local FxOld = data.Fx + data.Fxdt*lastInterval
        local FyOld = data.Fy + data.Fydt*lastInterval

        if forceTable.Fx == 0 and forceTable.Fy == 0 and (forceX ~= 0 or forceY ~= 0) then
            ALICE_Unpause(target)
        end

        forceTable.Fxdt = forceTable.Fxdt + forceXdt - data.Fxdt
        forceTable.Fydt = forceTable.Fydt + forceYdt - data.Fydt

        forceTable.Fx = forceTable.Fx + forceX - FxOld
        forceTable.Fy = forceTable.Fy + forceY - FyOld

        data.Fx, data.Fy = forceX, forceY
        data.Fxdt, data.Fydt = forceXdt, forceYdt

        data.lastUpdate = ALICE_TimeElapsed
        return interval
    end

    --===========================================================================================================================================================
    --Gravity
    --===========================================================================================================================================================

    local function InitGravity(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        local massSource = CAT_GetObjectMass(source)
        local massTarget = CAT_GetObjectMass(target)
        data.strength = massSource*massTarget*(GRAVITY_STRENGTH*1.0001)*data.typeMultiplier --1.0001 to convert to float to avoid integer overflow
        data.minDistance = source.minDistance or DEFAULT_GRAVITY_MIN_DISTANCE
        data.intervalFactor = 1/(GRAVITY_ACCURACY*data.strength/massTarget)
        if data.strength == 0 then
            ALICE_PairDisable()
        end
    end

    local function InitGravityEnemy(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        local massSource = CAT_GetObjectMass(source)
        local massTarget = CAT_GetObjectMass(target)
        data.strength = massSource*massTarget*(GRAVITY_STRENGTH*1.0001)*data.typeMultiplier --1.0001 to convert to float to avoid integer overflow
        data.minDistance = source.minDistance or DEFAULT_GRAVITY_MIN_DISTANCE
        data.intervalFactor = 1/(GRAVITY_ACCURACY*data.strength/massTarget)
        if data.strength == 0 or ALICE_PairIsFriend() then
            ALICE_PairDisable()
        end
    end

    local function GravityForce2D(source, target, data, dist, dx, dy, dvx, dvy)
        if data.minDistance > dist then
            dist = data.minDistance
        end
        local factor = data.strength/dist^3
        return dx*factor, dy*factor
    end

    local function GravityInterval2D(source, target, data, dist, dx, dy, dvx, dvy)
        --Increased update frequency when objects are moving towards each other.
        local vdotd = -(dvx*dx + dvy*dy)
        if vdotd < 0 then
            vdotd = 0
        end
        return dist*dist*data.intervalFactor/(1 + vdotd*data.intervalFactor)
    end

    --===========================================================================================================================================================
    --Pressure Force
    --===========================================================================================================================================================

    local function InitPressureForce(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        data.strengthFactor = GetObjectCrossSection(target)*data.typeMultiplier
        data.intervalFactor = CAT_GetObjectMass(target)/(PRESSURE_ACCURACY*data.strengthFactor)
        if data.strengthFactor*source.pressureStrength == 0 then
            ALICE_PairDisable()
        end
    end

    local function PressureForce2D(source, target, data, dist, dx, dy, dvx, dvy)
        if dist > source.pressureMaxRange then
            return 0, 0
        end
        local factor = -source.pressureStrength*data.strengthFactor*(source.pressureMaxRange - dist)/(source.pressureMaxRange*dist)
        return dx*factor, dy*factor
    end

    local function PressureInterval2D(source, target, data, dist, dx, dy, dvx, dvy)
        --Increased update frequency when objects are moving towards each other.
        local vdivd = -(dvx*dx + dvy*dy)/dist^2
        if vdivd < 0 then
            vdivd = 0
        end
        local interval = (0.15 + 0.85*(dist/source.pressureMaxRange))*data.intervalFactor/source.pressureStrength
        return interval/(1 + vdivd*interval)
    end

    --===========================================================================================================================================================
    --Windfield Force
    --===========================================================================================================================================================

    local function InitWindField(source, target)
        local data = ALICE_PairLoadData(forceMatrix)
        data.strengthFactor = GetObjectCrossSection(target)*data.typeMultiplier/1000
        data.intervalFactor = CAT_GetObjectMass(target)/(WIND_FIELD_ACCURACY*data.strengthFactor)
        data.vx = source.windFieldSpeed*cos(source.windFieldAngle)
        data.vy = source.windFieldSpeed*sin(source.windFieldAngle)

        if data.strengthFactor*source.windFieldDensity == 0 then
            ALICE_PairDisable()
        end
    end

    local function WindForce2D(source, target, data, dist, dx, dy, dvx, dvy)
        if dist > source.windFieldMaxRange then
            return 0, 0
        end
        local dvxWind = dvx + data.vx
        local dvyWind = dvy + data.vy
        local dvWindTotal = sqrt(dvxWind*dvxWind + dvyWind*dvyWind)
        local factor = dvWindTotal*source.windFieldDensity*data.strengthFactor*(source.windFieldMaxRange - dist)/(source.windFieldMaxRange*dist)
        return dvxWind*factor, dvyWind*factor
    end

    local function WindFieldInterval2D(source, target, data, dist, dx, dy, dvx, dvy)
        --Increased update frequency when objects are moving towards each other.
        local vdivd = -(dvx*dx + dvy*dy)/dist^2
        if vdivd < 0 then
            vdivd = 0
        end
        --Arbitrary numbers
        local interval = (0.15 + 0.85*(dist/source.windFieldMaxRange))*data.intervalFactor/source.windFieldDensity
        return interval/(1 + vdivd*interval)
    end

    --===========================================================================================================================================================
    --API
    --===========================================================================================================================================================                       

    ---Add a custom force to the gizmo.
    ---@param class table
    ---@param interactsWith table | string
    ---@param initFunc function
    ---@param forceFunc function
    ---@param intervalFunc function
    function CAT_AddForce2D(class, interactsWith, initFunc, forceFunc, intervalFunc)
        class.initForceFunc = initFunc
        class.forceFunc = forceFunc
        class.intervalFunc = intervalFunc

        if class.interactions == nil then
            class.interactions = {}
        end

        if type(interactsWith) == "table" then
            for __, id in pairs(interactsWith) do
                class.interactions[id] = Force2D
            end
        else
            class.interactions[interactsWith] = Force2D
        end
    end

    ---A long-range attraction that gets stronger as objects move closer together. Uses the mass field to determine the force strength.
    ---@param class table
    ---@param interactsWith table | string
    ---@param enemy boolean?
    function CAT_AddGravity2D(class, interactsWith, enemy)
        CAT_AddForce2D(class, interactsWith, enemy and InitGravityEnemy or InitGravity, GravityForce2D, GravityInterval2D)
        if class.range then
            class.radius = class.range
        else
            class.hasInfiniteRange = true
        end
    end

    ---Pushes nearby objects away. The strength is determined by the .pressureStrength field. The coupling strength with objects is based on the .collisionRadius in the case of gizmos, and the collision radius and height in the case of units. The field .pressureMaxRange determines the maximum range of the force. The force will drop gradually until it hits zero at that range.
    ---@param class table
    ---@param interactsWith table | string
    function CAT_AddPressure2D(class, interactsWith)
        CAT_AddForce2D(class, interactsWith, InitPressureForce, PressureForce2D, PressureInterval2D)
        class.radius = math.max(class.radius or ALICE_Config.DEFAULT_OBJECT_RADIUS, class.pressureMaxRange)
    end

    ---A force that pushes objects into a certain direction. The .windFieldDensity field determines the strength of the wind field. The .windFieldSpeed field determines the speed of the wind, the field .windFieldAngle the direction of the wind. The .windFieldMaxRange field determines the radius of the field. The wind density will drop gradually until it hits zero at that range.
    ---@param class table
    ---@param interactsWith table | string
    function CAT_AddWindField2D(class, interactsWith)
        CAT_AddForce2D(class, interactsWith, InitWindField, WindForce2D, WindFieldInterval2D)
        class.radius = math.max(class.radius or ALICE_Config.DEFAULT_OBJECT_RADIUS, class.windFieldMaxRange)
    end

    --===========================================================================================================================================================

    local function InitForcesCAT()
        Require "CAT_Data"
        Require "CAT_Units"
        Require "CAT_Interfaces"
        INTERVAL = ALICE_Config.MIN_INTERVAL
        ALICE_FuncSetInit(AccelerateGizmo2D, InitAccelerateGizmo2D)
        ALICE_FuncSetInit(AccelerateUnit2D, InitAccelerateUnit2D)
        ALICE_FuncSetInit(Force2D, InitForce2D)
        ALICE_FuncDistribute(ResumForceGizmo2D, 5.0)
        ALICE_FuncDistribute(ResumForceUnit2D, 5.0)
        ALICE_FuncSetOnBreak(Force2D, ClearForce2D)
        ALICE_FuncSetOnDestroy(AccelerateUnit2D, ClearUnitForce)
        ALICE_FuncSetName(AccelerateGizmo2D, "AccelerateGizmo2D")
        ALICE_FuncSetName(ResumForceGizmo2D, "ResumForceGizmo2D")
        ALICE_FuncSetName(AccelerateUnit2D, "AccelerateUnit2D")
        ALICE_FuncSetName(ResumForceUnit2D, "ResumForceUnit2D")
        ALICE_FuncSetName(Force2D, "Force2D")
    end

    OnInit.final("CAT_Forces2D", InitForcesCAT)

end