local _ctx = this;
local _rootctx = _rootctx;

class ZombieColorControl
{
    _zombie = null;
    _alpha = 255;
    _color = 0;
    _glowFactor = 1.0;

    _isFlashed = false;
    _flashTimer = 0.0;
    _flashTask = null;

    constructor(zombie)
    {
        _zombie = zombie;

        _zombie.__KeyValueFromInt("rendermode", 1);
        NetProps.SetPropInt(_zombie, "m_Glow.m_iGlowType", 2);
    }

    function UpdateAmt()
    {
        _zombie.__KeyValueFromInt("renderamt", _alpha);
    }

    function UpdateGlow()
    {
        local scaledR = 1;
        local scaledG = 1;
        local scaledB = 1;

        if (!_isFlashed)
        {
            local colors = _rootctx.Color24ToVec(_color);
            local scale = _alpha / 255.0 * _glowFactor;
            scaledR = colors.r * scale;
            scaledG = colors.g * scale;
            scaledB = colors.b * scale;
            scaledR = scaledR.tointeger();
            if (scaledR == 0) scaledR = 1;
            scaledG = scaledG.tointeger();
            if (scaledG == 0) scaledG = 1;
            scaledB = scaledB.tointeger();
            if (scaledB == 0) scaledB = 1;
        }

        NetProps.SetPropInt(_zombie, "m_Glow.m_glowColorOverride", _rootctx.GetColor24(scaledR, scaledG, scaledB));
    }

    function UpdateColor()
    {
        local colorVec = _rootctx.Color24ToVec(_color);
        local colorStr = _rootctx.ColorVecToString(colorVec);
        _zombie.__KeyValueFromString("rendercolor", colorStr);
    }

    function SetColor(color)
    {
        _color = color;
        UpdateGlow();
        UpdateColor();
        UpdateAmt();
    }

    function SetAlpha(alpha)
    {
        _alpha = alpha;
        UpdateGlow();
        UpdateAmt();
    }

    function SetGlowFactor(factor)
    {
        _glowFactor = factor;
        UpdateGlow();
    }

    //Temporarily disable the glowing effect.
    function Flash(time)
    {
        if (_isFlashed)
        {
            if (time > _flashTimer)
            {
                _flashTimer = time;
            }
        }
        else
        {
            _isFlashed = true;
            UpdateGlow();
            _flashTimer = time;
            local dt = 0.2;
            _flashTask = ::KtScript.Task(
                function() {
                    UpdateOnFlash(dt);
                }.bindenv(this),
                dt,
                true
            );
            _flashTask.Submit();
        }
    }

    function UpdateOnFlash(dt)
    {
        if (!_zombie.IsValid())
        {
            return;
        }

        _flashTimer -= dt;
        if (_flashTimer <= 0.0)
        {
            _isFlashed = false;
            UpdateGlow();
            _flashTask.Kill();
            _flashTask = null;
        }
    }

    function OnDestroy(params)
    {
        if (_zombie.IsValid())
        {
            NetProps.SetPropInt(_zombie, "m_Glow.m_iGlowType", 0);
            NetProps.SetPropInt(_zombie, "m_Glow.m_glowColorOverride", 0);
        }

        if (_flashTask != null)
        {
            _flashTask.Kill();
            _flashTask = null;
        }
    }
}

_mappingMgr <- _rootctx.ZombieMappingMgr(ZombieColorControl);

function SetZombieColor(zombie, color)
{
    _mappingMgr.Get(zombie).SetColor(color);
}

function SetZombieAlpha(zombie, alpha)
{
    _mappingMgr.Get(zombie).SetAlpha(alpha);
}

function SetZombieGlowFactor(zombie, factor)
{
    _mappingMgr.Get(zombie).SetGlowFactor(factor);
}

function TempDisableZombieGlow(zombie, time)
{
    _mappingMgr.Get(zombie).Flash(time);
}

function IsZombieColored(zombie)
{
    return _mappingMgr.TryGet(zombie) != null;
}

function Init()
{

}

function GetPublicMemberNames()
{
    return [
        "SetZombieColor",
        "SetZombieAlpha",
        "SetZombieGlowFactor",
        "TempDisableZombieGlow",
        "IsZombieColored"
    ];
}