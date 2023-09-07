local _ctx = this;
const ShieldZtypeColor = 0x0f368a;
const ShieldUpdateInterval = 0.1;
const ShieldMinGlowSpeed = 1.0;
const ShieldMaxGlowSpeed = 8.0;

const ShieldBreakSoundName = "physics\\metal\\chainsaw_impact1.wav";
PrecacheSound(ShieldBreakSoundName);

class ShieldZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.ShieldZtypeInstance;
    }

    function GetName()
    {
        return "shield";
    }

    function GetColor()
    {
        return ShieldZtypeColor;
    }
}

class ShieldZtypeInstance extends ZtypeInstance
{
    _originalHealth = null;
    _shieldMaxHealth = null;

    _healthBuffer = 0.0;

    _glowTimer = 0.0;

    //_isShieldBroken = false;

    _shieldTask = null;

    constructor(zombie)
    {
        base.constructor(zombie);
        InitShieldHealth();
        CreateTask();
    }

    function UpdateShield(dt)
    {
        if (!_zombie.IsValid() || _zombie.GetHealth() <= 0)
        {
            BreakShield();
            return;
        }
        local recoverSpeed = _ctx.GetCfgProp("ShieldRecoverSpeed");
        _healthBuffer += recoverSpeed * dt;
        ApplyHealth();
        local shieldHealth = GetShieldHealth();
        if (shieldHealth <= 0.0)
        {
            BreakShield();
        }
        else
        {
            UpdateShieldGlow(shieldHealth, dt);
        }
    }

    function UpdateShieldGlow(shieldHealth, dt)
    {
        local healthRatio = shieldHealth.tofloat() / _shieldMaxHealth;
        local healthRatioInversed = 1 - healthRatio;
        local glowSpeed = ShieldMinGlowSpeed + healthRatioInversed * (ShieldMaxGlowSpeed - ShieldMinGlowSpeed);
        _glowTimer += glowSpeed * dt;
        if (_glowTimer > 100.0)
        {
            _glowTimer = 0.0;
        }
        local minGlowFactor = healthRatio;
        local glowFactor = fabs(sin(PI * _glowTimer));
        if (glowFactor < minGlowFactor)
        {
            glowFactor = minGlowFactor;
        }
        _ctx.SetZombieGlowFactor(_zombie, glowFactor);
    }

    function BreakShield()
    {
        if (_shieldTask == null)
        {
            return;
        }
        local isZombieValid = _zombie.IsValid();
        if (isZombieValid)
        {
            PlayShieldBreakSound();
            SetBrokenStateColor();
        }
        _shieldTask.Kill();
        _shieldTask = null;
    }

    function SetBrokenStateColor()
    {
        _ctx.SetZombieColor(_zombie, 0xffffff);
        _ctx.SetZombieGlowFactor(_zombie, 0.0);
    }

    function InitShieldHealth()
    {
        local shieldMultiplier = _ctx.GetCfgProp("ShieldHealthMultiplier");
        local health = _zombie.GetHealth();
        _originalHealth = health;
        _shieldMaxHealth = health * shieldMultiplier;
        local newHealth = health + _shieldMaxHealth;
        _zombie.SetMaxHealth(newHealth);
        _zombie.SetHealth(newHealth);
    }

    function GetShieldHealth()
    {
        return _zombie.GetHealth() - _originalHealth;
    }

    function CreateTask()
    {
        local dt = ShieldUpdateInterval;
        local action = function() {
            UpdateShield(dt);
        }.bindenv(this);
        _shieldTask = ::KtScript.Task(action, dt, true);
        _shieldTask.Submit();
    }

    function ApplyHealth()
    {
        if (_healthBuffer > 1.0)
        {
            local healthInt = _healthBuffer.tointeger();
            _healthBuffer -= healthInt;
            local health = _zombie.GetHealth();
            local maxHealth = _zombie.GetMaxHealth();
            health += healthInt;
            if (health > maxHealth)
            {
                health = maxHealth;
            }
            _zombie.SetHealth(health);
        }
    }

    function PlayShieldBreakSound()
    {
        EmitAmbientSoundOn(ShieldBreakSoundName, 1.0, 130, 100, _zombie);
    }

    function OnDestroy(params)
    {
        BreakShield();
        base.OnDestroy(params);
    }
}