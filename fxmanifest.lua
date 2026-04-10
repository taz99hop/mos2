fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'mos2 assistant'
description 'QBCore ballistic missile launch system'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'stream/*.ydr',
    'stream/*.ytd',
    'stream/*.ytyp'
}

dependency 'qb-target'
