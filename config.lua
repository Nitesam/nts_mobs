Config = {}
Config.Debug = true

Config.Mob = {
    SelectType = "target", -- ox_target, target or control [ox_target is preferred, but you can use the integrated one putting just "target", control is using key controls and distance check]
    MobType = {
        ["zombie_a"] = {
            ped = "a_m_m_skater_01",
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
                        animClip = "",
                    },
                    damage = 15,
                    timeBetween = 4 -- in seconds
                }
            },
            movClipset = "MOVE_M@DRUNK@VERYDRUNK",
            visualRange = 25, -- in meters
            tryBeforeRemoving = 1, -- every try is equivalent to a range of seconds between 29 and 31 (if you expect to remove a dead mob that has not been looted after 5 minutes, set this to 10)
        },
        ["zombie_b"] = {
            ped = "a_f_y_juggalo_01",
            xp = nil,
            loot = {
                ["rame"] = {min = 1, max = 3, prob = 25}
            },
            attackTypes = {
                ["main"] = {
                    anim = { -- put anim nil for using default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "",
                    },
                    damage = 10,
                    timeBetween = 4 -- in seconds
                }
            },
            movClipset = "MOVE_M@DRUNK@VERYDRUNK",
            visualRange = 15, -- in meters
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
                vec3(-967.69, -2368.78, 13.94),
                vec3(-994.85, -2409.56, 13.94),
                vec3(-1033.33, -2389.52, 13.94),
                vec3(-1005.99, -2341.17, 13.94),
            },
            mobs = { -- mobs that can spawn in this zone (give the right weight to each mob)
                ["zombie_a"] = 90, -- higher the value, higher the chance to spawn
                ["zombie_b"] = 80  -- i'd suggest to not go over 100
            },
            mobMax = 40, -- maximum amount of mobs in zone
            newSpawnTime = 15, -- in seconds
            debug = false
        }
    }
}

Config.ToxicZone = {
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

