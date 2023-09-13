code <- @"{
    // In your custom config file, not all properties are required.
    // You can remove properties in your custom config to keep them consistent with the default config.
    // There are only these possible types for each property: integer, float, bool(true or false), string.
    // For bool type, integer value is allowed.(0 means false and others mean true)

    HeavyHealthMultiplier = 2.5
    HeavyHealthMultiplierCharger = 2.0
    ExtraHeavyHealthMultiplier = 4.5
    ExtraHeavyHealthMultiplierCharger = 3.0

    CloakingStartupTime = 1.0
    CloakingTime = 1.5
    CloakingExitTime = 1.5

    ExplosionMagnitude = 90
    ExplosionPhysMagnitude = 15
    ExplosionPhysMagnitudeTankRock = 25

    FlashAttFactor = 1.0 / 400.0
    FlashPeriod = 3.0
    FlashBlindHoldTime = 1.5
    FlashBlindFadeTime = 2.0
    FlashSlowFactor = 4.0
    FlashSlowFactorTank = 1.5
    IsFlashColorWhite = 0
    FlashDisableGlowTime = 1.0

    ShieldHealthMultiplier = 3.0
    ShieldRecoverSpeed = 100.0

    SpeedFactor0 = 1.3
    SpeedFactor1 = 1.7
    SpeedFactor0Charger = 1.2
    SpeedFactor1Charger = 1.5
    SpeedLateralAccelFactor = 10.0

    FlameAttackRange = 250.0
    FlameAttackPeriod = 2.0
    FlameFireballAttackRange = 130.0
    FlameFireballAttackPeriod = 0.5
    FlameFireballDamage = 5.0
    FlameIgniteObjectsRange = 300.0
    FlameIgniteObjectsPeriod = 2.0

    ScourgeHealthMultiplier = 2.0
    ScourgeResurrectMaxCount = 5
    ScourgeResurrectTime = 5.0
    ScourgeResurrectRange = 1000.0
    ScourgeResurrectSimulMax = 2
    ScourgeResurrectQueueCapacity = 4
    ScourgeResurrectToScourgeProb = 0.3
    ScourgeSpawnCommonInfectedCount = 10
    ScourgeSpawnCommonInfectedPeriod = 8.0
    ScourgeCommonInfectedLimit = 60

    ToxicSmokeDamageRadius = 150.0
    ToxicSmokeDamage = 1
    ToxicSmokeDuration = 10.0
    ToxicSmokeEmitInterval = 10.0
    ToxicEffectCutHealthToBuffer = 5
    ToxicEffectMinHealth = 20
    ToxicEffectDuration = 10.0
    ToxicEffectScreenEffectMaxAlpha = 128

    SlimeMaxSplitCount = 3
    SlimePoppingSpeed = 500.0

    BhopJumpAccel = 300.0
    BhopLateralAccel = 75.0
    BhopInitialAccel = 100.0
    BhopAccelIncrement = 75.0
    BhopAccelMaxCount = 4

    TeleporterTpHealthRatio = 0.2
    TeleporterTpRadius = 500.0

    // The ZTSPW means Zombie Type Spawning Probability Weight.
    // If the weight of a type is negative, the type will be never spawned naturally.
    ZTSPW_normal = 12.0
    ZTSPW_heavy = 2.0
    ZTSPW_extraheavy = 1.0
    ZTSPW_shield = 1.0
    ZTSPW_acid = 1.0
    ZTSPW_cloaking = 1.0
    ZTSPW_flash = 1.0
    ZTSPW_explosive = 2.0
    ZTSPW_speed = 1.0
    ZTSPW_flame = 1.0
    ZTSPW_scourge = 1.0
    ZTSPW_toxic = 1.0
    ZTSPW_slime = 1.0
    ZTSPW_bhop = 1.0
    ZTSPW_teleporter = 1.0

    // The ZTLimit means the max number of zombies of that type that can exist at the same time.
    // Zero means no limit.
    ZTLimit_heavy = 0
    ZTLimit_extraheavy = 0
    ZTLimit_shield = 0
    ZTLimit_acid = 0
    ZTLimit_cloaking = 0
    ZTLimit_flash = 0
    ZTLimit_explosive = 0
    ZTLimit_speed = 0
    ZTLimit_flame = 0
    ZTLimit_scourge = 0
    ZTLimit_toxic = 0
    ZTLimit_slime = 0
    ZTLimit_bhop = 0
    ZTLimit_teleporter = 0

    // ZT_Allow(Smoker/Boomer/Hunter/...)_x means whether or not the zombie type x will be spawned.
    // 1 means yes and 0 means no.
    ZT_AllowSmoker_heavy = 1
    ZT_AllowBoomer_heavy = 1
    ZT_AllowHunter_heavy = 1
    ZT_AllowSpitter_heavy = 1
    ZT_AllowJockey_heavy = 1
    ZT_AllowCharger_heavy = 1
    ZT_AllowWitch_heavy = 0
    ZT_AllowTank_heavy = 0

    ZT_AllowSmoker_extraheavy = 1
    ZT_AllowBoomer_extraheavy = 1
    ZT_AllowHunter_extraheavy = 1
    ZT_AllowSpitter_extraheavy = 1
    ZT_AllowJockey_extraheavy = 1
    ZT_AllowCharger_extraheavy = 1
    ZT_AllowWitch_extraheavy = 0
    ZT_AllowTank_extraheavy = 0

    ZT_AllowSmoker_shield = 1
    ZT_AllowBoomer_shield = 1
    ZT_AllowHunter_shield = 1
    ZT_AllowSpitter_shield = 1
    ZT_AllowJockey_shield = 1
    ZT_AllowCharger_shield = 1
    ZT_AllowWitch_shield = 0
    ZT_AllowTank_shield = 0

    ZT_AllowSmoker_acid = 1
    ZT_AllowBoomer_acid = 1
    ZT_AllowHunter_acid = 1
    ZT_AllowSpitter_acid = 1
    ZT_AllowJockey_acid = 1
    ZT_AllowCharger_acid = 1
    ZT_AllowWitch_acid = 1
    ZT_AllowTank_acid = 1

    ZT_AllowSmoker_cloaking = 1
    ZT_AllowBoomer_cloaking = 1
    ZT_AllowHunter_cloaking = 1
    ZT_AllowSpitter_cloaking = 1
    ZT_AllowJockey_cloaking = 1
    ZT_AllowCharger_cloaking = 1
    ZT_AllowWitch_cloaking = 1
    ZT_AllowTank_cloaking = 1

    ZT_AllowSmoker_flash = 1
    ZT_AllowBoomer_flash = 1
    ZT_AllowHunter_flash = 1
    ZT_AllowSpitter_flash = 1
    ZT_AllowJockey_flash = 1
    ZT_AllowCharger_flash = 1
    ZT_AllowWitch_flash = 1
    ZT_AllowTank_flash = 1

    ZT_AllowSmoker_explosive = 1
    ZT_AllowBoomer_explosive = 1
    ZT_AllowHunter_explosive = 1
    ZT_AllowSpitter_explosive = 1
    ZT_AllowJockey_explosive = 1
    ZT_AllowCharger_explosive = 1
    ZT_AllowWitch_explosive = 0
    ZT_AllowTank_explosive = 1

    ZT_AllowSmoker_speed = 1
    ZT_AllowBoomer_speed = 1
    ZT_AllowHunter_speed = 1
    ZT_AllowSpitter_speed = 1
    ZT_AllowJockey_speed = 1
    ZT_AllowCharger_speed = 1
    ZT_AllowWitch_speed = 0
    ZT_AllowTank_speed = 0

    ZT_AllowSmoker_flame = 1
    ZT_AllowBoomer_flame = 1
    ZT_AllowHunter_flame = 1
    ZT_AllowSpitter_flame = 1
    ZT_AllowJockey_flame = 1
    ZT_AllowCharger_flame = 1
    ZT_AllowWitch_flame = 0
    ZT_AllowTank_flame = 0

    ZT_AllowSmoker_scourge = 1
    ZT_AllowBoomer_scourge = 1
    ZT_AllowHunter_scourge = 1
    ZT_AllowSpitter_scourge = 1
    ZT_AllowJockey_scourge = 1
    ZT_AllowCharger_scourge = 1
    ZT_AllowWitch_scourge = 0
    ZT_AllowTank_scourge = 0

    ZT_AllowSmoker_toxic = 1
    ZT_AllowBoomer_toxic = 1
    ZT_AllowHunter_toxic = 1
    ZT_AllowSpitter_toxic = 1
    ZT_AllowJockey_toxic = 1
    ZT_AllowCharger_toxic = 1
    ZT_AllowWitch_toxic = 0
    ZT_AllowTank_toxic = 0

    ZT_AllowSmoker_slime = 1
    ZT_AllowBoomer_slime = 1
    ZT_AllowHunter_slime = 1
    ZT_AllowSpitter_slime = 1
    ZT_AllowJockey_slime = 1
    ZT_AllowCharger_slime = 1
    ZT_AllowWitch_slime = 0
    ZT_AllowTank_slime = 0

    ZT_AllowSmoker_bhop = 1
    ZT_AllowBoomer_bhop = 1
    ZT_AllowHunter_bhop = 1
    ZT_AllowSpitter_bhop = 1
    ZT_AllowJockey_bhop = 1
    ZT_AllowCharger_bhop = 1
    ZT_AllowWitch_bhop = 0
    ZT_AllowTank_bhop = 0

    ZT_AllowSmoker_teleporter = 1
    ZT_AllowBoomer_teleporter = 1
    ZT_AllowHunter_teleporter = 1
    ZT_AllowSpitter_teleporter = 1
    ZT_AllowJockey_teleporter = 1
    ZT_AllowCharger_teleporter = 1
    ZT_AllowWitch_teleporter = 0
    ZT_AllowTank_teleporter = 0
}
"