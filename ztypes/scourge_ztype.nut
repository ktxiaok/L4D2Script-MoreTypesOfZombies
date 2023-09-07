local _ctx = this;

const ScourgeZtypeColor = 0xe22b8a;

_entScopeKey_isScourgeResurrecting <- UniqueString("isResurrecting");

function IsEntityScourgeResurrecting(ent)
{
    local entScope = TryGetEntityScope(ent);
    if (entScope != null)
    {
        if (_entScopeKey_isScourgeResurrecting in entScope)
        {
            return entScope[_entScopeKey_isScourgeResurrecting];
        }
    }
    return false;
}

function SetEntityScourgeResurrecting(ent, val)
{
    local entScope = TryGetEntityScope(ent);
    if (entScope != null)
    {
        entScope[_entScopeKey_isScourgeResurrecting] <- val;
    }
}

class ScourgeZtype extends Ztype
{
    _zombieDeathCallback = null;

    constructor()
    {
        base.constructor();
    }

    function Init()
    {
        base.Init();
        _zombieDeathCallback = function(params) {
            OnZombieDeath(params);
        }.bindenv(this);
        ::KtScript.RegisterGameHook("OnGameEvent_zombie_death", _zombieDeathCallback);
    }

    function GetInstanceClass()
    {
        return _ctx.ScourgeZtypeInstance;
    }

    function GetName()
    {
        return "scourge";
    }

    function GetColor()
    {
        return ScourgeZtypeColor;
    }

    function OnZombieDeath(params)
    {
        local zombie = EntIndexToHScript(params.victim);
        if ("GetZombieType" in zombie)
        {
            local t = zombie.GetZombieType();
            if (t >= 1 && t <= 6)
            {
                foreach (instance in GetInstanceIter())
                {
                    instance.TryAddResurrectActivity(zombie);
                }
            }
        }
    }
}

class ScourgeZtypeInstance extends ZtypeInstance
{
    static UpdateInterval = 0.2;

    _resurrectActivities = null;
    _queuedResurrectActivities = null;

    _commonSpawnTimer = null;

    constructor(zombie)
    {
        base.constructor(zombie);
        _ctx.SetZombieHealthMultiplier(zombie, GetHealthMultiplier());
        _resurrectActivities = [];
        _queuedResurrectActivities = _ctx.Queue(_ctx.GetCfgProp("ScourgeResurrectQueueCapacity"));
        _commonSpawnTimer = GetCommonSpawnPeriod();
        EnableUpdater(UpdateInterval);
    }

    function OnUpdate(dt)
    {
        for (local i = 0; i < _resurrectActivities.len();)
        {
            local activity = _resurrectActivities[i];
            if (!activity.IsValid())
            {
                _resurrectActivities.remove(i);
                continue;
            }
            activity.Update(dt);
            i++;
        }

        while (_queuedResurrectActivities.GetCount() > 0)
        {
            local activity = _queuedResurrectActivities.GetHead();
            if (TryActivateResurrectActivity(activity))
            {
                _queuedResurrectActivities.PopHead();
            }
            else
            {
                break;
            }
        }

        _commonSpawnTimer -= dt;
        if (_commonSpawnTimer <= 0.0)
        {
            _commonSpawnTimer = GetCommonSpawnPeriod();

            local spawnPos = _zombie.GetOrigin();
            local spawnCount = GetCommonSpawnCount();
            local limit = GetCommonLimit();
            for (local i = 0; i < spawnCount; i++)
            {
                if (Director.GetCommonInfectedCount() >= limit)
                {
                    break;
                }
                ZSpawn({type = 0, pos = spawnPos});
            }
        }
    }

    function OnDestroy(params)
    {
        DisableUpdater();
        foreach (activity in _resurrectActivities)
        {
            activity.Destroy();
        }
        base.OnDestroy(params);
    }

    function TryAddResurrectActivity(zombie)
    {
        if (zombie == _zombie)
        {
            return;
        }
        if (!_zombie.IsValid())
        {
            return;
        }
        if (!zombie.IsValid())
        {
            return;
        }
        if (_ctx.IsEntityScourgeResurrecting(zombie))
        {
            return;
        }
        local range = GetResurrectRange();
        local rangeSqr = range * range;
        local distSqr = (_zombie.GetOrigin() - zombie.GetOrigin()).LengthSqr();
        if (distSqr > rangeSqr)
        {
            return;
        }
        _ctx.SetEntityScourgeResurrecting(zombie, true);

        local activity = _ctx.ScourgeResurrectActivity(_zombie, zombie.GetOrigin(), _ctx.GetBasicZombieType(zombie), _ctx.GetEntityZtypeName(zombie));
        if (!TryActivateResurrectActivity(activity))
        {
            if (_queuedResurrectActivities.GetCount() == _queuedResurrectActivities.GetCapacity())
            {
                _queuedResurrectActivities.PopHead();
            }
            _queuedResurrectActivities.PushTail(activity);
        }
    }

