local eTaskTypeIndex = {
    [0] = "CTaskHandsUp",
    [1] = "CTaskClimbLadder",
    [2] = "CTaskExitVehicle",
    [3] = "CTaskCombatRoll",
    [4] = "CTaskAimGunOnFoot",
    [5] = "CTaskMovePlayer",
    [6] = "CTaskPlayerOnFoot",
    [8] = "CTaskWeapon",
    [9] = "CTaskPlayerWeapon",
    [10] = "CTaskPlayerIdles",
    [12] = "CTaskAimGun",
    [14] = "CTaskPause",
    [15] = "CTaskDoNothing",
    [16] = "CTaskGetUp",
    [17] = "CTaskGetUpAndStandStill",
    [18] = "CTaskFallOver",
    [19] = "CTaskFallAndGetUp",
    [20] = "CTaskCrawl",
    [25] = "CTaskComplexOnFire",
    [26] = "CTaskDamageElectric",
    [28] = "CTaskTriggerLookAt",
    [29] = "CTaskClearLookAt",
    [30] = "CTaskSetCharDecisionMaker",
    [31] = "CTaskSetPedDefensiveArea",
    [32] = "CTaskUseSequence",
    [34] = "CTaskMoveStandStill",
    [35] = "CTaskComplexControlMovement",
    [36] = "CTaskMoveSequence",
    [38] = "CTaskAmbientClips",
    [39] = "CTaskMoveInAir",
    [40] = "CTaskNetworkClone",
    [41] = "CTaskUseClimbOnRoute",
    [42] = "CTaskUseDropDownOnRoute",
    [43] = "CTaskUseLadderOnRoute",
    [44] = "CTaskSetBlockingOfNonTemporaryEvents",
    [45] = "CTaskForceMotionState",
    [46] = "CTaskSlopeScramble",
    [47] = "CTaskGoToAndClimbLadder",
    [48] = "CTaskClimbLadderFully",
    [49] = "CTaskRappel",
    [50] = "CTaskVault",
    [51] = "CTaskDropDown",
    [52] = "CTaskAffectSecondaryBehaviour",
    [53] = "CTaskAmbientLookAtEvent",
    [54] = "CTaskOpenDoor",
    [55] = "CTaskShovePed",
    [56] = "CTaskSwapWeapon",
    [57] = "CTaskGeneralSweep",
    [58] = "CTaskPolice",
    [59] = "CTaskPoliceOrderResponse",
    [60] = "CTaskPursueCriminal",
    [62] = "CTaskArrestPed",
    [63] = "CTaskArrestPed2",
    [64] = "CTaskBusted",
    [65] = "CTaskFirePatrol",
    [66] = "CTaskHeliOrderResponse",
    [67] = "CTaskHeliPassengerRappel",
    [68] = "CTaskAmbulancePatrol",
    [69] = "CTaskPoliceWantedResponse",
    [70] = "CTaskSwat",
    [72] = "CTaskSwatWantedResponse",
    [73] = "CTaskSwatOrderResponse",
    [74] = "CTaskSwatGoToStagingArea",
    [75] = "CTaskSwatFollowInLine",
    [76] = "CTaskWitness",
    [77] = "CTaskGangPatrol",
    [78] = "CTaskArmy",
    [80] = "CTaskShockingEventWatch",
    [82] = "CTaskShockingEventGoto",
    [83] = "CTaskShockingEventHurryAway",
    [84] = "CTaskShockingEventReactToAircraft",
    [85] = "CTaskShockingEventReact",
    [86] = "CTaskShockingEventBackAway",
    [87] = "CTaskShockingPoliceInvestigate",
    [88] = "CTaskShockingEventStopAndStare",
    [89] = "CTaskShockingNiceCarPicture",
    [90] = "CTaskShockingEventThreatResponse",
    [92] = "CTaskTakeOffHelmet",
    [93] = "CTaskCarReactToVehicleCollision",
    [95] = "CTaskCarReactToVehicleCollisionGetOut",
    [97] = "CTaskDyingDead",
    [100] = "CTaskWanderingScenario",
    [101] = "CTaskWanderingInRadiusScenario",
    [103] = "CTaskMoveBetweenPointsScenario",
    [104] = "CTaskChatScenario",
    [106] = "CTaskCowerScenario",
    [107] = "CTaskDeadBodyScenario",
    [114] = "CTaskSayAudio",
    [116] = "CTaskWaitForSteppingOut",
    [117] = "CTaskCoupleScenario",
    [118] = "CTaskUseScenario",
    [119] = "CTaskUseVehicleScenario",
    [120] = "CTaskUnalerted",
    [121] = "CTaskStealVehicle",
    [122] = "CTaskReactToPursuit",
    [125] = "CTaskHitWall",
    [126] = "CTaskCower",
    [127] = "CTaskCrouch",
    [128] = "CTaskMelee",
    [129] = "CTaskMoveMeleeMovement",
    [130] = "CTaskMeleeActionResult",
    [131] = "CTaskMeleeUpperbodyAnims",
    [133] = "CTaskMoVEScripted",
    [134] = "CTaskScriptedAnimation",
    [135] = "CTaskSynchronizedScene",
    [137] = "CTaskComplexEvasiveStep",
    [138] = "CTaskWalkRoundCarWhileWandering",
    [140] = "CTaskComplexStuckInAir",
    [141] = "CTaskWalkRoundEntity",
    [142] = "CTaskMoveWalkRoundVehicle",
    [144] = "CTaskReactToGunAimedAt",
    [146] = "CTaskDuckAndCover",
    [147] = "CTaskAggressiveRubberneck",
    [150] = "CTaskInVehicleBasic",
    [151] = "CTaskCarDriveWander",
    [152] = "CTaskLeaveAnyCar",
    [153] = "CTaskComplexGetOffBoat",
    [155] = "CTaskCarSetTempAction",
    [156] = "CTaskBringVehicleToHalt",
    [157] = "CTaskCarDrive",
    [159] = "CTaskPlayerDrive",
    [160] = "CTaskEnterVehicle",
    [161] = "CTaskEnterVehicleAlign",
    [162] = "CTaskOpenVehicleDoorFromOutside",
    [163] = "CTaskEnterVehicleSeat",
    [164] = "CTaskCloseVehicleDoorFromInside",
    [165] = "CTaskInVehicleSeatShuffle",
    [167] = "CTaskExitVehicleSeat",
    [168] = "CTaskCloseVehicleDoorFromOutside",
    [169] = "CTaskControlVehicle",
    [170] = "CTaskMotionInAutomobile",
    [171] = "CTaskMotionOnBicycle",
    [172] = "CTaskMotionOnBicycleController",
    [173] = "CTaskMotionInVehicle",
    [174] = "CTaskMotionInTurret",
    [175] = "CTaskReactToBeingJacked",
    [176] = "CTaskReactToBeingAskedToLeaveVehicle",
    [177] = "CTaskTryToGrabVehicleDoor",
    [178] = "CTaskGetOnTrain",
    [179] = "CTaskGetOffTrain",
    [180] = "CTaskRideTrain",
    [190] = "CTaskMountThrowProjectile",
	[195] = "CTaskGoToCarDoorAndStandStill",
	[196] = "CTaskMoveGoToVehicleDoor",
	[197] = "CTaskSetPedInVehicle",
	[198] = "CTaskSetPedOutOfVehicle",
	[199] = "CTaskVehicleMountedWeapon",
	[200] = "CTaskVehicleGun",
	[201] = "CTaskVehicleProjectile",
	[204] = "CTaskSmashCarWindow",
	[205] = "CTaskMoveGoToPoint",
	[206] = "CTaskMoveAchieveHeading",
	[207] = "CTaskMoveFaceTarget",
	[208] = "CTaskComplexGoToPointAndStandStillTimed",
	[209] = "CTaskMoveFollowPointRoute",
	[210] = "CTaskMoveSeekEntity_CEntitySeekPosCalculatorStandard",
	[211] = "CTaskMoveSeekEntity_CEntitySeekPosCalculatorLastNavMeshIntersection",
	[212] = "CTaskMoveSeekEntity_CEntitySeekPosCalculatorLastNavMeshIntersection2",
	[213] = "CTaskMoveSeekEntity_CEntitySeekPosCalculatorXYOffsetFixed",
	[214] = "CTaskMoveSeekEntity_CEntitySeekPosCalculatorXYOffsetFixed2",
	[215] = "CTaskExhaustedFlee",
	[216] = "CTaskGrowlAndFlee",
	[217] = "CTaskScenarioFlee",
	[218] = "CTaskSmartFlee",
    [219] = "CTaskFlyAway",
    [220] = "CTaskWalkAway",
    [221] = "CTaskWander",
    [222] = "CTaskWanderInArea",
    [223] = "CTaskFollowLeaderInFormation",
    [224] = "CTaskGoToPointAnyMeans",
    [225] = "CTaskTurnToFaceEntityOrCoord",
    [226] = "CTaskFollowLeaderAnyMeans",
    [228] = "CTaskFlyToPoint",
    [229] = "CTaskFlyingWander",
    [230] = "CTaskGoToPointAiming",
    [231] = "CTaskGoToScenario",
    [233] = "CTaskSeekEntityAiming",
    [234] = "CTaskSlideToCoord",
    [235] = "CTaskSwimmingWander",
    [237] = "CTaskMoveTrackingEntity",
    [238] = "CTaskMoveFollowNavMesh",
    [239] = "CTaskMoveGoToPointOnRoute",
    [240] = "CTaskEscapeBlast",
    [241] = "CTaskMoveWander",
    [242] = "CTaskMoveBeInFormation",
    [243] = "CTaskMoveCrowdAroundLocation",
    [244] = "CTaskMoveCrossRoadAtTrafficLights",
    [245] = "CTaskMoveWaitForTraffic",
    [246] = "CTaskMoveGoToPointStandStillAchieveHeading",
    [251] = "CTaskMoveGetOntoMainNavMesh",
    [252] = "CTaskMoveSlideToCoord",
    [253] = "CTaskMoveGoToPointRelativeToEntityAndStandStill",
    [254] = "CTaskHelicopterStrafe",
    [256] = "CTaskGetOutOfWater",
    [259] = "CTaskMoveFollowEntityOffset",
    [261] = "CTaskFollowWaypointRecording",
    [264] = "CTaskMotionPed",
    [265] = "CTaskMotionPedLowLod",
    [268] = "CTaskHumanLocomotion",
    [269] = "CTaskMotionBasicLocomotionLowLod",
    [270] = "CTaskMotionStrafing",
    [271] = "CTaskMotionTennis",
    [272] = "CTaskMotionAiming",
    [273] = "CTaskBirdLocomotion",
    [274] = "CTaskFlightlessBirdLocomotion",
    [278] = "CTaskFishLocomotion",
    [279] = "CTaskQuadLocomotion",
    [280] = "CTaskMotionDiving",
    [281] = "CTaskMotionSwimming",
    [282] = "CTaskMotionParachuting",
    [283] = "CTaskMotionDrunk",
    [284] = "CTaskRepositionMove",
    [285] = "CTaskMotionAimingTransition",
    [286] = "CTaskThrowProjectile",
    [287] = "CTaskCover",
    [288] = "CTaskMotionInCover",
    [289] = "CTaskAimAndThrowProjectile",
    [290] = "CTaskGun",
    [291] = "CTaskAimFromGround",
    [295] = "CTaskAimGunVehicleDriveBy",
    [296] = "CTaskAimGunScripted",
    [298] = "CTaskReloadGun",
    [299] = "CTaskWeaponBlocked",
    [300] = "CTaskEnterCover",
    [301] = "CTaskExitCover",
    [302] = "CTaskAimGunFromCoverIntro",
    [303] = "CTaskAimGunFromCoverOutro",
    [304] = "CTaskAimGunBlindFire",
    [307] = "CTaskCombatClosestTargetInArea",
    [308] = "CTaskCombatAdditionalTask",
    [309] = "CTaskInCover",
    [313] = "CTaskAimSweep",
    [319] = "CTaskSharkCircle",
    [320] = "CTaskSharkAttack",
    [321] = "CTaskAgitated",
    [322] = "CTaskAgitatedAction",
    [323] = "CTaskConfront",
    [324] = "CTaskIntimidate",
    [325] = "CTaskShove",
    [326] = "CTaskShoved",
    [328] = "CTaskCrouchToggle",
    [329] = "CTaskRevive",
    [335] = "CTaskParachute",
    [336] = "CTaskParachuteObject",
    [337] = "CTaskTakeOffPedVariation",
    [340] = "CTaskCombatSeekCover",
    [342] = "CTaskCombatFlank",
    [343] = "CTaskCombat",
    [344] = "CTaskCombatMounted",
    [345] = "CTaskMoveCircle",
    [346] = "CTaskMoveCombatMounted",
    [347] = "CTaskSearch",
    [348] = "CTaskSearchOnFoot",
    [349] = "CTaskSearchInAutomobile",
    [350] = "CTaskSearchInBoat",
    [351] = "CTaskSearchInHeli",
    [352] = "CTaskThreatResponse",
    [353] = "CTaskInvestigate",
    [354] = "CTaskStandGuardFSM",
    [355] = "CTaskPatrol",
    [356] = "CTaskShootAtTarget",
    [357] = "CTaskSetAndGuardArea",
    [358] = "CTaskStandGuard",
    [359] = "CTaskSeparate",
    [360] = "CTaskStayInCover",
    [361] = "CTaskVehicleCombat",
    [362] = "CTaskVehiclePersuit",
    [363] = "CTaskVehicleChase",
    [364] = "CTaskDraggingToSafety",
    [365] = "CTaskDraggedToSafety",
    [366] = "CTaskVariedAimPose",
    [367] = "CTaskMoveWithinAttackWindow",
    [368] = "CTaskMoveWithinDefensiveArea",
    [369] = "CTaskShootOutTire",
    [370] = "CTaskShellShocked",
    [371] = "CTaskBoatChase",
    [372] = "CTaskBoatCombat",
    [373] = "CTaskBoatStrafe",
    [374] = "CTaskHeliChase",
    [375] = "CTaskHeliCombat",
    [376] = "CTaskSubmarineCombat",
    [377] = "CTaskSubmarineChase",
    [378] = "CTaskPlaneChase",
    [379] = "CTaskTargetUnreachable",
    [380] = "CTaskTargetUnreachableInInterior",
    [381] = "CTaskTargetUnreachableInExterior",
    [382] = "CTaskStealthKill",
    [383] = "CTaskWrithe",
    [384] = "CTaskAdvance",
    [385] = "CTaskCharge",
    [386] = "CTaskMoveToTacticalPoint",
    [387] = "CTaskToHurtTransit",
    [388] = "CTaskAnimatedHitByExplosion",
    [389] = "CTaskNMRelax",
    [391] = "CTaskNMPose",
    [392] = "CTaskNMBrace",
    [393] = "CTaskNMBuoyancy",
    [394] = "CTaskNMInjuredOnGround",
    [395] = "CTaskNMShot",
    [396] = "CTaskNMHighFall",
    [397] = "CTaskNMBalance",
    [398] = "CTaskNMElectrocute",
    [399] = "CTaskNMPrototype",
    [400] = "CTaskNMExplosion",
    [401] = "CTaskNMOnFire",
    [402] = "CTaskNMScriptControl",
    [403] = "CTaskNMJumpRollFromRoadVehicle",
    [404] = "CTaskNMFlinch",
    [405] = "CTaskNMSit",
    [406] = "CTaskNMFallDown",
    [407] = "CTaskBlendFromNM",
    [408] = "CTaskNMControl",
    [409] = "CTaskNMDangle",
    [412] = "CTaskNMGenericAttach",
    [414] = "CTaskNMDraggingToSafety",
    [415] = "CTaskNMThroughWindscreen",
    [416] = "CTaskNMRiverRapids",
    [417] = "CTaskNMSimple",
    [418] = "CTaskRageRagdoll",
    [421] = "CTaskJumpVault",
    [422] = "CTaskJump",
    [423] = "CTaskFall",
    [425] = "CTaskReactAimWeapon",
    [426] = "CTaskChat",
    [427] = "CTaskMobilePhone",
    [428] = "CTaskReactToDeadPed",
    [430] = "CTaskSearchForUnknownThreat",
    [432] = "CTaskBomb",
    [433] = "CTaskDetonator",
    [435] = "CTaskAnimatedAttach",
    [441] = "CTaskCutScene",
    [442] = "CTaskReactToExplosion",
    [443] = "CTaskReactToImminentExplosion",
    [444] = "CTaskDiveToGround",
    [445] = "CTaskReactAndFlee",
    [446] = "CTaskSidestep",
    [447] = "CTaskCallPolice",
    [448] = "CTaskReactInDirection",
    [449] = "CTaskReactToBuddyShot",
    [454] = "CTaskVehicleGoToAutomobileNew",
    [455] = "CTaskVehicleGoToPlane",
    [456] = "CTaskVehicleGoToHelicopter",
    [457] = "CTaskVehicleGoToSubmarine",
    [458] = "CTaskVehicleGoToBoat",
    [459] = "CTaskVehicleGoToPointAutomobile",
    [460] = "CTaskVehicleGoToPointWithAvoidanceAutomobile",
    [461] = "CTaskVehiclePursue",
    [462] = "CTaskVehicleRam",
    [463] = "CTaskVehicleSpinOut",
    [464] = "CTaskVehicleApproach",
    [465] = "CTaskVehicleThreePointTurn",
    [466] = "CTaskVehicleDeadDriver",
    [467] = "CTaskVehicleCruiseNew",
    [468] = "CTaskVehicleCruiseBoat",
    [469] = "CTaskVehicleStop",
    [470] = "CTaskVehiclePullOver",
    [471] = "CTaskVehiclePassengerExit",
    [472] = "CTaskVehicleFlee",
    [473] = "CTaskVehicleFleeAirborne",
    [474] = "CTaskVehicleFleeBoat",
    [475] = "CTaskVehicleFollowRecording",
    [476] = "CTaskVehicleFollow",
    [477] = "CTaskVehicleBlock",
    [478] = "CTaskVehicleBlockCruiseInFront",
    [479] = "CTaskVehicleBlockBrakeInFront",
    [481] = "CTaskVehicleCrash",
    [482] = "CTaskVehicleLand",
	[483] = "CTaskVehicleLandPlane",
	[484] = "CTaskVehicleHover",
	[485] = "CTaskVehicleAttack",
	[486] = "CTaskVehicleAttackTank",
	[487] = "CTaskVehicleCircle",
	[488] = "CTaskVehiclePoliceBehaviour",
	[489] = "CTaskVehiclePoliceBehaviourHelicopter",
	[490] = "CTaskVehiclePoliceBehaviourBoat",
	[491] = "CTaskVehicleEscort",
	[492] = "CTaskVehicleHeliProtect",
	[494] = "CTaskVehiclePlayerDriveAutomobile",
	[495] = "CTaskVehiclePlayerDriveBike",
	[496] = "CTaskVehiclePlayerDriveBoat",
	[497] = "CTaskVehiclePlayerDriveSubmarine",
	[498] = "CTaskVehiclePlayerDriveSubmarineCar",
	[499] = "CTaskVehiclePlayerDriveAmphibiousAutomobile",
	[500] = "CTaskVehiclePlayerDrivePlane",
	[501] = "CTaskVehiclePlayerDriveHeli",
	[502] = "CTaskVehiclePlayerDriveAutogyro",
	[503] = "CTaskVehiclePlayerDriveDiggerArm",
	[504] = "CTaskVehiclePlayerDriveTrain",
	[505] = "CTaskVehiclePlaneChase",
	[506] = "CTaskVehicleNoDriver",
	[507] = "CTaskVehicleAnimation",
	[508] = "CTaskVehicleConvertibleRoof",
	[509] = "CTaskVehicleParkNew",
	[510] = "CTaskVehicleFollowWaypointRecording",
	[511] = "CTaskVehicleGoToNavmesh",
	[512] = "CTaskVehicleReactToCopSiren",
	[513] = "CTaskVehicleGotoLongRange",
	[514] = "CTaskVehicleWait",
	[515] = "CTaskVehicleReverse",
	[516] = "CTaskVehicleBrake",
	[517] = "CTaskVehicleHandBrake",
	[518] = "CTaskVehicleTurn",
	[519] = "CTaskVehicleGoForward",
	[520] = "CTaskVehicleSwerve",
	[521] = "CTaskVehicleFlyDirection",
	[522] = "CTaskVehicleHeadonCollision",
	[523] = "CTaskVehicleBoostUseSteeringAngle",
	[524] = "CTaskVehicleShotTire",
	[525] = "CTaskVehicleBurnout",
	[526] = "CTaskVehicleRevEngine",
	[527] = "CTaskVehicleSurfaceInSubmarine",
	[528] = "CTaskVehiclePullAlongside",
	[529] = "CTaskVehicleTransformToSubmarine",
	[530] = "CTaskAnimatedFallback"
}

