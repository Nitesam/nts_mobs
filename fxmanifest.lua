fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Nitesam"

shared_script {
    "config.lua",
    "shared/*.lua",
    "@ox_lib/init.lua",
    "@es_extended/imports.lua"
}

client_scripts {
    "client/*.lua"
}

server_scripts {
    "server/*.lua"
}

escrow_ignore {
	'config.lua',
    'shared/functions.lua',
}