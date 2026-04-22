fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'mos2'
description 'Underground Silo & Missile System (QBCore + qb-target)'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
