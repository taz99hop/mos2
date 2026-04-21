fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'mos2'
description 'Police emergency wall button (QBCore + qb-target + qb-doorlock)'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
