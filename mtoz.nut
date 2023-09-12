DefaultConfigFilePath <- "ktscript/more_types_of_zombies/default_config_template.nut";
ConfigDirectoryPath <- "ktscript/more_types_of_zombies/configs/"
AutoLoadConfigNameFilePath <- ConfigDirectoryPath + "_autoload_.txt";
ReadmeFilePath <- "ktscript/more_types_of_zombies/readme.txt";

const FlashSoundName = "ambient\\fire\\gascan_ignite1.wav";
PrecacheSound(FlashSoundName);

PrecacheModel("models/props_doors/null.mdl");

local _ctx = this;

_version <- "1.5.0";

_basicZtypeNameToInt <- {
    smoker = 1,
    boomer = 2,
    hunter = 3,
    spitter = 4,
    jockey = 5,
    charger = 6,
    witch = 7,
    tank = 8
};

_basicZtypeIntToInitcapName <- {
    [1] = "Smoker",
    [2] = "Boomer",
    [3] = "Hunter",
    [4] = "Spitter",
    [5] = "Jockey",
    [6] = "Charger",
    [7] = "Witch",
    [8] = "Tank"
}

IncludeScript("ktscript/more_types_of_zombies/utils");

function ImportModule(fileName, name)
{
    local moduleScope = {};
    moduleScope._rootctx <- this;
    IncludeScript("ktscript/more_types_of_zombies/" + fileName, moduleScope);
    ::KtScript.ImportPublicMembers(moduleScope, this);
    this["_module" + name] <- moduleScope;
}

ImportModule("config_system", "ConfigSystem");
ImportModule("random_weight_picker", "RandomWeightPicker");
ImportModule("tank_rock_mgr", "TankRockMgr");
ImportModule("zombie_mapping_mgr", "ZombieMappingMgr");
ImportModule("shadow_mgr", "ShadowMgr");
ImportModule("zombie_color_mgr", "ZombieColorMgr");
ImportModule("explosion_mgr", "ExplosionMgr");

_entScopeKey_ztypeName <- UniqueString("ztypeName");

function GetEntityZtypeName(ent)
{
    local entScope = TryGetEntityScope(ent);
    if (entScope != null)
    {
        if (_entScopeKey_ztypeName in entScope)
        {
            return entScope[_entScopeKey_ztypeName];
        }
    }
    return null;
}

function SetEntityZtypeName(ent, name)
{
    local entScope = TryGetEntityScope(ent);
    if (entScope != null)
    {
        entScope[_entScopeKey_ztypeName] <- name;
    }
}

class Ztype
{
    _task = null;
    _zombieMapping = null;

    constructor()
    {
        _ctx.RegisterZtype(this);
    }

    function Init()
    {
        local instanceClass = GetInstanceClass();
        if (!_ctx.IsSubClass(_ctx.ZtypeInstance, instanceClass))
        {
            throw format("The class %s isn't the subclass of the class %s", instanceClass.tostring(), _ctx.ZtypeInstance.tostring());
        }
        _zombieMapping = _ctx.ZombieMappingMgr(instanceClass);
        if (IsAbilityListeningEnabled())
        {
            _zombieMapping.EnableAbilityListening();
        }
        if (IsTankRockListeningEnabled())
        {
            _zombieMapping.EnableTankRockListening();
        }
        if (IsHurtListeningEnabled())
        {
            _zombieMapping.EnableHurtListening();
        }
    }

    function GetInstanceClass()
    {
        throw "The method GetInstanceClass isn't implemented!";
    }

    function IsAbilityListeningEnabled()
    {
        return false;
    }

    function IsTankRockListeningEnabled()
    {
        return false;
    }

    function IsHurtListeningEnabled()
    {
        return false;
    }

    function GetName()
    {
        throw "GetName() not implemented!";
    }

    function GetColor()
    {
        return null;
    }

    function GetLimit()
    {
        return _ctx.GetCfgProp("ZTLimit_" + GetName());
    }

    function GetCurrentCount()
    {
        return _zombieMapping.GetCount();
    }

    function ContainsZombie(ent)
    {
        return _zombieMapping.TryGet(ent) != null;
    }

    function GetInstanceIter()
    {
        foreach (instance in _zombieMapping.GetMappingObjectIter())
        {
            yield instance;
        }
    }

    function TryGetInstance(zombie)
    {
        return _zombieMapping.TryGet(zombie);
    }

