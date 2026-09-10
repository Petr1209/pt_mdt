local ESX = exports['es_extended']:getSharedObject()

-- Vyhledávání vozidel
lib.callback.register('pt_mdt:searchVehicles', function(src, query)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not query or query == '' then return {} end

    local searchQuery = ('%%%s%%'):format(query:upper())
    local results = MySQL.query.await([[
        SELECT 
            ov.plate,
            ov.owner,
            CONCAT(u.firstname, ' ', u.lastname) AS owner_name,
            ov.vehicle,
            vd.stolen
        FROM owned_vehicles ov
        LEFT JOIN users u ON ov.owner = u.identifier
        LEFT JOIN pt_mdt_vehicle_data vd ON ov.plate = vd.plate
        WHERE ov.plate LIKE ?
        LIMIT ?
    ]], { searchQuery, Config.Limits.MaxSearchResults }) or {}

    return results
end)

-- Získání detailu vozidla
lib.callback.register('pt_mdt:getVehicleProfile', function(src, plate)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not plate then return nil end

    local cleanPlate = string.upper(plate)
    local vehicle = MySQL.single.await([[
        SELECT 
            ov.plate,
            ov.owner,
            CONCAT(u.firstname, ' ', u.lastname) AS owner_name,
            ov.vehicle,
            vd.stolen,
            vd.notes
        FROM owned_vehicles ov
        LEFT JOIN users u ON ov.owner = u.identifier
        LEFT JOIN pt_mdt_vehicle_data vd ON ov.plate = vd.plate
        WHERE ov.plate = ?
    ]], { cleanPlate })

    -- Pokud není vozidlo v owned_vehicles (např. NPC auto), zkusíme alespoň data z MDT
    if not vehicle then
        local mdtData = MySQL.single.await('SELECT * FROM pt_mdt_vehicle_data WHERE plate = ?', { cleanPlate })
        if mdtData then
            vehicle = {
                plate = cleanPlate,
                owner = nil,
                owner_name = _U('unknown'),
                vehicle = '{}',
                stolen = mdtData.stolen,
                notes = mdtData.notes
            }
        end
    end

    -- Zjistit, zda je na vozidlo aktivní BOLO
    local bolo = MySQL.single.await([[
        SELECT id, title, description, creator_name, created_at
        FROM pt_mdt_bolos
        WHERE type = 'vehicle' AND plate = ? AND status = 'active'
    ]], { cleanPlate })

    return {
        vehicle = vehicle,
        bolo = bolo
    }
end)

-- Uložení stavu vozidla (stolen, poznámky)
lib.callback.register('pt_mdt:saveVehicleStatus', function(src, data)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not data.plate then return false end

    local cleanPlate = string.upper(data.plate)
    MySQL.query.await([[
        INSERT INTO pt_mdt_vehicle_data (plate, stolen, notes)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE stolen = VALUES(stolen), notes = VALUES(notes)
    ]], { cleanPlate, data.stolen and 1 or 0, data.notes or '' })

    return true
end)
