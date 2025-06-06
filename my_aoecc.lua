local this = aura_env

this.cooldownQueue = {}

local LibOpenRaid = LibStub:GetLibrary("LibOpenRaid-1.0")

function this.Split(input, delimiter)
  local pos, arr = 0, {}
  for st, sp in function() return string.find(input, delimiter, pos, true) end do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end

function this.IsLeader()
  if not (IsInGroup(5) and UnitIsGroupLeader("player")) then return false end
  return true
end

if not this.region.callbacksRegistered then
  local id = this.id
  local callbacks = {
    CooldownListUpdate = function(...) WeakAuras.ScanEvents("CooldownListUpdate", id, ...) end,
    CooldownListWipe = function(...) WeakAuras.ScanEvents("CooldownListWipe", id, ...) end,
    CooldownUpdate = function(...) WeakAuras.ScanEvents("CooldownUpdate", id, ...) end,
    CooldownAdded = function(...) WeakAuras.ScanEvents("CooldownAdded", id, ...) end
  }

  LibOpenRaid.RegisterCallback(callbacks, "CooldownListUpdate", "CooldownListUpdate")
  LibOpenRaid.RegisterCallback(callbacks, "CooldownListWipe", "CooldownListWipe")
  LibOpenRaid.RegisterCallback(callbacks, "CooldownUpdate", "CooldownUpdate")
  LibOpenRaid.RegisterCallback(callbacks, "CooldownAdded", "CooldownAdded")

  this.region.callbacksRegistered = true
end

function this.GetActiveSpellInfo()
  if not this.IsLeader() then return nil end

  local E = OmniCD[1]
  local P = E.Party

  local activeExBars = P.activeExBars
  local extraBarKeys = P.extraBarKeys

  local aoeCCIndex = E.profile.Party["party"].frame["aoeCC"]

  local exKey = extraBarKeys[aoeCCIndex]

  local exBar = activeExBars[exKey]

  local spellInfos = {}
  if exBar then
    local icons = exBar.icons
    for _, icon in ipairs(icons) do
      local guid = icon.guid
      local spellID = icon.spellID
      local unit = icon.unit

      table.insert(
        spellInfos,
        {
          spellID = spellID,
          guid = guid,
          unit = unit
        }
      )

      -- if not spellInfos[unit] then
      --   spellInfos[unit] = {}
      -- end
      -- spellInfos[unit][spellID] = {
      --   priority = 1,
      --   guid = guid
      -- }
    end
    return spellInfos
  end
  return nil
end

function this.UpdateEntry(unit, guid, spellID, index)
  if not guid then return end
  if not spellID then return end
  if not this.cooldownQueue then return end

  local _, _, timeLeft, charges, _, _, _, duration = LibOpenRaid.GetCooldownStatusFromUnitSpellID(unit, spellID)

  for _, cooldownData in ipairs(this.cooldownQueue) do
    if cooldownData.guid == guid and cooldownData.spellID == spellID then
      cooldownData.expirationTime = timeLeft + GetTime()
      cooldownData.duration = duration
      cooldownData.charges = charges
      return true
    end
  end

  table.insert(
    this.cooldownQueue,
    {
      guid = guid,
      unit = unit,
      spellID = spellID,
      expirationTime = timeLeft + GetTime(),
      index = index,
      duration = duration,
      charges = charges
    }
  )
  return true
end

function this.RebuildQueue()
  this.cooldownQueue = {}
  local spells = this.GetActiveSpellInfo()
  if spells then
    for index, value in ipairs(spells) do
      local guid = value.guid
      local unit = value.unit
      local spellID = value.spellID
      this.UpdateEntry(unit, guid, spellID, index)
    end
    -- for unit, spell in pairs(spells) do
    --   for spellID, detail in pairs(spell) do
    --     local guid = detail.guid
    --     this.UpdateEntry(unit, guid, spellID)
    --   end
    -- end
  end

  -- print("RebuildQueue" .. (#this.cooldownQueue))

  WeakAuras.ScanEvents("LYC_CC_TASK", this.id)
end

function this.CooldownSort(a, b, currTime)
  local unitA = a.unit
  local unitB = b.unit

  local deadA = UnitIsDeadOrGhost(unitA)
  local deadB = UnitIsDeadOrGhost(unitB)

  local connectedA = UnitIsConnected(unitA)
  local connectedB = UnitIsConnected(unitB)

  local inRangeA = UnitInRange(unitA)
  local inRangeB = UnitInRange(unitB)

  local readyA = a.charges >= 1 or a.expirationTime <= currTime
  local readyB = b.charges >= 1 or b.expirationTime <= currTime

  if deadA ~= deadB then
    return deadB
  elseif connectedA ~= connectedB then
    return connectedA
  elseif inRangeA ~= inRangeB then
    return inRangeA
  elseif readyA ~= readyB then
    return readyA
  elseif readyA then
    if a.index ~= b.index then
      return a.index < b.index
    else
      return a.guid < b.guid
    end
  else
    if a.expirationTime ~= b.expirationTime then
      return a.expirationTime < b.expirationTime
    else
      return a.guid < b.guid
    end
  end
end

-- 注册
C_ChatInfo.RegisterAddonMessagePrefix("LYC_CC")

aura_env.lastTtsSpellID = nil
