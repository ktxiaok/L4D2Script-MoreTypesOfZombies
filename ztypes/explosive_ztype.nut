local _ctx = this;
const ExplosiveZtypeColor = 0x0000ff;

class ExplosiveZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.ExplosiveZtypeInstance;
    }

    function GetName()
    {
        return "explosive";
    }

    function GetColor()
    {
        return ExplosiveZtypeColor;
    }

    function IsTankRockListeningEnabled()
    {
        return true;
    }
}

class ExplosiveZtypeInstance extends ZtypeInstance
{
    constructor(zombie)
    {
        base.constructor(zombie);
    }

    function OnDestroy(params)
    {
        if (params.isEntValid)
        {
            _ctx.Explode(_ctx.GetCfgProp("ExplosionMagnitude"), _ctx.GetCfgProp("ExplosionPhysMagnitude"), _zombie.GetOrigin(), _zombie);
        }
        base.OnDestroy(params);
    }

    function OnTankRockDestroy(params)
    {
        local pos = params.pos;
        if (pos == null)
        {
            return;
        }
        local physMagnitude = _ctx.GetCfgProp("ExplosionPhysMagnitudeTankRock");
        // ::KtScript.Task(
        //     function() {
        //         _ctx.Explode(0, physMagnitude, pos);
        //     },
        //     0.0
        // ).Submit();
        _ctx.Explode(0, physMagnitude, pos);
    }
}