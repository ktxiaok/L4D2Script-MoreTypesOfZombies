local _ctx = this;
const FlashZtypeColor = 0xffffff;
FlashSlowTime <- 1.0;

class FlashZtype extends Ztype
{
    constructor()
    {
        base.constructor();
    }

    function GetInstanceClass()
    {
        return _ctx.FlashZtypeInstance;
    }

    function GetName()
    {
        return "flash";
    }

    function GetColor()
    {
        return FlashZtypeColor;
    }
}

class FlashZtypeInstance extends ZtypeInstance
{
    static FlickerMinSpeed = 0.5;
    static FlickerMaxSpeed = 10.0;
    static DeltaTime = 0.05;

    _task = null;

    _playerHurtCallback = null;

    _glowTimer = 0.0;
    _flashTimer = 0.0;

    _isTank = null;

    constructor(zombie)
    {
        base.constructor(zombie);

        _isTank = false;
        if ("GetZombieType" in zombie)
        {
            if (zombie.GetZombieType() == DirectorScript.ZOMBIE_TANK)
            {
                _isTank = true;
            }
        }

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

        _playerHurtCallback = function(params) {
            local zombie = instance._zombie;
            if (!zombie.IsValid())
            {
                return;
            }
            local zombieEntIdx = zombie.GetEntityIndex();
            local attackerEntIdx = params.attackerentid;
            if (zombieEntIdx == attackerEntIdx)
            {
                local player = GetPlayerFromUserID(params.userid);
                if (player.IsSurvivor())
                {
                    instance.OnHurtPlayer(player);
                }
            }
        };
        _ctx.AddPlayerHurtCallback(_playerHurtCallback);
    }

    function Update(dt)
    {
        if (!_zombie.IsValid())
        {
            return;
        }

        local flashPeriod = _ctx.GetCfgProp("FlashPeriod");
        _flashTimer += dt;
        if (_flashTimer >= flashPeriod)
        {
            _flashTimer = 0.0;
            RadiateFlash();
        }

        local flickerSpeed = FlickerMinSpeed + (FlickerMaxSpeed - FlickerMinSpeed) * (_flashTimer / flashPeriod);
        _glowTimer += flickerSpeed * dt;
        if (_glowTimer >= 1000.0)
        {
            _glowTimer = 0.0;
        }
        local glowFactor = fabs(sin(PI * _glowTimer));
        //glowFactor = glowFactor * glowFactor;
        _ctx.SetZombieGlowFactor(_zombie, glowFactor);
    }

    function OnHurtPlayer(player)
    {
        RadiateFlash(player);
    }

    function OnDestroy(params)
    {
        _task.Kill();
        _ctx.RemovePlayerHurtCallback(_playerHurtCallback);
        base.OnDestroy(params);
    }

    function RadiateFlash(targetPlayer = null)
    {
        if (!_zombie.IsValid())
        {
            return;
        }

        local fadeTime = _ctx.GetCfgProp("FlashBlindFadeTime");
        local holdTime = _ctx.GetCfgProp("FlashBlindHoldTime");
        local isFlashWhite = _ctx.GetCfgProp("IsFlashColorWhite");

        local ScreenFlash = function(player, factor = 1.0) {
            ::KtScript.Task(
                function() {
                    if (!player.IsValid())
                    {
                        return;
                    }
                    local color = null;
                    if (isFlashWhite)
                    {
                        color = {r = 255, g = 255, b = 255};
                    }
                    else
                    {
                        color = {r = 0, g = 0, b = 0};
                    }
                    ScreenFade(player, color.r, color.g, color.b, 255, factor * fadeTime, factor * holdTime, 1);//arg: player, r, g, b, a, fadeTime, fadeHold, flags
                },
                0.1
            ).Submit();
        };

        if (targetPlayer == null)
        {
            PlayFlashSound(_zombie);
            local survivors = GetSurvivors();
            local zombiePos = _zombie.GetClassname() == "witch" ? _zombie.GetOrigin() : _zombie.EyePosition();
            ShakePlayers(zombiePos);
            foreach (player in survivors)
            {
                local playerPos = player.EyePosition();
                if (_ctx.EntLinecast(player, _zombie, playerPos, zombiePos))
                {
                    continue;
                }
                local attFactor = _ctx.GetCfgProp("FlashAttFactor");
                local att = (playerPos - zombiePos).Length() * attFactor;
                if (att < 1.0)
                {
                    att = 1.0;
                }
                local v = CalcVisibility(player, playerPos, zombiePos);
                if (v > 0.0)
                {
                    ScreenFlash(player, v / att);
                }
                SlowPlayer(player, 1.0 / att);
            }
            TempDisableGlow();
        }
        else
        {
            ScreenFlash(targetPlayer);
        }
    }

