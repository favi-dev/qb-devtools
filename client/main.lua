local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isDevToolsOpen = false
local isShowingCoords = false
local isShowingEntityInfo = false
local isMonitoringEvents = false
local devToolsInitialized = false

-- Initialize variables
local function Initialize()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- الكل مسموح له، لا حاجة للتحقق من الصلاحيات
    TriggerEvent('QBDevTools:Client:Initialize')
    devToolsInitialized = true
end

-- Check if player is authorized to use dev tools
function IsAuthorized()
    -- السماح للجميع باستخدام Dev Tools
    return true
end

-- Open Dev Tools UI
function OpenDevTools()
    if not IsAuthorized() then
        QBCore.Functions.Notify(Lang:t('error.no_permission'), 'error')
        return
    end
    
    if isDevToolsOpen then return end
    isDevToolsOpen = true
    
    -- Send initial data to NUI
    SendNUIMessage({
        action = 'openDevTools',
        data = {
            playerData = {
                name = GetPlayerName(PlayerId()),
                id = GetPlayerServerId(PlayerId()),
                position = GetEntityCoords(PlayerPedId()),
                heading = GetEntityHeading(PlayerPedId())
            },
            resources = GetResourceList(),
            settings = Config.UISettings,
            teleportLocations = Config.TeleportLocations,
            features = Config.Features
        }
    })
    
    SetNuiFocus(true, true)
    TriggerEvent('QBDevTools:Client:DevToolsOpened')
end

-- Close Dev Tools UI
function CloseDevTools()
    if not isDevToolsOpen then return end
    isDevToolsOpen = false
    
    SendNUIMessage({
        action = 'closeDevTools'
    })
    
    SetNuiFocus(false, false)
    TriggerEvent('QBDevTools:Client:DevToolsClosed')
end

-- Get list of resources
function GetResourceList()
    local resources = {}
    local resourceCount = GetNumResources()
    
    for i = 0, resourceCount - 1 do
        local resourceName = GetResourceByFindIndex(i)
        table.insert(resources, {
            name = resourceName,
            status = GetResourceState(resourceName)
        })
    end
    
    return resources
end

-- Event handlers
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    Initialize()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isDevToolsOpen = false
end)

RegisterNetEvent('QBCore:Client:OnPermissionUpdate', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- Command to open dev tools - now available to everyone
RegisterCommand(Config.OpenCommand, function()
    if not devToolsInitialized then
        PlayerData = QBCore.Functions.GetPlayerData()
        Initialize()
    end
    
    OpenDevTools()
end, false)

-- Force open dev tools for player
RegisterNetEvent('QBDevTools:Client:ForceOpen', function()
    if not devToolsInitialized then
        PlayerData = QBCore.Functions.GetPlayerData()
        Initialize()
    end
    OpenDevTools()
end)

-- Initialize on script start
CreateThread(function()
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(100)
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    devToolsInitialized = true
end)

-- Export functions
exports('IsDevToolsOpen', function()
    return isDevToolsOpen
end)

exports('ToggleDevTools', function()
    if isDevToolsOpen then
        CloseDevTools()
    else
        OpenDevTools()
    end
end)
