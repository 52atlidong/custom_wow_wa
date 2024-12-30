-- 音频 - 马戏团 - LYC 触发器1
-- 自定义:事件:CHAT_MSG_ADDON

function (event, ...)
    local this = aura_env
    if "CHAT_MSG_ADDON" == event then
        local mxtPrefix = LYC_MAXITUAN.config.prefix
        local prefix, message, channel, sender = ...

        if prefix == mxtPrefix.."_DIE" then

            local strs = LYC_MAXITUAN.Split(message, ":")
            local unitInfo = LYC_MAXITUAN.Split(strs[1],",")
            local dieIsMe = UnitGUID("player") == unitInfo[1]
            if not dieIsMe then
                local role = unitInfo[4]
                this.role = role
                return true
            end
        end
    end
    return false
end

-- name 
function()
    if aura_env.role ~= nil then
        return aura_env.role
    end
end


for index, value in ipairs(state) do
    print(index..value)
end