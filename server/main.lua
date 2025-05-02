local QBCore = exports['qb-core']:GetCoreObject()

local devSettings = {}

local function IsPlayerAuthorized(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    if not Config.UsePermissions then return true end

    local identifiers = QBCore.Functions.GetIdentifiers(source)
    for _, allowedId in ipairs(Config.AllowedIdentifiers) do
        for _, id in pairs(identifiers) do
            if id == allowedId then
                return true
            end
        end
    end

    local permission = Config.RequiredPermission
    if Player.PlayerData.permission == permission or 
       Player.PlayerData.permission == "admin" or 
       Player.PlayerData.permission == "god" then
        return true
    end

    return false
end

local function LoadPlayerDevSettings(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    local citizenId = Player.PlayerData.citizenid
    if not citizenId then return nil end

    if devSettings[citizenId] then
        return devSettings[citizenId]
    end

    return Config.UISettings
end

local function SavePlayerDevSettings(source, settings)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local citizenId = Player.PlayerData.citizenid
    if not citizenId then return false end

    devSettings[citizenId] = settings
    return true
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
end)

QBCore.Commands.Add(Config.AdminOpenCommand, '', { { name = 'id', help = '' } }, true, function(source, args)
    local src = source

    if not IsPlayerAuthorized(src) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_target'), 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.invalid_target'), 'error')
        return
    end

    TriggerClientEvent('QBDevTools:Client:ForceOpen', targetId)
    TriggerClientEvent('QBCore:Notify', src, 'Dev tools opened for ' .. targetPlayer.PlayerData.name, 'success')
end, 'admin')

exports('IsPlayerAuthorized', IsPlayerAuthorized)
exports('LoadPlayerDevSettings', LoadPlayerDevSettings)
exports('SavePlayerDevSettings', SavePlayerDevSettings)
