Config = {}

-- Jazyk rozhraní: 'cs' | 'en' | 'de'
Config.Locale = 'en'

-- Povolení zaměstnání (frakce) a jejich označení
Config.AllowedJobs = {
    ['police'] = { label = 'Police Department', badge = 'LSPD', canIssueWarrant = true, canSendToJail = true },
    ['sheriff'] = { label = 'Sheriff Office', badge = 'LSSD', canIssueWarrant = true, canSendToJail = true }
}

-- Povolit přístup administrátorům pro testování a správu (i když nemají job police)
Config.AllowAdminBypass = true

-- Otevírání MDT (pouze přes položku v inventáři)
Config.OpenOptions = {
    ItemOnly = true                    -- Otevírání výhradně použitím položky v inventáři (i ve vozidle)
}

-- Název položky v ox_inventory
Config.ItemName = 'mdt_tablet'

-- Animace a prop tabletu
Config.Animation = {
    Enable = true,
    Prop = 'prop_cs_tablet',
    Bone = 28422,
    Pos = vector3(0.0, -0.03, 0.0),
    Rot = vector3(20.0, -90.0, 0.0),
    Dict = 'amb@world_human_seat_wall_tablet@female@base',
    Anim = 'base'
}

-- Nastavení automatického účtování pokut
Config.Billing = {
    Enable = true,                     -- Vytvářet automatické pokuty/faktury
    UseSociety = true,                 -- Připsat částku na účet society
    SocietyName = 'society_police',    -- Účet policie
    FallbackSociety = 'society_sheriff'
}

-- Integrace vězení
Config.Jail = {
    Enable = true,
    Event = 'esx_jail:sendToJail',     -- Standardní event pro posílání do vězení (nebo qalle-jail atd.)
}

-- Nastavení vyhledávání a limitů
Config.Limits = {
    MaxSearchResults = 25,
    RecentIncidents = 10,
    ActiveWarrants = 15
}
