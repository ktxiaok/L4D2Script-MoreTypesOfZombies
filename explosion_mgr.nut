local _ctx = this;
const FireballSpriteName = "";

const FlagNoDamage = 1;
const FlagPushPlayers = 2;
const FlagTestLos = 8;
const FlagDisorientPlayer = 16;


MinDistDivisor <- 100000.0;
PlayerPushFactor <- 5000000.0;
TankPushFactor <- 0.1;
ChargerPushFactor <- 0.6;

PushPosZAdjustThreshold <- 100.0;
PushPosZAdjust <- 60.0;
PushPlaneAdjust <- 30.0;

function Init()
{

}

function Explode(magnitude, physMagnitude, pos, srcEnt = null)
{
    if (srcEnt != null)
    {
        if (!srcEnt.IsValid())
        {
            srcEnt = null;
        }
    }

    local entNameExplosion = ::KtScript.CreateUniqueTargetName("explosion");
    local entExplosion = SpawnEntityFromTable("env_explosion", {
        targetname = entNameExplosion,
        iMagnitude = magnitude,
        fireballsprite = FireballSpriteName,
        rendermode = 0,
        spawnflags = 0
    });

    local entNamePhysExplosion = ::KtScript.CreateUniqueTargetName("physexplosion");
    local entPhysExplosion = SpawnEntityFromTable("env_physexplosion", {
        targetname = entNamePhysExplosion,
        magnitude = physMagnitude,
        radius = 0,
        spawnflags = FlagNoDamage | FlagPushPlayers | FlagTestLos | FlagDisorientPlayer
    });

    entExplosion.SetOrigin(pos);
    entPhysExplosion.SetOrigin(pos);

    EntFire(entNameExplosion, "Explode");
    EntFire(entNamePhysExplosion, "Explode");
    EntFire(entNameExplosion, "Kill", null, 1.0);
    EntFire(entNamePhysExplosion, "Kill", null, 1.0);

    PushPlayers(physMagnitude, pos, srcEnt);
}

function PushPlayers(magnitude, pos, srcEnt)
{
    local players = ::KtScript.AllPlayers();
    foreach (player in players)
    {
        local playerPos = player.EyePosition();
        if (_rootctx.EntLinecast(srcEnt, player, pos, playerPos))
        {
            continue;
        }
        local dir = playerPos - pos;
        if (fabs(dir.z) < PushPosZAdjustThreshold)
        {
            dir.z = PushPosZAdjust;
            local planeDir = _rootctx.VecProjectToPlane(dir, Vector(0.0, 0.0, 1.0));
            planeDir = _rootctx.VecSafeNorm(planeDir) * PushPlaneAdjust;
            dir += planeDir;
        }
        local distSqr = dir.LengthSqr();
        local dist = sqrt(distSqr);
        if (dist < 0.00001)
        {
            dir = Vector(1.0, 0.0, 0.0);
        }
        else
        {
            dir *= 1.0 / dist;
        }
        local accel = magnitude * PlayerPushFactor;
        local distDivisor = distSqr;
        if (distDivisor < MinDistDivisor)
        {
            distDivisor = MinDistDivisor;
        }
        accel /= distDivisor;
        local playerType = player.GetZombieType();
        if (playerType == DirectorScript.ZOMBIE_TANK)
        {
            accel *= TankPushFactor;
        }
        else if (playerType == DirectorScript.ZOMBIE_CHARGER)
        {
            accel *= ChargerPushFactor;
        }
        local accelVel = dir * accel;
        player.SetVelocity(player.GetVelocity() + accelVel);
    }
}

function GetPublicMemberNames()
{
    return [
        "Explode"
    ];
}