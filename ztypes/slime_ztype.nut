local _ctx = this;
const SlimeZtypeColor = 0x40913d;
const SlimeZtypeAlpha1 = 200;
const SlimeZtypeAlpha2 = 150;
const SlimeZtypeAlpha3 = 110;

class SlimeZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.SlimeZtypeInstance;
    }

    function GetName()
    {
        return "slime";
    }

    function GetColor()
    {
        return SlimeZtypeColor;
    }
}

class SlimeZtypeInstance extends ZtypeInstance
{
    _splitCount = 0;
    _initialHealth = null;

    constructor(zombie)
    {
        base.constructor(zombie);

        _splitCount = _ctx.SlimeZtype_GetZombieSplitCount(zombie);
        _initialHealth = _ctx.SlimeZtype_GetZombieInitialHealth(zombie);

        zombie.SetHealth(_initialHealth);

        local alpha = null;
        if (_splitCount == 1)
        {
            alpha = SlimeZtypeAlpha1;
        }
        else if (_splitCount == 2)
        {
            alpha = SlimeZtypeAlpha2;
        }
        else if (_splitCount >= 3)
        {
            alpha = SlimeZtypeAlpha3;
        }
        if (alpha != null)
        {
            _ctx.SetZombieAlpha(zombie, alpha);
        }

        if (_splitCount > 0)
        {
            zombie.SetVelocity(_ctx.VecRandomUnit() * GetPoppingSpeed());
        }
    }

    function OnDestroy(params)
    {
        if (params.isEntValid)
        {
            if (_splitCount < GetMaxSplitCount())
            {
                local nextHealth = (_initialHealth * 0.5).tointeger();
                if (nextHealth > 0)
                {
                    CreateSplitParticleEffect();
                    local spawnInterceptor = _ctx.SlimeZtypeSpawnInterceptor(_splitCount + 1, nextHealth);
                    local spawnTable = {type = _ctx.GetBasicZombieType(_zombie), pos = _zombie.GetOrigin()};
                    _ctx.ZSpawnWithInterceptor(spawnTable, spawnInterceptor);
                    _ctx.ZSpawnWithInterceptor(spawnTable, spawnInterceptor);
                }
            }
        }
        base.OnDestroy(params);
    }

    function CreateSplitParticleEffect()
    {
        local propTable = {
            origin = _zombie.GetOrigin(),
            effect_name = "vomit_jar_b",
            start_active = "1"
        }
        local effect = SpawnEntityFromTable("info_particle_system", propTable);
        _ctx.SimpleEntFire(effect, "Kill", null, 3.0);
    }

    function GetMaxSplitCount()
    {
        return _ctx.GetCfgProp("SlimeMaxSplitCount");
    }

    function GetPoppingSpeed()
    {
        return _ctx.GetCfgProp("SlimePoppingSpeed");
    }
}

class SlimeZtypeSpawnInterceptor extends ZombieSpawnInterceptor
{
    _splitCount = 0;
    _initialHealth = null;

    constructor(nextSplitCount, nextHealth)
    {
        base.constructor();
        _splitCount = nextSplitCount;
        _initialHealth = nextHealth;
        SetZtypeName("slime");
    }

    function OnSpawn(zombie)
    {
        _ctx.SlimeZtype_SetZombieSplitCount(zombie, _splitCount);
        _ctx.SlimeZtype_SetZombieInitialHealth(zombie, _initialHealth);
    }
}

local _entScopeKey_SplitCount = UniqueString("splitCount");
local _entScopeKey_InitialHealth = UniqueString("initialHealth");

function SlimeZtype_GetZombieSplitCount(zombie)
{
    zombie.ValidateScriptScope();
    local scope = zombie.GetScriptScope();
    if (_entScopeKey_SplitCount in scope)
    {
        return scope[_entScopeKey_SplitCount];
    }
    else
    {
        return 0;
    }
}

function SlimeZtype_SetZombieSplitCount(zombie, splitCount)
{
    zombie.ValidateScriptScope();
    zombie.GetScriptScope()[_entScopeKey_SplitCount] <- splitCount;
}

function SlimeZtype_GetZombieInitialHealth(zombie)
{
    zombie.ValidateScriptScope();
    local scope = zombie.GetScriptScope();
    if (_entScopeKey_InitialHealth in scope)
    {
        return scope[_entScopeKey_InitialHealth];
    }
    else
    {
        return zombie.GetHealth();
    }
}

function SlimeZtype_SetZombieInitialHealth(zombie, initialHealth)
{
    zombie.ValidateScriptScope();
    zombie.GetScriptScope()[_entScopeKey_InitialHealth] <- initialHealth;
}
