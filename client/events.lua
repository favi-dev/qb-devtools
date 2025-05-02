local QBCore = exports['qb-core']:GetCoreObject()

-- Event Handlers for Developer Tools

-- Initialize event
RegisterNetEvent('QBDevTools:Client:Initialize', function()
    -- This event is triggered when the client script initializes
    if Config.Features.EventMonitoring.Enabled and not isMonitoringEvents then
        StartEventMonitoring()
    end
end)

-- Event for when dev tools are opened
RegisterNetEvent('QBDevTools:Client:DevToolsOpened', function()
    -- Update player data when tools are opened
    SendNUIMessage({
        action = 'updatePlayerData',
        data = {
            name = GetPlayerName(PlayerId()),
            id = GetPlayerServerId(PlayerId()),
            position = GetEntityCoords(PlayerPedId()),
            heading = GetEntityHeading(PlayerPedId())
        }
    })
    
    -- Start debug loop if debug features are enabled
    if Config.Features.DebugTools.Enabled then
        TriggerEvent('QBDevTools:Client:StartDebugLoop')
    end
    
    -- Get latest resource list
    SendNUIMessage({
        action = 'updateResources',
        data = GetResourceList()
    })
    
    -- Get monitored events if monitoring is active
    if isMonitoringEvents then
        SendNUIMessage({
            action = 'updateEventMonitoring',
            data = {
                events = GetMonitoredEvents()
            }
        })
    end
end)

-- Event for when dev tools are closed
RegisterNetEvent('QBDevTools:Client:DevToolsClosed', function()
    -- Clean up any running processes when tools are closed
    TriggerEvent('QBDevTools:Client:StopDebugLoop')
end)

-- Event to restart a resource
RegisterNetEvent('QBDevTools:Client:RestartResource', function(resourceName)
    -- This event is triggered from the NUI to restart a resource
    TriggerServerEvent('QBDevTools:Server:RestartResource', resourceName)
end)

-- Event to handle resource restart response
RegisterNetEvent('QBDevTools:Client:ResourceRestarted', function(resourceName, success)
    -- This event is triggered from the server to confirm resource restart
    local message = success and
        string.format(Lang:t('success.resource_restarted'), resourceName) or
        string.format(Lang:t('error.restart_failed'), resourceName)
    
    local messageType = success and 'success' or 'error'
    QBCore.Functions.Notify(message, messageType)
    
    -- Update resource list
    SendNUIMessage({
        action = 'updateResources',
        data = GetResourceList()
    })
end)

-- Event to trigger another event (for testing)
RegisterNetEvent('QBDevTools:Client:TriggerEvent', function(eventName, isServerEvent, ...)
    -- This event is triggered from the NUI to manually trigger another event
    if isServerEvent then
        TriggerServerEvent(eventName, ...)
    else
        TriggerEvent(eventName, ...)
    end
    
    QBCore.Functions.Notify(Lang:t('info.event_triggered') .. ': ' .. eventName, 'primary')
end)

-- Event to teleport to coordinates
RegisterNetEvent('QBDevTools:Client:Teleport', function(x, y, z, h)
    -- This event is triggered from the NUI to teleport the player
    TeleportToCoordinates(x, y, z, h)
end)

-- Event to execute Lua code
RegisterNetEvent('QBDevTools:Client:ExecuteLua', function(code)
    -- This event is triggered from the NUI to execute Lua code
    local success, result = ExecuteLuaCode(code)
    
    SendNUIMessage({
        action = 'luaExecutionResult',
        data = {
            success = success,
            result = result
        }
    })
end)

-- Event to start debug loop for showing coordinates and entity info
RegisterNetEvent('QBDevTools:Client:StartDebugLoop', function()
    -- Debug display thread
    CreateThread(function()
        local debugActive = true
        
        while debugActive and isDevToolsOpen do
            -- Get player position
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            -- Format coordinates
            local coordsText = string.format(
                "X: %.2f | Y: %.2f | Z: %.2f | H: %.2f",
                coords.x, coords.y, coords.z, heading
            )
            
            -- Get entity info if enabled
            local entityInfo = nil
            if Config.Features.DebugTools.ShowEntityInfo then
                entityInfo = GetTargetEntityInfo()
            end
            
            -- Send data to UI
            SendNUIMessage({
                action = 'updateDebugInfo',
                data = {
                    coords = coordsText,
                    entityInfo = entityInfo,
                    playerInfo = {
                        health = GetEntityHealth(playerPed),
                        armor = GetPedArmour(playerPed),
                        speed = GetEntitySpeed(playerPed) * 3.6, -- Convert to km/h
                        vehicle = IsPedInAnyVehicle(playerPed, false) and GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(playerPed, false))) or "None"
                    }
                }
            })
            
            -- Check if dev tools still open
            if not isDevToolsOpen then
                debugActive = false
            end
            
            Wait(100) -- Update 10 times per second
        end
    end)
end)

-- Event to stop debug loop
RegisterNetEvent('QBDevTools:Client:StopDebugLoop', function()
    -- This event is called when debug mode should be stopped
    -- The loop will stop itself when isDevToolsOpen becomes false
end)

-- Event to clear all logs
RegisterNetEvent('QBDevTools:Client:ClearLogs', function()
    -- This event is triggered from the NUI to clear logs
    SendNUIMessage({
        action = 'clearLogs'
    })
    
    QBCore.Functions.Notify(Lang:t('info.logs_cleared'), 'primary')
end)

-- Event to update UI settings
RegisterNetEvent('QBDevTools:Client:UpdateSettings', function(settings)
    -- This event is triggered from the NUI to update settings
    -- We would typically save these settings to the server
    TriggerServerEvent('QBDevTools:Server:SaveSettings', settings)
    
    -- Update local settings
    Config.UISettings = settings
end)
