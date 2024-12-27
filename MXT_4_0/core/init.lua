-- 核心初始化 START prefix LYC_MAXITUAN
-- config
-- name:key:type
-- 前缀:prefix:string
-- 昵称:nickname:string
-- 队长开场白:msgMythicStartLeader:string[]
-- 队员开场白:msgMythicStartNormal:string[]
-- 死亡文案:msgYouDie:string[]
-- 其他人死亡文案:msgOtherDie:string[]
-- 坠落死亡:msgYouDieByFalling:string[]
-- 队友坠落死亡:msgOtherDieByFalling:string[]
-- 环境火焰死亡:msgYouDieByFire:string[]
-- 队友环境火焰死亡:msgOtherDieByFire:string[]
-- 队友死亡物品使用ID:useItemID:string

local this = aura_env

LYC_MAXITUAN = LYC_MAXITUAN or {}

local config = this.config

local prefix = config.prefix or "MXT"

this.numGroupMembers = 0

function LYC_MAXITUAN.Split(input, delimiter)
  local pos, arr = 0, {}
  for st, sp in function() return string.find(input, delimiter, pos, true) end do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end

LYC_MAXITUAN.config = config
-- 成员信息
LYC_MAXITUAN.party = {}

-- 团员信息请求
C_ChatInfo.RegisterAddonMessagePrefix(prefix.."_INFO_REQ")
-- 团员信息返回
C_ChatInfo.RegisterAddonMessagePrefix(prefix.."_INFO_RES")
-- 大秘境开始
C_ChatInfo.RegisterAddonMessagePrefix(prefix.."_M_START")
-- 有人死亡
C_ChatInfo.RegisterAddonMessagePrefix(prefix.."_DIE")

-- 初始化完成 发送时间
WeakAuras.ScanEvents("EVENT_LYC_MAXITUAN_INITIALIZED")

-- 组队状态变更时 校验队伍数据
function this.CheckGroupMembers()
  local numGroupMembers = GetNumGroupMembers()
  if numGroupMembers == 0 then
    LYC_MAXITUAN.party = {}
    print("队伍解散")
  elseif numGroupMembers > 1 then
    -- 如果是队长 遍历队伍成员检查成员信息
    if UnitIsGroupLeader("player") then
      -- 是否需要欢迎
      local needWelcome = this.numGroupMembers ~= numGroupMembers
      
      local realGuidTable = {}
      
      for i = 1, 4, 1 do
        local unit = "party" .. i
        local guid = UnitGUID(unit)
        -- 判断是否是玩家
        if guid and strfind(guid, "Player") then
          realGuidTable[guid] = guid
          -- 没有数据发送消息请求数据
          if not LYC_MAXITUAN.party[guid] then
            -- 对暗号
            local res = C_ChatInfo.SendAddonMessage(prefix.."_INFO_REQ", needWelcome and "1" or "0", "WHISPER",
              UnitName(unit))
            print("发送"..(prefix.."_INFO_REQ") .. UnitName(unit) .. "状态" .. ":" .. res)
          end
        end
      end
      
      for guid, _ in ipairs(LYC_MAXITUAN.party) do
        if not realGuidTable[guid] then
          local info = LYC_MAXITUAN.party[guid]
          print("队友: "..info.unitName..", nickname: "..info.nickname.." 退出队伍")
          LYC_MAXITUAN.party[guid] = nil
        end
      end
      
    end
  else
    print("队伍创建")
  end
  this.numGroupMembers = numGroupMembers
end

-- 收到团员昵称消息
function this.HandleInfoRes(nickname, sender)
  for i = 1, 4, 1 do
    local unit = "party" .. i
    local guid = UnitGUID(unit)
    
    if guid and strfind(guid, "Player") then
      local unitName = UnitName(unit)
      if sender == unitName or LYC_MAXITUAN.Split(sender, "-")[1] == unitName then
        local info = {}
        info.nickname = nickname
        info.unitName = unitName
        LYC_MAXITUAN.party[guid] = info
        print("Set guid: "..guid.." nickname: "..nickname.."成功")
      end
    end
    
    print("当前队伍团员个数"..(#LYC_MAXITUAN.party))
    
  end
end

-- 核心初始化 END

