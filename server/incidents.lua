local ESX = exports['es_extended']:getSharedObject()

-- Seznam incidentů
lib.callback.register('pt_mdt:getIncidents', function(src, query)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return {} end

    local sql = 'SELECT id, title, creator_name, created_at FROM pt_mdt_incidents ORDER BY created_at DESC LIMIT 30'
    local params = {}

    if query and query ~= '' then
        sql = 'SELECT id, title, creator_name, created_at FROM pt_mdt_incidents WHERE title LIKE ? OR description LIKE ? ORDER BY created_at DESC LIMIT 30'
        local q = ('%%%s%%'):format(query)
        params = { q, q }
    end

    local incidents = MySQL.query.await(sql, params) or {}
    return incidents
end)

-- Detail incidentu
lib.callback.register('pt_mdt:getIncidentDetails', function(src, id)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not id then return nil end

    local incident = MySQL.single.await('SELECT * FROM pt_mdt_incidents WHERE id = ?', { id })
    if not incident then return nil end

    incident.suspects = json.decode(incident.suspects) or {}
    incident.officers = json.decode(incident.officers) or {}
    incident.civilians = json.decode(incident.civilians) or {}
    incident.evidence = json.decode(incident.evidence) or {}

    return incident
end)

-- Vytvoření / uložení incidentu
lib.callback.register('pt_mdt:createIncident', function(src, data)
    local allowed, xPlayer = IsPlayerAllowed(src)
    if not allowed or not data.title then return false end

    local officerName = ('%s (%s)'):format(xPlayer.getName(), xPlayer.job.grade_label)

    local incidentId = MySQL.insert.await([[
        INSERT INTO pt_mdt_incidents (title, description, creator_identifier, creator_name, suspects, officers, civilians, evidence)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.title,
        data.description or '',
        xPlayer.identifier,
        officerName,
        json.encode(data.suspects or {}),
        json.encode(data.officers or {}),
        json.encode(data.civilians or {}),
        json.encode(data.evidence or {})
    })

    if not incidentId then return false end

    -- Zpracování trestů a rejstříku pro každého podezřelého
    if data.suspects and type(data.suspects) == 'table' then
        for _, suspect in ipairs(data.suspects) do
            local identifier = suspect.identifier
            local charges = suspect.charges or {}
            local totalFine = 0
            local totalPrison = 0

            for _, charge in ipairs(charges) do
                local fine = tonumber(charge.fine) or 0
                local prison = tonumber(charge.prison) or 0
                totalFine = totalFine + fine
                totalPrison = totalPrison + prison

                -- Uložení záznamu do rejstříku
                if identifier and identifier ~= '' then
                    MySQL.insert.await([[
                        INSERT INTO pt_mdt_convictions (identifier, incident_id, charge_name, fine, prison, officer_name)
                        VALUES (?, ?, ?, ?, ?, ?)
                    ]], {
                        identifier,
                        incidentId,
                        charge.title or charge.id,
                        fine,
                        prison,
                        officerName
                    })
                end
            end

            -- Pokud má podezřelý pokutu a je zapnutý billing
            if Config.Billing.Enable and totalFine > 0 and identifier then
                local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
                local society = Config.Billing.UseSociety and (xPlayer.job.name == 'sheriff' and Config.Billing.FallbackSociety or Config.Billing.SocietyName) or 'society_police'

                if targetPlayer then
                    -- Hráč je online: vystavíme fakturu přes esx_billing nebo strhneme
                    TriggerEvent('esx_billing:sendBill', targetPlayer.source, society, ('MDT Pokuta: %s'):format(data.title), totalFine)
                    TriggerClientEvent('ox_lib:notify', targetPlayer.source, {
                        type = 'warning',
                        title = 'Policejní pokuta',
                        description = _U('fine_issued_msg', totalFine, data.title)
                    })
                else
                    -- Hráč je offline: vložíme záznam do billing tabulky
                    MySQL.insert.await('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (?, ?, ?, ?, ?, ?)', {
                        identifier,
                        xPlayer.identifier,
                        'society',
                        society,
                        ('MDT Pokuta: %s'):format(data.title),
                        totalFine
                    })
                end
            end

            -- Pokud má podezřelý trest vězení
            if Config.Jail.Enable and totalPrison > 0 and identifier then
                local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
                if targetPlayer then
                    TriggerEvent(Config.Jail.Event, targetPlayer.source, totalPrison)
                end
            end
        end
    end

    return incidentId
end)

-- Smazání incidentu
lib.callback.register('pt_mdt:deleteIncident', function(src, id)
    local allowed = IsPlayerAllowed(src)
    if not allowed or not id then return false end

    MySQL.update.await('DELETE FROM pt_mdt_convictions WHERE incident_id = ?', { id })
    local affected = MySQL.update.await('DELETE FROM pt_mdt_incidents WHERE id = ?', { id })
    return affected > 0
end)
