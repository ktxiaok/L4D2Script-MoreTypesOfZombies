local _ctx = this;

class WeightItem
{
    weight = null;
    weightPos = null;
    name = null;

    constructor(name, weight, weightPos)
    {
        this.name = name;
        this.weight = weight;
        this.weightPos = weightPos;
    }

    function InRange(pos)
    {
        if (pos < weightPos)
        {
            return -1;
        }
        if (pos > weightPos + weight)
        {
            return 1;
        }
        return 0;
    }
}

class RandomWeightPicker
{
    _weightItems = null;
    _totalWeight = null;

    constructor(weightTable)
    {
        _weightItems = [];
        local currentPos = 0.0;
        foreach (name, weight in weightTable)
        {
            weight = weight.tofloat();
            local item = _ctx.WeightItem(name, weight, currentPos);
            currentPos += weight;
            _weightItems.append(item);
        }
        _totalWeight = currentPos;
    }

    //return name : string
    function Pick()
    {
        local pos = RandomFloat(0.0, _totalWeight);
        local left = 0;
        local right = _weightItems.len() - 1;
        if (_weightItems[left].InRange(pos) == 0)
        {
            return _weightItems[left].name;
        }
        if (_weightItems[right].InRange(pos) == 0)
        {
            return _weightItems[right].name;
        }
        while (true)
        {
            if (left == right)
            {
                return _weightItems[left].name;
            }
            local mid = (left + right) / 2;
            local r = _weightItems[mid].InRange(pos);
            if (r < 0)
            {
                right = mid;
            }
            else if (r > 0)
            {
                left = mid;
            }
            else
            {
                return _weightItems[mid].name;
            }
        }
    }
}

function GetPublicMemberNames()
{
    return [
        "RandomWeightPicker"
    ];
}