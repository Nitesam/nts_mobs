fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Nitesam"
version "0.0.2"
description "Multi-framework mob system (QB-Core / ESX / Standalone)"

shared_script {
    "config.lua",
    "shared/enums.lua",
    "shared/bridge.lua",
    "shared/functions.lua",
    "@ox_lib/init.lua"
}

client_scripts { "client/*.lua" }
server_scripts { "server/*.lua" }
