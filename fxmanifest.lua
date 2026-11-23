fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Luna for Ianspinn'
description 'Utility Locating job — transmitter + receiver, buried fiber / electric / gas / water lines across the map'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
