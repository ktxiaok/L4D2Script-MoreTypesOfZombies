const OxygenTankModelName = "models/props_equipment/oxygentank01.mdl";
const PropaneTankModelName = "models/props_junk/propanecanister001a.mdl";
const FireworkCrateModelName = "models/props_junk/explosive_box001.mdl";

function GetLookPosition(player, maxDist = 1000)
{
    local start = player.EyePosition();
    local dir = player.EyeAngles().Forward();
    local end = start + dir * maxDist;
    local traceTable = {
        start = start,
        end = end,
        ignore = player
    };
    if (TraceLine(traceTable))
    {
        if (traceTable.hit)
        {
            return traceTable.pos;
        }
    }
    return null;
}

function PrintTalk(text, player = null)
{
    ClientPrint(player, DirectorScript.HUD_PRINTTALK, text);
}

//0xBGR
function Color24ToVec(color24)
{
    local result = {};
	local c = color24;

	result.r <- (c & 0xFF);
	result.g <- ((c >>> 8) & 0xFF);
	result.b <- ((c >>> 16) & 0xFF);
	return result;
}

function ColorVecToString(colorVec)
{
    return colorVec.r + " " + colorVec.g + " " + colorVec.b;
}

function GetColor24(r, g, b)
{
    local color = b;
	color = (color << 8) | g;
	color = (color << 8) | r;
	return color;
}

//Check if there is something between the line that connnects two entities.
//When arg entx is null the posx mustn't be null.
function EntLinecast(ent1, ent2, pos1 = null, pos2 = null, mask = null)
{
    if (mask == null)
    {
        mask = DirectorScript.TRACE_MASK_VISIBLE_AND_NPCS;
    }
    if (pos1 == null)
    {
        pos1 = ent1.GetOrigin();
    }
    if (pos2 == null)
    {
        pos2 = ent2.GetOrigin();
    }
    local traceTable = {
        start = pos1,
        end = pos2,
        mask = mask
    }
    if (ent1 != null)
    {
        traceTable.ignore <- ent1;
    }
    if (TraceLine(traceTable))
    {
        if (traceTable.hit)
        {
            if ("enthit" in traceTable && traceTable.enthit)
            {
                if (traceTable.enthit != ent2)
                {
                    return true;
                }
            }
            else
            {
                return true;
            }
        }
    }
    return false;
}

function IsPlayerAZombie(player)
{
    local t = player.GetZombieType();
    return t >= 1 && t <= 8;
}

function CapitalizeString(str)
{
    local strLen = str.len();
    if (strLen <= 1)
    {
        return str.toupper();
    }
    local first = str.slice(0, 1);
    local remaining = str.slice(1, strLen);
    return first.toupper() + remaining;
}

function IsSubClass(baseClass, subClass)
{
    local currentClass = subClass;
    while (true)
    {
        currentClass = currentClass.getbase();
        if (currentClass == null)
        {
            return false;
        }
        if (currentClass == baseClass)
        {
            return true;
        }
    }
}

function SetSpeedFactor(ent, factor)
{
    NetProps.SetPropFloat(ent, "m_flLaggedMovementValue", factor);
}

function VecProjectToPlane(vec, normal)
{
    return vec - normal * vec.Dot(normal);
}

function VecRandomUnit()
{
    local u = RandomFloat(0.0, 1.0);
    local v = RandomFloat(0.0, 1.0);
    local theta = 2.0 * PI * u;
    local phi = acos(2 * v - 1.0);
    local sinphi = sin(phi);
    local cosphi = cos(phi);
    local x = sin(theta) * sinphi;
    local y = cos(theta) * sinphi;
    local z = cosphi;
    return Vector(x, y, z);
}

function Vec2RandomUnit()
{
    local angle = RandomFloat(0.0, 2.0 * PI);
    return Vector2D(cos(angle), sin(angle));
}

function VecSafeNorm(vec)
{
    local len = vec.Length();
    if (len < 0.00001)
    {
        return VecRandomUnit();
    }
    return vec * (1.0 / len);
}

function GetExplosivesInSphere(pos, radius)
{
    local ent = null;
    local radiusSqr = radius * radius;
    while (true)
    {
        ent = Entities.FindByClassname(ent, "prop_physics");
        if (ent == null)
        {
            break;
        }
        local modelName = ent.GetModelName();
        if (modelName == OxygenTankModelName || modelName == PropaneTankModelName || modelName == FireworkCrateModelName)
        {
            local distSqr = (ent.GetOrigin() - pos).LengthSqr();
            if (distSqr <= radiusSqr)
            {
                yield ent;
            }
        }
    }
}

