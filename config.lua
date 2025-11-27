---============================================================================
--- NTS MOBS CONFIGURATION
---============================================================================

Config = {}

---============================================================================
--- GENERAL SETTINGS
---============================================================================
Config.Debug = false                                    -- Enable debug mode (disable in production)
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
            speed = 3.0,                                -- Movement speed multiplier

            --- Animation & Movement
            movClipset = "creatures@deer@move",         -- Movement animation clipset
            visualRange = 50,                           -- Detection range (meters)
            attackRange = 1.5,                          -- Attack range (meters)

            --- Loot Table
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    prob = 25                           -- Drop probability (0-100)
                }
            },

            --- Combat Configuration
            attackTypes = {
                ["main"] = {
                    anim = {                            -- Set to nil for default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 15,                        -- Damage per hit
                    timeBetween = 4                     -- Seconds between attacks
                }
            },
            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 1                       -- Attempts before corpse removal (≈30 sec per try)
        }
    },

    ---========================================================================
    --- ZONE DEFINITIONS
    ---========================================================================
    Zone = {
        ["zone_a"] = {
            --- Display & Identification
            name = "Zone A",                            -- Zone display name
            debug = true,                               -- Debug mode for this zone

            --- Blip Configuration
            blip = {
                sprite = 50,                            -- Blip sprite ID
                color = 3,                              -- Blip color
                display = 4,                            -- Display mode
                scale = 1.0                             -- Blip scale
            },

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(291.73077392578, 3443.4208984375, 35.67728805542),
                vector3(984.38073730469, 3527.0632324219, 32.861618041992),
                vector3(1118.4897460938, 3270.9006347656, 37.023284912109),
                vector3(226.31533813477, 3154.4365234375, 41.226364135742)
            },

            --- Spawning Configuration
            mobMax = 120,                               -- Maximum mobs in zone
            newSpawnTime = 15,                          -- Spawn interval (seconds)
            spawnBorderDistance = 25,                   -- Min distance from polygon edge (meters)
            forcedMinHeight = nil,                      -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                ["deer"] = 100                          -- Higher = higher spawn chance
            },

            --- Soil Type Restrictions (optional)
            whitelistedSoilTypes = {
                [-1595148316] = true                    -- Allowed soil type hashes
            }
        }
    }
}