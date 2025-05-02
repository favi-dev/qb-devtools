local QBCore = exports['qb-core']:GetCoreObject()

-- NUI Callback Handlers
-- These callbacks handle communication from the UI to the game

-- Close UI
RegisterNUICallback('closeDevTools', function(_, cb)
    CloseDevTools()
    cb('ok')
end)

-- Get player data
RegisterNUICallback('getPlayerData', function(_, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    cb({
        name = GetPlayerName(PlayerId()),
        id = GetPlayerServerId(PlayerId()),
        position = {
            x = string.format("%.2f", coords.x),
            y = string.format("%.2f", coords.y),
            z = string.format("%.2f", coords.z)
        },
        heading = string.format("%.2f", GetEntityHeading(playerPed)),
        health = GetEntityHealth(playerPed),
        armor = GetPedArmour(playerPed)
    })
end)

-- Get resource list
RegisterNUICallback('getResources', function(_, cb)
    cb(GetResourceList())
end)

-- Restart resource
RegisterNUICallback('restartResource', function(data, cb)
    if not data.resourceName then
        cb({ success = false, message = Lang:t('error.invalid_resource') })
        return
    end
    
    -- Check if resource is in blocked list
    for _, blockedResource in ipairs(Config.Features.ResourceManager.BlockedResources) do
        if data.resourceName == blockedResource then
            cb({ success = false, message = Lang:t('error.restart_failed') .. ' (Blocked Resource)' })
            return
        end
    end
    
    TriggerServerEvent('QBDevTools:Server:RestartResource', data.resourceName)
    cb({ success = true, message = Lang:t('info.restarting_resource') })
end)

-- Start resource
RegisterNUICallback('startResource', function(data, cb)
    if not data.resourceName then
        cb({ success = false, message = Lang:t('error.invalid_resource') })
        return
    end
    
    TriggerServerEvent('QBDevTools:Server:StartResource', data.resourceName)
    cb({ success = true, message = Lang:t('info.starting_resource') })
end)

-- Stop resource
RegisterNUICallback('stopResource', function(data, cb)
    if not data.resourceName then
        cb({ success = false, message = Lang:t('error.invalid_resource') })
        return
    end
    
    -- Check if resource is in blocked list
    for _, blockedResource in ipairs(Config.Features.ResourceManager.BlockedResources) do
        if data.resourceName == blockedResource then
            cb({ success = false, message = Lang:t('error.stop_failed') .. ' (Blocked Resource)' })
            return
        end
    end
    
    TriggerServerEvent('QBDevTools:Server:StopResource', data.resourceName)
    cb({ success = true, message = Lang:t('info.stopping_resource') })
end)

-- Teleport player
RegisterNUICallback('teleport', function(data, cb)
    if not data.x or not data.y or not data.z then
        cb({ success = false, message = Lang:t('error.invalid_coordinates') })
        return
    end
    
    TeleportToCoordinates(data.x, data.y, data.z, data.h)
    cb({ success = true, message = Lang:t('success.teleported') })
end)

-- Copy coordinates
RegisterNUICallback('copyCoords', function(data, cb)
    local format = data.format or "vector3"
    local coords = CopyCoords(format)
    
    cb({
        success = true,
        message = Lang:t('info.coordinates_copied'),
        coords = coords
    })
end)

-- Execute Lua code
RegisterNUICallback('executeLua', function(data, cb)
    if not data.code then
        cb({ success = false, message = Lang:t('error.invalid_parameters') })
        return
    end
    
    local isServerSide = data.isServerSide or false
    
    if isServerSide then
        -- Send code to server for execution
        TriggerServerEvent('QBDevTools:Server:ExecuteLua', data.code)
        cb({ success = true, message = Lang:t('info.executing_server_code') })
    else
        -- Execute code on client
        local success, result = ExecuteLuaCode(data.code)
        cb({
            success = success,
            message = success and Lang:t('success.function_executed') or Lang:t('error.execution_failed'),
            result = result
        })
    end
end)

-- Execute QB function
RegisterNUICallback('executeFunction', function(data, cb)
    if not data.functionName then
        cb({ success = false, message = Lang:t('error.invalid_parameters') })
        return
    end
    
    local isServerFunction = data.isServerFunction or false
    local args = data.args or {}
    
    if isServerFunction then
        -- Send to server for execution
        TriggerServerEvent('QBDevTools:Server:ExecuteFunction', data.functionName, args)
        cb({ success = true, message = Lang:t('info.executing_server_function') })
    else
        -- Try to execute client function
        local funcParts = {}
        for part in string.gmatch(data.functionName, "([^.]+)") do
            table.insert(funcParts, part)
        end
        
        local errorMsg = Lang:t('error.function_not_found')
        local success = false
        local result = nil
        
        -- Try to find and execute the function
        if #funcParts > 0 then
            local currentTable = _G
            for i = 1, #funcParts do
                if type(currentTable) ~= "table" then
                    break
                end
                
                if i == #funcParts then
                    -- Last part should be the function
                    if type(currentTable[funcParts[i]]) == "function" then
                        -- Execute function with arguments
                        success, result = pcall(function()
                            if #args > 0 then
                                return currentTable[funcParts[i]](table.unpack(args))
                            else
                                return currentTable[funcParts[i]]()
                            end
                        end)
                        
                        if not success then
                            errorMsg = result
                        end
                    end
                else
                    -- Navigate to next table
                    currentTable = currentTable[funcParts[i]]
                    if not currentTable then break end
                end
            end
        end
        
        cb({
            success = success,
            message = success and Lang:t('success.function_executed') or errorMsg,
            result = result
        })
    end
end)

-- Start monitoring events
RegisterNUICallback('startMonitoringEvents', function(_, cb)
    StartEventMonitoring()
    cb({ success = true, message = Lang:t('info.event_monitoring_started') })
end)

-- Stop monitoring events
RegisterNUICallback('stopMonitoringEvents', function(_, cb)
    StopEventMonitoring()
    cb({ success = true, message = Lang:t('info.event_monitoring_stopped') })
end)

-- Get monitored events
RegisterNUICallback('getMonitoredEvents', function(_, cb)
    cb(GetMonitoredEvents())
end)

-- Trigger custom event
RegisterNUICallback('triggerEvent', function(data, cb)
    if not data.eventName then
        cb({ success = false, message = Lang:t('error.invalid_parameters') })
        return
    end
    
    local isServerEvent = data.isServerEvent or false
    local args = data.args or {}
    
    -- Convert string arguments to their proper types
    local processedArgs = {}
    for _, arg in ipairs(args) do
        -- Try to convert strings to numbers or booleans if appropriate
        if type(arg) == "string" then
            if arg == "true" then
                table.insert(processedArgs, true)
            elseif arg == "false" then
                table.insert(processedArgs, false)
            elseif tonumber(arg) ~= nil then
                table.insert(processedArgs, tonumber(arg))
            else
                table.insert(processedArgs, arg)
            end
        else
            table.insert(processedArgs, arg)
        end
    end
    
    -- Trigger the event
    if isServerEvent then
        TriggerServerEvent(data.eventName, table.unpack(processedArgs))
    else
        TriggerEvent(data.eventName, table.unpack(processedArgs))
    end
    
    cb({
        success = true,
        message = Lang:t('info.event_triggered') .. ': ' .. data.eventName
    })
end)

-- Save UI settings
RegisterNUICallback('saveSettings', function(data, cb)
    if not data then
        cb({ success = false, message = Lang:t('error.invalid_parameters') })
        return
    end
    
    -- Update local settings
    Config.UISettings = data
    
    -- Save settings to server
    TriggerServerEvent('QBDevTools:Server:SaveSettings', data)
    
    cb({ success = true, message = Lang:t('info.settings_saved') })
end)

-- Clear logs
RegisterNUICallback('clearLogs', function(_, cb)
    TriggerEvent('QBDevTools:Client:ClearLogs')
    cb({ success = true, message = Lang:t('info.logs_cleared') })
end)
