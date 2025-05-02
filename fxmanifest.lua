fx_version 'cerulean'
game 'gta5'

author 'Favi'
description 'Developer Tools for qb-core framework'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/events.lua',
    'client/nui.lua',
    'client/debug.lua'
}

server_scripts {
    'server/main.lua',
    'server/events.lua',
    'server/functions.lua'
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/img/*.png'
}

-- lua54 'yes'  