function isPointNearPolygonBorder(x, y, polygon, distance)
    for i = 1, #polygon do
        local j = i == #polygon and 1 or i + 1
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        local dx, dy = xj - xi, yj - yi
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len

        local t = dx * (x - xi) + dy * (y - yi)
        if t < 0 then
            t = 0
        elseif t > len then
            t = len
        end

        local nearestX, nearestY = xi + dx * t, yi + dy * t
        local dist = math.sqrt((x - nearestX) * (x - nearestX) + (y - nearestY) * (y - nearestY))
        if dist <= distance then return true end
    end
    return false
end

function isPointInPolygon(x, y, polygon)
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
        if intersect then inside = not inside end
        j = i
    end
    return inside
end

function getCentroid(points)
    local x, y, z = 0, 0, 0
    local n = #points

    for _, point in ipairs(points) do
        x = x + point.x
        y = y + point.y
        z = z + point.z
    end

    return vec3(x / n, y / n, z / n)
end

function getMinRadius(centroid, points)
    local minRadius = math.huge

    for _, point in ipairs(points) do
        local dx = point.x - centroid.x
        local dy = point.y - centroid.y
        local dz = point.z - centroid.z
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)

        if distance < minRadius then
            minRadius = distance
        end
    end

    return minRadius
end

function getRandomPoint(centroid, radius)
    local t = 2 * math.pi * math.random()
    local u = math.random() + math.random()
    local r = u > 1 and 2 - u or u
    r = r * radius

    local x = centroid.x + r * math.cos(t)
    local y = centroid.y + r * math.sin(t)
    local z = centroid.z

    return vec3(x, y, z)
end

function DebugPedTask(ped)
    local tCount = 0

    for k,v in pairs(eTaskTypeIndex) do
        if GetIsTaskActive(ped, k) then
            tCount += 1
            print("Executing: [".. k .."] - " .. v)
        end
    end

    if tCount == 0 then
        print("No Task Executed by " .. ped)
    else
        print("Total Task Executed: " .. tCount)
    end
end

function Notify(...)
    local t = {...}
    
    if IsDuplicityVersion() then
    else
        ESX.ShowNotification(...)
    end
end

Debug = function (...)
    if Config.Debug then
        print(...)
    end
end

if not IsDuplicityVersion() then
    if Config.Debug then
        RegisterCommand("task", function (source, args, raw)
            local ped = Target(50)

            if ped then
                DebugPedTask(ped)
            end
        end, false)
    end
end