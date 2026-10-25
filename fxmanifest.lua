fx_version 'cerulean'
game 'gta5'

author 'zodi4ctvn'
description 'Shared storage system for QBCore and Qbox (QBX) + ox_inventory'
version '1.0.0'
repository 'https://github.com/zodi4ctvn/zodi4c-storage'

lua54 'yes'

shared_scripts {
    'config.lua',
    'locales/tr.lua',
    'locales/en.lua',
    'shared/locale.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*.svg'
}

dependencies {
    'oxmysql',
    'qb-core',
    'ox_inventory'
}
