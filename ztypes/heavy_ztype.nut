local _ctx = this;
const HeavyZtypeColor = 0x00d7ff;

class HeavyZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.HeavyZtypeInstance;
    }

    function GetName()
    {
        return "heavy";
    }

    function GetColor()
    {
        return HeavyZtypeColor;
    }
}

class HeavyZtypeInstance extends ZtypeInstance
{
    _isCharger = null;

    constructor(zombie)
    {
        base.constructor(zombie);

        _isCharger = false;
        if ("GetZombieType" in zombie)
        {
            if (zombie.GetZombieType() == DirectorScript.ZOMBIE_CHARGER)
            {
                _isCharger = true;
            }
        }

        local health = zombie.GetHealth() * GetHealthMultiplier();
        health = health.tointeger();
        zombie.SetMaxHealth(health);
        zombie.SetHealth(health);
    }

    function GetHealthMultiplier()
    {
        return _ctx.GetCfgProp(_isCharger ? "HeavyHealthMultiplierCharger" : "HeavyHealthMultiplier");
    }
}