local _ctx = this;

class ToxicZtype extends Ztype
{
    _playerHurtCallback = null;

    constructor()
    {
        base.constructor();

        _playerHurtCallback = function(params) {
            local player = GetPlayerFromUserID(params.userid);
            if (!player.IsSurvivor())
            {
                return;
            }
            local attacker = EntIndexToHScript(params.attackerentid);
            local ztypeInstance = TryGetInstance(attacker);
            if (ztypeInstance == null)
            {
                return;
            }
            OnPlayerHurt(player);
        }.bindenv(this);

        ::KtScript.RegisterGameHook("OnGameEvent_player_hurt_concise", _playerHurtCallback);
    }

    function GetInstanceClass()
    {
        return _ctx.ToxicZtypeInstance;
    }

    function GetName()
    {
        return "toxic";
    }

    function OnPlayerHurt(player)
    {
        _ctx.AddToxicEffect(player);
    }
}

class ToxicZtypeInstance extends ZtypeInstance
{
    static UpdateInterval = 0.2;

    _particleSystem = null;

    _emitTimer = null;

    constructor(zombie)
    {
        base.constructor(zombie);
        _particleSystem = SpawnEntityFromTable("info_particle_system", {
            origin = zombie.GetOrigin(),
            effect_name = "smoke_traintunnel_lower",
            start_active = "1"
        });
        _emitTimer = 0.0;
        EnableUpdater(UpdateInterval);
    }

    function OnUpdate(dt)
    {
        if (_particleSystem.IsValid())
        {
            _particleSystem.SetOrigin(_zombie.GetOrigin());
        }

        _emitTimer -= dt;
        if (_emitTimer <= 0.0)
        {
            _emitTimer = GetEmitInterval();
            _ctx.CreateToxicSmoke(_zombie);
        }
    }

    function OnDestroy(params)
    {
        DisableUpdater();
        if (_particleSystem.IsValid())
        {
            _particleSystem.Kill();
        }
        base.OnDestroy(params);
    }

    function GetEmitInterval()
    {
        return _ctx.GetCfgProp("ToxicSmokeEmitInterval");
    }
}

class ToxicSmokeManager
{
    static UpdateInterval = 0.5;

    _smokes = null;

    _roundStartCallback = null;

    _task = null;

    constructor()
    {
        _smokes = [];

        _roundStartCallback = function(params) {
            foreach (smoke in _smokes)
            {
                smoke.Destroy();
            }
        }.bindenv(this);
        ::KtScript.RegisterGameHook("OnGameEvent_round_start_pre_entity", _roundStartCallback);

        local taskAction = function() {
            Update(UpdateInterval);
        }.bindenv(this);
        _task = ::KtScript.Task(taskAction, UpdateInterval, true, true);
        _task.Submit();
    }

    function Update(dt)
    {
        for (local i = 0; i < _smokes.len();)
        {
            local smoke = _smokes[i];
            if (!smoke.IsValid())
            {
                _smokes.remove(i);
                continue;
            }
            smoke.OnUpdate(dt);
            i++;
        }
    }

    function Add(smoke)
    {
        _smokes.append(smoke);
    }
}

class ToxicSmoke
{
    static DamageInterval = 0.5;

    _pos = null;

    _owner = null;

    _timer = null;

    _damageTimer = null;

    _particleSystem = null;

    _isValid = true;

    constructor(pos, owner)
    {
        _pos = pos;
        _owner = owner;
        _timer = GetDuration();
        _damageTimer = DamageInterval;

        local particlePos = Vector(pos.x, pos.y, pos.z - 100.0);
        _particleSystem = SpawnEntityFromTable("info_particle_system", {
            origin = particlePos,
            effect_name = "smoke_traintunnel",
            start_active = "1"
        });
    }

    function IsValid()
    {
        return _isValid;
    }

    function OnUpdate(dt)
    {
        if (!_isValid)
        {
            return;
        }

        _damageTimer -= dt;
        if (_damageTimer <= 0.0)
        {
            _damageTimer = DamageInterval;

            foreach (survivor in ::KtScript.GetSurvivorIter())
            {
                if (survivor.IsDead())
                {
                    continue;
                }
                local radius = GetRadius();
                local radiusSqr = radius * radius;
                local survivorPos = survivor.EyePosition();
                local distSqr = (_pos - survivorPos).LengthSqr();
                if (distSqr <= radiusSqr)
                {
                    local damage = GetDamage();
                    survivor.TakeDamage(damage, DirectorScript.DMG_BURN, survivor.GetHealth() + survivor.GetHealthBuffer() <= damage ? GetOwner() : null);
                    _ctx.AddToxicEffect(survivor);
                }
            }
        }

        _timer -= dt;
        if (_timer <= 0.0)
        {
            Destroy();
        }
    }

