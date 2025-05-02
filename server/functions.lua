local QBCore = exports['qb-core']:GetCoreObject()

function ExecuteLuaCode(code, playerId)
    if not Config.Features.LuaExecution.Enabled then
        return false, Lang:t('error.feature_disabled')
    end
    
    local src = playerId
    local wrappedCode = 'local result = function() ' .. code .. ' end return result()'
    
    local env = {
        QBCore = QBCore,
        source = src,
        print = function(...)
            local msg = table.concat({...}, ' ')
            print('^2[DevTools Lua Execution]^7 ' .. msg)
        end,
        GetPlayerIdentifiers = GetPlayerIdentifiers,
        GetPlayers = GetPlayers,
        os = {
            time = os.time,
            date = os.date,
            difftime = os.difftime,
            clock = os.clock,
        },
        math = math,
        string = string,
        table = table,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        Wait = Wait,
        GetResourceState = GetResourceState,
        GetNumResources = GetNumResources,
        GetResourceByFindIndex = GetResourceByFindIndex,
    }
    
    setmetatable(env, {
        __index = function(t, k)
            for _, funcName in ipairs(Config.Features.LuaExecution.RestrictedFunctions) do
                if k == funcName then
                    return nil
                end
            end
            if _G[k] ~= nil and type(_G[k]) ~= 'function' then
                return _G[k]
            end
            return nil
        end
    })
    
    local func, loadError = load(wrappedCode, 'DevTools', 't', env)
    if not func then
        return false, 'Compilation error: ' .. loadError
    end
    
    local maxTime = Config.Features.LuaExecution.MaxExecutionTime or 5000
    local co = coroutine.create(func)
    local startTime = os.clock() * 1000
    local success, result = coroutine.resume(co)
    local executionTime = (os.clock() * 1000) - startTime
    
    if executionTime > maxTime then
        return false, 'Execution timed out after ' .. math.floor(executionTime) .. 'ms (limit: ' .. maxTime .. 'ms)'
    end
    
    if not success then
        return false, 'Execution error: ' .. result
    end
    
    local resultStr = ''
    if result == nil then
        resultStr = 'nil'
    elseif type(result) == 'table' then
        resultStr = 'Table: ' .. TableToString(result)
    else
        resultStr = tostring(result)
    end
    
    return true, resultStr
end

function ExecuteQBFunction(functionName, args, playerId)
    local src = playerId
    local result = nil
    local errorMsg = nil
    
    local parts = {}
    for part in string.gmatch(functionName, "([^.]+)") do
        table.insert(parts, part)
    end
    
    local currentObj = _G
    for i = 1, #parts do
        if type(currentObj) ~= 'table' then
            return false, 'Invalid function path: ' .. functionName
        end
        
        currentObj = currentObj[parts[i]]
        if currentObj == nil then
            return false, 'Function not found: ' .. functionName
        end
    end
    
    if type(currentObj) ~= 'function' then
        return false, 'Not a function: ' .. functionName
    end
    
    local success, funcResult = pcall(function()
        if #args > 0 then
            return currentObj(table.unpack(args))
        else
            return currentObj()
        end
    end)
    
    if not success then
        return false, 'Execution error: ' .. funcResult
    end
    
    local resultStr = ''
    if funcResult == nil then
        resultStr = 'nil'
    elseif type(funcResult) == 'table' then
        resultStr = 'Table: ' .. TableToString(funcResult)
    else
        resultStr = tostring(funcResult)
    end
    
    return true, resultStr
end

function TableToString(tbl, indent)
    if not indent then indent = 0 end
    if indent > 5 then return "[nested table]" end
    
    local result = "{\n"
    for k, v in pairs(tbl) do
        result = result .. string.rep("  ", indent + 1)
        if type(k) == "string" then
            result = result .. k .. " = "
        else
            result = result .. "[" .. tostring(k) .. "] = "
        end
        
        if type(v) == "table" then
            result = result .. TableToString(v, indent + 1)
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        else
            result = result .. tostring(v)
        end
        
        result = result .. ",\n"
    end
    result = result .. string.rep("  ", indent) .. "}"
    
    return result
end

function SendToDevToolsLog(message, logType, playerId)
    if playerId and IsPlayerAuthorized(playerId) then
        TriggerClientEvent('QBDevTools:Client:AddLog', playerId, {
            message = message,
            type = logType or 'info',
            time = os.date('%H:%M:%S')
        })
    end
end

function GetAllResources()
    local resources = {}
    local count = GetNumResources()
    
    for i = 0, count - 1 do
        local resourceName = GetResourceByFindIndex(i)
        table.insert(resources, {
            name = resourceName,
            status = GetResourceState(resourceName)
        })
    end
    
    return resources
end

exports('ExecuteLuaCode', ExecuteLuaCode)
exports('ExecuteQBFunction', ExecuteQBFunction)
exports('SendToDevToolsLog', SendToDevToolsLog)
exports('GetAllResources', GetAllResources)
