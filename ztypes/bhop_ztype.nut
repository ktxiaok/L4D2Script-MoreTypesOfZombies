local _ctx = this;

const BhopZtypeColor = 0xebce87;

class BhopZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.BhopZtypeInstance;
    }

    function GetName()
    {
        return "bhop";
    }

    function GetColor()
    {
        return BhopZtypeColor;
    }
}

class BhopZtypeInstance extends ZtypeInstance
{
    static UpdateInterval = 0.2;
    static BhopMinSpeedAllowed = 120;
    static BhopMinIntervalTime = 0.5;
    static BhopPauseCycleTime = 6.0;
    static BhopPauseTime = 2.0;

    _nextBhopTimer = -1.0;
    _bhopPauseTimer = 0.0;
    _isBhopPaused = false;

    _accelCount = 0;
    _accel = 0.0;
    _lateralDir = 1;

    constructor(zombie)
    {
        base.constructor(zombie);
        EnableUpdater(UpdateInterval);
    }

    function OnUpdate(dt)
    {
        _bhopPauseTimer -= dt;
        if (_isBhopPaused)
        {
            if (_bhopPauseTimer <= 0.0)
            {
                _isBhopPaused = false;
                _bhopPauseTimer = BhopPauseCycleTime;
            }
        }
        else
        {
            if (_bhopPauseTimer <= 0.0)
            {
                _isBhopPaused = true;
                _bhopPauseTimer = BhopPauseTime;
            }
        }

        if (_nextBhopTimer > 0.0)
        {
            _nextBhopTimer -= dt;
        }

        if (ShouldAllowBhop())
        {
            local vel = _zombie.GetVelocity();
            local velLenSqr = vel.LengthSqr();
            if (velLenSqr >= BhopMinSpeedAllowed * BhopMinSpeedAllowed)
            {
                local eyeDir = ("EyeAngles" in _zombie) ? _zombie.EyeAngles().Forward() : _zombie.GetForwardVector();
                local newVel = Bhop(vel, eyeDir);
                _zombie.SetVelocity(newVel);
                _nextBhopTimer = BhopMinIntervalTime;
            }
        }
    }

    function ShouldAllowBhop()
    {
        return !_isBhopPaused && _nextBhopTimer <= 0.0 && _ctx.IsPlayerGrounded(_zombie);
    }

    function Bhop(vel, eyeDir)
    {
        local totalAccel = Vector(0.0, 0.0, GetJumpAccel());
        local planeVel = _ctx.VecProjectToPlane(vel, Vector(0.0, 0.0, 1.0));
        local planeVelLenSqr = planeVel.LengthSqr();
        if (planeVelLenSqr > 1.0)
        {
            local planeVelLen = sqrt(planeVelLenSqr);
            local planeVelNorm = planeVel * (1.0 / planeVelLen);
            local lateralVelNorm = Vector(planeVelNorm.y, -planeVelNorm.x, 0.0);
            _lateralDir *= -1;
            totalAccel += lateralVelNorm * (_lateralDir * GetLateralAccel());
        }

        local maxCount = GetAccelMaxCount();
        _accelCount++;
        if (_accelCount > maxCount)
        {
            _accelCount = 1;
        }

        if (_accelCount == 1)
        {
            _accel = GetInitialAccel();
        }
        else
        {
            _accel += GetAccelIncrement();
        }

        totalAccel += eyeDir * _accel;
        return vel + totalAccel;
    }

    function GetJumpAccel()
    {
        return _ctx.GetCfgProp("BhopJumpAccel");
    }

    function GetLateralAccel()
    {
        return _ctx.GetCfgProp("BhopLateralAccel");
    }

    function GetInitialAccel()
    {
        return _ctx.GetCfgProp("BhopInitialAccel");
    }

    function GetAccelIncrement()
    {
        return _ctx.GetCfgProp("BhopAccelIncrement");
    }

    function GetAccelMaxCount()
    {
        return _ctx.GetCfgProp("BhopAccelMaxCount");
    }
}