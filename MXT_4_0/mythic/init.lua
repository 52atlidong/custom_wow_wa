-- 大秘境模块init
local this = aura_env

-- 溢出伤害记录
this.overkillSources = {}

-- 大秘境是否正在进行
local isMythicOngoing = false

-- 死亡统计
local dieStatistical = {}

-- 自己的guid
local myGuid = UnitGUID("player")
local myUnitName = UnitName("player")
-- 死亡总数
local totalDieCount = 0

local function ResetData()
  dieStatistical = {}
  totalDieCount = 0
end

-- 处理大秘境开始
function this.HandleStartMythic()

  local prefix = LYC_MAXITUAN.config.prefix or "MXT"

  ResetData()
  local numMembers = (#LYC_MAXITUAN.party) + 1

  local nicknames = LYC_MAXITUAN.config.nickname

  for guid, info in ipairs(LYC_MAXITUAN.party) do
    nicknames = nicknames + ","..(info.nickname)
  end

  if numMembers >= 5 then
    isMythicOngoing = true
    local res = C_ChatInfo.SendAddonMessage(prefix.."_M_START", nicknames, "PARTY")
  end
end

-- 处理有人死亡
function this.HandleDie(guid, overkillSource)

  local prefix = LYC_MAXITUAN.config.prefix or "MXT"

  if not isMythicOngoing then
    -- 大秘境未开始
    return
  end

  local info = LYC_MAXITUAN.party[guid]

  if guid ~=  (not info) then
    -- 不是团员死亡
    return
  end

  totalDieCount = totalDieCount + 1
  
  if not dieStatistical[guid] then
    dieStatistical[guid] = 0
  end

  dieStatistical[guid] = dieStatistical[guid] + 1

  local nickname = guid == myGuid and LYC_MAXITUAN.config.nickname or info.nickname
  local unitName = guid == myGuid and myUnitName or info.unitName

  -- UnitGroupRolesAssigned("player")

  local deadUnit

  for i = 0, 4, 1 do
    local unit = i == 0 and "player" or "party"..i
    if guid == UnitGUID(unit) then
      deadUnit = unit
    end
  end

  -- guid,nickname,unitName,DPS:dieType,spellID:dieCount,totalDieCount
  C_ChatInfo.SendAddonMessage(prefix.."_DIE", guid..","..nickname..","..unitName..","..UnitGroupRolesAssigned(deadUnit)..":"..overkillSource..":"..dieStatistical[guid]..":"..totalDieCount, "PARTY")
  -- /run C_ChatInfo.SendAddonMessage("MXT_DIE", UnitGUID("player")..",".."尼"..","..UnitName("player")..":SWING:"..(1)..","..1, "PARTY")
end

