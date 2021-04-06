local FuncUtil = require "FuncUtil"

---@class LuaDelegateAgent : UObject@comment string
local LuaDelegateAgent = LuaUnrealClass()

function LuaDelegateAgent:Initialize(Initializer)
    print("TestThroughScene:Initialize()")
    _G.__LuaDelegateAgent = self;
end

function LuaDelegateAgent:OnAppShutDown()
    print("LuaDelegateAgent:OnAppShutDown")
    _G.__LuaDelegateAgent = nil;
    UE4.ULuaDelegateAgent.Shutdown();
end

function LuaDelegateAgent.GetInstance()
    if _G.__LuaDelegateAgent == nil then
        print("UE4.ULuaDelegateAgent.CreateInstance")
        UE4.ULuaDelegateAgent.CreateInstance();
        return _G.__LuaDelegateAgent;
    else
        return _G.__LuaDelegateAgent
    end
end

--单播delegate绑定,无法unbind
---@param targetDelegate  userdata 需要绑定的单播delegate
---@param tbTarget table 绑定的function的self,可以为nil.
---@param funcTarget function 绑定的function
function LuaDelegateAgent.BindToDelegate(targetDelegate, tbTarget,funcTarget,...)
    if not targetDelegate then
        return
    end

    local params = {...}
    local funcAgent = function(_,...)
        local _,rt = FuncUtil.CallFunc(tbTarget,funcTarget,params,...)
        return rt;
    end
    targetDelegate:Bind(LuaDelegateAgent:GetInstance(),funcAgent)
    return funcAgent;
end

local DelegatesMapForUnbind = {}
--单播delegate绑定拓展版,!!!!!慎用!!!!因为必须手动unbind,不然会导致lua内存泄漏.
---@param targetDelegate  userdata 需要绑定的单播delegate
---@param tbTarget table 绑定的function的self,可以为nil.
---@param funcTarget function 绑定的function
function LuaDelegateAgent.BindToDelegateEx(targetDelegate, tbTarget,funcTarget,...)
    if not targetDelegate then
        return
    end

    local agentFunc = LuaDelegateAgent.BindToDelegate(targetDelegate,tbTarget,funcTarget,...);
    DelegatesMapForUnbind[targetDelegate] = {tb = tbTarget,func = funcTarget,agent = agentFunc}
end

---@param targetDelegate  userdata 需要解绑的单播delegate
---@param tbTarget table 之前绑定的function的self,可以为nil.
---@param funcTarget function 之前绑定的function
function LuaDelegateAgent.UnbindToDelegateEx(targetDelegate, tbTarget,funcTarget)
    if not targetDelegate then
        return
    end

    for k,v in pairs(DelegatesMapForUnbind) do
        if k == targetDelegate and v.tb == tbTarget and v.func == funcTarget then
            targetDelegate:Unbind(LuaDelegateAgent:GetInstance(),v.agent)
            DelegatesMapForUnbind[targetDelegate] = nil;
        end
    end
end

---@param tbTarget table 之前绑定的function的self
function LuaDelegateAgent.UnbindAllForTableEx(tbTarget)
    if tbTarget == nil then
        return;
    end

    local arrayToRemove = {}
    for targetDelegate,v in pairs(DelegatesMapForUnbind) do
        if v.tb == tbTarget then
            targetDelegate:Unbind(LuaDelegateAgent:GetInstance(),v.agent)
            table.insert(arrayToRemove,targetDelegate)
        end
    end

    for _,targetDelegate in ipairs(arrayToRemove) do
        DelegatesMapForUnbind[targetDelegate] = nil;
    end
end

--多播delegate绑定
---@param targetDelegate  userdata 需要绑定的单播delegate
---@param tbTarget table 绑定的function的self,可以为nil.
---@param funcTarget function 绑定的function
function LuaDelegateAgent.AddToDelegate(targetDelegate, tbTarget,funcTarget,...)
    if not targetDelegate then
        return
    end

    local params = {...}
    local agentFunc = function(_,...)
        local _,rt = FuncUtil.CallFunc(tbTarget,funcTarget,params,...)
        return rt;
    end
    targetDelegate:Add(LuaDelegateAgent:GetInstance(),agentFunc)
    return agentFunc;
end

local MultiDelegatesMapForRemove = {}
--多播delegate绑定拓展版,!!!!!慎用!!!!因为必须手动Remove,不然会导致lua内存泄漏.
---@param targetDelegate  userdata 需要监听的多播delegate
---@param tbTarget table 监听的function的self,可以为nil.
---@param funcTarget function 监听的function
function LuaDelegateAgent.AddToDelegateEx(targetDelegate, tbTarget,funcTarget,...)
    if not targetDelegate then
        return
    end

    local agentFunc = LuaDelegateAgent.AddToDelegate(targetDelegate, tbTarget,funcTarget,...)
    local collections = MultiDelegatesMapForRemove[targetDelegate]
    if not collections then
        collections = {}
        MultiDelegatesMapForRemove[targetDelegate] = collections;
    end

    table.insert(collections,{tb = tbTarget,func = funcTarget,agent = agentFunc});
end

---@param targetDelegate  userdata 监听的多播delegate
---@param tbTarget table 监听的function的self,可以为nil.
---@param funcTarget function 监听的function
function LuaDelegateAgent.RemoveToDelegateEx(targetDelegate, tbTarget,funcTarget)
    if not targetDelegate then
        return
    end

    local delegateToRemoved = {}
    for delegate,arrayAdded in pairs(MultiDelegatesMapForRemove) do
        if delegate == targetDelegate then
            for index = #arrayAdded,1,-1 do
                local addedInfo = arrayAdded[index];
                if addedInfo.tb == tbTarget and addedInfo.func == funcTarget then
                    targetDelegate:Remove(LuaDelegateAgent:GetInstance(),addedInfo.agent)
                    table.remove(arrayAdded,index);
                end
            end
            if #arrayAdded == 0 then
                table.insert(delegateToRemoved,delegate)
            end
        end
    end

    for _,delegate in ipairs(delegateToRemoved) do
        MultiDelegatesMapForRemove[delegate] = nil;
    end
end

---@param tbTarget table 之前监听的function的self
function LuaDelegateAgent.RemoveAllForTableEx(tbTarget)
    if tbTarget == nil then
        return;
    end

    local delegateToRemoved = {}
    for delegate,arrayAdded in pairs(MultiDelegatesMapForRemove) do
        local arrayToRemoved = {}
        for index = #arrayAdded,1,-1 do
            local addedInfo = arrayAdded[index];
            if addedInfo.tb == tbTarget then
                delegate:Remove(LuaDelegateAgent:GetInstance(),addedInfo.agent)
                table.remove(arrayAdded,index);
            end
        end
        if #arrayAdded == 0 then
            table.insert(delegateToRemoved,delegate)
        end
    end

    for _,delegate in ipairs(delegateToRemoved) do
        MultiDelegatesMapForRemove[delegate] = nil;
    end
end

--delegate参数传递
function LuaDelegateAgent.CreateDelegateAgent(tbTarget,funcTarget,...)
    local params = {...}
    local delegate = {LuaDelegateAgent:GetInstance(),function(_,...)
        local _,rt = FuncUtil.CallFunc(tbTarget,funcTarget,params,...)
        return rt;
    end}
    return delegate
end

return LuaDelegateAgent
