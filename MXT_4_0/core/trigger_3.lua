-- 核心 - 马戏团 - LYC 触发器3
-- 自定义:事件:CHAT_MSG_ADDON

function (event, ...)
  local this = aura_env
  if "CHAT_MSG_ADDON" == event then
    local prefix, message, channel, sender = ...
    if prefix == "MXT_INFO_REQ" then
      print(message.."."..channel.."."..sender)
      
      if LYC_MAXITUAN.config and LYC_MAXITUAN.config.nickname then
        -- 发送昵称过去
        local res = C_ChatInfo.SendAddonMessage("MXT_INFO_RES", LYC_MAXITUAN.config.nickname, "WHISPER", sender)
        -- print("Send nickname to "..sender.." result:"..res)
        
        if message == "1" and LYC_MAXITUAN.config.msgEnterParty then
          SendChatMessage(LYC_MAXITUAN.config.msgEnterParty, "PARTY")
        end
        
      end
    elseif prefix == "MXT_INFO_RES" then
      -- print("received nickname: "..message.."from "..sender)
      this.HandleInfoRes(message, sender)
    end
  end
end


