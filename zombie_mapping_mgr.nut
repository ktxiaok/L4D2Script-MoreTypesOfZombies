local _ctx = this;
local _rootctx = _rootctx;

class ZombieMappingMgr
{
    _objClass = null;

    //entity zombie -> MappingObject obj
    _objects = null;

    _abilityCallback = null;

    _tankRockSpawnCallback = null;
    _tankRockDestroyCallback = null;

    _playerHurtCallback = null;

    _roundStartCallback = null;

    _isAbilityListeningEnabled = false;
    _isTankRockListeningEnabled = false;
    _isPlayerHurtListeningEnabled = false;

    _tempArray = null;

    /**
     * The class objClass should have a constructor: constructor(entity zombie)
     * When any zombie is about to be destroyed, the method OnDestroy() of the mapping object will be called.
     */
    constructor(objClass)
    {
        _objClass = objClass;
        _objects = {};
        _tempArray = [];

        InitRoundStartCallback();

        //_taskCheckInvalid = ::KtScript.Task(function(){CheckInvalid();}.bindenv(this), 4.0, true, true);
        //_taskCheckInvalid.Submit();

        _ctx.AddManager(this);
    }

    function TryGet(zombie)
    {
        if (zombie in _objects)
        {
            return _objects[zombie];
        }
        return null;
    }

    function Get(zombie)
    {
        local obj = TryGet(zombie);
        if (obj == null)
        {
            obj = CreateMappingObject(zombie);
        }
        return obj;
    }

    function GetZombies()
    {
        local zombies = [];
        foreach (zombie, obj in _objects)
        {
            zombies.append(zombie);
        }
        return zombies;
    }

    function GetMappingObjectIter()
    {
        foreach (zombie, obj in _objects)
        {
            yield obj;
        }
    }

    function GetCount()
    {
        return _objects.len();
    }

    function NotifyZombieDestroy(zombie, isEntValid)
    {
        local obj = TryGet(zombie);
        if (obj == null)
        {
            return;
        }
        delete _objects[zombie];
        NotifyMappingObjectDestroy(obj, {isEntValid = isEntValid});
    }

    function NotifyMappingObjectDestroy(obj, params)
    {
        if ("OnDestroy" in obj)
        {
            obj.OnDestroy(params);
        }
    }

    function Destroy()
    {
        //_taskCheckInvalid.Kill();
        DisableAbilityListening();
        DisableTankRockListening();
        DisableHurtListening();
        DestroyRoundStartCallback();
        _ctx.RemoveManager(this);
    }

    function CreateMappingObject(zombie)
    {
        local obj = _objClass(zombie);
        _objects[zombie] <- obj;
        return obj;
    }

    function EnableAbilityListening()
    {
        if (_isAbilityListeningEnabled)
        {
            return;
        }
        _isAbilityListeningEnabled = true;

        local abilityToMethod = _ctx._abilityToMethodName;
        local mgr = this;
        _abilityCallback = function(zombie, abilityName) {
            local mappingObj = mgr.TryGet(zombie);
            if (mappingObj == null)
            {
                return;
            }

            if (abilityName in abilityToMethod)
            {
                local methodName = abilityToMethod[abilityName];
                if (methodName in mappingObj)
                {
                    mappingObj[methodName]();
                }
            }
        };
        _ctx.AddAbilityUseCallback(_abilityCallback);
    }

    function DisableAbilityListening()
    {
        if (!_isAbilityListeningEnabled)
        {
            return;
        }
        _isAbilityListeningEnabled = false;

        _ctx.RemoveAbilityUseCallback(_abilityCallback);
    }

    function EnableTankRockListening()
    {
        if (_isTankRockListeningEnabled)
        {
            return;
        }
        _isTankRockListeningEnabled = true;

        _tankRockSpawnCallback = function(params) {
            local tank = params.thrower;
            local mappingObj = TryGet(tank);
            if (mappingObj == null)
            {
                return;
            }

            if ("OnTankRockSpawn" in mappingObj)
            {
                mappingObj.OnTankRockSpawn(params);
            }
        }.bindenv(this);

        _tankRockDestroyCallback = function(params) {
            local tank = params.thrower;
            local mappingObj = TryGet(tank);
            if (mappingObj == null)
            {
                return;
            }

            if ("OnTankRockDestroy" in mappingObj)
            {
                mappingObj.OnTankRockDestroy(params);
            }
        }.bindenv(this);

        _rootctx.AddTankRockSpawnCallback(_tankRockSpawnCallback);
        _rootctx.AddTankRockDestroyCallback(_tankRockDestroyCallback);
    }

    function DisableTankRockListening()
    {
        if (!_isTankRockListeningEnabled)
        {
            return;
        }
        _isTankRockListeningEnabled = false;

        _rootctx.RemoveTankRockSpawnCallback(_tankRockSpawnCallback);
        _rootctx.RemoveTankRockDestroyCallback(_tankRockDestroyCallback);
    }

