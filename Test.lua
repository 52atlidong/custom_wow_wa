-- 大秘境方法
local this = aura_env

-- 大米是否已开始
local mythicStarted = false

-- 死亡次数
local dieNums = {}

local overkill = {}

local tankDie = false

local totalDieNum = 0

local playerGuid = UnitGUID("player")

local tankGuid = nil
-- local deathMessages = { "这Z炮怎么压到我的", "我畜两下怎么了？",  "我大死特死了!!", "我被怪邦邦两拳，像蛆一样死掉了！", "我是猪，被宰了!!" , "我成ATM了!!!", "全完了，我超鬼了！！！！" }

local function diePlus(GUID)
  if dieNums[GUID] == nil then
    dieNums[GUID] = 1
  else
    dieNums[GUID] = dieNums[GUID] + (tankGuid == GUID and 3 or 1)
  end
end

-- 大秘境开始
function this.mythicStart()
  totalDieNum = 0
  dieNums = {}
  
  local maxituanLength = MAXITUAN.tableLength(MAXITUAN.party, function(k, v)
      return MAXITUAN.battleAccounts[v.battleTag] ~= nil
  end)
  
  local partyNum = GetNumGroupMembers()
  
  tankGuid = nil
  
  -- tank职责Guid
  for i = 0, partyNum - 1 do
    local GUID = i == 0 and playerGuid or UnitGUID("party" .. i)
    if UnitGroupRolesAssigned(i == 0 and "player" or "party" .. i) == "TANK" then
      tankGuid = GUID
    end
  end
  
  -- print("TankGuid: ")
  -- print(tankGuid)
  
  if maxituanLength >= MAXITUAN.memberMinCount then
    mythicStarted = true
    MAXITUAN.sendMessageMustLeader("马戏团开始团建[" .. maxituanLength .. "人]！畜之大舞台，能畜你就来")
  else
    --        print("成员不足，不统计")
  end
end

function this.someoneDead(GUID)
  if not mythicStarted then
    -- print("未开始大秘境")
    return
  end
  
  if MAXITUAN.party[GUID] == nil then
    --        print("不是队友死亡")
    return
  end
  
  local accountInfo = MAXITUAN.party[GUID]
  
  if MAXITUAN.battleAccounts[accountInfo.battleTag] == nil then
    print("不是成员死亡")
    return
  end
  local nickname = MAXITUAN.battleAccounts[accountInfo.battleTag]
  
  if GUID == tankGuid then
    tankDie = true
  end
  
  totalDieNum = totalDieNum + 1
  
  local sourcename = overkill[GUID] or "怪"
  local messageCount = MAXITUAN.tableLength(MAXITUAN.diedMessages, function ()
      return true
  end)
  local message = MAXITUAN.diedMessages[math.random(messageCount)]
  message = string.gsub(message, "甲", nickname)
  message = string.gsub(message, "乙", sourcename)
  MAXITUAN.sendMessageMustLeader(message)
  diePlus(GUID)
  
  WeakAuras.ScanEvents("MAXITUAN_PARTY_DIE", GUID, nickname, tankGuid, tankDie)
end

function this.mythicCompleted()
  if mythicStarted ~= true then
    return
  end
  
  local sortedKeys = MAXITUAN.getKeysSortByValue(dieNums, function(a, b)
      return a > b
  end)
  
  MAXITUAN.sendMessageMustLeader("午夜马戏团完美谢幕，看看谁是大畜")
  
  if totalDieNum <= 0 then
    C_Timer.After(1, function()
        MAXITUAN.sendMessageMustLeader("我敲，没人犯畜，这马戏团趁早解散")
    end)
  else
    local i = 1
    local dachuPlayer = nil
    for _, GUID in ipairs(sortedKeys) do
      local count = dieNums[GUID]
      local accountInfo = MAXITUAN.party[GUID]
      if accountInfo ~= nil then
        if dachuPlayer == nil then
          dachuPlayer = accountInfo
        end
        local nickname = MAXITUAN.battleAccounts[accountInfo.battleTag]
        C_Timer.After(i * 0.1, function()
            MAXITUAN.sendMessageMustLeader((nickname) .. "畜了" .. count .. "次")
        end)
      end
      i = i + 1
    end
    if dachuPlayer ~= nil then
      local nickname = MAXITUAN.battleAccounts[dachuPlayer.battleTag]
      C_Timer.After((i + 1) * 0.1, function()
          MAXITUAN.sendMessageMustLeader("本次大畜是" .. nickname)
      end)
      if dachuPlayer == "尼畜" then
        C_Timer.After((i + 2) * 0.1, function()
            MAXITUAN.sendMessageMustLeader("不愧是马戏团团长，啧啧啧")
        end)
      else
        C_Timer.After((i + 2) * 0.1, function()
            MAXITUAN.sendMessageMustLeader("你是要竞选马戏团团长吗？畜成这样")
        end)
      end
    end
  end
end

-- 进入战斗
function this.enterBattle()
  tankDie = false
end

function this.overkill(GUID, name)
  overkill[GUID] = name
end

-- function this.split(input, delimiter)
--     local pos, arr = 0, {}
--     for st, sp in function() return string.find(input, delimiter, pos, true) end do
--         table.insert(arr, string.sub(input, pos, st - 1))
--         pos = sp + 1
--     end
--     table.insert(arr, string.sub(input, pos))
--     return arr
-- end

-- /run C_VoiceChat.SpeakText(0, "你他妈又犯畜了", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)

