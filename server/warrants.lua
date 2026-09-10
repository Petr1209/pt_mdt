local ESX = exports['es_extended']:getSharedObject()

-- ==========================================================
-- WARRANTS (Zatykače)
-- ==========================================================

-- Získání zatykačů
lib.callback.register('pt_mdt:getWarrants', function(src, status)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return {} end

    local currentStatus = status or 'active'
    local warrants = MySQL.query.await([[
        SELECT id, suspect_identifier, suspect_name, reason, creator_name, status, created_at, expires_at
        FROM pt_mdt_warrants
        WHERE status = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]], { currentStatus }) or {}

    return warrants
end)

-- Vytvoření zatykače
lib.callback.register('pt_mdt:createWarrant', function(src, data)
    local allowed, xPlayer = IsPlayerAllowed(src)
    if not allowed or not data.suspect_name or not data.reason then return false end

    local officerName = ('%s (%s)'):format(xPlayer.getName(), xPlayer.job.grade_label)

    local id = MySQL.insert.await([[
        INSERT INTO pt_mdt_warrants (suspect_identifier, suspect_name, reason, creator_identifier, creator_name, status)
        VALUES (?, ?, ?, ?, ?, 'active')
    ]], {
        data.suspect_identifier or '',
        data.suspect_name,
        data.reason,
        xPlayer.identifier,
        officerName
    })

    -- Notifikace všem online policistům
    if id then
        local players = ESX.GetExtendedPlayers()
        for _, ply in pairs(players) do
            if ply.job and Config.AllowedJobs[ply.job.name] then
                TriggerClientEvent('ox_lib:notify', ply.source, {
                    type = 'warning',
                    title = 'Nový zatykač',
                    description = ('Byl vydán zatykač na osobu: %s'):format(data.suspect_name)
                })
            end
        end
    end

    return id ~= nil
end)

-- Změna stavu zatykače (např. uzavření po zatčení)
lib.callback.register('pt_mdt:updateWarrantStatus', function(src, data)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not data.id then return false end

    local affected = MySQL.update.await('UPDATE pt_mdt_warrants SET status = ? WHERE id = ?', {
        data.status or 'closed',
        data.id
    })

    return affected > 0
end)

-- ==========================================================
-- BOLO (Pátrání po osobách a vozidlech)
-- ==========================================================

-- Získání aktivních BOLO
lib.callback.register('pt_mdt:getBolos', function(src)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return {} end

    local bolos = MySQL.query.await([[
        SELECT id, type, title, plate, suspect_name, description, creator_name, status, created_at
        FROM pt_mdt_bolos
        WHERE status = 'active'
        ORDER BY created_at DESC
        LIMIT 50
    ]]) or {}

    return bolos
end)

-- Vytvoření BOLO
lib.callback.register('pt_mdt:createBolo', function(src, data)
    local allowed, xPlayer = IsPlayerAllowed(src)
    if not allowed or not data.title or not data.description then return false end

    local officerName = ('%s (%s)'):format(xPlayer.getName(), xPlayer.job.grade_label)

    local id = MySQL.insert.await([[
        INSERT INTO pt_mdt_bolos (type, title, plate, suspect_name, description, creator_name, status)
        VALUES (?, ?, ?, ?, ?, ?, 'active')
    ]], {
        data.type or 'person',
        data.title,
        data.plate and string.upper(data.plate) or nil,
        data.suspect_name or nil,
        data.description,
        officerName
    })

    -- Notifikace všem online policistům
    if id then
        local players = ESX.GetExtendedPlayers()
        for _, ply in pairs(players) do
            if ply.job and Config.AllowedJobs[ply.job.name] then
                TriggerClientEvent('ox_lib:notify', ply.source, {
                    type = 'error',
                    title = 'BOLO VYHLÁŠENO',
                    description = ('Pátrání: %s'):format(data.title)
                })
            end
        end
    end

    return id ~= nil
end)

-- Uzavření / smazání BOLO
lib.callback.register('pt_mdt:deleteBolo', function(src, id)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not id then return false end

    local affected = MySQL.update.await('DELETE FROM pt_mdt_bolos WHERE id = ?', { id })
    return affected > 0
end)
