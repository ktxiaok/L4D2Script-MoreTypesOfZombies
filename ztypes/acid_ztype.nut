local _ctx = this;
const AcidZtypeColor = 0x00ff00;

class AcidZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.AcidZtypeInstance;
    }

    function GetName()
    {
        return "acid";
    }

    function GetColor()
    {
        return AcidZtypeColor;
    }

    function IsAbilityListeningEnabled()
    {
        return true;
    }

    function IsTankRockListeningEnabled()
    {
        return true;
    }
}

class AcidZtypeInstance extends ZtypeInstance
{
    constructor(zombie)
    {
        base.constructor(zombie);
    }

    function SpawnSpit()
    {
        local pos = _zombie.GetOrigin();
        ::KtScript.Task(
            function() {
                DropSpit(pos);
            },
            0.5
        ).Submit();
    }

    function OnTankRockDestroy(params)
    {
        local pos = params.pos;
        if (pos == null)
        {
            return;
        }
        DropSpit(pos);
    }

    function OnAbilityHunter()
    {
        SpawnSpit();
    }

    function OnAbilitySmoker()
    {
        SpawnSpit();
    }

    function OnAbilityBoomer()
    {
        SpawnSpit();
    }

    function OnAbilitySpitter()
    {
        SpawnSpit();
    }

    function OnAbilityCharger()
    {
        SpawnSpit();
    }

    function OnDestroy(params)
    {
        if (params.isEntValid)
        {
            DropSpit(_zombie.GetOrigin());
        }
        base.OnDestroy(params);
    }
}

