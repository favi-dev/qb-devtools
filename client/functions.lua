local QBCore = exports['qb-core']:GetCoreObject()

-- Utility Functions for Developer Tools

-- Get current player position formatted as a string
function GetFormattedCoords()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    return {
        x = string.format("%.2f", coords.x),
        y = string.format("%.2f", coords.y),
        z = string.format("%.2f", coords.z),
        h = string.format("%.2f", heading)
    }
end

-- Copy coordinates to clipboard with specified format
function CopyCoords(format)
    local coords = GetFormattedCoords()
    local coordString = ""
    
    if format == "vector3" then
        coordString = string.format("vector3(%s, %s, %s)", coords.x, coords.y, coords.z)
    elseif format == "vector4" then
        coordString = string.format("vector4(%s, %s, %s, %s)", coords.x, coords.y, coords.z, coords.h)
    elseif format == "table" then
        coordString = string.format("{ x = %s, y = %s, z = %s, h = %s }", coords.x, coords.y, coords.z, coords.h)
    elseif format == "simple" then
        coordString = string.format("%s, %s, %s, %s", coords.x, coords.y, coords.z, coords.h)
    end
    
    -- Send to NUI to copy to clipboard
    SendNUIMessage({
        action = "copyToClipboard",
        data = coordString
    })
    
    QBCore.Functions.Notify(Lang:t("info.coordinates_copied"), "success")
    return coords
end

