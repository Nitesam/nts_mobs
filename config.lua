Config = {}
Config.Debug = true          -- Black ricorda di mettere a false in prod.

Config.ZoneEmptyTimeout = 60 -- secondi usati per resettare la zone qualora rimanesse vuota, volendo spostabile in zona, così da avere limiti differenti per ogni zona.
Config.ZoneEntryCooldown = 5 -- previeni abusi in/out

Config.Mob = {
    SelectType = "target", -- ox_target, target or control [ox_target is preferred, but you can use the integrated one putting just "target", control is using key controls and distance check]
    MobType = {
        ["zombie_a"] = {
            ped = "G_M_M_Zombie_01",
            xp = nil,      -- messo a nil perchè dipende dal mio vecchio sistema di xp, se necessario da implementare.
            loot = {
                ["rame"] = {min = 1, max = 3, prob = 25}
            },
            attackTypes = {
                ["main"] = {
                    anim = { -- put anim nil for using default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap",
                    },
                    damage = 15,
                    timeBetween = 4 -- in seconds
                }
            },
            movClipset = "MOVE_M@DRUNK@VERYDRUNK",
            visualRange = 25, -- in meters
            attackRange = 1.5, -- in meters
            speed = 1.0,
            tryBeforeRemoving = 1, -- every try is equivalent to a range of seconds between 29 and 31 (if you expect to remove a dead mob that has not been looted after 5 minutes, set this to 10)
        },
        ["zombie_b"] = {
            ped = "U_M_Y_Zombie_01",
            xp = nil,
            loot = {
                ["rame"] = {min = 1, max = 3, prob = 25}
            },
            attackTypes = {
                ["main"] = {
                    anim = { -- put anim nil for using default game attack
                        animDict = "creatures@retriever@melee@streamed_core@",
                        animClip = "attack",
                    },
                    damage = 4,
                    timeBetween = 4 -- in seconds
                }
            },
            movClipset = "MOVE_M@DRUNK@VERYDRUNK",
            visualRange = 15, -- in meters
            attackRange = 1.5, -- in meters
            speed = 1.8,
            tryBeforeRemoving = 1, -- every try is equivalent to a range of seconds between 29 and 31 (if you expect to remove a dead mob that has not been looted after 5 minutes, set this to 10)
        },
        ["zombie_c"] = {
            ped = "G_M_M_Zombie_02",
            xp = nil,
            loot = {
                ["rame"] = {min = 1, max = 3, prob = 25}
            },
            attackTypes = {
                ["main"] = {
                    anim = { -- put anim nil for using default game attack
                        animDict = "creatures@retriever@melee@streamed_core@",
                        animClip = "attack",
                    },
                    damage = 10,
                    timeBetween = 4 -- in seconds
                }
            },
            movClipset = "MOVE_M@DRUNK@VERYDRUNK",
            visualRange = 15, -- in meters
            attackRange = 1.5, -- in meters
            speed = 1.15,
            tryBeforeRemoving = 1, -- every try is equivalent to a range of seconds between 29 and 31 (if you expect to remove a dead mob that has not been looted after 5 minutes, set this to 10)
        },
    },
    Zone = {
        ["zone_a"] = {
            name = "Zone A",
            blip = {
                sprite = 50,
                color = 3,
                display = 4,
                scale = 1.0
            },
            pos = { -- all the positions that are using to create polygon
                vector3(291.73077392578, 3443.4208984375, 35.67728805542),
                vector3(984.38073730469, 3527.0632324219, 32.861618041992),
                vector3(1118.4897460938, 3270.9006347656, 37.023284912109),
                vector3(226.31533813477, 3154.4365234375, 41.226364135742),
            },
            mobs = { -- mobs that can spawn in this zone (give the right weight to each mob)
                ["zombie_b"] = 100 -- higher the value, higher the chance to spawn
            },
            forcedMinHeight = nil, -- 90.0, -- forced minimum for poly
            mobMax = 40, -- maximum amount of mobs in zone
            newSpawnTime = 15, -- in seconds
            spawnBorderDistance = 25, -- distanza minima in metri dal bordo del poligono per spawn
            debug = true
        }
    }
}