function GetGascansInSphere(pos, radius)
{
    local radiusSqr = radius * radius;
    local ent = null;
    while (true)
    {
        ent = Entities.FindByClassname(ent, "weapon_gascan");
        if (ent == null)
        {
            break;
        }
        local distSqr = (ent.GetOrigin() - pos).LengthSqr();
        if (distSqr <= radiusSqr)
        {
            yield ent;
        }
    }
}

function SimpleEntFire(ent, action, val = null, delay = 0)
{
    EntFire("!activator", action, val, delay, ent);
}

function TryGetEntityScope(ent)
{
    if (ent.IsValid())
    {
        if (ent.ValidateScriptScope())
        {
            return ent.GetScriptScope();
        }
    }
    return null;
}

class Queue
{
    _elements = null;

    _headIdx = 0;
    _tailIdx = 0;

    _count = 0;

    constructor(initialCapacity = 4)
    {
        _elements = array(initialCapacity);
    }

    // from head to tail
    function GetElementIter()
    {
        local capacity = _elements.len();
        local count = _count;
        local idx = _headIdx;
        while (count > 0)
        {
            yield _elements[idx];
            idx++;
            if (idx >= capacity)
            {
                idx = 0;
            }
            count--;
        }
    }

    function GetCount()
    {
        return _count;
    }

    function GetHead()
    {
        CheckEmpty();
        return _elements[_headIdx];
    }

    function PopHead()
    {
        CheckEmpty();
        local head = _elements[_headIdx];
        _elements[_headIdx] = null;
        _headIdx++;
        if (_headIdx >= _elements.len())
        {
            _headIdx = 0;
        }
        _count--;
    }

    function PushTail(element)
    {
        CheckFull();
        _elements[_tailIdx] = element;
        _tailIdx++;
        if (_tailIdx >= _elements.len())
        {
            _tailIdx = 0;
        }
        _count++;
    }

    function GetCapacity()
    {
        return _elements.len();
    }

    function SetCapacity(newCapacity)
    {
        local capacity = _elements.len();
        local newArray = array(newCapacity);
        local newTailIdx = 0;
        local newCount = 0;
        foreach (element in GetElementIter())
        {
            newArray[newTailIdx] = element;
            newTailIdx++;
            newCount++;
            if (newTailIdx >= newCapacity)
            {
                newTailIdx = 0;
                break;
            }
        }

        _elements = newArray;
        _headIdx = 0;
        _tailIdx = newTailIdx;
        _count = newCount;
    }

    function CheckEmpty()
    {
        if (_count == 0)
        {
            throw "The container is empty!";
        }
    }

    function CheckFull()
    {
        local capacity = _elements.len();
        if (_count == capacity)
        {
            local newCapacity = 2 * capacity;
            if (newCapacity == 0)
            {
                newCapacity = 1;
            }
            SetCapacity(newCapacity);
        }
    }
}

function GetBasicZombieType(zombie)
{
    if ("GetZombieType" in zombie)
    {
        return zombie.GetZombieType();
    }
    if (zombie.GetClassname() == "witch")
    {
        return DirectorScript.ZOMBIE_WITCH;
    }
    return 0;
}

function SetZombieHealthMultiplier(zombie, m)
{
    local health = zombie.GetHealth();
    health *= m;
    health = health.tointeger();
    zombie.SetMaxHealth(health);
    zombie.SetHealth(health);
}

function AddPlayerHealth(player, increment)
{
    local maxHealth = player.GetMaxHealth();
    local health = player.GetHealth();
    if (health < maxHealth)
    {
        health += increment;
        if (health > maxHealth)
        {
            health = maxHealth;
        }
        player.SetHealth(health);
        local maxHealthBuffer = maxHealth - health;
        local healthBuffer = player.GetHealthBuffer().tointeger();
        if (healthBuffer > maxHealthBuffer)
        {
            player.SetHealthBuffer(maxHealthBuffer);
        }
    }
}

function AddPlayerHealthBuffer(player, increment)
{
    local maxHealth = player.GetMaxHealth();
    local health = player.GetHealth();
    local maxHealthBuffer = maxHealth - health;
    maxHealthBuffer = maxHealthBuffer.tofloat();
    local healthBuffer = player.GetHealthBuffer();
    healthBuffer += increment;
    if (healthBuffer > maxHealthBuffer)
    {
        healthBuffer = maxHealthBuffer;
    }
    player.SetHealthBuffer(healthBuffer);
}