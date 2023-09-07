local _ctx = this;
local _rootctx = _rootctx;

class Shadow
{
    _propEnt = null;

    _targetName = null;

    _alpha = null;

    constructor(srcEnt)
    {
        _targetName = ::KtScript.CreateUniqueTargetName("shadow");
        _propEnt = SpawnEntityFromTable("prop_dynamic", {
            targetname = _targetName
            model = srcEnt.GetModelName(),
            solid = 0,
            rendermode = 1,
            renderamt = 0
        });
        _alpha = 0.0;
    }

    function GetPropEntity()
    {
        return _propEnt;
    }

    function GetAlpha()
    {
        return _alpha;
    }

    function SetAlpha(alpha)
    {
        _alpha = alpha;
        UpdateAmt();
    }

    function Sync(srcEnt, posRandomRange)
    {
        if ("GetSequence" in srcEnt)
        {
            _propEnt.SetSequence(srcEnt.GetSequence());
        }
        local randomPosOffset = _rootctx.Vec2RandomUnit() * posRandomRange;
        randomPosOffset = Vector(randomPosOffset.x, randomPosOffset.y, 0.0);
        _propEnt.SetOrigin(srcEnt.GetOrigin() + randomPosOffset);
        _propEnt.SetAngles(srcEnt.GetAngles());
    }

    function Destroy()
    {
        _propEnt.Kill();
    }

    function UpdateAmt()
    {
        local a = 255.0 * _alpha;
        a = a.tointeger();
        _propEnt.__KeyValueFromInt("renderamt", a);
    }
}

class ShadowController
{
    _ent = null;

    _stepTime = null;
    _fadeSpeed = null;
    _initialAlpha = null;
    _shadowSpeedThresholdSqr = null;
    _shadowRandomRange = null;

    _stepTimer = 0.0;

    _shadows = null;
    _shadowCount = null;
    _shadowIdx = 0;

    _isEnabled = false;

    /**
     * infoTable:
     * {
     *      int shadowCount
     *      float stepTime
     *      float fadeSpeed
     *      float initialAlpha
     *      float shadowSpeedThreshold
     *      float shadowRandomRange
     * }
     */
    constructor(ent, infoTable)
    {
        _ent = ent;
        _stepTime = infoTable.stepTime.tofloat();
        _stepTimer = _stepTime + 1.0;
        _fadeSpeed = infoTable.fadeSpeed.tofloat();
        _initialAlpha = infoTable.initialAlpha.tofloat();
        _shadowSpeedThresholdSqr = infoTable.shadowSpeedThreshold.tofloat();
        _shadowSpeedThresholdSqr *= _shadowSpeedThresholdSqr;
        _shadowRandomRange = infoTable.shadowRandomRange;
        _shadowCount = infoTable.shadowCount.tointeger();
        InitShadows(_shadowCount);
    }

    function IsValid()
    {
        return _ent.IsValid();
    }

    function IsEnabled()
    {
        return _isEnabled;
    }

    function SetEnabled(isEnabled)
    {
        if (isEnabled == _isEnabled)
        {
            return;
        }
        _isEnabled = isEnabled;
        if (isEnabled)
        {
            _stepTimer = 0.0;
        }
        else
        {

        }
    }

    function InitShadows(count)
    {
        _shadows = array(count);
        for (local i = 0; i < count; i++)
        {
            _shadows[i] = _ctx.Shadow(_ent);
        }
    }

    function Destroy()
    {
        foreach (shadow in _shadows)
        {
            shadow.Destroy();
        }
    }

    function Update(dt)
    {
        if (!_ent.IsValid())
        {
            printl("[MTOZ] Invalid entity in ShadowController!");
        }

        if (_isEnabled)
        {
            _stepTimer += dt;
            if (_stepTimer >= _stepTime)
            {
                _stepTimer = 0.0;

                local vel = _ent.GetVelocity();
                local speedSqr = vel.LengthSqr();
                if (speedSqr >= _shadowSpeedThresholdSqr)
                {
                    local shadow = _shadows[_shadowIdx];
                    shadow.Sync(_ent, _shadowRandomRange);
                    shadow.SetAlpha(_initialAlpha);
                    NextShadowIndex();
                }
            }
        }

        foreach (shadow in _shadows)
        {
            local alpha = shadow.GetAlpha();
            if (alpha > 0.00001)
            {
                alpha -= _fadeSpeed * dt;
                if (alpha < 0.0)
                {
                    alpha = 0.0;
                }
                shadow.SetAlpha(alpha);
            }
        }
    }

    function NextShadowIndex()
    {
        _shadowIdx++;
        if (_shadowIdx >= _shadowCount)
        {
            _shadowIdx = 0;
        }
    }
}

class ShadowMgr
{
    static UpdateDeltaTime = 0.05;

    // table(entity ent -> ShadowController controller)
    _controllers = null;

    _task = null;

    _tempInvalidControllers = null;

    constructor()
    {
        _controllers = {};
        _tempInvalidControllers = [];
        InitTask();
    }

    function Destroy()
    {
        DestroyTask();
        foreach (ent, controller in _controllers)
        {
            controller.Destroy();
        }
    }

    function CreateShadow(ent, infoTable)
    {
        if (ent in _controllers)
        {
            return;
        }
        _controllers[ent] <- _ctx.ShadowController(ent, infoTable);
    }

    function DestroyShadow(ent)
    {
        if (!(ent in _controllers))
        {
            return;
        }
        local controller = _controllers[ent];
        controller.Destroy();
        delete _controllers[ent];
    }

    function IsShadowEnabled(ent)
    {
        if (!(ent in _controllers))
        {
            return false;
        }
        local controller = _controllers[ent];
        return controller.IsEnabled();
    }

    function SetShadowEnabled(ent, isEnabled)
    {
        if (!(ent in _controllers))
        {
            return;
        }
        local controller = _controllers[ent];
        controller.SetEnabled(isEnabled);
    }

    function InitTask()
    {
        local dt = UpdateDeltaTime;
        local action = function() {
            Update(dt);
        }.bindenv(this);
        _task = ::KtScript.Task(action, dt, true, true);
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

    function Update(dt)
    {
        foreach (ent, controller in _controllers)
        {
            if (!controller.IsValid())
            {
                _tempInvalidControllers.append(controller);
                continue;
            }
            controller.Update(dt);
        }

        foreach (controller in _tempInvalidControllers)
        {
            controller.Destroy();
            delete _controllers[controller.GetEntity()];
        }
        _tempInvalidControllers.clear();
    }
}

_mgr <- null;

function Init()
{
    _mgr = ShadowMgr();
}

function CreateEntityShadow(ent, infoTable)
{
    _mgr.CreateShadow(ent, infoTable);
}

function DestroyEntityShadow(ent)
{
    _mgr.DestroyShadow(ent);
}

function IsEntityShadowEnabled(ent)
{
    return _mgr.IsShadowEnabled(ent);
}

function SetEntityShadowEnabled(ent, isEnabled)
{
    _mgr.SetShadowEnabled(ent, isEnabled);
}

function GetPublicMemberNames()
{
    return [
        "CreateEntityShadow",
        "DestroyEntityShadow",
        "IsEntityShadowEnabled",
        "SetEntityShadowEnabled"
    ];
}

