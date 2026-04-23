fx_version 'cerulean'
game 'gta5'

name 'rocket_system'
author 'mos2-dev'
version '1.0.0'
description 'Realistic missile launcher system for QBCore'

lua54 'yes'

shared_script 'locales.lua'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'Rc2menu'
}
