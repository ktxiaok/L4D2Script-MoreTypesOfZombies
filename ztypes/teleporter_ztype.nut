local _ctx = this;

const TeleporterZtypeColor = 0xe16941;

TeleporterZtypeShadowConfig <- {
    shadowCount = 5,
    stepTime = 0.1,
    fadeSpeed = 1.0,
    initialAlpha = 0.5,
    shadowSpeedThreshold = 0.0,
    shadowRandomRange = 25.0
};

class TeleporterZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetName()
    {
        return "teleporter";
    }

    function GetInstanceClass()
    {
        return _ctx.TeleporterZtypeInstance;
    }

    function GetColor()
    {
        return TeleporterZtypeColor;
    }

    function IsHurtListeningEnabled()
    {
        return true;
    }
}

class TeleporterZtypeInstance extends ZtypeInstance
{
    _tpHealth = null;
    _hurtBuffer = 0;

    constructor(zombie)
    {
        base.constructor(zombie);

        local health = zombie.GetHealth();
        _tpHealth = (health * GetTpHealthRatio()).tointeger();

        _ctx.CreateEntityShadow(zombie, _ctx.TeleporterZtypeShadowConfig);
        _ctx.SetEntityShadowEnabled(zombie, true);
    }

    function OnDestroy(params)
    {
        _ctx.DestroyEntityShadow(_zombie);
        base.OnDestroy(params);
    }

    function OnHurt(params)
    {
        if (_zombie.GetHealth() <= 0 || _ctx.GetDominatedPlayer(_zombie) != null)
        {
            return;
        }
        local damage = params.dmg_health;
        _hurtBuffer += damage;
        if (_hurtBuffer >= _tpHealth)
        {
            _hurtBuffer = 0;
            RandomTeleport();
        }
    }

    function RandomTeleport()
    {
        local dst = GetRandomPoint(_zombie.GetOrigin(), GetTpRadius());
        if (dst == null)
        {
            return;
        }
        PlayTeleportSound(_zombie.GetOrigin());
        _zombie.SetOrigin(dst);
    }

    function PlayTeleportSound(pos)
    {
        _ctx.EmitAmbientSoundOnPos(TeleportSoundName, 1.0, 130, 230, pos);
    }

    function GetTpHealthRatio()
    {
        return _ctx.GetCfgProp("TeleporterTpHealthRatio");
    }

    function GetTpRadius()
    {
        return _ctx.GetCfgProp("TeleporterTpRadius");
    }

    function GetRandomPoint(origin, radius)
    {
        local navTable = {};
        NavMesh.GetNavAreasInRadius(origin, radius, navTable);
        local navAreas = [];
        foreach (key, navArea in navTable)
        {
            navAreas.append(navArea);
        }
        local count = navAreas.len();
        if (count == 0)
        {
            return null;
        }
        local index = RandomInt(0, count - 1);
        return navAreas[index].FindRandomSpot();
    }
}