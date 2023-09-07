local _ctx = this;

const RockFindDelay = 1.5;
const NetPropNameThrower = "m_hThrower";
const RockUpdateInterval = 0.03;

class TankRockProxy
{
    _rock = null;
    _thrower = null;
    _pos = null;

    constructor(rock)
    {
        _rock = rock;
        _thrower = _ctx.GetTankRockThrower(rock);
        Record();
    }

    function Record()
    {
        if (!_rock.IsValid())
        {
            return;
        }

        _pos = _rock.GetOrigin();
    }

    function GetRock()
    {
        return _rock;
    }

    function GetThrower()
    {
        return _thrower;
    }

    function GetPosition()
    {
        return _pos;
    }
}

_zombieMapping <- null;

//entity rock -> TankRockProxy rockProxy
_rocks <- {};

_rockSpawnCallbacks <- [];
_rockDestroyCallbacks <- [];

_eventCallbacks <- {
    OnGameEvent_ability_use = function(params) {
        if (params.ability == "ability_throw")
        {
            ::KtScript.Task(
                function() {
                    local rock = null;
                    while (true)
                    {
                        rock = Entities.FindByClassname(rock, "tank_rock");
                        if (rock == null)
                        {
                            break;
                        }
                        TryRegisterRock(rock);
                    }
                }.bindenv(_ctx),
                RockFindDelay
            ).Submit();
        }
    }.bindenv(_ctx),

    OnGameEvent_round_start_pre_entity = function(params) {
        OnRoundStartPreEntity();
    }.bindenv(_ctx),

    OnGameEvent_round_start_post_nav = function(params) {
        OnRoundStartPostNav();
    }.bindenv(_ctx)
}

function TryRegisterRock(rock)
{
    if (rock in _rocks)
    {
        return;
    }
    local rockProxy = TankRockProxy(rock);
    _rocks[rock] <- rockProxy;
    InvokeRockSpawnCallbacks(rockProxy);
}

function ContainsRock(rock)
{
    return rock in _rocks;
}

function ClearInvalidRocks()
{
    local invalidRocks = [];
    foreach (rock, val in _rocks)
    {
        if (!rock.IsValid())
        {
            invalidRocks.append(rock);
        }
    }
    foreach (rock in invalidRocks)
    {
        local rockProxy = _rocks[rock];
        delete _rocks[rock];
        InvokeRockDestroyCallbacks(rockProxy);
    }
}

function RecordRocksInfo()
{
    foreach (rock, rockProxy in _rocks)
    {
        rockProxy.Record();
    }
}

function InvokeRockSpawnCallbacks(rockProxy)
{
    foreach (callback in _rockSpawnCallbacks)
    {
        callback({rock = rockProxy.GetRock(), thrower = rockProxy.GetThrower(), pos = rockProxy.GetPosition()});
    }
}

function InvokeRockDestroyCallbacks(rockProxy)
{
    foreach (callback in _rockDestroyCallbacks)
    {
        callback({rock = rockProxy.GetRock(), thrower = rockProxy.GetThrower(), pos = rockProxy.GetPosition()});
    }
}

function AddTankRockSpawnCallback(callback)
{
    _rockSpawnCallbacks.append(callback);
}

function RemoveTankRockSpawnCallback(callback)
{
    local idx = _rockSpawnCallbacks.find(callback);
    if (idx != null)
    {
        _rockSpawnCallbacks.remove(idx);
    }
}

function AddTankRockDestroyCallback(callback)
{
    _rockDestroyCallbacks.append(callback);
}

function RemoveTankRockDestroyCallback(callback)
{
    local idx = _rockDestroyCallbacks.find(callback);
    if (idx != null)
    {
        _rockDestroyCallbacks.remove(idx);
    }
}

function GetTankRockThrower(rock)
{
    return NetProps.GetPropEntity(rock, NetPropNameThrower);
}

function OnRoundStartPreEntity()
{
    ClearInvalidRocks();
}

function OnRoundStartPostNav()
{
    CreateTasks();
}

function RockUpdate()
{
    ClearInvalidRocks();
    RecordRocksInfo();
}

function CreateTasks()
{
    ::KtScript.Task(
        function() {
            RockUpdate();
        }.bindenv(_ctx),
        RockUpdateInterval,
        true
    ).Submit();
}

function Init()
{
}

function RegisterEventCallbacks()
{
    ::KtScript.RegisterEventCallbacks(_ctx, _eventCallbacks);
}

function GetPublicMemberNames()
{
    return [
        "AddTankRockSpawnCallback",
        "RemoveTankRockSpawnCallback"
        "AddTankRockDestroyCallback",
        "RemoveTankRockDestroyCallback"
    ];
}