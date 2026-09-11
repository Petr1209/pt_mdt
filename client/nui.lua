-- Zavření NUI
RegisterNUICallback('close', function(_, cb)
    CloseMDT()
    cb('ok')
end)

-- Občané
RegisterNUICallback('searchCitizens', function(data, cb)
    lib.callback('pt_mdt:searchCitizens', false, function(results)
        cb(results or {})
    end, data.query)
end)

RegisterNUICallback('getCitizenProfile', function(data, cb)
    lib.callback('pt_mdt:getCitizenProfile', false, function(profile)
        cb(profile)
    end, data.identifier)
end)

RegisterNUICallback('saveCitizenProfile', function(data, cb)
    lib.callback('pt_mdt:saveCitizenProfile', false, function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('addLicense', function(data, cb)
    lib.callback('pt_mdt:addLicense', false, function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('removeLicense', function(data, cb)
    lib.callback('pt_mdt:removeLicense', false, function(success)
        cb(success)
    end, data)
end)

-- Vozidla
RegisterNUICallback('searchVehicles', function(data, cb)
    lib.callback('pt_mdt:searchVehicles', false, function(results)
        cb(results or {})
    end, data.query)
end)

RegisterNUICallback('getVehicleProfile', function(data, cb)
    lib.callback('pt_mdt:getVehicleProfile', false, function(profile)
        cb(profile)
    end, data.plate)
end)

RegisterNUICallback('saveVehicleStatus', function(data, cb)
    lib.callback('pt_mdt:saveVehicleStatus', false, function(success)
        cb(success)
    end, data)
end)

-- Incidenty
RegisterNUICallback('getIncidents', function(data, cb)
    lib.callback('pt_mdt:getIncidents', false, function(results)
        cb(results or {})
    end, data and data.query)
end)

RegisterNUICallback('getIncidentDetails', function(data, cb)
    lib.callback('pt_mdt:getIncidentDetails', false, function(incident)
        cb(incident)
    end, data.id)
end)

RegisterNUICallback('createIncident', function(data, cb)
    lib.callback('pt_mdt:createIncident', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('deleteIncident', function(data, cb)
    lib.callback('pt_mdt:deleteIncident', false, function(success)
        cb(success)
    end, data.id)
end)

-- Zatykače (Warrants)
RegisterNUICallback('getWarrants', function(data, cb)
    lib.callback('pt_mdt:getWarrants', false, function(warrants)
        cb(warrants or {})
    end, data and data.status)
end)

RegisterNUICallback('createWarrant', function(data, cb)
    lib.callback('pt_mdt:createWarrant', false, function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('updateWarrantStatus', function(data, cb)
    lib.callback('pt_mdt:updateWarrantStatus', false, function(success)
        cb(success)
    end, data)
end)

-- BOLO
RegisterNUICallback('getBolos', function(_, cb)
    lib.callback('pt_mdt:getBolos', false, function(bolos)
        cb(bolos or {})
    end)
end)

RegisterNUICallback('createBolo', function(data, cb)
    lib.callback('pt_mdt:createBolo', false, function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('deleteBolo', function(data, cb)
    lib.callback('pt_mdt:deleteBolo', false, function(success)
        cb(success)
    end, data.id)
end)

-- Nástěnka (Bulletins)
RegisterNUICallback('addBulletin', function(data, cb)
    lib.callback('pt_mdt:addBulletin', false, function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('deleteBulletin', function(data, cb)
    lib.callback('pt_mdt:deleteBulletin', false, function(success)
        cb(success)
    end, data.id)
end)

-- Dispečink
RegisterNUICallback('getDispatchCalls', function(_, cb)
    lib.callback('pt_mdt:getDispatchCalls', false, function(calls)
        cb(calls or {})
    end)
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if data.x and data.y then
        SetNewWaypoint(data.x + 0.0, data.y + 0.0)
        lib.notify({
            type = 'success',
            title = 'GPS Nastaveno',
            description = _U('gps_set')
        })
    end
    cb('ok')
end)

-- Živé jednotky pro taktickou mapu
RegisterNUICallback('getLiveUnits', function(_, cb)
    lib.callback('pt_mdt:getLiveUnits', false, function(units)
        cb(units or {})
    end)
end)

-- Uložení / ukončení přesunu radaru
RegisterNUICallback('saveRadarPosition', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

