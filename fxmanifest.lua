fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'pt_scripts (it-petrfila)'
description 'pt_mdt - Moderní Policejní Mobile Data Terminal pro FiveM (ESX Legacy & ox_inventory)'
version '1.0.0'
repository 'https://github.com/it-petrfila/pt_mdt'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/penal_code.lua',
    'locales/*.lua',
    'shared/locale.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/citizens.lua',
    'server/vehicles.lua',
    'server/incidents.lua',
    'server/warrants.lua',
    'server/dispatch.lua'
}

client_scripts {
    'client/main.lua',
    'client/animation.lua',
    'client/nui.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/**/*.css',
    'web/js/**/*.js',
    'web/img/**/*',
    'locales/*.json'
}

dependencies {
    'es_extended',
    'oxmysql',
    'ox_lib'
}
