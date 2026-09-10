local ESX = exports['es_extended']:getSharedObject()
local activeDispatches = {}

-- Získání dispečerských hovorů
lib.callback.register('pt_mdt:getDispatchCalls', function(src)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return {} end
    return activeDispatches
end)

-- Nové volání na 911 / dispečink
RegisterNetEvent('pt_mdt:newDispatch', function(callData)
    -- callData: { code = '10-31', title = 'Vloupání do obchodu', coords = vector3, message = 'Ozbrojený pachatel', caller = 'Svědek' }
    local dispatchId = #activeDispatches + 1
    local call = {
        id = dispatchId,
        code = callData.code or '10-99',
        title = callData.title or 'Nouzové hlášení',
        message = callData.message or 'Bez popisu',
        caller = callData.caller or 'Anonym',
        coords = {
            x = callData.coords and callData.coords.x or 0.0,
            y = callData.coords and callData.coords.y or 0.0,
            z = callData.coords and callData.coords.z or 0.0
        },
        time = os.date('%H:%M:%S'),
        units = {}
    }

    table.insert(activeDispatches, 1, call)

    -- Udržujeme max 30 hovorů
    if #activeDispatches > 30 then
        table.remove(activeDispatches, #activeDispatches)
    end

    -- Notifikace všem online policistům
    local players = ESX.GetExtendedPlayers()
    for _, ply in pairs(players) do
        if ply.job and Config.AllowedJobs[ply.job.name] then
            TriggerClientEvent('ox_lib:notify', ply.source, {
                type = 'inform',
                title = ('DISPEČINK [%s]'):format(call.code),
                description = ('%s - %s'):format(call.title, call.message)
            })
            TriggerClientEvent('pt_mdt:clientDispatchCall', ply.source, call)
        end
    end
end)

-- Export pro jiné skripty (např. systém loupeží, drog atd.)
exports('SendDispatch', function(data)
    TriggerEvent('pt_mdt:newDispatch', data)
end)
