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

-- Kontrola, zda hráč sedí v policejním autě
function IsInPoliceVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end
    local veh = GetVehiclePedIsIn(ped, false)
    local class = GetVehicleClass(veh)
    -- Třída 18 = Emergency vehicles (police, ambulance, fire)
    return class == 18
end

-- Kontrola oprávnění a podmínek otevření
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

    if IsInPoliceVehicle() and Config.OpenOptions.AllowInPoliceVehicleWithoutItem then
        return true
    end

    -- Kontrola ox_inventory itemu
    if Config.OpenOptions.RequireItem then
        local count = exports.ox_inventory:Search('count', Config.ItemName)
        if not count or count <= 0 then
            return false, _U('need_item_or_car')
        end
    end

    return true
end

-- Otevření MDT
function OpenMDT(fromItem)
    if isMdtOpen then return end

    if not fromItem then
        local canOpen, reason = CanOpenMDT()
        if not canOpen then
            lib.notify({ type = 'error', description = reason })
            return
        end
    end

    lib.callback('pt_mdt:getInitialData', false, function(data)
        if not data then
            lib.notify({ type = 'error', description = _U('not_authorized') })
            return
        end

        isMdtOpen = true
        SetNuiFocus(true, true)

        -- Spustit animaci tabletu pokud hráč není řidičem jedoucího vozu
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

RegisterNetEvent('pt_mdt:openMDT', function(fromItem)
    OpenMDT(fromItem)
end)

-- Registrace příkazu a klávesy
RegisterCommand(Config.OpenOptions.Command, function()
    OpenMDT(false)
end, false)

RegisterKeyMapping(Config.OpenOptions.Command, 'Otevřít policejní MDT', 'keyboard', Config.OpenOptions.Keybind)