    function EnableHurtListening()
    {
        if (_isPlayerHurtListeningEnabled)
        {
            return;
        }
        _isPlayerHurtListeningEnabled = true;

        _playerHurtCallback = function(params) {
            local victim = GetPlayerFromUserID(params.userid);
            if (victim in _objects)
            {
                local mappingObj = _objects[victim];
                if ("OnHurt" in mappingObj)
                {
                    mappingObj.OnHurt(params);
                }
            }
        }.bindenv(this);

        _ctx.AddPlayerHurtCallback(_playerHurtCallback);
    }

    function DisableHurtListening()
    {
        if (!_isPlayerHurtListeningEnabled)
        {
            return;
        }
        _isPlayerHurtListeningEnabled = false;

        _ctx.RemovePlayerHurtCallback(_playerHurtCallback);
    }

    function InitRoundStartCallback()
    {
        _roundStartCallback = function() {
            local zombies = GetZombies();
            foreach (zombie in zombies)
            {
                NotifyZombieDestroy(zombie, false);
            }
        }.bindenv(this);
        _ctx.AddRoundStartCallback(_roundStartCallback);
    }

    function DestroyRoundStartCallback()
    {
        _ctx.RemoveRoundStartCallback(_roundStartCallback);
    }

    function CheckInvalid()
    {
        foreach (ent, val in _objects)
        {
            _tempArray.append(ent);
        }
        foreach (ent in _tempArray)
        {
            if (!ent.IsValid())
            {
                NotifyZombieDestroy(ent, false);
            }
        }
        _tempArray.clear();
    }
}

_managers <- [];

_taskCheckInvalid <- ::KtScript.Task(function(){CheckInvalid();}.bindenv(this), 4.0, true, true);

_abilityToMethodName <- {
    ability_tongue = "OnAbilitySmoker",
    ability_vomit = "OnAbilityBoomer",
    ability_lunge = "OnAbilityHunter",
    ability_spit = "OnAbilitySpitter",
    ability_charge = "OnAbilityCharger",
    ability_throw = "OnAbilityTank"
}
_abilityMethodNames <- [];
foreach (ability, methodName in _abilityToMethodName)
{
    _abilityMethodNames.append(methodName);
}

_abilityUseCallbacks <- [];

_playerHurtCallbacks <- [];

_roundStartCallbacks <- [];

function AddAbilityUseCallback(callback)
{
    _abilityUseCallbacks.append(callback);
}

function RemoveAbilityUseCallback(callback)
{
    local idx = _abilityUseCallbacks.find(callback);
    if (idx != null)
    {
        _abilityUseCallbacks.remove(idx);
    }
}

function OnAbilityUse(zombie, abilityName)
{
    foreach (callback in _abilityUseCallbacks)
    {
        callback(zombie, abilityName);
    }
}

function AddPlayerHurtCallback(callback)
{
    _playerHurtCallbacks.append(callback);
}

function RemovePlayerHurtCallback(callback)
{
    local idx = _playerHurtCallback.find(callback);
    if (idx != null)
    {
        _playerHurtCallbacks.remove(idx);
    }
}

function OnPlayerHurt(params)
{
    foreach (callback in _playerHurtCallbacks)
    {
        callback(params);
    }
}

function AddRoundStartCallback(callback)
{
    _roundStartCallbacks.append(callback);
}

function RemoveRoundStartCallback(callback)
{
    local idx = _roundStartCallbacks.find(callback);
    if (idx != null)
    {
        _roundStartCallbacks.remove(idx);
    }
}

function OnRoundStart()
{
    foreach (callback in _roundStartCallbacks)
    {
        callback();
    }
}

_eventCallbacks <- {
    OnGameEvent_zombie_death = function(params) {
        local zombie = EntIndexToHScript(params.victim);
        foreach (manager in _managers)
        {
            manager.NotifyZombieDestroy(zombie, true);
        }
    }.bindenv(_ctx),

    OnGameEvent_player_disconnect = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        foreach (manager in _managers)
        {
            manager.NotifyZombieDestroy(player, false);
        }
    }.bindenv(_ctx),

    OnGameEvent_ability_use = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        local abilityName = params.ability;
        OnAbilityUse(player, abilityName);
    }.bindenv(_ctx),

    OnGameEvent_player_hurt = function(params) {
        OnPlayerHurt(params);
    }.bindenv(_ctx),

    OnGameEvent_round_start_pre_entity = function(params) {
        OnRoundStart();
    }.bindenv(_ctx)
}

function AddManager(manager)
{
    _managers.append(manager);
}

function RemoveManager(manager)
{
    local idx = _managers.find(manager);
    if (idx != null)
    {
        _managers.remove(idx);
    }
}

function CheckInvalid()
{
    foreach (manager in _managers)
    {
        manager.CheckInvalid();
    }
}

function Init()
{
    _taskCheckInvalid.Submit();
}

function RegisterEventCallbacks()
{
    ::KtScript.RegisterEventCallbacks(_ctx, _eventCallbacks);
}

// function ImportPublic(scope)
// {
//     scope.ZombieMappingMgr <- ZombieMappingMgr;
// }
function GetPublicMemberNames()
{
    return [
        "ZombieMappingMgr"
    ];
}