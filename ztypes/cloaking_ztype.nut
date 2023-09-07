local _ctx = this;

class CloakingZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.CloakingZtypeInstance;
    }

    function GetName()
    {
        return "cloaking";
    }
}

class CloakingZtypeInstance extends ZtypeInstance
{
    static StageStartup = 0;
    static StageHold = 1;
    static StageExit = 2;
    static DeltaTime = 0.05;

    _task = null;
    _timer = 0.0;
    _stage = 0;

    constructor(zombie)
    {
        base.constructor(zombie);
        local instance = this;
        local dt = DeltaTime;
        _task = ::KtScript.Task(
            function() {
                instance.Update(dt);
            },
            dt,
            true
        );
        _task.Submit();
    }

    function Update(dt)
    {
        if (!_zombie.IsValid())
        {
            return;
        }

        local alpha = null;
        _timer += dt;
        if (_stage == StageStartup)
        {
            local startupTime = _ctx.GetCfgProp("CloakingStartupTime");
            if (_timer >= startupTime)
            {
                alpha = 0;
                _timer = 0.0;
                _stage = StageHold;
            }
            else
            {
                alpha = (1.0 - _timer / startupTime) * 255.0;
                alpha = alpha.tointeger();
            }
        }
        else if (_stage == StageHold)
        {
            local holdTime = _ctx.GetCfgProp("CloakingTime");
            alpha = 0;
            if (_timer >= holdTime)
            {
                _timer = 0.0;
                _stage = StageExit;
            }
        }
        else
        {
            local exitTime = _ctx.GetCfgProp("CloakingExitTime");
            if (_timer >= exitTime)
            {
                alpha = 255;
                _timer = 0.0;
                _stage = StageStartup;
            }
            else
            {
                alpha = (_timer / exitTime) * 255.0;
                alpha = alpha.tointeger();
            }
        }

        _ctx.SetZombieAlpha(_zombie, alpha);
    }

    function OnDestroy(params)
    {
        _task.Kill();
        base.OnDestroy(params);
    }
}