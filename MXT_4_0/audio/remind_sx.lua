-- 提醒嗜血 - 马戏团 - LYC 触发器1
-- 自定义:事件:CHAT_MSG_ADDON

-- C_ChatInfo.SendAddonMessage("MXT_N_SX", "SX", "PARTY")

function (event, ...)
    local this = aura_env
    if "CHAT_MSG_ADDON" == event then
        local mxtPrefix = LYC_MAXITUAN.config.prefix
        local prefix, message, channel, sender = ...
        if prefix == mxtPrefix.."_N_SX" then
            return true
        end
    end
end