    function TempDisableGlow()
    {
        local pos = _zombie.GetClassname() == "witch" ? _zombie.GetOrigin() : _zombie.EyePosition();
        local time = _ctx.GetCfgProp("FlashDisableGlowTime");
        _ctx.TempDisableZombieGlow(_zombie, time);
        local ent = null;

        while (true)
        {
            ent = Entities.FindByClassname(ent, "player");
            if (ent == _zombie)
            {
                continue;
            }
            if (ent == null)
            {
                break;
            }
            if (!_ctx.IsPlayerAZombie(ent))
            {
                continue;
            }
            if (!_ctx.IsZombieColored(ent))
            {
                continue;
            }

            if (!_ctx.EntLinecast(_zombie, ent, pos, ent.EyePosition()))
            {
                _ctx.TempDisableZombieGlow(ent, time);
            }
        }
        ent = null;
        while (true)
        {
            ent = Entities.FindByClassname(ent, "witch");
            if (ent == _zombie)
            {
                continue;
            }
            if (ent == null)
            {
                break;
            }
            if (!_ctx.IsZombieColored(ent))
            {
                continue;
            }

            if (!_ctx.EntLinecast(_zombie, ent, pos, ent.GetOrigin()))
            {
                _ctx.TempDisableZombieGlow(ent, time);
            }
        }
    }

    function PlayFlashSound(ent)
    {
        EmitAmbientSoundOn(FlashSoundName, 1.0, 130, 100, ent);
    }

    function CalcVisibility(player, playerPos, zombiePos)
    {
        local eyeAngles = player.EyeAngles();
        local eyeDir = eyeAngles.Forward();
        local dir = zombiePos - playerPos;
        local dist = dir.Norm();
        local p = eyeDir.Dot(dir);
        if (p > 0)
        {
            return p;
        }
        else
        {
            return -1.0;
        }
    }

    // function SlowPlayer(player, factor)
    // {
    //     local accel = _ctx._flashSlowAccel * factor;
    //     local time = _ctx.FlashSlowTime;
    //     local timer = 0.0;
    //     local task = null;
    //     local dt = 0.01;
    //     local action = function() {
    //         if (!player.IsValid())
    //         {
    //             task.Kill();
    //         }
    //         timer += dt;
    //         local vel = player.GetVelocity();
    //         local speed = vel.Length();
    //         if (speed < 1.0)
    //         {
    //             return;
    //         }
    //         local newSpeed = speed - accel * dt;
    //         if (newSpeed < 0.0)
    //         {
    //             newSpeed = 0.0;
    //         }
    //         vel *= newSpeed / speed;
    //         player.SetVelocity(vel);
    //         if (timer >= time)
    //         {
    //             task.Kill();
    //         }
    //     }
    //     task = ::KtScript.Task(action, dt, true);
    //     task.Submit();
    // }

    function SlowPlayer(player, factor)
    {
        local friction = _ctx.GetCfgProp(_isTank ? "FlashSlowFactorTank" : "FlashSlowFactor");
        friction *= factor;
        if (friction < 1.0)
        {
            friction = 1.0;
        }
        local slowTime = 1.0;
        player.OverrideFriction(slowTime, friction);
    }

    function ShakePlayers(center)
    {
        //void ScreenShake(Vector vecCenter, float flAmplitude, float flFrequency, float flDuration, float flRadius, int eCommand, bool bAirShake)
        ScreenShake(center, 8.0, 5.0, 1.0, 500.0, 0, true);
    }

    function GetSurvivors()
    {
        local ent = null;
        while (true)
        {
            ent = Entities.FindByClassname(ent, "player");
            if (ent == null)
            {
                break;
            }
            if (ent.IsSurvivor())
            {
                if (ent.IsDead())
                {
                    continue;
                }
                yield ent;
            }
        }
    }
}