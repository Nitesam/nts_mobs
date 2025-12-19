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
                ["holonastro_piano"] = {
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
                ["carnecruda_sylrak"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
                },

                ["pelle_animale"] = {
                    min = 2,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
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
                ["carnecruda_pyril"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
                },

                ["pelle_animale"] = {
                    min = 1,                            -- Minimum quantity
                    max = 2,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
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
                ["carnecruda_thoryn"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
                },

                ["pelle_animale"] = {
                    min = 2,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
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
                ["carnecruda_vharok"] = {
                    min = 1,                            -- Minimum quantity
                    max = 3,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
                },

                ["pelle_animale"] = {
                    min = 2,                            -- Minimum quantity
                    max = 4,                            -- Maximum quantity
                    weight = 100                        -- Drop probability (0-100)
                }
            },

            hasTrollMode = true,                       -- Shoots RPG if player raises hands

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
            ped = "velxor_goat",                         -- GTA model hash/name
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
            ped = "velxor_goat",                         -- GTA model hash/name
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
        ["zone_a_green"] = {
            --- Display & Identification
            name = "zone_a_green",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(343.3242, -342.4894, 224.8999),
                vector3(245.0393, -788.9842, 218.9549),
                vector3(652.4891, -797.6891, 218.83191),
                vector3(790.3426, -509.0922, 174.9967)
            },

            --- Spawning Configuration
            mobMax = 20,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                ["deer2"] = 50,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                ["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },

        ["zone_b_green"] = {
            --- Display & Identification
            name = "zone_b_green",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(1020.4070, -1351.2511, 221.1693),
                vector3(1029.9106, -466.4460, 204.8005),
                vector3(1364.2922, -330.5164, 229.3672),
                vector3(1551.3341, -1397.5233, 267.0090)
            },

            --- Spawning Configuration
            mobMax = 50,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                ["deer2"] = 50,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                ["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },        







        ["zone_a_orange"] = {
            --- Display & Identification
            name = "zone_a_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(971.9084, 216.6523, 35.5323),
                vector3(93.9602, 766.3568, 44.6384),
                vector3(775.0135, 1231.5184, 27.5921),
                vector3(1155.1978, 786.9205, 46.0644)
            },

            --- Spawning Configuration
            mobMax = 80,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                ["deer1"] = 50,  
                ["deer2"] = 10,          
                ["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },


        ["zone_b_orange"] = {
            --- Display & Identification
            name = "zone_b_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(2309.1353, -2081.0173, 220.5602),
                vector3(3099.1238, -2615.7915, 213.1186),
                vector3(3020.2690, -2823.1643, 223.5323),
                vector3(2138.6616, -2265.3745, 221.6027)
            },

            --- Spawning Configuration
            mobMax = 80,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                ["deer1"] = 50,  
                --["deer2"] = 10,          
                ["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },  
        
        
        ["zone_c_orange"] = {
            --- Display & Identification
            name = "zone_c_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(709.7933, -2940.4614, 43.1887),
                vector3(1300.6293, -2307.8835, 81.2073),
                vector3(1804.6212, -2710.9597, 77.7995),
                vector3(1095.2025, -3287.0801, 57.0892)
            },

            --- Spawning Configuration
            mobMax = 80,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                ["deer1"] = 50,  
                --["deer2"] = 10,          
                ["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },   
        
        
        ["zone_d_orange"] = {
            --- Display & Identification
            name = "zone_d_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-90.2354, 397.2726, 222.6465),
                vector3(-174.2281, 182.9799, 225.7401),
                vector3(-1253.2115, 704.3705, 206.2096),
                vector3(-1083.8027, 915.3314, 195.4475)
            },

            --- Spawning Configuration
            mobMax = 80,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                ["deer1"] = 50,  
                --["deer2"] = 10,          
                ["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                --["cow1"] = 25,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                --["mountain_lion1"] = 25                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },
        
        ["zone_e_orange"] = {
            --- Display & Identification
            name = "zone_e_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(15.9088, -2908.3545, 88.4300),
                vector3(-715.3306, -3738.2373, 52.5047),
                vector3(-1828.4733, -2709.5854, 52.7633),
                vector3(-1241.6240, -2020.2188, 78.4809)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                ["deer1"] = 50,  
                ["deer2"] = 10,          
                ["deer3"] = 50,      
                ["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                ["coyote"] = 25,
                ["coyote1"] = 25,                
                ["boar"] = 25,
                ["cow1"] = 25,                
                ["rabbit"] = 25,
                --["rat"] = 25,
                ["mountain_lion"] = 15,       
                ["mountain_lion1"] = 15                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },     
        
        


        ["zone_a_red"] = {
            --- Display & Identification
            name = "zone_e_orange",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-2689.9399, 441.4294, 129.4635),
                vector3(-3491.0930, 543.5516, 225.5711),
                vector3(-3850.0437, 1194.9561, 203.9345),
                vector3(-3198.5444, 1401.6016, 202.7968)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },
        
        ["zone_b_red"] = {
            --- Display & Identification
            name = "zone_b_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-3157.0762, 2472.4985, 49.5756),
                vector3(-2779.0398, 2985.7104, 63.1443),
                vector3(-1563.2369, 2293.5361, 41.2754),
                vector3(-1962.7168, 1773.6580, 41.3314)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }, 
        
        
        ["zone_c_red"] = {
            --- Display & Identification
            name = "zone_c_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(1644.0745, 1948.8796, 73.4303),
                vector3(2511.1287, 900.1794, 49.8385),
                vector3(3483.9326, 1528.9625, 54.0018),
                vector3(3175.4221, 2465.5864, 65.4556)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },     
        
        ["zone_d_red"] = {
            --- Display & Identification
            name = "zone_d_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(1112.9618, -3296.3884, 57.2034),
                vector3(1805.8247, -2748.2380, 85.3885),
                vector3(1992.6531, -3207.7358, 34.0096),
                vector3(1419.6287, -3602.0701, 66.3440)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }, 
        
        ["zone_e_red"] = {
            --- Display & Identification
            name = "zone_e_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-724.4334, -3763.6609, 53.6543),
                vector3(-1837.3881, -2737.7361, 52.8237),
                vector3(-2090.2561, -3129.5664, 52.6795),
                vector3(-1018.8697, -3967.5232, 40.6994)
            },

            --- Spawning Configuration
            mobMax = 150,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }, 
        
        ["zone_f_red"] = {
            --- Display & Identification
            name = "zone_f_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-3537.3728, -2506.5134, 188.1814),
                vector3(-3515.8354, -3067.9373, 195.6290),
                vector3(-3093.1313, -2794.9451, 207.6990),
                vector3(-3092.3948, -2567.3818, 140.9528)
            },

            --- Spawning Configuration
            mobMax = 100,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        },  
        
        ["zone_g_red"] = {
            --- Display & Identification
            name = "zone_g_red",                             -- Zone display name
            debug = false,                               -- Debug mode for this zone

            --- Zone Boundaries (Polygon Points)
            pos = {
                vector3(-3344.5576, -1043.6312, 149.3687),
                vector3(-2394.4377, -1569.6691, 157.5931),
                vector3(-3018.4329, -1786.2484, 191.4764),
                vector3(-3527.0117, -1331.4281, 204.8571)
            },

            --- Spawning Configuration
            mobMax = 100,                                -- Maximum mobs in zone
            newSpawnTime = 15,                           -- Spawn interval (seconds)
            spawnBorderDistance = 2,                     -- Min distance from polygon edge (meters)
            forcedMinHeight =  98.727104187012,          -- Force minimum Z height (nil = auto)

            --- Mob Spawn Weights
            mobs = {
                --["deer"] = 50,     
                --["deer1"] = 50,  
                --["deer2"] = 10,          
                --["deer3"] = 50,      
                --["deer4"] = 50,                                                                                                                              -- Higher = higher spawn chance
                --["coyote"] = 25,
                --["coyote1"] = 25,                
                --["boar"] = 25,
                ["cow1"] = 50,                
                --["rabbit"] = 25,
                --["rat"] = 25,
                --["mountain_lion"] = 25,       
                ["mountain_lion1"] = 10                                          
            },

            ---Soil Type Restrictions (optional)
            whitelistedSoilTypes = {                     -- Allowed soil type hashes
                [-1595148316] = true,                    -- OBLIVION DESERT SOIL
                [510490462] = true                       -- GTA BASED SOIL
            }
        }        



    }
}