    function TryActivateResurrectActivity(activity)
    {
        if (_resurrectActivities.len() < GetResurrectSimulMax())
        {
            activity.Activate();
            _resurrectActivities.append(activity);
            return true;
        }
        return false;
    }

    function GetResurrectRange()
    {
        return _ctx.GetCfgProp("ScourgeResurrectRange");
    }

    function GetResurrectSimulMax()
    {
        return _ctx.GetCfgProp("ScourgeResurrectSimulMax");
    }

    function GetCommonSpawnPeriod()
    {
        return _ctx.GetCfgProp("ScourgeSpawnCommonInfectedPeriod");
    }

    function GetCommonSpawnCount()
    {
        return _ctx.GetCfgProp("ScourgeSpawnCommonInfectedCount");
    }

    function GetCommonLimit()
    {
        return _ctx.GetCfgProp("ScourgeCommonInfectedLimit");
    }

    function GetHealthMultiplier()
    {
        return _ctx.GetCfgProp("ScourgeHealthMultiplier");
    }
}

class ScourgeResurrectActivity
{
    _scourgeZombie = null;

    _pos = null;

    _basicZombieType = null;

    _ztypeName = null;

    _timer = null;

    _beam = null;
    _beamStartPoint = null;
    _beamEndPoint = null;

    _isValid = true;
    _isActivated = false;

    constructor(scourgeZombie, pos, basicZombieType, ztypeName)
    {
        _scourgeZombie = scourgeZombie;
        _pos = pos;
        _basicZombieType = basicZombieType;
        _ztypeName = ztypeName;
        _timer = GetPeriod();
    }

    function IsValid()
    {
        return _isValid;
    }

    function Activate()
    {
        if (_isActivated)
        {
            return;
        }
        if (!_scourgeZombie.IsValid())
        {
            return;
        }
        _isActivated = true;

        local nullModelName = "models/props_doors/null.mdl";
        local beamStartTargetName = ::KtScript.CreateUniqueTargetName("beam_start");
        local beamEndTargetName = ::KtScript.CreateUniqueTargetName("beam_end");

        _beamStartPoint = SpawnEntityFromTable("prop_dynamic", {
            targetname = beamStartTargetName,
            origin = GetScourgeZombiePos(),
            model = nullModelName
        });
        EntFire(beamStartTargetName, "SetParent", "!activator", 0, _scourgeZombie);
        _beamEndPoint = SpawnEntityFromTable("prop_dynamic", {
            targetname = beamEndTargetName,
            origin = _pos,
            model = nullModelName
        });
        _beam = SpawnEntityFromTable("env_beam", {
            BoltWidth = 1,
            damage = 0,
            decalname = "Bigshot",
            framerate = 0,
            framestart = 0,
            life = 0,
            LightningStart = beamStartTargetName,
            LightningEnd = beamEndTargetName,
            NoiseAmplitude = 4,
            renderamt = 255,
            rendercolor = "128 0 255",
            renderfx = 0,
            spawnflags = 1 | 128,
            StrikeTime = 1,
            texture = "sprites/laserbeam.spr",
            TextureScoll = 35,
            TouchType = 0
        });
    }

    function Update(dt)
    {
        if (!_isValid || !_isActivated)
        {
            return;
        }

        // if (_scourgeZombie.IsValid())
        // {
        //     if (_beamStartPoint.IsValid())
        //     {
        //         _beamStartPoint.SetOrigin(GetScourgeZombiePos());
        //     }
        // }

        _timer -= dt;
        if (_timer <= 0.0)
        {
            Resurrect();
            Destroy();
        }
    }

    function Resurrect()
    {
        local scourgeProb = GetSpawnScourgeProb();
        local ztypeName = RandomFloat(0.0, 1.0) <= scourgeProb ? "scourge" : _ztypeName;
        if (ztypeName != null)
        {
            _ctx._nextZtypeName = ztypeName;
        }
        ZSpawn({type = _basicZombieType, pos = _pos});
        if (ztypeName != null)
        {
            _ctx._nextZtypeName = null;
        }
    }

    function Destroy()
    {
        if (!_isValid)
        {
            return;
        }

        if (_isActivated)
        {
            if (_beam.IsValid())
            {
                _beam.Kill();
            }
            if (_beamStartPoint.IsValid())
            {
                _beamStartPoint.Kill();
            }
            if (_beamEndPoint.IsValid())
            {
                _beamEndPoint.Kill();
            }
        }

        _isValid = false;
    }

    function GetScourgeZombiePos()
    {
        return ("EyePosition" in _scourgeZombie) ? _scourgeZombie.EyePosition() : _scourgeZombie.GetOrigin();
    }

    function GetPeriod()
    {
        return _ctx.GetCfgProp("ScourgeResurrectTime");
    }

    function GetSpawnScourgeProb()
    {
        return _ctx.GetCfgProp("ScourgeResurrectToScourgeProb");
    }
}