    function Destroy()
    {
        if (!_isValid)
        {
            return;
        }

        _isValid = false;
        if (_particleSystem.IsValid())
        {
            _particleSystem.Kill();
        }
    }

    function GetDuration()
    {
        return _ctx.GetCfgProp("ToxicSmokeDuration");
    }

    function GetRadius()
    {
        return _ctx.GetCfgProp("ToxicSmokeDamageRadius");
    }

    function GetDamage()
    {
        return _ctx.GetCfgProp("ToxicSmokeDamage");
    }

    function GetOwner()
    {
        if (_owner != null && !_owner.IsValid())
        {
            _owner = null;
        }
        return _owner;
    }
}

_toxicSmokeMgr <- ToxicSmokeManager();

function CreateToxicSmoke(zombie)
{
    local pos = null;
    if ("EyePosition" in zombie)
    {
        pos = zombie.EyePosition();
    }
    else
    {
        pos = zombie.GetOrigin();
    }
    local smoke = ToxicSmoke(pos, zombie);
    _toxicSmokeMgr.Add(smoke);
}

class ToxicEffectManager
{
    static UpdateInterval = 0.25;

    // table: entity player -> ToxicEffect effect
    _effects = null;

    _mapTransitionCallback = null;
    _roundStartCallback = null;

    _task = null;

    constructor()
    {
        _effects = {};

        _mapTransitionCallback = function(params) {
            ClearEffects(true);
        }.bindenv(this);
        ::KtScript.RegisterGameHook("OnGameEvent_map_transition", _mapTransitionCallback);

        _roundStartCallback = function(params) {
            ClearEffects(false);
        }.bindenv(this);
        ::KtScript.RegisterGameHook("OnGameEvent_round_start_post_nav", _roundStartCallback);

        local taskAction = function() {
            Update(UpdateInterval);
        }.bindenv(this);
        _task = ::KtScript.Task(taskAction, UpdateInterval, true, true);
        _task.Submit();
    }

    function Add(player)
    {
        if (player.IsIncapacitated() || player.IsDying() || player.IsDead())
        {
            return;
        }
        if (player in _effects)
        {
            _effects[player].Reset();
        }
        else
        {
            _effects[player] <- _ctx.ToxicEffect(player, GetEffectMinHealth(), GetEffectDuration());
        }
    }

    function Update(dt)
    {
        foreach (player, effect in _effects)
        {
            if (!effect.IsValid())
            {
                delete _effects[player];
            }
            effect.Update(dt);
        }
    }

    function ClearEffects(restoreHealth)
    {
        foreach (player, effect in _effects)
        {
            effect.Destroy(restoreHealth);
        }
        _effects.clear();
    }

    function GetEffectMinHealth()
    {
        return _ctx.GetCfgProp("ToxicEffectMinHealth");
    }

    function GetEffectDuration()
    {
        return _ctx.GetCfgProp("ToxicEffectDuration");
    }
}

class ToxicEffect
{
    static ScreenEffectInterval = 2.0;
    static ScreenEffectHoldTime = 1.0;
    static ScreenEffectFadeTime = 1.5;
    //static ScreenEffectMaxAlpha = 128;
    static ScreenEffectMaxSlantAngle = 30.0;

    _player = null;

    _duration = null;

    _minHealth = null;

    _timer = null;
    _screenEffectTimer = null;
    _healthAddTimer = null;

    _healthAddInterval = null;

    _remainingHealth = 0;
    _remainingHealthBuffer = 0;

    _isValid = true;

    constructor(player, minHealth, duration)
    {
        _player = player;
        _duration = duration;
        _minHealth = minHealth;
        Reset();
    }

