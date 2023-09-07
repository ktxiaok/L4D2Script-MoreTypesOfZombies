local _ctx = this;
const ExtraHeavyZtypeColor = 0x1299ff;

class ExtraHeavyZtype extends HeavyZtype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.ExtraHeavyZtypeInstance;
    }

    function GetName()
    {
        return "extraheavy";
    }

    function GetColor()
    {
        return ExtraHeavyZtypeColor;
    }
}

class ExtraHeavyZtypeInstance extends HeavyZtypeInstance
{
    constructor(zombie)
    {
        base.constructor(zombie);
    }

    function GetHealthMultiplier()
    {
        return _ctx.GetCfgProp(_isCharger ? "ExtraHeavyHealthMultiplierCharger" : "ExtraHeavyHealthMultiplier");
    }
}