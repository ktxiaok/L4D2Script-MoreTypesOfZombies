local _ctx = this;

class Property
{
    _name = null;
    _type = null;
    _getter = null;
    _setter = null;

    constructor(name)
    {
        _name = name;
    }

    function GetName()
    {
        return _name;
    }

    function GetType()
    {
        return _type;
    }

    function SetType(type)
    {
        _type = type;
        return this;
    }

    function GetGetter()
    {
        return _getter;
    }

    function SetGetter(getter)
    {
        _getter = getter;
        return this;
    }

    function GetSetter()
    {
        return _setter;
    }

    function SetSetter(setter)
    {
        _setter = setter;
        return this;
    }

    function RawGetValue(scope)
    {
        return scope[_name];
    }

    function RawSetValue(val, scope)
    {
        scope[_name] = val;
    }

    function GetValue(scope)
    {
        if (_getter == null)
        {
            return RawGetValue(scope);
        }
        return _getter(this, scope);
    }

    function SetValue(val, scope, asDefault = false)
    {
        val = ConvertType(val);

        if (_setter == null)
        {
            RawSetValue(val, scope);
            return;
        }
        _setter(val, this, scope);
        if (!asDefault)
        {
            scope._changedProperties[_name] <- true;
        }
    }

    //may throw a exception
    function ConvertType(val)
    {
        local valType = typeof val;

        if (_type == "string")
        {
            return val.tostring();
        }
        if (_type == "bool")
        {
            if (valType == "string")
            {
                if (val == "true")
                {
                    return true;
                }
                if (val == "false")
                {
                    return false;
                }
                try
                {
                    local num = val.tointeger();
                    if (num == 0)
                    {
                        return false;
                    }
                    else
                    {
                        return true;
                    }
                }
                catch (exception)
                {

                }
            }
            if (val)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        if (_type == "integer")
        {
            return val.tointeger();
        }
        if (_type == "float")
        {
            return val.tofloat();
        }
        throw format("Unsupported type: %s", _type);
    }
}

//table(string name -> Property propertyInstance)
_properties <- {};

_configScope <- null;

_setterExpEnv <- {
    range = function(min = null, max = null) {
        return NewRangePropertySetter(min, max);
    }.bindenv(_ctx)
};

/**
 * infoTable:
 * {
 *      string name;
 *      string type; (optional)
 *      function getter(Property property, table scope); (optional)
 *      function setter(any val, Property property, table scope); (optional)
 * }
 */
function DefineProperty(infoTable)
{
    local name = infoTable.name;
    local property = Property(name);
    if ("type" in infoTable)
    {
        property.SetType(infoTable.type);
    }
    if ("getter" in infoTable)
    {
        property.SetGetter(infoTable.getter);
    }
    if ("setter" in infoTable)
    {
        local setter = infoTable.setter;
        local setterType = typeof setter;
        if (setterType == "string")
        {
            try
            {
                local func = compilestring("return " + setter).bindenv(_setterExpEnv);
                setter = func();
            }
            catch (exception)
            {
                setter = null;
            }
        }
        if (setter != null && typeof setter == "function")
        {
            property.SetSetter(setter);
        }
    }

    _properties[name] <- property;

    _configScope[name] <- null;
}

function LoadConfigFromTable(table, asDefault = false)
{
    if (asDefault)
    {
        _configScope._changedProperties.clear();
    }
    foreach (name, val in table)
    {
        if (name in _properties)
        {
            SetCfgProp(name, val, asDefault);
        }
    }
}

function SaveConfigToTable(table)
{
    local changedProps = _configScope._changedProperties;
    foreach (name, val in changedProps)
    {
        table[name] <- _configScope[name];
    }
}

function SaveConfigToFile(filePath)
{
    local table = {};
    SaveConfigToTable(table);
    ::KtScript.TableToFile(table, filePath);
}

function GetCfgProp(name)
{
    if (!(name in _properties))
    {
        throw format("The config \"%s\" doesn't exist!", name);
    }
    local property = _properties[name];
    return property.GetValue(_configScope);
}

function SetCfgProp(name, val, asDefault = false)
{
    if (!(name in _properties))
    {
        throw format("The property \"%s\" doesn't exist!", name);
    }
    local property = _properties[name];
    property.SetValue(val, _configScope, asDefault);
}

function ContainsCfgProp(name)
{
    return name in _properties;
}

function Init(configScope)
{
    _configScope = configScope;

    //string propName -> true
    _configScope._changedProperties <- {};
}

function GetPublicMemberNames()
{
    return [
        "DefineProperty",
        "LoadConfigFromTable",
        "SaveConfigToFile",
        "GetCfgProp",
        "SetCfgProp",
        "ContainsCfgProp"
    ]
}

function NewRangePropertySetter(min = null, max = null)
{
    return function(val, property, scope) {
        if (min != null)
        {
            if (val < min)
            {
                val = min;
            }
        }
        if (max != null)
        {
            if (val > max)
            {
                val = max;
            }
        }
        property.RawSetValue(val, scope);
    }
}

function PrintError(str)
{
    printl(str);
    //Say(null, str, false);
}