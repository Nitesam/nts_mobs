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
            ped = "a_c_deer",
            speed = 1.4,

            behaviour = "fugitive",

            --- Component Variations (optional)
            --- Format: [componentId] = {drawable = X, texture = Y, palette = Z}
            --- If absent or nil, component won't be changed
            randomComponents = true,                     -- Enable random component variations
            components = { -- OPTIONAL | RANDOM COMPONENTS IGNORED IF randomComponents IS SET TO TRUE
                -- [0] = {drawable = 0, texture = 0, palette = 0},  -- Face
                -- [1] = {drawable = 0, texture = 0, palette = 0},  -- Mask
                -- [2] = {drawable = 0, texture = 0, palette = 0},  -- Hair
                -- [3] = {drawable = 0, texture = 0, palette = 0},  -- Torso
                -- [4] = {drawable = 0, texture = 0, palette = 0},  -- Leg
                -- [5] = {drawable = 0, texture = 0, palette = 0},  -- Parachute/bag
                -- [6] = {drawable = 0, texture = 0, palette = 0},  -- Shoes
                -- [7] = {drawable = 0, texture = 0, palette = 0},  -- Accessory
                -- [8] = {drawable = 0, texture = 0, palette = 0},  -- Undershirt
                -- [9] = {drawable = 0, texture = 0, palette = 0},  -- Kevlar
                -- [10] = {drawable = 0, texture = 0, palette = 0}, -- Badge
                -- [11] = {drawable = 0, texture = 0, palette = 0}, -- Torso 2
            },

            --- Animation & Movement
            movClipset = "creatures@deer@move",
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },

        ["deer1"] = {
            --- Model & Base Stats
            ped = "velxor_deer",                           -- GTA model hash/name
            speed = 1.4,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@deer@move",         -- Movement animation clipset
            visualRange = 20,                           -- Detection range (meters)

            escapeDistanceMax = {min = 20.0, max = 50.0}, -- Max distance to flee (meters)
            randomComponents = true,                     -- Enable random component variations
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },

        ["deer2"] = {
            --- Model & Base Stats
            ped = "velxor_goat",                           -- GTA model hash/name
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },    
        
        ["deer3"] = {
            --- Model & Base Stats
            ped = "velxor_moose",                           -- GTA model hash/name
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },    

        ["deer4"] = {
            --- Model & Base Stats
            ped = "a_c_deer_02",                           -- GTA model hash/name
            speed = 1.4,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@deer@move",         -- Movement animation clipset
            visualRange = 20,                           -- Detection range (meters)

            escapeDistanceMax = {min = 20.0, max = 50.0}, -- Max distance to flee (meters)
            randomComponents = true,                     -- Enable random component variations
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },

        ["coyote"] = {
            --- Model & Base Stats
            ped = "a_c_coyote",                        -- GTA model hash/name
            speed = 1.5,                               -- Movement speed multiplier

            behaviour = "fugitive",                    -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@coyote@move",      -- Movement animation clipset
            visualRange = 20,                          -- Detection range (meters)
            randomComponents = true,                     -- Enable random component variations
            escapeDistanceMax = {min = 20.0, max = 60.0}, -- Max distance to flee (meters)

            --- Combat Configuration                    -- NOT USED FOR FUGITIVE BEHAVIOUR
            --  attackRange = 1.5,                      -- Attack range (meters)
            --[[attackTypes = {                         -- if behaviour is in aggressive or passive, you can define attack types here if ped does not have default attacks
                ["main"] = {
                    anim = {                            -- Set to nil for default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 10,                        -- Damage per hit
                    timeBetween = 4                     -- Seconds between attacks
                }
            },]]

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["coyote_pelt"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 10                         -- Drop probability (0-100)
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },

        ["coyote1"] = {
            --- Model & Base Stats
            ped = "a_c_coyote_02",                        -- GTA model hash/name
            speed = 1.5,                               -- Movement speed multiplier

            behaviour = "fugitive",                    -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@coyote@move",      -- Movement animation clipset
            visualRange = 20,                          -- Detection range (meters)
            randomComponents = true,                     -- Enable random component variations
            escapeDistanceMax = {min = 20.0, max = 60.0}, -- Max distance to flee (meters)

            --- Combat Configuration                    -- NOT USED FOR FUGITIVE BEHAVIOUR
            --  attackRange = 1.5,                      -- Attack range (meters)
            --[[attackTypes = {                         -- if behaviour is in aggressive or passive, you can define attack types here if ped does not have default attacks
                ["main"] = {
                    anim = {                            -- Set to nil for default game attack
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 10,                        -- Damage per hit
                    timeBetween = 4                     -- Seconds between attacks
                }
            },]]

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["coyote_pelt"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 10                         -- Drop probability (0-100)
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },        

        ["boar"] = {
            --- Model & Base Stats
            ped = "a_c_boar_02",                           -- GTA model hash/name
            speed = 1.2,                                -- Movement speed multiplier

            behaviour = "aggressive",                   -- Behaviour type (passive/aggressive/fugitive/neutral)
            randomComponents = true,                     -- Enable random component variations
            --- Animation & Movement
            movClipset = "creatures@boar@move",         -- Movement animation clipset
            visualRange = 25,                           -- Detection range (meters)

            --- Combat Configuration
            attackRange = 2.0,                          -- Attack range (meters)

            attackTypes = {                             -- if behaviour is in aggressive or passive, you can define attack types here if ped does not have default attacks
                --[[["main"] = {
                    anim = nil,                         
                    damage = 20,                        -- IF ANIM IS NULL, IT WILL USE GTA Damage per hit
                    executeTime = 2000,                 -- Milliseconds between attacks
                    cooldown = 1500                     -- Milliseconds before next attack
                }]]
            },

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["boar_meat"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 15                         -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },


        ["cow1"] = {
            --- Model & Base Stats
            ped = "velxor_bull",                            -- GTA model hash/name
            speed = 1.0,                                -- Movement speed multiplier

            behaviour = "passive",                      -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@cow@move",          -- Movement animation clipset
            visualRange = 20,                           -- Detection range (meters)

            --- Combat Configuration                    -- PASSIVE: NO ATTACKS
            -- attackRange = 0.0,                       -- Attack range (meters)
            -- attackTypes = {},

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["cow_meat"] = {
                    min = 2,                            -- Minimum quantity
                    max = 5,                            -- Maximum quantity
                    weight = 20                         -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },
        
        
        ["rabbit"] = {
            --- Model & Base Stats
            ped = "a_c_rabbit_01",                      -- GTA model hash/name
            speed = 1.8,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)
            randomComponents = true,                     -- Enable random component variations
            --- Animation & Movement
            movClipset = "creatures@rabbit@move",       -- Movement animation clipset
            visualRange = 15,                           -- Detection range (meters)

            escapeDistanceMax = {min = 15.0, max = 40.0}, -- Max distance to flee (meters)

            --- Combat Configuration                    -- NOT USED FOR FUGITIVE BEHAVIOUR
            -- attackRange = 1.5,                       -- Attack range (meters)
            --[[attackTypes = {
                ["main"] = {
                    anim = {
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 5,
                    timeBetween = 4
                }
            },]]

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["rabbit_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 1,                            -- Maximum quantity
                    weight = 15                         -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                       -- Attempts before corpse removal (≈30 sec per try)
        },
        ["rat"] = {
            --- Model & Base Stats
            ped = "a_c_rat",                            -- GTA model hash/name
            speed = 1.6,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)

            --- Animation & Movement
            movClipset = "creatures@rat@move",          -- Movement animation clipset
            visualRange = 10,                           -- Detection range (meters)
            randomComponents = true,                     -- Enable random component variations
            escapeDistanceMax = {min = 10.0, max = 25.0}, -- Max distance to flee (meters)

            --- Combat Configuration                    -- NOT USED FOR FUGITIVE BEHAVIOUR
            -- attackRange = 1.5,                       -- Attack range (meters)
            --[[attackTypes = {
                ["main"] = {
                    anim = {
                        animDict = "melee@unarmed@streamed_variations",
                        animClip = "plyr_takedown_front_backslap"
                    },
                    damage = 3,
                    timeBetween = 4
                }
            },]]

            --- Loot Table
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["rat_tail"] = {
                    min = 1,                            -- Minimum quantity
                    max = 1,                            -- Maximum quantity
                    weight = 5                          -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                       -- Attempts before corpse removal (≈30 sec per try)
        },



        ["custom_deer_1"] = {
            --- Model & Base Stats
            ped = "velxor_deer",                           -- GTA model hash/name
            speed = 1.4,                                -- Movement speed multiplier

            behaviour = "fugitive",                     -- Behaviour type (passive/aggressive/fugitive/neutral)
            randomComponents = true,                     -- Enable random component variations
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
            max_loot = 2,                                -- Maximum different loot items to drop,
            loot = {
                ["elk_fur"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 5                          -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                        -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                      -- Attempts before corpse removal (≈30 sec per try)
        },        
        ["mountain_lion"] = {
            --- Model & Base Stats
            ped = "a_c_mtlion",                         -- GTA model hash/name
            speed = 1.7,                                -- Movement speed multiplier

            behaviour = "aggressive",                   -- Behaviour type (passive/aggressive/fugitive/neutral)
            randomComponents = true,                     -- Enable random component variations
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
            max_loot = 2,                                -- Maximum different loot items to drop
            loot = {
                ["mountain_lion_pelt"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 5                          -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                     -- Attempts before corpse removal (≈30 sec per try)
        },


        ["mountain_lion1"] = {
            --- Model & Base Stats
            ped = "a_c_mtlion_02",                         -- GTA model hash/name
            speed = 1.7,                                -- Movement speed multiplier

            behaviour = "aggressive",                   -- Behaviour type (passive/aggressive/fugitive/neutral)
            randomComponents = true,                     -- Enable random component variations
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
            max_loot = 2,                                -- Maximum different loot items to drop
            loot = {
                ["mountain_lion_pelt"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 5                          -- Drop probability
                }
            },

            hasTrollMode = false,                       -- Shoots RPG if player raises hands

            --- Death & Cleanup
            tryBeforeRemoving = 200                     -- Attempts before corpse removal (≈30 sec per try)
        }        
    },

    ---========================================================================
    --- ZONE DEFINITIONS
    ---========================================================================
    Zone = {
        ["zone_a"] = {
            --- Display & Identification
            name = "Zone A",                             -- Zone display name
            debug = true,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-3465.8328, 558.9139, 223.8700),
                vector3(-3779.2009, 1201.3663, 201.8117),
                vector3(-3502.8323, 1376.0372, 195.1998),
                vector3(-2705.1714, 731.2459, 153.3470)
            },

            --- Spawning Configuration
            mobMax = 300,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                ["deer"] = 50,     
                ["deer1"] = 50,  
                ["deer2"] = 50,          
                ["deer3"] = 50,      
                ["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                ["coyote"] = 25,
                ["coyote1"] = 25,                
                ["boar"] = 25,
                ["cow1"] = 25,                
                ["rabbit"] = 25,
                ["rat"] = 25,
                ["mountain_lion"] = 25,       
                ["mountain_lion1"] = 25                                            
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }
    }
}