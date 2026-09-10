local ESX = exports['es_extended']:getSharedObject()

-- Automatická inicializace databázových tabulek při startu skriptu
MySQL.ready(function()
    print('^4[pt_mdt]^7 Kontrola a vytváření databázových tabulek...')

    local schema = {
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_incidents` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `title` VARCHAR(255) NOT NULL,
            `description` LONGTEXT DEFAULT NULL,
            `creator_identifier` VARCHAR(64) NOT NULL,
            `creator_name` VARCHAR(128) NOT NULL,
            `suspects` LONGTEXT DEFAULT '[]',
            `officers` LONGTEXT DEFAULT '[]',
            `civilians` LONGTEXT DEFAULT '[]',
            `evidence` LONGTEXT DEFAULT '[]',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_creator` (`creator_identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_warrants` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `suspect_identifier` VARCHAR(64) NOT NULL,
            `suspect_name` VARCHAR(128) NOT NULL,
            `reason` TEXT NOT NULL,
            `creator_identifier` VARCHAR(64) NOT NULL,
            `creator_name` VARCHAR(128) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'active',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_suspect` (`suspect_identifier`),
            INDEX `idx_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_bolos` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `type` VARCHAR(20) NOT NULL DEFAULT 'person',
            `title` VARCHAR(255) NOT NULL,
            `plate` VARCHAR(16) DEFAULT NULL,
            `suspect_name` VARCHAR(128) DEFAULT NULL,
            `description` TEXT NOT NULL,
            `creator_name` VARCHAR(128) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'active',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_bolo_status` (`status`),
            INDEX `idx_bolo_type` (`type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_bulletins` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `title` VARCHAR(255) NOT NULL,
            `message` TEXT NOT NULL,
            `author` VARCHAR(128) NOT NULL,
            `pinned` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_citizen_data` (
            `identifier` VARCHAR(64) NOT NULL,
            `avatar_url` TEXT DEFAULT NULL,
            `notes` TEXT DEFAULT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_vehicle_data` (
            `plate` VARCHAR(16) NOT NULL,
            `stolen` TINYINT(1) NOT NULL DEFAULT 0,
            `notes` TEXT DEFAULT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]],
        [[
        CREATE TABLE IF NOT EXISTS `pt_mdt_convictions` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `incident_id` INT(11) DEFAULT NULL,
            `charge_name` VARCHAR(255) NOT NULL,
            `fine` INT(11) NOT NULL DEFAULT 0,
            `prison` INT(11) NOT NULL DEFAULT 0,
            `officer_name` VARCHAR(128) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_convict_identifier` (`identifier`),
            INDEX `idx_convict_incident` (`incident_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
    }

    for _, query in ipairs(schema) do
        MySQL.query.await(query)
    end
    print('^2[pt_mdt]^7 Všechny databázové tabulky byly úspěšně zkontrolovány a vytvořeny!')
end)

-- Kontrola oprávnění hráče
function IsPlayerAllowed(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false, nil end
    local job = xPlayer.job and xPlayer.job.name
    if job and Config.AllowedJobs[job] then
        return true, xPlayer
    end
    -- Povolit adminům pokud je zapnutý bypass v configu
    if Config.AllowAdminBypass then
        local group = (xPlayer.getGroup and xPlayer.getGroup()) or xPlayer.group
        if group == 'admin' or group == 'superadmin' then
            return true, xPlayer
        end
    end
    return false, xPlayer
end

-- Registrace použitelné položky v ESX
ESX.RegisterUsableItem(Config.ItemName, function(source)
    local allowed, xPlayer = IsPlayerAllowed(source)
    if not allowed then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = _U('not_authorized')
        })
        return
    end
    TriggerClientEvent('pt_mdt:openMDT', source, true)
end)

-- Serverový export pro ox_inventory
exports('openTablet', function(event, item, inventory, slot, data)
    local src = source
    if not src or src == 0 then
        if type(inventory) == 'table' and inventory.id then
            src = inventory.id
        elseif type(event) == 'table' and event.source then
            src = event.source
        end
    end
    if src then
        local allowed, xPlayer = IsPlayerAllowed(src)
        if not allowed then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = _U('not_authorized')
            })
            return false
        end
        TriggerClientEvent('pt_mdt:openMDT', src, true)
    end
end)

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
    if not allowed then
        print(('[pt_mdt] Hráč ID %s nemá oprávnění k MDT'):format(src))
        return nil
    end

    local jobName = xPlayer.job and xPlayer.job.name or 'police'
    local jobInfo = Config.AllowedJobs[jobName] or { label = 'Police Dept', badge = 'LSPD', canIssueWarrant = true, canSendToJail = true }
    local officerData = {
        name = xPlayer.getName(),
        identifier = xPlayer.identifier,
        job = jobName,
        jobLabel = xPlayer.job and xPlayer.job.label or 'Police Officer',
        grade = xPlayer.job and xPlayer.job.grade_label or 'Officer',
        badge = jobInfo.badge or 'LSPD',
        canIssueWarrant = jobInfo.canIssueWarrant or true,
        canSendToJail = jobInfo.canSendToJail or true
    }

    -- Počet hlídek ve službě
    local activeOfficers = 0
    local players = ESX.GetExtendedPlayers()
    for _, ply in pairs(players) do
        if ply.job and Config.AllowedJobs[ply.job.name] then
            activeOfficers = activeOfficers + 1
        end
    end

    -- Statistiky s bezpečným obalením
    local warrantCount = 0
    pcall(function()
        warrantCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_warrants WHERE status = ?', {'active'}) or 0
    end)

    local boloCount = 0
    pcall(function()
        boloCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_bolos WHERE status = ?', {'active'}) or 0
    end)

    local incidentCount = 0
    pcall(function()
        incidentCount = MySQL.scalar.await('SELECT COUNT(*) FROM pt_mdt_incidents WHERE created_at >= NOW() - INTERVAL 1 DAY') or 0
    end)

    -- Bulletins (Nástěnka)
    local bulletins = {}
    pcall(function()
        bulletins = MySQL.query.await('SELECT * FROM pt_mdt_bulletins ORDER BY pinned DESC, created_at DESC LIMIT 10') or {}
    end)

    -- Poslední incidenty pro dashboard
    local recentIncidents = {}
    pcall(function()
        recentIncidents = MySQL.query.await('SELECT id, title, creator_name, created_at FROM pt_mdt_incidents ORDER BY created_at DESC LIMIT ?', { Config.Limits.RecentIncidents }) or {}
    end)

    local function GetLocalizedPenalCode()
        local locale = Config.Locale or 'cs'
        local result = {}
        for _, cat in ipairs(PenalCode) do
            local catName = cat.category
            if type(catName) == 'table' then
                catName = catName[locale] or catName['en'] or catName['cs'] or ''
            end
            local items = {}
            for _, it in ipairs(cat.items) do
                local itemTitle = it.title
                if type(itemTitle) == 'table' then
                    itemTitle = itemTitle[locale] or itemTitle['en'] or itemTitle['cs'] or ''
                end
                table.insert(items, {
                    id = it.id,
                    title = itemTitle,
                    fine = it.fine,
                    prison = it.prison
                })
            end
            table.insert(result, {
                category = catName,
                items = items
            })
        end
        return result
    end

    print(('[pt_mdt] Úspěšně odeslána data MDT pro důstojníka %s (ID %s)'):format(officerData.name, src))

    return {
        officer = officerData,
        activeOfficers = activeOfficers,
        warrantCount = warrantCount,
        boloCount = boloCount,
        incidentCount = incidentCount,
        bulletins = bulletins,
        recentIncidents = recentIncidents,
        penalCode = GetLocalizedPenalCode(),
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

-- Získání živých pozic státních složek pro taktickou GPS mapu
lib.callback.register('pt_mdt:getLiveUnits', function(src)
    local allowed = IsPlayerAllowed(src)
    if not allowed then return {} end

    local units = {}
    local players = ESX.GetExtendedPlayers()
    for _, ply in pairs(players) do
        local job = ply.job and ply.job.name
        if job and (Config.AllowedJobs[job] or job == 'ambulance') then
            local ped = GetPlayerPed(ply.source)
            if ped and DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local inVeh = GetVehiclePedIsIn(ped, false) ~= 0

                table.insert(units, {
                    id = ply.source,
                    name = ply.getName(),
                    job = job,
                    jobLabel = ply.job.label,
                    grade = ply.job.grade_label,
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    heading = math.floor(heading),
                    inVehicle = inVeh
                })
            end
        end
    end

    return units
end)
