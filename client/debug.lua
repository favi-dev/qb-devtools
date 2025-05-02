local QBCore = exports['qb-core']:GetCoreObject()

-- Debug Display Variables
local showDebugInfo = false
local debugEntities = {}
local debugCoords = false

-- Start displaying debug info on screen
function StartDebugDisplay()
    if showDebugInfo then return end
    showDebugInfo = true
    
    -- Main debug thread
    CreateThread(function()
        local display = true
        while display and showDebugInfo do
            -- Get player data
            local player = PlayerPedId()
            local playerCoords = GetEntityCoords(player)
            
            -- Display player coordinates if enabled
            if Config.Features.DebugTools.ShowCoordinates then
                local coordsString = string.format(
                    "~y~X:~w~ %s ~y~Y:~w~ %s ~y~Z:~w~ %s",
                    string.format("%.2f", playerCoords.x),
                    string.format("%.2f", playerCoords.y),
                    string.format("%.2f", playerCoords.z)
                )
                
                if Config.Features.DebugTools.ShowHeading then
                    local heading = GetEntityHeading(player)
                    coordsString = coordsString .. string.format(" ~y~H:~w~ %s", string.format("%.2f", heading))
                end
                
                DrawTextOnScreen(coordsString, 0.45, 0.01, 0.35, 4, {r = 255, g = 255, b = 255}, true)
            end
            
            -- Display entity info if enabled
            if Config.Features.DebugTools.ShowEntityInfo then
                local entity = GetEntityInFrontOfPlayer(5.0)
                if DoesEntityExist(entity) then
                    local entityType = GetEntityType(entity)
                    local entityHash = GetEntityModel(entity)
                    local entityCoords = GetEntityCoords(entity)
                    local distance = #(playerCoords - entityCoords)
                    
                    if entityType > 0 then
                        local typeNames = {"", "Ped", "Vehicle", "Object"}
                        local typeName = typeNames[entityType] or "Unknown"
                        
                        -- Base entity info
                        local infoText = string.format(
                            "~g~Entity:~w~ %s (%d) ~g~Type:~w~ %s ~g~Hash:~w~ %d ~g~Distance:~w~ %.2f",
                            entity, NetworkGetNetworkIdFromEntity(entity), typeName, entityHash, distance
                        )
                        
                        DrawTextOnScreen(infoText, 0.45, 0.06, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                        
                        -- Type-specific info
                        local line = 0.09
                        
                        if entityType == 1 then -- Ped
                            local health = GetEntityHealth(entity)
                            local maxHealth = GetEntityMaxHealth(entity)
                            local isPlayer = IsPedAPlayer(entity)
                            
                            DrawTextOnScreen(string.format(
                                "~b~Health:~w~ %d/%d ~b~Player:~w~ %s",
                                health, maxHealth, isPlayer and "Yes" or "No"
                            ), 0.45, line, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                            
                            if isPlayer then
                                local playerId = NetworkGetPlayerIndexFromPed(entity)
                                local playerName = GetPlayerName(playerId)
                                local serverId = GetPlayerServerId(playerId)
                                
                                line = line + 0.03
                                DrawTextOnScreen(string.format(
                                    "~b~Name:~w~ %s ~b~Server ID:~w~ %d",
                                    playerName, serverId
                                ), 0.45, line, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                            end
                            
                        elseif entityType == 2 then -- Vehicle
                            local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(entityHash))
                            local vehicleClass = GetVehicleClassName(GetVehicleClass(entity))
                            local plate = GetVehicleNumberPlateText(entity)
                            
                            DrawTextOnScreen(string.format(
                                "~b~Model:~w~ %s ~b~Class:~w~ %s ~b~Plate:~w~ %s",
                                vehicleName, vehicleClass, plate
                            ), 0.45, line, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                            
                            line = line + 0.03
                            local engine = GetVehicleEngineHealth(entity)
                            local body = GetVehicleBodyHealth(entity)
                            local fuel = GetVehicleFuelLevel(entity)
                            
                            DrawTextOnScreen(string.format(
                                "~b~Engine:~w~ %.0f ~b~Body:~w~ %.0f ~b~Fuel:~w~ %.0f",
                                engine, body, fuel
                            ), 0.45, line, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                            
                        elseif entityType == 3 then -- Object
                            DrawTextOnScreen(string.format(
                                "~b~Model Hash:~w~ 0x%08X",
                                entityHash
                            ), 0.45, line, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                        end
                    end
                end
            end
            
            -- Display server info if enabled
            if Config.Features.DebugTools.ShowServerInfo then
                local yPos = 0.95 -- Start from bottom of screen
                
                -- Server ID and name
                DrawTextOnScreen(string.format(
                    "~o~Server ID:~w~ %d ~o~Name:~w~ %s",
                    GetPlayerServerId(PlayerId()),
                    GetPlayerName(PlayerId())
                ), 0.45, yPos, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                
                -- FPS counter
                yPos = yPos - 0.03
                DrawTextOnScreen(string.format(
                    "~o~FPS:~w~ %d",
                    GetFPS()
                ), 0.45, yPos, 0.35, 4, {r = 255, g = 255, b = 255}, true)
                
                -- Game/Server time
                yPos = yPos - 0.03
                local hours, minutes = GetClockHours(), GetClockMinutes()
                DrawTextOnScreen(string.format(
                    "~o~Time:~w~ %02d:%02d",
                    hours, minutes
                ), 0.45, yPos, 0.35, 4, {r = 255, g = 255, b = 255}, true)
            end
            
            -- Check if we should stop displaying
            if not showDebugInfo then
                display = false
            end
            
            Wait(0)
        end
    end)
end

-- Stop displaying debug info
function StopDebugDisplay()
    showDebugInfo = false
end

-- Draw text on screen helper function
function DrawTextOnScreen(text, xPos, yPos, scale, font, color, center)
    SetTextScale(scale, scale)
    SetTextFont(font)
    SetTextProportional(true)
    SetTextColour(color.r, color.g, color.b, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    
    if center then
        SetTextCentre(true)
    end
    
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(xPos, yPos)
end

-- Get entity in front of player
function GetEntityInFrontOfPlayer(distance)
    local coords = GetEntityCoords(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    local forwardCoords = coords + (forward * distance)
    
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z, forwardCoords.x, forwardCoords.y, forwardCoords.z, -1, PlayerPedId(), 0)
    local _, _, _, _, entity = GetShapeTestResult(ray)
    
    return entity
end

-- Calculate FPS
local fps = 0
local lastFrameTime = 0

function GetFPS()
    local currentTime = GetGameTimer()
    if currentTime - lastFrameTime > 1000 then
        fps = math.floor(1000 / (currentTime - lastFrameTime))
        lastFrameTime = currentTime
    end
    return fps
end

-- Toggle debug display
function ToggleDebugDisplay()
    if showDebugInfo then
        StopDebugDisplay()
        QBCore.Functions.Notify(Lang:t("info.debug_display_off"), "primary")
    else
        StartDebugDisplay()
        QBCore.Functions.Notify(Lang:t("info.debug_display_on"), "primary")
    end
end

-- Toggle coordinates display
function ToggleCoordinatesDisplay()
    debugCoords = not debugCoords
    Config.Features.DebugTools.ShowCoordinates = debugCoords
    
    QBCore.Functions.Notify(
        debugCoords and Lang:t("info.coords_display_on") or Lang:t("info.coords_display_off"),
        "primary"
    )
end

-- Toggle entity info display
function ToggleEntityInfoDisplay()
    local showEntityInfo = not Config.Features.DebugTools.ShowEntityInfo
    Config.Features.DebugTools.ShowEntityInfo = showEntityInfo
    
    QBCore.Functions.Notify(
        showEntityInfo and Lang:t("info.entity_info_on") or Lang:t("info.entity_info_off"),
        "primary"
    )
end

-- Register commands
RegisterCommand('devdebug', function()
    if not IsAuthorized() then
        QBCore.Functions.Notify(Lang:t("error.no_permission"), "error")
        return
    end
    
    ToggleDebugDisplay()
end, false)

RegisterCommand('devcoords', function()
    if not IsAuthorized() then
        QBCore.Functions.Notify(Lang:t("error.no_permission"), "error")
        return
    end
    
    ToggleCoordinatesDisplay()
end, false)

RegisterCommand('deventity', function()
    if not IsAuthorized() then
        QBCore.Functions.Notify(Lang:t("error.no_permission"), "error")
        return
    end
    
    ToggleEntityInfoDisplay()
end, false)

-- Export functions
exports('StartDebugDisplay', StartDebugDisplay)
exports('StopDebugDisplay', StopDebugDisplay)
exports('ToggleDebugDisplay', ToggleDebugDisplay)
exports('ToggleCoordinatesDisplay', ToggleCoordinatesDisplay)
exports('ToggleEntityInfoDisplay', ToggleEntityInfoDisplay)
