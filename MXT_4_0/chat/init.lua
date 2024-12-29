local this = aura_env

local function RandomMsg(message)
    local messages = LYC_MAXITUAN.Split(message, "\n")
    return messages[math.random(#messages)]
end

function this.GetConfigMsg(key)
    if LYC_MAXITUAN and LYC_MAXITUAN.config and LYC_MAXITUAN.config[key] then
        local message = LYC_MAXITUAN.config[key]
        return RandomMsg(message)
    end
    return nil
end

function this.FormatDieMsg(msg, name, reason)
    msg = string.gsub(msg, "%%p", name)
    msg = string.gsub(msg, "%%r", reason)
    return msg
end

function this.FormatMstartMsg(msg, nicknames)
    
    for index, nickname in ipairs(nicknames) do
        msg = string.gsub(msg, "%%p"..index, nickname)
    end
    return msg
end