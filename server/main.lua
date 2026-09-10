local ESX = exports['es_extended']:getSharedObject()

-- Kontrola oprávnění hráče
function IsPlayerAllowed(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false, nil end
    local job = xPlayer.job and xPlayer.job.name
    if job and Config.AllowedJobs[job] then
        return true, xPlayer
    end
    return false, xPlayer
end

-- Registrace použitelné položky v ox_inventory
CreateThread(function()
    Wait(500)
    local hasOxInventory = GetResourceState('ox_inventory') == 'started'
    if hasOxInventory then
        exports['ox_inventory']:registerHook('useItem', function(payload)
            if payload.name == Config.ItemName then
                local src = payload.source
                local allowed, xPlayer = IsPlayerAllowed(src)
                if not allowed then
                    TriggerClientEvent('ox_lib:notify', src, {
                        type = 'error',
                        description = _U('not_authorized')
                    })
                    return false
                end
                TriggerClientEvent('pt_mdt:openMDT', src, true)
                return false -- nekonzumovat item
            end
        end, {
            itemFilter = { [Config.ItemName] = true }
        })
    end
end)

-- Callback pro získání počátečních dat (přihlášený policista, statistiky, lokalizace, sazebník)
lib.callback.register('pt_mdt:getInitialData', function(src)
    local allowed, xPlayer = IsPlayerAllowed(src)
    if not allowed then return nil end

    local jobInfo = Config.AllowedJobs[xPlayer.job.name]
    local officerData = {
        name = xPlayer.getName(),
        identifier = xPlayer.identifier,
        job = xPlayer.job.name,
        jobLabel = xPlayer.job.label,
        grade = xPlayer.job.grade_label,
        badge = jobInfo and jobInfo.badge or 'LSPD',
        canIssueWarrant = jobInfo and jobInfo.canIssueWarrant or false,
        canSendToJail = jobInfo and jobInfo.canSendToJail or false
    }

    -- Počet hlídek ve službě
    local activeOfficers = 0
    local players = ESX.GetExtendedPlayers()
    for _, ply in pairs(players) do
        if ply.job and Config.AllowedJobs[ply.job.name] then
            activeOfficers = activeOfficers + 1
        end
    end

    -- Statistiky
    local warrantCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_warrants WHERE status = ?', {'active'}) or 0
    local boloCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_bolos WHERE status = ?', {'active'}) or 0
    local incidentCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_incidents WHERE created_at >= NOW() - INTERVAL 1 DAY') or 0

    -- Bulletins (Nástěnka)
    local bulletins = MySQL.query.await('SELECT * FROM pt_mdt_bulletins ORDER BY pinned DESC, created_at DESC LIMIT 10') or {}

    -- Poslední incidenty pro dashboard
    local recentIncidents = MySQL.query.await('SELECT id, title, creator_name, created_at FROM pt_mdt_incidents ORDER BY created_at DESC LIMIT ?', { Config.Limits.RecentIncidents }) or {}

    return {
        officer = officerData,
        activeOfficers = activeOfficers,
        warrantCount = warrantCount,
        boloCount = boloCount,
        incidentCount = incidentCount,
        bulletins = bulletins,
        recentIncidents = recentIncidents,
        penalCode = PenalCode,
        locales = GetCurrentLocaleTable()
    }
end)

-- Přidání záznamu na nástěnku
lib.callback.register('pt_mdt:addBulletin', function(src, data)
    local allowed, xPlayer = IsPlayerAllowed(src)
    if not allowed then return false end

    local authorName = ('%s (%s)'):format(xPlayer.getName(), xPlayer.job.grade_label)
    local insertId = MySQL.insert.await('INSERT INTO pt_mdt_bulletins (title, message, author, pinned) VALUES (?, ?, ?, ?)', {
        data.title,
        data.message,
        authorName,
        data.pinned and 1 or 0
    })

    return insertId ~= nil
end)

-- Smazání záznamu z nástěnky
lib.callback.register('pt_mdt:deleteBulletin', function(src, id)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return false end

    local affected = MySQL.update.await('DELETE FROM pt_mdt_bulletins WHERE id = ?', { id })
    return affected > 0
end)
