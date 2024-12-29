-- 垃圾话 - 马戏团 - LYC 触发器2
-- 自定义:事件:CHAT_MSG_ADDON

function (event, ...)
    local this = aura_env

    if "CHAT_MSG_ADDON" == event then
        local mxtPrefix = LYC_MAXITUAN.config.prefix
        local prefix, message, channel, sender = ...

        if not UnitIsGroupLeader("player") then
            return false
        end

        if prefix == mxtPrefix.."_DIE" then
            print("received die message:"..message)
            local strs = LYC_MAXITUAN.Split(message, ":")
            local unitInfo = LYC_MAXITUAN.Split(strs[1],",")
            local dieInfo = LYC_MAXITUAN.Split(strs[2], ",")
            local dieCountInfo = LYC_MAXITUAN.Split(strs[3], ",")

            local role = unitInfo[4]
            local nickname = unitInfo[2]
            local dieType = dieInfo[1]
            if dieType == "SWING" then
                -- 近战
                -- C_ChatInfo.SendAddonMessage("MXT_DIE", UnitGUID("player")..",".."尼"..","..UnitName("player")..",TANK"..":SWING:"..(1)..","..1, "PARTY")
                local msg = this.GetConfigMsg(role == "TANK" and "msgDieTank" or "msgDieSwing")
                if msg then
                    SendChatMessage(this.FormatDieMsg(msg, nickname, "近战攻击"), "PARTY")
                end
            elseif dieType == "Falling" then
                -- 坠落
                -- C_ChatInfo.SendAddonMessage("MXT_DIE", UnitGUID("player")..",".."尼"..","..UnitName("player")..",DPS"..":Falling:"..(1)..","..1, "PARTY")
                local msg = this.GetConfigMsg("msgDieFalling")
                if msg then
                    SendChatMessage(this.FormatDieMsg(msg, nickname, ""), "PARTY")
                end
            elseif dieType == "Fire" then
                -- 环境火焰
                -- C_ChatInfo.SendAddonMessage("MXT_DIE", UnitGUID("player")..",".."尼"..","..UnitName("player")..",DPS"..":Fire:"..(1)..","..1, "PARTY")
                local msg = this.GetConfigMsg("msgDieFire")
                if msg then
                    SendChatMessage(this.FormatDieMsg(msg, nickname, ""), "PARTY")
                end
            elseif dieType == "SPELL" then
                -- 法术
                -- C_ChatInfo.SendAddonMessage("MXT_DIE", UnitGUID("player")..",".."尼"..","..UnitName("player")..",TANK"..":SPELL,462439:"..(1)..","..1, "PARTY")
                local spellID = dieInfo[2]
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                if LYC_MAXITUAN and LYC_MAXITUAN.avoidable[tonumber(spellID)] then
                    -- 该躲不躲
                    local msg = this.GetConfigMsg("msgDieAvoidable")
                    if msg then
                        SendChatMessage(this.FormatDieMsg(msg, nickname, spellInfo.name), "PARTY")
                    end
                else
                    local msg = this.GetConfigMsg(role == "TANK" and "msgDieTank" or "msgDie")
                    if msg then
                        SendChatMessage(this.FormatDieMsg(msg, nickname, spellInfo.name), "PARTY")
                    end
                end
            end
        elseif prefix == mxtPrefix.."_M_START" then
            print("received m start message:"..message)
            -- 大秘境开始
            -- C_ChatInfo.SendAddonMessage("MXT_M_START", "尼,鹏,龙,萍,远", "PARTY")

            local nicknames = LYC_MAXITUAN.Split(message, ",")
            local msg = this.GetConfigMsg("msgMythicStart")
            if msg then
                msg = this.FormatMstartMsg(msg, nicknames)
                print(msg)
                SendChatMessage(msg, "PARTY")
            end
        end
    end
end