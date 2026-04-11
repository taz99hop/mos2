fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Resistance Full System'
description 'Advanced resistance gameplay system for QBCore'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html'
}

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu',
    'qb-input'
}
