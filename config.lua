Config = {}
Config.Debug = true

Config.Mob = {
    SelectType = "target", -- ox_target, target or control [ox_target is preferred, but you can use the integrated one putting just "target", control is using key controls and distance check]
    MobType = {
        ["zombie_a"] = {
            ped = "G_M_M_Zombie_01",
            xp = { -- set to nil if not using ns_ab
                ["forza"] = {min = 4, max = 10},
            },
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
                vector3(-614.81750488281, -492.20806884766, 33.76),
                vector3(-653.82049560547, -481.6484375, 33.76),
                vector3(-654.80548095703, -342.49392700195, 33.76),
                vector3(-601.068359375, -350.92135620117, 34.115264892578),
            },
            mobs = { -- mobs that can spawn in this zone (give the right weight to each mob)
                ["zombie_b"] = 100 -- higher the value, higher the chance to spawn
            },
            mobMax = 80, -- maximum amount of mobs in zone
            newSpawnTime = 15, -- in seconds
            debug = false
        }
    }
}

Config.ToxicZone = {
    Enable = false,
    GlobalRendering = 24, -- in meters
    Zones = {
        ["ZoneA"] = {
            name = "Ruined Gas Zone",
            thickness = 2,
            blip = {
                sprite = 50,
                color = 3,
                display = 4,
                scale = 1.0
            },
            positions = {
                vec3(-929.35, -3514.32, 13.97),
                vec3(-757.13, -3239.53, 13.97),
                vec3(-1577.84, -2744.62, 13.97),
                vec3(-1244.18, -2164.90, 13.97),
                vec3(-1304.01, -2133.10, 13.97),
                vec3(-1830.69, -2872.95, 13.97),
            },
            effects = {
                damage = 1,
                tickTime = 1, -- in secondi
                effectsDistance = 3,
                borderDistance = 20,
                particle = {
                    particleDictionary = "core",
                    particleName = "ent_amb_cig_smoke_linger",
                    color = {0.0, 1.0, 0.0, 1},
                    alpha = 1.5,
                    scale = 4.0,
                }
            },
            debug = false
        }
    }
}

