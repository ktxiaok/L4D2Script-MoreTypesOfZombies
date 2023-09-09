const SpeedZtypeColor = 0xffff00;

local _ctx = this;

SpeedZtypeShadowConfig <- {
    shadowCount = 8,
    stepTime = 0.1,
    fadeSpeed = 0.8,
    initialAlpha = 0.8,
    shadowSpeedThreshold = 50.0,
    shadowRandomRange = 30.0
};

class SpeedZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.SpeedZtypeInstance;
    }

    function GetName()
    {
        return "speed";
    }

    // function GetColor()
    // {
    //     return SpeedZtypeColor;
    // }

    function IsHurtListeningEnabled()
    {
        return true;
    }
}

class SpeedZtypeInstance extends ZtypeInstance
{
    static UpdateDeltaTime = 0.1;
    static HurtStateTime = 0.7;

    _task = null;

    _isCharger = false;

    _hurtTimer = 0.0;
    _isHurting = false;

    constructor(zombie)
    {
        base.constructor(zombie);
        local basicType = _ctx.GetBasicZombieType(zombie);
        if (basicType == DirectorScript.ZOMBIE_CHARGER)
        {
            _isCharger = true;
        }
        SetSpeed0();
        EnableColor();
        InitShadow();
        InitTask();
    }

    function InitShadow()
    {
        _ctx.CreateEntityShadow(_zombie, _ctx.SpeedZtypeShadowConfig);
    }

    function DestroyShadow()
    {
        _ctx.DestroyEntityShadow(_zombie);
    }

    function InitTask()
    {
        local action = function() {
            Update(UpdateDeltaTime);
        }.bindenv(this);
        _task = ::KtScript.Task(action, UpdateDeltaTime, true);
        _task.Submit();
    }

    function DestroyTask()
    {
        if (_task == null)
        {
            return;
        }
        _task.Kill();
        _task = null;
    }

    function OnHurt(params)
    {
        _isHurting = true;
        _hurtTimer = 0.0;
        SetSpeed1();
        DisableColor();
        EnableShadow();
    }

    function Update(dt)
    {
        if (!_zombie.IsValid())
        {
            return;
        }
        if (_isHurting)
        {
            local vel = _zombie.GetVelocity();
            local planeVel = _ctx.VecProjectToPlane(vel, Vector(0.0, 0.0, 1.0));
            local lateralVel = Vector(planeVel.y, -planeVel.x, 0.0);
            local velSize = lateralVel.Length();
            if (velSize > 1.0)
            {
                local accelFactor = _ctx.GetCfgProp("SpeedLateralAccelFactor");
                local lateralDir = lateralVel * (1.0 / velSize);
                local lateralAccel = lateralDir * (velSize * RandomFloat(-accelFactor, accelFactor));
                local newVel = vel + lateralAccel * dt;
                _zombie.SetVelocity(newVel);
            }

            _hurtTimer += dt;
            if (_hurtTimer >= HurtStateTime)
            {
                _isHurting = false;
                SetSpeed0();
                EnableColor();
                DisableShadow();
            }
        }
    }

    function OnDestroy(params)
    {
        DestroyTask();
        DestroyShadow();
        base.OnDestroy(params);
    }

    function EnableShadow()
    {
        _ctx.SetEntityShadowEnabled(_zombie, true);
    }

    function DisableShadow()
    {
        _ctx.SetEntityShadowEnabled(_zombie, false);
    }

    function SetSpeed0()
    {
        _ctx.SetSpeedFactor(_zombie, GetSpeedFactor0());
    }

    function SetSpeed1()
    {
        _ctx.SetSpeedFactor(_zombie, GetSpeedFactor1());
    }

    function EnableColor()
    {
        _ctx.SetZombieColor(_zombie, SpeedZtypeColor);
        _ctx.SetZombieGlowFactor(_zombie, 0.3);
    }

    function DisableColor()
    {
        _ctx.SetZombieColor(_zombie, 0xffffff);
        _ctx.SetZombieGlowFactor(_zombie, 0.0);
    }

    function GetSpeedFactor0()
    {
        return _ctx.GetCfgProp(_isCharger ? "SpeedFactor0Charger" : "SpeedFactor0");
    }

    function GetSpeedFactor1()
    {
        return _ctx.GetCfgProp(_isCharger ? "SpeedFactor1Charger" : "SpeedFactor1");
    }
}