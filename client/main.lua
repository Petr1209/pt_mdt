local ESX = exports['es_extended']:getSharedObject()
local isMdtOpen = false
local playerJob = nil

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    playerJob = xPlayer.job
end)

RegisterNetEvent('esx:setJob', function(job)
    playerJob = job
end)

CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(500)
    end
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        playerJob = playerData.job
    end
end)

-- Kontrola oprávnění hráče
function CanOpenMDT()
    local playerData = ESX.GetPlayerData()
    local currentJob = (playerData and playerData.job) or playerJob
    local isAllowed = currentJob and Config.AllowedJobs[currentJob.name]

    -- Povolit adminům pro testování
    if not isAllowed and Config.AllowAdminBypass then
        local group = (playerData and playerData.group)
        if group == 'admin' or group == 'superadmin' then
            isAllowed = true
        end
    end

    if not isAllowed then
        return false, _U('not_authorized')
    end

    return true
end

-- Otevření MDT (výhradně přes item mdt_tablet)
function OpenMDT(fromItem)
    if isMdtOpen then return end

    local canOpen, reason = CanOpenMDT()
    if not canOpen then
        lib.notify({ type = 'error', description = reason })
        return
    end

    lib.callback('pt_mdt:getInitialData', false, function(data)
        if not data then
            lib.notify({ type = 'error', description = 'Chyba: Data MDT se nepodařilo ze serveru načíst!' })
            return
        end

        isMdtOpen = true
        SetNuiFocus(true, true)

        -- Spustit animaci tabletu pokud hráč nesedí ve vozidle
        local ped = PlayerPedId()
        local inVeh = IsPedInAnyVehicle(ped, false)
        if not inVeh then
            StartTabletAnimation()
        end

        SendNUIMessage({
            action = 'open',
            data = data
        })
    end)
end

-- Zavření MDT
function CloseMDT()
    if not isMdtOpen then return end
    isMdtOpen = false
    SetNuiFocus(false, false)
    StopTabletAnimation()
    SendNUIMessage({ action = 'close' })
end

-- Event ze serveru
RegisterNetEvent('pt_mdt:openMDT', function(fromItem)
    OpenMDT(fromItem)
end)

-- Export pro ox_inventory při kliknutí / použití itemu v inventáři
exports('openTablet', function(data, slot)
    OpenMDT(true)
end)

-- Synchronizace času startu serveru při připojení hráče
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('pt_mdt:requestBootTime')
end)

RegisterNetEvent('pt_mdt:syncBootTime', function(bootTime)
    SendNUIMessage({
        action = 'initSession',
        bootTime = bootTime
    })
end)
