fx_version 'cerulean'
game 'gta5'

name 'qb-panicdevice'
author 'GPT-5.3-Codex'
description 'Realistic panic device for QBCore'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
    'install.lua',
}

dependencies {
    'qb-core'
}