    function CanAccept(zombie)
    {
        local intBasicZtype = zombie.GetClassname() == "witch" ? DirectorScript.ZOMBIE_WITCH : zombie.GetZombieType();
        local intBasicZtypeToName = _ctx._basicZtypeIntToInitcapName;
        if (!(intBasicZtype in intBasicZtypeToName))
        {
            return false;
        }
        local basicZtypeName = intBasicZtypeToName[intBasicZtype];
        if (_ctx.GetCfgProp("ZT_Allow" + basicZtypeName + "_" + GetName()))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    function TryInitZombie(zombie)
    {
        if (_zombieMapping.TryGet(zombie) != null)
        {
            return false;
        }

        if (!CanAccept(zombie))
        {
            return false;
        }

        local limit = GetLimit();
        local currentCount = GetCurrentCount();
        if (limit > 0 && currentCount >= limit)
        {
            return false;
        }

        _zombieMapping.Get(zombie);
        _ctx.SetEntityZtypeName(zombie, GetName());

        local color = GetColor();
        if (color != null)
        {
            _ctx.SetZombieColor(zombie, color);
            _ctx.SetZombieGlowFactor(zombie, 0.33);
        }

        return true;
    }
}

class ZtypeInstance
{
    _zombie = null;
    _base_task = null;

    constructor(zombie)
    {
        _zombie = zombie;
    }

    function EnableUpdater(updateInterval)
    {
        if (_base_task != null)
        {
            return;
        }

        local action = function() {
            if (!_zombie.IsValid())
            {
                return;
            }
            return OnUpdate(_base_task.GetDelay());
        }.bindenv(this);
        _base_task = ::KtScript.Task(action, updateInterval, true);
        _base_task.Submit();
    }

    function DisableUpdater()
    {
        if (_base_task == null)
        {
            return;
        }
        _base_task.Kill();
        _base_task = null;
    }

    function OnUpdate(dt)
    {
        throw "OnUpdate not implemented!";
    }

    function OnDestroy(params)
    {
        DisableUpdater();
    }
}

class ZombieSpawnInterceptor
{
    _ztypeName = null;

    constructor()
    {

    }

    function GetZtypeName()
    {
        return _ztypeName;
    }

    function SetZtypeName(ztypeName)
    {
        _ztypeName = ztypeName;
    }

