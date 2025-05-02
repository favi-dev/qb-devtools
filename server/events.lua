local QBCore = exports['qb-core']:GetCoreObject()

local monitoredEvents = {}
local isMonitoringEvents = false

RegisterNetEvent('QBDevTools:Server:RestartResource', function(resourceName)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    if not GetResourceState(resourceName) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_resource'), 'error')
        TriggerClientEvent('QBDevTools:Client:ResourceRestarted', src, resourceName, false)
        return
    end

    for _, blockedResource in ipairs(Config.Features.ResourceManager.BlockedResources) do
        if resourceName == blockedResource then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.restart_failed') .. ' (Blocked Resource)', 'error')
            TriggerClientEvent('QBDevTools:Client:ResourceRestarted', src, resourceName, false)
            return
        end
    end

    local success = false

    if GetResourceState(resourceName) == "started" then
        StopResource(resourceName)
        Wait(100)
        if StartResource(resourceName) then
            success = true
        else
            print('^1[QB-DevTools] Failed to restart resource: ' .. resourceName .. '^0')
        end
    else
        if StartResource(resourceName) then
            success = true
        else
            print('^1[QB-DevTools] Failed to start resource: ' .. resourceName .. '^0')
        end
    end

    TriggerClientEvent('QBDevTools:Client:ResourceRestarted', src, resourceName, success)
    local playerName = GetPlayerName(src)
    print('^3[QB-DevTools] Player ' .. playerName .. ' (ID: ' .. src .. ') ' .. (success and 'restarted' or 'attempted to restart') .. ' resource: ' .. resourceName .. '^0')
end)

RegisterNetEvent('QBDevTools:Server:StartResource', function(resourceName)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    if not GetResourceState(resourceName) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_resource'), 'error')
        return
    end

    if GetResourceState(resourceName) == "started" then
        TriggerClientEvent('QBCore:Notify', src, 'Resource is already started', 'error')
        return
    end

    local success = StartResource(resourceName)

    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Resource started: ' .. resourceName, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to start resource: ' .. resourceName, 'error')
    end

    local playerName = GetPlayerName(src)
    print('^3[QB-DevTools] Player ' .. playerName .. ' (ID: ' .. src .. ') ' .. (success and 'started' or 'attempted to start') .. ' resource: ' .. resourceName .. '^0')
end)

RegisterNetEvent('QBDevTools:Server:StopResource', function(resourceName)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    if not GetResourceState(resourceName) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_resource'), 'error')
        return
    end

    for _, blockedResource in ipairs(Config.Features.ResourceManager.BlockedResources) do
        if resourceName == blockedResource then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.stop_failed') .. ' (Blocked Resource)', 'error')
            return
        end
    end

    if GetResourceState(resourceName) ~= "started" then
        TriggerClientEvent('QBCore:Notify', src, 'Resource is not running', 'error')
        return
    end

    StopResource(resourceName)
    local success = (GetResourceState(resourceName) ~= "started")

    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Resource stopped: ' .. resourceName, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to stop resource: ' .. resourceName, 'error')
    end

    local playerName = GetPlayerName(src)
    print('^3[QB-DevTools] Player ' .. playerName .. ' (ID: ' .. src .. ') ' .. (success and 'stopped' or 'attempted to stop') .. ' resource: ' .. resourceName .. '^0')
end)

RegisterNetEvent('QBDevTools:Server:ExecuteLua', function(code)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    if not Config.Features.LuaExecution.Enabled then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.feature_disabled'), 'error')
        return
    end

    for _, funcName in ipairs(Config.Features.LuaExecution.RestrictedFunctions) do
        if string.find(code, funcName) then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.restricted_function'), 'error')
            return
        end
    end

    local playerName = GetPlayerName(src)
    print('^3[QB-DevTools] Player ' .. playerName .. ' (ID: ' .. src .. ') is executing server Lua code^0')
    print('^5[Code]:\n' .. code .. '^0')

    local result, errorMsg = ExecuteLuaCode(code, src)
    TriggerClientEvent('QBDevTools:Client:ExecutionResult', src, result, errorMsg)
end)

RegisterNetEvent('QBDevTools:Server:ExecuteFunction', function(functionName, args)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    local playerName = GetPlayerName(src)
    print('^3[QB-DevTools] Player ' .. playerName .. ' (ID: ' .. src .. ') is executing server function: ' .. functionName .. '^0')

    local result, errorMsg = ExecuteQBFunction(functionName, args, src)
    TriggerClientEvent('QBDevTools:Client:ExecutionResult', src, result, errorMsg)
end)

RegisterNetEvent('QBDevTools:Server:SaveSettings', function(settings)
    local src = source
    SavePlayerDevSettings(src, settings)
end)

RegisterNetEvent('QBDevTools:Server:StartEventMonitoring', function()
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    StartEventMonitoring(src)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.event_monitoring_started'), 'success')
end)

RegisterNetEvent('QBDevTools:Server:StopEventMonitoring', function()
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    StopEventMonitoring(src)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.event_monitoring_stopped'), 'success')
end)

function StartEventMonitoring(playerId)
    local src = playerId
    isMonitoringEvents = true
    monitoredEvents = {}
    print('^3[QB-DevTools] Player ' .. GetPlayerName(src) .. ' (ID: ' .. src .. ') started event monitoring^0')
end

function StopEventMonitoring(playerId)
    local src = playerId
    isMonitoringEvents = false
    print('^3[QB-DevTools] Player ' .. GetPlayerName(src) .. ' (ID: ' .. src .. ') stopped event monitoring^0')
end

function SendMonitoredEvent(playerId, eventName, eventSource, eventArgs)
    if not isMonitoringEvents then return end

    TriggerClientEvent('QBDevTools:Client:MonitoredEvent', playerId, {
        name = eventName,
        source = eventSource,
        args = eventArgs,
        time = os.date("%H:%M:%S")
    })
end
