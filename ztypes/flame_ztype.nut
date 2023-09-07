local _ctx = this;

const FlameZtypeColor = 0xcbc0ff;

class FlameZtype extends Ztype
{
    _allowTakeDamageCallback = null;

    constructor()
    {
        base.constructor();
    }

    function Init()
    {
        base.Init();
        _allowTakeDamageCallback = function(damageTable) {
            local victim = damageTable.Victim;
            if (ContainsZombie(victim))
            {
                local damageType = damageTable.DamageType;
                if (damageType & DirectorScript.DMG_BURN)
                {
                    return false;
                }
            }
            return true;
        }.bindenv(this);
        ::KtScript.RegisterGameHook("AllowTakeDamage", _allowTakeDamageCallback);
    }

    function GetInstanceClass()
    {
        return _ctx.FlameZtypeInstance;
    }

    function GetName()
    {
        return "flame";
    }

    function GetColor()
    {
        return FlameZtypeColor;
    }
}

class FlameZtypeInstance extends ZtypeInstance
{
    static UpdateInterval = 0.2;

    _fireParticleSystem = null;
    _fireball = null;

    _attackTimer = null;
    _igniteTimer = null;

    constructor(zombie)
    {
        base.constructor(zombie);
        InitFireParticleSystem();
        _attackTimer = GetAttackPeriod();
        _igniteTimer = GetIgnitePeriod();
        EnableUpdater(UpdateInterval);
    }

    function InitFireParticleSystem()
    {
        local propTable = {
            origin = _zombie.GetOrigin(),
            effect_name = "env_fire_medium",
            start_active = "1"
        };
        _fireParticleSystem = SpawnEntityFromTable("info_particle_system", propTable);
    }

    function DestroyFireParticleSystem()
    {
        if (!_fireParticleSystem.IsValid())
        {
            return;
        }
        _fireParticleSystem.Kill();
    }

    function OnUpdate(dt)
    {
        if (_fireParticleSystem.IsValid())
        {
            _fireParticleSystem.SetOrigin(_zombie.GetOrigin());
        }

        _attackTimer -= dt;
        if (_attackTimer <= 0.0)
        {
            _attackTimer = -1.0;

            DestroyFireball();

            local attackRange = GetAttackRange();
            local attackRangeSqr = attackRange * attackRange;

            local zombiePos = ("EyePosition" in _zombie) ? _zombie.EyePosition() : _zombie.GetOrigin();

            local nearestSurvivor = null;
            local minDistSqr = null;
            foreach (survivor in ::KtScript.GetSurvivorIter())
            {
                if (survivor.IsDead())
                {
                    continue;
                }
                local survivorPos = survivor.EyePosition();
                local distSqr = (zombiePos - survivorPos).LengthSqr();
                if (distSqr > attackRangeSqr)
                {
                    continue;
                }
                if (_ctx.EntLinecast(_zombie, survivor, zombiePos, survivorPos))
                {
                    continue;
                }
                if (nearestSurvivor == null)
                {
                    nearestSurvivor = survivor;
                    minDistSqr = distSqr;
                }
                else
                {
                    if (distSqr < minDistSqr)
                    {
                        nearestSurvivor = survivor;
                        minDistSqr = distSqr;
                    }
                }
            }

            if (nearestSurvivor != null)
            {
                CreateFireball(nearestSurvivor.GetOrigin());
                _attackTimer = GetAttackPeriod();
            }
        }

        if (_fireball != null)
        {
            _fireball.Update(_zombie, dt);
        }

        _igniteTimer -= dt;
        if (_igniteTimer <= 0.0)
        {
            _igniteTimer = GetIgnitePeriod();
            IgniteObjects();
        }
    }

    function OnDestroy(params)
    {
        DisableUpdater();
        DestroyFireball();
        DestroyFireParticleSystem();
        base.OnDestroy(params);
    }

    function CreateFireball(pos)
    {
        if (_fireball != null)
        {
            throw "Couldn't create fireball! (fireball != null)";
        }
        _fireball = _ctx.Fireball(pos);
    }

    function DestroyFireball()
    {
        if (_fireball != null)
        {
            _fireball.Destroy();
            _fireball = null;
        }
    }

    function IgniteObjects()
    {
        local zombiePos = ("EyePosition" in _zombie) ? _zombie.EyePosition() : _zombie.GetOrigin();
        local range = GetIgniteRange();
        foreach (explosive in _ctx.GetExplosivesInSphere(zombiePos, range))
        {
            TryIgniteObject(zombiePos, explosive);
        }
        foreach (gascan in _ctx.GetGascansInSphere(zombiePos, range))
        {
            TryIgniteObject(zombiePos, gascan);
        }
    }

    function TryIgniteObject(zombiePos, ent)
    {
        if (_ctx.EntLinecast(_zombie, ent, zombiePos))
        {
            return;
        }
        _ctx.SimpleEntFire(ent, "Ignite");
    }

    function GetAttackPeriod()
    {
        return _ctx.GetCfgProp("FlameAttackPeriod");
    }

    function GetAttackRange()
    {
        return _ctx.GetCfgProp("FlameAttackRange");
    }

    function GetIgnitePeriod()
    {
        return _ctx.GetCfgProp("FlameIgniteObjectsPeriod");
    }

    function GetIgniteRange()
    {
        return _ctx.GetCfgProp("FlameIgniteObjectsRange");
    }
}

class Fireball
{
    _pos = null;

    _particleSystem = null;

    _attackTimer = null;

    constructor(pos)
    {
        _pos = pos;
        InitParticleSystem(pos);
        _attackTimer = GetAttackPeriod();
    }

    function InitParticleSystem(pos)
    {
        local propTable = {
            origin = pos,
            effect_name = "env_fire_large_smoke",
            start_active = "1"
        };
        _particleSystem = SpawnEntityFromTable("info_particle_system", propTable);
    }

    function DestroyParticleSystem()
    {
        if (!_particleSystem.IsValid())
        {
            return;
        }
        _particleSystem.Kill();
    }

    function Destroy()
    {
        DestroyParticleSystem();
    }

    function GetAttackRange()
    {
        return _ctx.GetCfgProp("FlameFireballAttackRange");
    }

    function GetAttackPeriod()
    {
        return _ctx.GetCfgProp("FlameFireballAttackPeriod");
    }

    function GetDamage()
    {
        return _ctx.GetCfgProp("FlameFireballDamage");
    }

    function Update(attacker, dt)
    {
        _attackTimer -= dt;
        if (_attackTimer <= 0.0)
        {
            _attackTimer = GetAttackPeriod();
            Attack(attacker);
        }
    }

    function Attack(attacker)
    {
        local range = GetAttackRange();
        local rangeSqr = range * range;
        local damage = GetDamage();
        foreach (survivor in ::KtScript.GetSurvivorIter())
        {
            if (survivor.IsDead())
            {
                continue;
            }
            local survivorPos = survivor.EyePosition();
            local distSqr = (_pos - survivorPos).LengthSqr();
            if (distSqr > rangeSqr)
            {
                continue;
            }
            if (_ctx.EntLinecast(null, survivor, _pos, survivorPos))
            {
                continue;
            }
            survivor.TakeDamage(damage, DirectorScript.DMG_BURN, attacker);
        }
    }
}