    function OnSpawn(zombie)
    {

    }
}

IncludeScript("ktscript/more_types_of_zombies/ztypes/heavy_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/extra_heavy_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/acid_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/cloaking_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/explosive_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/flash_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/shield_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/speed_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/flame_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/scourge_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/toxic_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/slime_ztype");
IncludeScript("ktscript/more_types_of_zombies/ztypes/bhop_ztype");

_config <- {};

_ztypeRandomWeights <- null;

_ztypes <- {};

_ztypeRandomPicker <- null;

_nextZtypeName <- null;

function DefineProperties()
{
    DefineProperty({name = "HeavyHealthMultiplier", type = "float", setter = "range(1.0)"});
    DefineProperty({name = "HeavyHealthMultiplierCharger", type = "float", setter = "range(1.0)"});
    DefineProperty({name = "ExtraHeavyHealthMultiplier", type = "float", setter = "range(1.0)"});
    DefineProperty({name = "ExtraHeavyHealthMultiplierCharger", type = "float", setter = "range(1.0)"});

    DefineProperty({name = "CloakingStartupTime", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "CloakingTime", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "CloakingExitTime", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "ExplosionMagnitude", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ExplosionPhysMagnitude", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ExplosionPhysMagnitudeTankRock", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "FlashAttFactor", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlashPeriod", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlashBlindHoldTime", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlashBlindFadeTime", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlashSlowFactor", type = "float", setter = "range(1.0)"});
    DefineProperty({name = "FlashSlowFactorTank", type = "float", setter = "range(1.0)"});
    DefineProperty({name = "IsFlashColorWhite", type = "bool"});
    DefineProperty({name = "FlashDisableGlowTime", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "ShieldHealthMultiplier", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ShieldRecoverSpeed", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "SpeedFactor0", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "SpeedFactor1", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "SpeedFactor0Charger", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "SpeedFactor1Charger", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "SpeedLateralAccelFactor", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "FlameAttackRange", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameAttackPeriod", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameFireballAttackRange", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameFireballAttackPeriod", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameFireballDamage", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameIgniteObjectsRange", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "FlameIgniteObjectsPeriod", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "ScourgeHealthMultiplier", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ScourgeResurrectMaxCount", type = "integer", setter = "range(1)"});
    DefineProperty({name = "ScourgeResurrectTime", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ScourgeResurrectRange", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ScourgeResurrectSimulMax", type = "integer", setter = "range(0)"});
    DefineProperty({name = "ScourgeResurrectQueueCapacity", type = "integer", setter = "range(1)"});
    DefineProperty({name = "ScourgeResurrectToScourgeProb", type = "float", setter = "range(0.0,1.0)"});
    DefineProperty({name = "ScourgeSpawnCommonInfectedCount", type = "integer", setter = "range(0)"});
    DefineProperty({name = "ScourgeSpawnCommonInfectedPeriod", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ScourgeCommonInfectedLimit", type = "integer", setter = "range(0)"});

    DefineProperty({name = "ToxicSmokeDamageRadius", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ToxicSmokeDamage", type = "integer", setter = "range(0)"});
    DefineProperty({name = "ToxicSmokeDuration", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ToxicSmokeEmitInterval", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ToxicEffectCutHealthToBuffer", type = "integer", setter = "range(0)"});
    DefineProperty({name = "ToxicEffectMinHealth", type = "integer", setter = "range(1)"});
    DefineProperty({name = "ToxicEffectDuration", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "ToxicEffectScreenEffectMaxAlpha", type = "integer", setter = "range(0,255)"});

    DefineProperty({name = "SlimeMaxSplitCount", type = "integer", setter = "range(1)"});
    DefineProperty({name = "SlimePoppingSpeed", type = "float", setter = "range(0.0)"});

    DefineProperty({name = "BhopJumpAccel", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "BhopLateralAccel", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "BhopInitialAccel", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "BhopAccelIncrement", type = "float", setter = "range(0.0)"});
    DefineProperty({name = "BhopAccelMaxCount", type = "integer", setter = "range(1)"});

    DefineProperty({name = "ZTSPW_normal", type = "float"});
    foreach (ztype in GetAllZtypes())
    {
        local name = ztype.GetName();
        DefineProperty({name = "ZTSPW_" + name, type = "float"});
    }

    foreach (ztype in GetAllZtypes())
    {
        local name = ztype.GetName();
        DefineProperty({name = "ZTLimit_" + name, type = "integer", setter = "range(0)"});
    }

    foreach (ztype in GetAllZtypes())
    {
        local ztypeName = ztype.GetName();
        foreach (key, basicZtypeName in _basicZtypeIntToInitcapName)
        {
            DefineProperty({name = "ZT_Allow" + basicZtypeName + "_" + ztypeName, type = "bool"});
        }
    }
}

function LoadDefaultConfig()
{
    local code = {};
    IncludeScript("ktscript/more_types_of_zombies/default_config", code);
    code = code.code;
    code = compilestring("return " + code);
    local table = code();
    LoadConfigFromTable(table);
}

function LoadConfig(name)
{
    local path = ConfigDirectoryPath + name + ".nut";
    local config = ::KtScript.FileToTable(path);
    if (config == null)
    {
        throw format("The config template \"%s\" doesn't exist!", name);
    }
    LoadConfigFromTable(config);
}

function AutoLoadConfigUnchecked()
{
    local name = GetAutoLoadConfigName();
    if (name == null)
    {
        return false;
    }
    LoadConfig(name);
    return true;
}

function AutoLoadConfig()
{
    try
    {
        return AutoLoadConfigUnchecked();
    }
    catch (exception)
    {
        printl("[MTOZ] Auto Load Config Error: ");
        printl(exception);
    }
}

function GetAutoLoadConfigName()
{
    return FileToString(AutoLoadConfigNameFilePath);
}

function SaveAutoLoadConfigName(name)
{
    StringToFile(AutoLoadConfigNameFilePath, name);
}

function GenerateDefaultConfigFile()
{
    local code = {};
    IncludeScript("ktscript/more_types_of_zombies/default_config", code);
    local text = code.code;
    StringToFile(DefaultConfigFilePath, text);
}

function SaveCustomConfig()
{
    SaveConfigToFile(CustomConfigFilePath);
}

function ApplyConfig()
{
    CreateZtypeRandomPicker();
}

function CreateZtypeRandomPicker()
{
    local weightTable = {};
    local normalWeight = GetCfgProp("ZTSPW_normal");
    if (normalWeight > 0.0)
    {
        weightTable.normal <- normalWeight;
    }
    foreach (ztype in GetAllZtypes())
    {
        local name = ztype.GetName();
        local weightName = "ZTSPW_" + name;
        local weight = GetCfgProp(weightName);
        if (weight > 0.0)
        {
            weightTable[name] <- weight;
        }
    }
    _ztypeRandomPicker = RandomWeightPicker(weightTable);
}

function RandomPickZtype()
{
    local name = _ztypeRandomPicker.Pick();
    if (name == "normal")
    {
        return null;
    }
    return FindZtype(name);
}

function FindZtype(name)
{
    if (name in _ztypes)
    {
        return _ztypes[name];
    }
    return null;
}

function GetAllZtypes()
{
    foreach (name, ztype in _ztypes)
    {
        yield ztype;
    }
}

function RegisterZtype(ztype)
{
    _ztypes[ztype.GetName()] <- ztype;
}

function InitZtypes()
{
    foreach (ztype in GetAllZtypes())
    {
        ztype.Init();
    }
}

function CreateAllZtypes()
{
    HeavyZtype();
    ExtraHeavyZtype();
    ShieldZtype();
    AcidZtype();
    CloakingZtype();
    ExplosiveZtype();
    FlashZtype();
    SpeedZtype();
    FlameZtype();
    ScourgeZtype();
    ToxicZtype();
    SlimeZtype();
    BhopZtype();
}

function SpawnZombie(basicName, ztypeName, pos)
{
    local basicType = null;
    if (basicName in _basicZtypeNameToInt)
    {
        basicType = _basicZtypeNameToInt[basicName];
    }
    if (basicType == null)
    {
        return;
    }

    local ztype = FindZtype(ztypeName);
    if (ztype == null)
    {
        return;
    }

    _nextZtypeName = ztypeName;
    local spawnTable = {
        type = basicType,
        pos = pos
    };
    ZSpawn(spawnTable);
}

function OnPlayerSpawn(player)
{
    local t = player.GetZombieType();
    if (t >= 1 && t <= 8)
    {
        OnZombieSpawn(player);
    }
}

function OnWitchSpawn(witch)
{
    OnZombieSpawn(witch);
}

_zombieSpawnInterceptor <- null;

function OnZombieSpawn(zombie)
{
    local ztype = null;
    if (_nextZtypeName != null)
    {
        ztype = FindZtype(_nextZtypeName);
        _nextZtypeName = null;
    }
    else if (_zombieSpawnInterceptor != null)
    {
        _zombieSpawnInterceptor.OnSpawn(zombie);
        local expectedZtypeName = _zombieSpawnInterceptor.GetZtypeName();
        if (expectedZtypeName != null)
        {
            ztype = FindZtype(expectedZtypeName);
        }
    }
    if (ztype == null)
    {
        ztype = RandomPickZtype();
    }
    if (ztype != null)
    {
        ztype.TryInitZombie(zombie);
    }
}

function ZSpawnWithInterceptor(spawnTable, interceptor)
{
    _zombieSpawnInterceptor = interceptor;
    ZSpawn(spawnTable);
    _zombieSpawnInterceptor = null;
}

_playerHurtCallbacks <- [];

function AddPlayerHurtCallback(callback)
{
    _playerHurtCallbacks.append(callback);
}

function RemovePlayerHurtCallback(callback)
{
    local idx = _playerHurtCallbacks.find(callback);
    if (idx != null)
    {
        _playerHurtCallbacks.remove(idx);
    }
}

_eventCallbacks <- {
    OnGameEvent_player_spawn = function(params) {
        OnPlayerSpawn(GetPlayerFromUserID(params.userid));
    }.bindenv(_ctx),

    OnGameEvent_witch_spawn = function(params) {
        local witch = EntIndexToHScript(params.witchid);
        OnWitchSpawn(witch);
    }.bindenv(_ctx),

    OnGameEvent_player_hurt_concise = function(params) {
        foreach (callback in _playerHurtCallbacks)
        {
            callback(params);
        }
    }.bindenv(_ctx)
};

function InitChatCmds()
{
    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_spawn",
        args = [
            ::KtScript.ChatCmdArg({
                name = "basicname",
                isOptional = false,
            }),
            ::KtScript.ChatCmdArg({
                name = "ztypename",
                isOptional = false,
            })
        ]
        action = function(player, argTable) {
            local pos = GetLookPosition(player);
            if (pos == null)
            {
                PrintTalk("Invalid spawn position!", player);
                return;
            }
            SpawnZombie(argTable.basicname, argTable.ztypename, pos);
        }.bindenv(_ctx),
        positionalArgs = ["basicname", "ztypename"],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_cfg_load",
        args = [
            ::KtScript.ChatCmdArg({
                name = "cfgname",
                isOptional = true
            })
        ]
        action = function(player, argTable) {
            LoadDefaultConfig();
            local cfgname = argTable.cfgname;
            if (cfgname == null)
            {
                try
                {
                    if (AutoLoadConfigUnchecked())
                    {
                        ApplyConfig();
                        Say(null, "Load auto-load config successfully!", false);
                    }
                    else
                    {
                        Say(null, "The auto-load config doesn't exist!", false);
                    }
                }
                catch (exception)
                {
                    Say(null, exception.tostring(), false);
                }
            }
            else
            {
                try
                {
                    LoadConfig(cfgname);
                    ApplyConfig();
                    Say(null, format("Load the config \"%s\" successfully!", cfgname), false);
                }
                catch (exception)
                {
                    Say(null, exception.tostring(), false);
                }
            }
        }.bindenv(_ctx),
        positionalArgs = ["cfgname"],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_cfg_autoload",
        args = [
            ::KtScript.ChatCmdArg({
                name = "cfgname",
                isOptional = true
            })
        ]
        action = function(player, argTable) {
            local cfgname = argTable.cfgname;
            if (cfgname == null)
            {
                local autoloadCfgname = GetAutoLoadConfigName();
                if (autoloadCfgname == null)
                {
                    Say(null, "No auto-load config.", false);
                }
                else
                {
                    Say(null, format("Current auto-load config: %s", autoloadCfgname), false);
                }
            }
            else
            {
                SaveAutoLoadConfigName(cfgname);
                Say(null, format("Set the auto-load config to %s successfully.", cfgname), false);
            }
        }.bindenv(_ctx),
        positionalArgs = ["cfgname"],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_cfg_reset",
        args = [

        ]
        action = function(player, argTable) {
            LoadDefaultConfig();
            ApplyConfig();
            Say(null, "Set the config to default successfully!", false);
        }.bindenv(_ctx),
        positionalArgs = [],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_cfg_prop",
        args = [
            ::KtScript.ChatCmdArg({
                name = "propname",
                isOptional = false
            }),
            ::KtScript.ChatCmdArg({
                name = "propval",
                isOptional = true
            })
        ]
        action = function(player, argTable) {
            local name = argTable.propname;
            local val = argTable.propval;
            try
            {
                if (val == null)
                {
                    val = GetCfgProp(name);
                    Say(null, format("%s=%s", name, val.tostring()), false);
                }
                else
                {
                    SetCfgProp(name, val);
                    ApplyConfig();
                    Say(null, format("Set the property %s to %s successfully!", name, val.tostring()), false);
                }
            }
            catch (exception)
            {
                Say(null, "Error: " + exception.tostring(), false);
            }
        }.bindenv(_ctx),
        positionalArgs = ["propname", "propval"],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_cfg_save",
        args = [
            ::KtScript.ChatCmdArg({
                name = "cfgname",
                isOptional = false
            }),
            ::KtScript.ChatCmdArg({
                name = "ow",
                isOptional = true,
                expectedType = "integer",
                defaultValue = 0
            })
        ]
        action = function(player, argTable) {
            local cfgname = argTable.cfgname;
            local ow = argTable.ow;
            local filepath = ConfigDirectoryPath + cfgname + ".nut";
            if (!ow && FileToString(filepath))
            {
                Say(null, format("Overwriting is disabled! Please use \"/mtoz_cfg_save %s -ow 1\" to enable overwriting.\n"
                + "Warning: Overwriting config file will cause code comments to be lost and mess up the writing order!", cfgname), false);
                return;
            }
            SaveConfigToFile(filepath);
            Say(null, format("Save the current configuration to config template file \"%s\" successfully!", cfgname), false);
        }.bindenv(_ctx),
        positionalArgs = ["cfgname"],
        permissionLevel = 4
    }));

    ::KtScript.AddChatCmd(::KtScript.ChatCmd({
        name = "mtoz_version",
        args = [

        ]
        action = function(player, argTable) {
            Say(null, format("More Types of Zombies v%s", _version), false);
        }.bindenv(_ctx),
        positionalArgs = [],
        permissionLevel = 0
    }));
}

function GenerateReadmeFile()
{
    local table = {};
    IncludeScript("ktscript/more_types_of_zombies/ems_readme.nut", table);
    local content = table.content;
    StringToFile(ReadmeFilePath, content);
}

function Init()
{
    CreateAllZtypes();

    _moduleConfigSystem.Init(_config);
    DefineProperties();
    LoadDefaultConfig();
    AutoLoadConfig();

    _moduleTankRockMgr.Init();

    _moduleZombieMappingMgr.Init();

    _moduleZombieColorMgr.Init();

    _moduleShadowMgr.Init();

    _moduleExplosionMgr.Init();

    ApplyConfig();

    InitZtypes();

    InitChatCmds();

    GenerateReadmeFile();
    GenerateDefaultConfigFile();

    _moduleTankRockMgr.RegisterEventCallbacks();
    _moduleZombieMappingMgr.RegisterEventCallbacks();
    ::KtScript.RegisterEventCallbacks(_ctx, _eventCallbacks);
}