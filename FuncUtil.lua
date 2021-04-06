

---@class FuncUtil
local FuncUtil = {}

function FuncUtil.CallFunc(tbTarget,funcTarget,paramsPack,...)
    local bOK,strErr;
    if (4 <= #paramsPack) then
        if (4 < #paramsPack) then
            error("too many param on func " .. funcTarget);
        end
        local _param_1 = select(1,table.unpack(paramsPack));
        local _param_2 = select(2,table.unpack(paramsPack));
        local _param_3 = select(3,table.unpack(paramsPack));
        local _param_4 = select(4,table.unpack(paramsPack));
        if tbTarget ~= nil then
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,tbTarget, _param_1,_param_2,_param_3,_param_4,...);
        else
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler, _param_1,_param_2,_param_3,_param_4,...);
        end
    elseif (3 <= #paramsPack) then
        local _param_1 = select(1,table.unpack(paramsPack));
        local _param_2 = select(2,table.unpack(paramsPack));
        local _param_3 = select(3,table.unpack(paramsPack));
        if tbTarget ~= nil then
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,tbTarget, _param_1,_param_2,_param_3,...);
        else
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler, _param_1,_param_2,_param_3,...);
        end
    elseif (2 <= #paramsPack) then
        local _param_1 = select(1,table.unpack(paramsPack));
        local _param_2 = select(2,table.unpack(paramsPack));
        if tbTarget ~= nil then
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,tbTarget, _param_1,_param_2,...);
        else
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler, _param_1,_param_2,...);
        end
    elseif (1 <= #paramsPack) then
        local _param_1 = select(1,table.unpack(paramsPack));
        if tbTarget ~= nil then
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,tbTarget, _param_1,...);
        else
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler, _param_1,...);
        end
    else
        if tbTarget ~= nil then
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,tbTarget,...);
        else
            bOK,strErr = xpcall(funcTarget, _G.Error_Handler,...);
        end
    end

    return bOK,strErr
end

return FuncUtil