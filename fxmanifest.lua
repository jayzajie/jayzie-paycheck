fx_version 'cerulean'
game 'gta5'

author 'jayzie-paycheck'
description 'Jayzie Paycheck System with ox_target, ox_lib, and ESX'
version '1.0.0'

dependencies {
    'ox_lib',       
    'ox_target',    
    'oxmysql'      
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

lua54 'yes' 
