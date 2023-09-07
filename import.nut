IncludeScript("ktscript/base/import");
local ctxId = "MoreTypesOfZombies";
local onlineId = ctxId + "Online";
if (!(onlineId in ::KtScript))
{
    ::KtScript[ctxId] <- {};
    IncludeScript("ktscript/more_types_of_zombies/mtoz", ::KtScript[ctxId]);
    ::KtScript[ctxId].Init();
    ::KtScript[onlineId] <- true;
}