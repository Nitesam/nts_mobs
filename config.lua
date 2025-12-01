---============================================================================
--- NTS MOBS CONFIGURATION
---============================================================================

Config = {}

---============================================================================
--- GENERAL SETTINGS
---============================================================================
Config.Debug = true                                     -- Enable debug mode (disable in production)
Config.ZoneEmptyTimeout = 60                            -- Seconds to reset zone if empty (per-zone override available)
Config.ZoneEntryCooldown = 5                            -- Prevent in/out abuse (cooldown in seconds)

---============================================================================
--- MOB SYSTEM CONFIGURATION
---============================================================================
Config.Mob = {
    --- Selection Method: "target" (ox_target), "control" (key-based), or "integrated"
    SelectType = "target",

    ---========================================================================
    --- MOB TYPE DEFINITIONS
    ---========================================================================
    MobType = {
        ["deer"] = {
            --- Model & Base Stats
            ped = "a_c_deer",                           -- GTA model hash/name
            xp = nil,                                   -- XP reward (nil = disabled for now)
            speed = 1.4,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@deer@move",         -- Movement animation clipset
            visualRange = 20,                           -- Detection range (meters)

            escapeDistanceMax = {min = 20.0, max = 50.0}, -- Max distance to flee (meters)

            --- Combat Configuration                    -- NOT USED FOR FUGITIVE BEHAVIOUR
            --  attackRange = 1.5,                      -- Attack range (meters)
            --[[attackTypes = {                         -- if behaviour is in aggressive or passive, you can define attack types here if ped does not have default attacks
                ["main"] = {
                    anim = {                            -- Set to nil for default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 15,                        -- Damage per hit
                    timeBetween = 4                     -- Seconds between attacks
                }
            },]]

            --- Loot Table
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 20                      -- Attempts before corpse removal (≈30 sec per try)
        },
        ["mountain_lion"] = {
            --- Model & Base Stats
            ped = "a_c_mtlion",                         -- GTA model hash/name
            xp = nil,                                   -- XP reward (nil = disabled for now)
            speed = 1.7,                                -- Movement speed multiplier

            behaviour = "aggressive",                   -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@mountain_lion@move",-- Movement animation clipset
            visualRange = 30,                           -- Detection range (meters)

            --- Combat Configuration
            attackRange = 29.9,                         -- Attack range (meters)

                                                        -- SET TO NIL OR EMPTY THIS TABLE TO USE DEFAULT GTA ATTACKS
            attackTypes = {                             -- if behaviour is in aggressive or passive, you can define attack types here if ped does not have default attacks
                --[[["main"] = {
                    anim = nil,                         
                    damage = 25,                        -- IF ANIM IS NULL, IT WILL USE GTA Damage per hit
                    executeTime = 3000,                 -- Milliseconds between attacks
                    cooldown = 2000                     -- Milliseconds before next attack
                }]]
            },

            --- Loot Table
            loot = {
                ["mountain_lion_pelt"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 5                          -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 2                       -- Attempts before corpse removal (≈30 sec per try)
        }
    },

    ---========================================================================
    --- ZONE DEFINITIONS
    ---========================================================================
    Zone = {
        ["zone_a"] = {
            --- Display & Identification
            name = "Zone A",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(287.6848449707, 3203.8896484375, 42.530754089355),
                vector3(302.75173950195, 3259.5988769531, 44.691047668457),
                vector3(358.23547363281, 3231.1918945312, 43.239730834961),
                vector3(323.02163696289, 3190.8505859375, 49.12760925293)
            },

            --- Spawning Configuration
            mobMax = 10,                                 -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                ["deer"] = 50,                           -- Higher = higher spawn chance
                ["mountain_lion"] = 25
            },

            --- Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }
    }
}