    function Reset()
    {
        if (!_isValid)
        {
            return;
        }
        if (!_player.IsValid())
        {
            Destroy();
            return;
        }
        if (_player.IsIncapacitated() || _player.IsDying() || _player.IsDead())
        {
            Destroy(false);
            return;
        }

        _timer = _duration;
        _screenEffectTimer = 0.0;
        _healthAddTimer = null;
        local health = _player.GetHealth() + _remainingHealth;
        local healthBuffer = _player.GetHealthBuffer().tointeger() + _remainingHealthBuffer;
        local healthToBuffer = GetCutHealthToBuffer();

        if (health >= healthToBuffer)
        {
            health -= healthToBuffer;
            healthBuffer += healthToBuffer;
        }
        else
        {
            healthBuffer += health;
            health = 0;
        }

        if (health < 1)
        {
            health = 1;
        }

        local totalHealth = health + healthBuffer;
        if (totalHealth > _minHealth)
        {
            local cutTotalHealth = totalHealth - _minHealth;
            if (cutTotalHealth <= healthBuffer)
            {
                _remainingHealthBuffer = cutTotalHealth;
                healthBuffer -= cutTotalHealth;
            }
            else
            {
                _remainingHealthBuffer = healthBuffer;
                local cutHealth = cutTotalHealth - healthBuffer;
                healthBuffer = 0;
                _remainingHealth = cutHealth;
                health -= cutHealth;
            }
            _healthAddInterval = _duration / cutTotalHealth;
            _healthAddTimer = _healthAddInterval;
        }

        _player.SetHealth(health);
        _player.SetHealthBuffer(healthBuffer);
    }

    function IsValid()
    {
        return _isValid;
    }

    function Destroy(restoreHealth = true)
    {
        if (!_isValid)
        {
            return;
        }
        _isValid = false;
        if (_player.IsValid())
        {
            if (restoreHealth)
            {
                if (_remainingHealth > 0)
                {
                    _ctx.AddPlayerHealth(_player, _remainingHealth);
                }
                if (_remainingHealthBuffer > 0)
                {
                    _ctx.AddPlayerHealthBuffer(_player, _remainingHealthBuffer);
                }
            }

            local eyeAngles = _player.EyeAngles();
            eyeAngles.z = 0.0;
            _player.SnapEyeAngles(eyeAngles);
        }
    }

    function Update(dt)
    {
        if (!_isValid)
        {
            return;
        }
        if (!_player.IsValid())
        {
            Destroy();
            return;
        }
        if (_player.IsIncapacitated() || _player.IsDying() || _player.IsDead())
        {
            Destroy(false);
            return;
        }

        if (_healthAddTimer != null)
        {
            local healthIncrement = 0;
            _healthAddTimer -= dt;
            while (_healthAddTimer <= 0.0)
            {
                healthIncrement++;
                _healthAddTimer = _healthAddInterval + _healthAddTimer;
            }
            if (healthIncrement > 0)
            {
                if (_remainingHealth >= healthIncrement)
                {
                    _remainingHealth -= healthIncrement;
                    _ctx.AddPlayerHealth(_player, healthIncrement);
                }
                else
                {
                    if (_remainingHealth > 0)
                    {
                        _ctx.AddPlayerHealth(_player, _remainingHealth);
                        healthIncrement -= _remainingHealth;
                        _remainingHealth = 0;
                    }
                    if (healthIncrement > 0)
                    {
                        if (healthIncrement < _remainingHealthBuffer)
                        {
                            _remainingHealthBuffer -= healthIncrement;
                            _ctx.AddPlayerHealthBuffer(_player, healthIncrement);
                        }
                        else
                        {
                            _ctx.AddPlayerHealthBuffer(_player, _remainingHealthBuffer);
                            _healthAddTimer = null;
                        }
                    }
                }
            }
        }

        _screenEffectTimer -= dt;
        if (_screenEffectTimer <= 0.0)
        {
            _screenEffectTimer = ScreenEffectInterval;

            local ratio = _timer / _duration;

            local alpha = GetScreenEffectMaxAlpha() * ratio;
            alpha = alpha.tointeger();
            ScreenFade(_player, RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255), alpha, ScreenEffectFadeTime, ScreenEffectHoldTime, 1);

            local eyeAngles = _player.EyeAngles();
            local slantAngle = RandomFloat(-ScreenEffectMaxSlantAngle, ScreenEffectMaxSlantAngle) * ratio;
            eyeAngles.z = slantAngle;
            _player.SnapEyeAngles(eyeAngles);
        }

        _timer -= dt;
        if (_timer <= 0.0)
        {
            Destroy();
        }
    }

    function GetScreenEffectMaxAlpha()
    {
        return _ctx.GetCfgProp("ToxicEffectScreenEffectMaxAlpha");
    }

    function GetCutHealthToBuffer()
    {
        return _ctx.GetCfgProp("ToxicEffectCutHealthToBuffer");
    }
}

_toxicEffectMgr <- ToxicEffectManager();

function AddToxicEffect(player)
{
    _toxicEffectMgr.Add(player);
}