-- Get entity information that player is looking at
function GetTargetEntityInfo()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local result, entity = RayCastGamePlayCamera(1000.0)
    
    if not result then return nil end
    
    local entityType = GetEntityType(entity)
    local entityTypeName = "Unknown"
    local entityHash = GetEntityModel(entity)
    local entityHashHex = string.format("0x%08X", entityHash)
    local entityCoords = GetEntityCoords(entity)
    
    if entityType == 1 then
        entityTypeName = "Ped"
    elseif entityType == 2 then
        entityTypeName = "Vehicle"
    elseif entityType == 3 then
        entityTypeName = "Object"
    end
    
    local entityInfo = {
        handle = entity,
        hash = entityHash,
        hashHex = entityHashHex,
        type = entityTypeName,
        coords = {
            x = string.format("%.2f", entityCoords.x),
            y = string.format("%.2f", entityCoords.y),
            z = string.format("%.2f", entityCoords.z)
        },
        distance = string.format("%.2f", #(coords - entityCoords)),
        health = GetEntityHealth(entity),
        netId = NetworkGetNetworkIdFromEntity(entity),
        owner = NetworkGetEntityOwner(entity)
    }
    
    -- Add type-specific information
    if entityType == 1 then -- Ped
        entityInfo.model = GetPedModelNameFromHash(entityHash)
        entityInfo.isPlayer = IsPedAPlayer(entity)
    elseif entityType == 2 then -- Vehicle
        entityInfo.model = GetDisplayNameFromVehicleModel(entityHash)
        entityInfo.plate = GetVehicleNumberPlateText(entity)
        entityInfo.class = GetVehicleClassName(GetVehicleClass(entity))
    elseif entityType == 3 then -- Object
        entityInfo.model = entityHash
    end
    
    return entityInfo
end

-- RayCast from gameplay camera
function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, hit, endCoords, _, entityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
    return hit, entityHit, endCoords
end

-- Convert rotation to direction vector
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    
    return direction
end

-- Get ped model name from hash
function GetPedModelNameFromHash(hash)
    for _, model in ipairs({ 
        "mp_m_freemode_01", "mp_f_freemode_01", 
        "a_c_boar", "a_c_cat_01", "a_c_chickenhawk", "a_c_chimp", "a_c_chop",
        "a_c_cormorant", "a_c_cow", "a_c_coyote", "a_c_crow", "a_c_deer", "a_c_fish",
        "a_c_hen", "a_c_husky", "a_c_mtlion", "a_c_pig", "a_c_pigeon", "a_c_rat",
        "a_c_retriever", "a_c_rhesus", "a_c_rottweiler", "a_c_seagull", "a_c_sharktiger",
        "a_c_shepherd", "a_f_m_beach_01", "a_f_m_bevhills_01", "a_f_m_bevhills_02",
        "a_f_m_bodybuild_01", "a_f_m_business_02", "a_f_m_downtown_01", "a_f_m_eastsa_01",
        "a_f_m_eastsa_02", "a_f_m_fatbla_01", "a_f_m_fatwhite_01", "a_f_m_ktown_01",
        "a_f_m_salton_01", "a_f_m_skidrow_01", "a_f_m_soucent_01", "a_f_m_soucent_02",
        "a_f_m_tourist_01", "a_f_m_trampbeac_01", "a_f_o_genstreet_01", "a_f_o_indian_01",
        "a_f_o_ktown_01", "a_f_o_salton_01", "a_f_o_soucent_01", "a_f_o_soucent_02",
        "a_f_y_beach_01", "a_f_y_bevhills_01", "a_f_y_bevhills_02", "a_f_y_bevhills_03",
        "a_f_y_bevhills_04", "a_f_y_business_01", "a_f_y_business_02", "a_f_y_business_03",
        "a_f_y_business_04", "a_f_y_eastsa_01", "a_f_y_eastsa_02", "a_f_y_eastsa_03",
        "a_f_y_epsilon_01", "a_f_y_fitness_01", "a_f_y_fitness_02", "a_f_y_genhot_01",
        "a_f_y_golfer_01", "a_f_y_hiker_01", "a_f_y_hippie_01", "a_f_y_hipster_01",
        "a_f_y_hipster_02", "a_f_y_hipster_03", "a_f_y_hipster_04", "a_f_y_indian_01",
        "a_f_y_juggalo_01", "a_f_y_runner_01", "a_f_y_rurmeth_01", "a_f_y_scdressy_01",
        "a_f_y_skater_01", "a_f_y_soucent_01", "a_f_y_soucent_02", "a_f_y_soucent_03",
        "a_f_y_tennis_01", "a_f_y_topless_01", "a_f_y_tourist_01", "a_f_y_tourist_02",
        "a_f_y_vinewood_01", "a_f_y_vinewood_02", "a_f_y_vinewood_03", "a_f_y_vinewood_04",
        "a_f_y_yoga_01", "a_m_m_acult_01", "a_m_m_afriamer_01", "a_m_m_beach_01",
        "a_m_m_beach_02", "a_m_m_bevhills_01", "a_m_m_bevhills_02", "a_m_m_business_01",
        "a_m_m_eastsa_01", "a_m_m_eastsa_02", "a_m_m_farmer_01", "a_m_m_fatlatin_01",
        "a_m_m_genfat_01", "a_m_m_genfat_02", "a_m_m_golfer_01", "a_m_m_hasjew_01",
        "a_m_m_hillbilly_01", "a_m_m_hillbilly_02", "a_m_m_indian_01", "a_m_m_ktown_01"
    }) do
        if GetHashKey(model) == hash then
            return model
        end
    end
    
    return string.format("Unknown (Hash: %d)", hash)
end

-- Get vehicle class name from class ID
function GetVehicleClassName(classId)
    local classes = {
        [0] = "Compact",
        [1] = "Sedan",
        [2] = "SUV",
        [3] = "Coupe",
        [4] = "Muscle",
        [5] = "Sport Classic",
        [6] = "Sport",
        [7] = "Super",
        [8] = "Motorcycle",
        [9] = "Off-road",
        [10] = "Industrial",
        [11] = "Utility",
        [12] = "Van",
        [13] = "Cycle",
        [14] = "Boat",
        [15] = "Helicopter",
        [16] = "Plane",
        [17] = "Service",
        [18] = "Emergency",
        [19] = "Military",
        [20] = "Commercial",
        [21] = "Train"
    }
    
    return classes[classId] or "Unknown"
end

-- Teleport player to coordinates
function TeleportToCoordinates(x, y, z, h)
    local playerPed = PlayerPedId()
    local teleportCoords = vector3(tonumber(x), tonumber(y), tonumber(z))
    
    -- Request collision at the coordinate
    RequestCollisionAtCoord(teleportCoords.x, teleportCoords.y, teleportCoords.z)
    
    -- Set the entity coordinates and heading
    SetEntityCoords(playerPed, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, true)
    
    -- Set heading if provided
    if h then
        SetEntityHeading(playerPed, tonumber(h))
    end
    
    -- Wait for collision to load
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Wait(100)
    end
    
    QBCore.Functions.Notify(Lang:t("success.teleported"), "success")
end

-- Execute Lua code safely
function ExecuteLuaCode(code)
    local result, errorMsg
    
    if not Config.Features.LuaExecution.Enabled then
        return false, Lang:t("error.no_permission")
    end
    
    -- Check for restricted functions
    for _, funcName in ipairs(Config.Features.LuaExecution.RestrictedFunctions) do
        if string.find(code, funcName) then
            return false, Lang:t("error.restricted_function")
        end
    end
    
    -- Create a safe environment
    local env = {
        QBCore = QBCore,
        vector3 = vector3,
        vector4 = vector4,
        PlayerPedId = PlayerPedId,
        GetEntityCoords = GetEntityCoords,
        Wait = Wait,
        CreateThread = CreateThread,
        TriggerEvent = TriggerEvent,
        print = print,
        tostring = tostring,
        tonumber = tonumber,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        string = string,
        math = math,
        table = table,
    }
    
    -- Set environment metatable to access _G in a controlled way
    setmetatable(env, {
        __index = function(t, k)
            if _G[k] ~= nil then
                -- Check if the function is in the restricted list
                for _, funcName in ipairs(Config.Features.LuaExecution.RestrictedFunctions) do
                    if k == funcName or (type(_G[k]) == "table" and funcName:find(_G[k])) then
                        return nil
                    end
                end
                return _G[k]
            end
        end
    })
    
    -- Add a prefix to the code to capture its return value
    local wrappedCode = "local result = function() " .. code .. " end; return result()"
    
    -- Compile the code
    local func, compileErr = load(wrappedCode, "DevTools", "t", env)
    if not func then
        return false, "Compilation error: " .. compileErr
    end
    
    -- Run with pcall to catch errors
    local success, funcResult = pcall(func)
    if not success then
        return false, "Execution error: " .. funcResult
    end
    
    return true, funcResult or "Code executed successfully (no return value)"
end

-- Monitor Events
local monitoredEvents = {}

function StartEventMonitoring()
    if isMonitoringEvents then return end
    isMonitoringEvents = true
    
    QBCore.Functions.Notify(Lang:t("info.event_monitoring_started"), "primary")
    
    -- Clear previous events
    monitoredEvents = {}
    
    -- Create a large table of common events to monitor
    local eventsToMonitor = {
        -- QBCore events
        "QBCore:Client:OnPlayerLoaded",
        "QBCore:Client:OnPlayerUnload",
        "QBCore:Client:OnJobUpdate",
        "QBCore:Client:OnGangUpdate",
        "QBCore:Client:OnMoneyChange",
        "QBCore:Client:OnPlayerData",
        
        -- General gameplay events
        "baseevents:onPlayerDied",
        "baseevents:onPlayerKilled",
        "baseevents:onPlayerWasted",
        "baseevents:enteredVehicle",
        "baseevents:leftVehicle",
        
        -- Custom events to monitor (example)
        "inventory:client:ItemBox",
        "hud:client:UpdateNeeds",
        "police:client:SignalReceived",
        
        -- Add more events as needed
    }
    
    -- Register handler for each event
    for _, eventName in ipairs(eventsToMonitor) do
        -- Skip blacklisted events
        local isBlacklisted = false
        for _, blacklisted in ipairs(Config.Features.EventMonitoring.BlacklistedEvents) do
            if eventName == blacklisted then
                isBlacklisted = true
                break
            end
        end
        
        if not isBlacklisted then
            RegisterNetEvent(eventName)
            AddEventHandler(eventName, function(...)
                RecordEvent(eventName, "client", {...})
            end)
        end
    end
end

function StopEventMonitoring()
    if not isMonitoringEvents then return end
    isMonitoringEvents = false
    
    QBCore.Functions.Notify(Lang:t("info.event_monitoring_stopped"), "primary")
    
    -- Note: We can't actually remove event handlers in FiveM
    -- But we can stop recording them
end

function RecordEvent(eventName, source, args)
    if not isMonitoringEvents then return end
    
    -- Add event to the monitored events table
    table.insert(monitoredEvents, {
        name = eventName,
        source = source,
        args = args,
        time = os.date("%H:%M:%S")
    })
    
    -- Limit the number of events stored
    if #monitoredEvents > Config.Features.EventMonitoring.MaxEventsHistory then
        table.remove(monitoredEvents, 1)
    end
    
    -- Update UI with new event
    if isDevToolsOpen then
        SendNUIMessage({
            action = "updateEventMonitoring",
            data = {
                events = monitoredEvents
            }
        })
    end
end

function GetMonitoredEvents()
    return monitoredEvents
end

-- Export functions
exports('CopyCoords', CopyCoords)
exports('GetTargetEntityInfo', GetTargetEntityInfo)
exports('TeleportToCoordinates', TeleportToCoordinates)
exports('ExecuteLuaCode', ExecuteLuaCode)
exports('StartEventMonitoring', StartEventMonitoring)
exports('StopEventMonitoring', StopEventMonitoring)
exports('GetMonitoredEvents', GetMonitoredEvents)
