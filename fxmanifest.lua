fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'mos2_command'
author 'GPT-5.3-Codex'
description 'Advanced Military Command System (QBCore) with ballistic missile physics'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/ballistics.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
