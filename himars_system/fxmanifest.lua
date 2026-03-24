fx_version 'cerulean'
game 'gta5'

name 'himars_system'
author 'custom'
description 'Long range MLRS system with old military UI'
version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
