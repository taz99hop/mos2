fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'mos2'
description 'Tactical cinematic airstrike system for QBCore'
version '1.1.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core'
}
