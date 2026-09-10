local ESX = exports['es_extended']:getSharedObject()

-- Vyhledávání občanů
lib.callback.register('pt_mdt:searchCitizens', function(src, query)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not query or query == '' then return {} end

    local searchQuery = ('%%%s%%'):format(query)
    local results = MySQL.query.await([[
        SELECT 
            u.identifier,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            u.sex,
            u.job,
            u.job_grade,
            u.phone_number,
            cd.avatar_url
        FROM users u
        LEFT JOIN pt_mdt_citizen_data cd ON u.identifier = cd.identifier
        WHERE 
            CONCAT(u.firstname, ' ', u.lastname) LIKE ? 
            OR u.identifier LIKE ? 
            OR (u.phone_number IS NOT NULL AND u.phone_number LIKE ?)
        LIMIT ?
    ]], { searchQuery, searchQuery, searchQuery, Config.Limits.MaxSearchResults }) or {}

    return results
end)

-- Získání detailního profilu občana
lib.callback.register('pt_mdt:getCitizenProfile', function(src, identifier)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not identifier then return nil end

    -- Základní údaje
    local user = MySQL.single.await([[
        SELECT 
            u.identifier,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            u.sex,
            u.height,
            u.job,
            u.job_grade,
            u.phone_number,
            j.label AS job_label,
            jg.label AS grade_label,
            cd.avatar_url,
            cd.notes
        FROM users u
        LEFT JOIN jobs j ON u.job = j.name
        LEFT JOIN job_grades jg ON u.job = jg.job_name AND u.job_grade = jg.grade
        LEFT JOIN pt_mdt_citizen_data cd ON u.identifier = cd.identifier
        WHERE u.identifier = ?
    ]], { identifier })

    if not user then return nil end

    -- Vlastněné licence
    local licenses = MySQL.query.await([[
        SELECT ul.type, COALESCE(l.label, ul.type) AS label
        FROM user_licenses ul
        LEFT JOIN licenses l ON ul.type = l.type
        WHERE ul.owner = ?
    ]], { identifier }) or {}

    -- Trestní rejstřík (convictions)
    local convictions = MySQL.query.await([[
        SELECT id, incident_id, charge_name, fine, prison, officer_name, created_at
        FROM pt_mdt_convictions
        WHERE identifier = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]], { identifier }) or {}

    -- Aktivní zatykače
    local warrants = MySQL.query.await([[
        SELECT id, reason, creator_name, status, created_at
        FROM pt_mdt_warrants
        WHERE suspect_identifier = ? AND status = 'active'
    ]], { identifier }) or {}

    -- Vlastněná vozidla
    local vehicles = MySQL.query.await([[
        SELECT 
            ov.plate, 
            ov.vehicle,
            vd.stolen
        FROM owned_vehicles ov
        LEFT JOIN pt_mdt_vehicle_data vd ON ov.plate = vd.plate
        WHERE ov.owner = ?
    ]], { identifier }) or {}

    return {
        profile = user,
        licenses = licenses,
        convictions = convictions,
        warrants = warrants,
        vehicles = vehicles
    }
end)

-- Uložení poznámek a fotografie občana
lib.callback.register('pt_mdt:saveCitizenProfile', function(src, data)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not data.identifier then return false end

    MySQL.query.await([[
        INSERT INTO pt_mdt_citizen_data (identifier, avatar_url, notes)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE avatar_url = VALUES(avatar_url), notes = VALUES(notes)
    ]], { data.identifier, data.avatar_url or '', data.notes or '' })

    return true
end)
