local radarActive = false
local radarShowing = false
local radarLocked = false
local lockedData = nil

-- Kontrola, zda je vozidlo policejní
local function IsPoliceVehicle(veh)
    if not veh or veh == 0 then return false end
    return GetVehicleClass(veh) == 18
end

-- Detekce vozidla paprskem (ShapeTest)
local function GetVehicleInDirection(coordFrom, coordTo)
    local shapeTest = StartShapeTestCapsule(
        coordFrom.x, coordFrom.y, coordFrom.z,
        coordTo.x, coordTo.y, coordTo.z,
        3.0, 10, PlayerPedId(), 7
    )
    local _, hit, _, _, entityHit = GetShapeTestResult(shapeTest)
    if hit == 1 and IsEntityAVehicle(entityHit) then
        return entityHit
    end
    return nil
end

-- Získání vozidla před hlídkou
local function ScanFrontVehicle(patrolVeh)
    local offsetFrom = GetOffsetFromEntityInWorldCoords(patrolVeh, 0.0, 1.5, 0.5)
    local offsetTo = GetOffsetFromEntityInWorldCoords(patrolVeh, 0.0, 45.0, 0.0)
    return GetVehicleInDirection(offsetFrom, offsetTo)
end

-- Získání vozidla za hlídkou
local function ScanRearVehicle(patrolVeh)
    local offsetFrom = GetOffsetFromEntityInWorldCoords(patrolVeh, 0.0, -1.5, 0.5)
    local offsetTo = GetOffsetFromEntityInWorldCoords(patrolVeh, 0.0, -35.0, 0.0)
    return GetVehicleInDirection(offsetFrom, offsetTo)
end

-- Vlákno pro měření rychlosti radarem s automatickým skrytím při vystoupení
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if radarActive then
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if IsPoliceVehicle(veh) and GetPedInVehicleSeat(veh, -1) == ped then
                    sleep = 60 -- Plynulá aktualizace radaru

                    if not radarShowing then
                        radarShowing = true
                        SendNUIMessage({ action = 'toggleRadar', show = true })
                    end

                    local patrolSpeed = math.floor(GetEntitySpeed(veh) * 3.6)

                    local frontVeh = ScanFrontVehicle(veh)
                    local frontSpeed = 0
                    local frontPlate = '---'
                    local frontModel = ''

                    if frontVeh and DoesEntityExist(frontVeh) then
                        frontSpeed = math.floor(GetEntitySpeed(frontVeh) * 3.6)
                        frontPlate = GetVehicleNumberPlateText(frontVeh) or '---'
                        local modelHash = GetEntityModel(frontVeh)
                        frontModel = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
                    end

                    local rearVeh = ScanRearVehicle(veh)
                    local rearSpeed = 0
                    local rearPlate = '---'

                    if rearVeh and DoesEntityExist(rearVeh) then
                        rearSpeed = math.floor(GetEntitySpeed(rearVeh) * 3.6)
                        rearPlate = GetVehicleNumberPlateText(rearVeh) or '---'
                    end

                    SendNUIMessage({
                        action = 'updateRadar',
                        data = {
                            patrolSpeed = patrolSpeed,
                            frontSpeed = frontSpeed,
                            frontPlate = frontPlate,
                            frontModel = frontModel,
                            rearSpeed = rearSpeed,
                            rearPlate = rearPlate,
                            locked = radarLocked,
                            lockedData = lockedData
                        }
                    })
                else
                    -- V jiném než policejním voze nebo na sedadle spolujezdce
                    if radarShowing then
                        radarShowing = false
                        SendNUIMessage({ action = 'toggleRadar', show = false })
                    end
                end
            else
                -- Policista vystoupil z vozu -> radar se ihned skryje (dočasně vypne)
                if radarShowing then
                    radarShowing = false
                    SendNUIMessage({ action = 'toggleRadar', show = false })
                end
            end
        else
            if radarShowing then
                radarShowing = false
                SendNUIMessage({ action = 'toggleRadar', show = false })
            end
        end

        Wait(sleep)
    end
end)

-- Přepnutí radaru (zapnout/vypnout)
function ToggleRadar()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({ type = 'error', description = _U('need_item_or_car') })
        return
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if not IsPoliceVehicle(veh) then
        lib.notify({ type = 'error', description = 'Radar funguje pouze v policejním voze!' })
        return
    end

    radarActive = not radarActive
    if not radarActive then
        radarShowing = false
        SendNUIMessage({
            action = 'toggleRadar',
            show = false
        })
        lib.notify({ type = 'inform', description = 'Policejní radar byl vypnut.' })
    else
        radarShowing = true
        SendNUIMessage({
            action = 'toggleRadar',
            show = true
        })
        lib.notify({ type = 'inform', description = 'Policejní radar byl aktivován.' })
    end
end

-- Uzamknutí / uvolnění rychlosti (Lock speed)
function ToggleLockRadar()
    if not radarActive then return end
    radarLocked = not radarLocked

    if radarLocked then
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local frontVeh = ScanFrontVehicle(veh)
        if frontVeh and DoesEntityExist(frontVeh) then
            local speed = math.floor(GetEntitySpeed(frontVeh) * 3.6)
            local plate = GetVehicleNumberPlateText(frontVeh)
            lockedData = {
                speed = speed,
                plate = plate
            }
            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
            lib.notify({ type = 'warning', description = ('Rychlost uzamčena: %s km/h (SPZ: %s)'):format(speed, plate) })
        end
    else
        lockedData = nil
    end

    SendNUIMessage({
        action = 'lockRadar',
        locked = radarLocked,
        lockedData = lockedData
    })
end

local radarEditMode = false

function ToggleRadarSet()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({ type = 'error', description = 'Musíte sedět v policejním voze!' })
        return
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if not IsPoliceVehicle(veh) then
        lib.notify({ type = 'error', description = 'Radar funguje pouze v policejním voze!' })
        return
    end

    if not radarActive then
        radarActive = true
        SendNUIMessage({ action = 'toggleRadar', show = true })
    end

    radarEditMode = not radarEditMode
    SetNuiFocus(radarEditMode, radarEditMode)
    SendNUIMessage({
        action = 'setRadarEditMode',
        editing = radarEditMode
    })

    if radarEditMode then
        lib.notify({
            type = 'inform',
            title = 'Pozice radaru',
            description = 'Uchopte radar myší a přesuňte jej kamkoliv na obrazovce. Pro uložení klikněte na Uložit nebo napište /radarset.'
        })
    else
        lib.notify({ type = 'success', description = 'Pozice radaru byla uložena.' })
    end
end

RegisterCommand('radar', ToggleRadar, false)
RegisterCommand('radarlock', ToggleLockRadar, false)
RegisterCommand('radarset', ToggleRadarSet, false)
RegisterCommand('radarreset', function()
    SendNUIMessage({ action = 'resetRadarPosition' })
    lib.notify({
        type = 'inform',
        title = 'Radar',
        description = 'Pozice radaru byla vrácena do výchozího stavu.'
    })
end, false)

RegisterKeyMapping('radar', 'Zapnout/Vypnout policejní radar', 'keyboard', 'NUMPAD9')
RegisterKeyMapping('radarlock', 'Uzamknout rychlost radaru (Lock)', 'keyboard', 'NUMPAD8')
