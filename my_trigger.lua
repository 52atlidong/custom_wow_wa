function (allstates, event, ...)
  if event == "OPTIONS" then
    for i = 1, 2 do
      local spellID = i == 1 and 119381 or 179057
      local spellName = C_Spell.GetSpellInfo(spellID).name
      local icon = C_Spell.GetSpellInfo(spellID).iconID
      allstates[i] = {
        show = true,
        changed = true,
        unit = "player",
        spellName = spellName,
        next = i > 1,
        index = i,
        icon = icon
      }
    end
  end

  if event == "CHAT_MSG_ADDON" then
    local prefix, message, channel, sender = ...

    if prefix == "LYC_CC" then

      for _, state in pairs(allstates) do
        state.isPlayer = false
        state.changed = true
      end

      local arr = aura_env.Split(message, ";")
      
      for i, value in ipairs(arr) do
        local data = aura_env.Split(value, ",")
        local spellID = data[1]
        local guid = data[2]
        local unit = data[3]
        local duration = tonumber(data[4])
        local expirationTime = tonumber(data[5])

        local spellName = C_Spell.GetSpellInfo(spellID).name
        local icon = C_Spell.GetSpellInfo(spellID).iconID
        local isPlayer = guid == UnitGUID("player")
        allstates[i] = {
          show = true,
          changed = true,
          progressType = "timed",
          duration = duration,
          expirationTime = expirationTime,
          guid = guid,
          unit = unit,
          spellID = spellID,
          spellName = spellName,
          isPlayer = isPlayer,
          icon = icon,
          next = i > 1,
          index = i,
          autoHide = false
        }

        if i == 1 and isPlayer and spellID ~= aura_env.lastTtsSpellID then
          C_VoiceChat.SpeakText(1, spellName, Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
          aura_env.lastTtsSpellID = spellID
        end

      end
      return true
    end

  end

  if not aura_env.IsLeader() then return true end

  if event == "LYC_CC_TASK" then
    local id = ...
    if id ~= aura_env.id then return end
    for _, state in pairs(allstates) do
      state.show = false
      state.changed = true
    end
    local currTime = GetTime()
    local inCombat = InCombatLockdown()
    local currAssignedState = allstates[1]

    table.sort(
      aura_env.cooldownQueue,
      function (a, b)
        return aura_env.CooldownSort(a, b, currTime)
        -- print(v)
      end
    )

    local str = ""

    for i = 1, 2 do
      local cooldownData = aura_env.cooldownQueue[i]
      if cooldownData then
        local isReady = cooldownData.charges >= 1 or cooldownData.expirationTime <= currTime
        local guid = cooldownData.guid
        local spellName = C_Spell.GetSpellInfo(cooldownData.spellID).name
        -- local icon = C_Spell.GetSpellInfo(cooldownData.spellID).iconID
        local unit = cooldownData.unit
        -- allstates[i] = {
        --   show = true,
        --   changed = true,
        --   progressType = "timed",
        --   duration = cooldownData.duration,
        --   expirationTime = isReady and currTime or cooldownData.expirationTime,
        --   guid = guid,
        --   unit = unit,
        --   spellID = cooldownData.spellID,
        --   spellName = spellName,
        --   isPlayer = guid == UnitGUID("player"),
        --   icon = icon,
        --   next = i > 1,
        --   index = i,
        --   autoHide = false
        -- }

        str = str..cooldownData.spellID..","..guid..","..unit..","..cooldownData.duration..","..(isReady and currTime or cooldownData.expirationTime)
        if i == 1 then
          str = str..";"
        end
      end
    end

    C_ChatInfo.SendAddonMessage("LYC_CC", str, "PARTY")

    -- return true
  elseif event == "CooldownListUpdate" then
    local id = ...
    
    if id ~= aura_env.id then return end
    
    local changed = false

    local spells = aura_env.GetActiveSpellInfo()

    if spells then
      for _, value in ipairs(spells) do
        local guid = value.guid
        local unit = value.unit
        local spellID = value.spellID
        aura_env.UpdateEntry(unit, guid, spellID)
      end
    end

    if changed then
      WeakAuras.ScanEvents("LYC_CC_TASK", aura_env.id)
    end

  elseif event == "CooldownListWipe" then

    local id = ...
    
    if id ~= aura_env.id then return end

    aura_env.RebuildQueue()

  elseif event == "CooldownUpdate" or event == "CooldownAdded" then
    local id, unit, spellID, cooldownInfo = ...
    
    if id ~= aura_env.id then return end
    
    local spells = aura_env.GetActiveSpellInfo()

    if not spells then return end

    -- if not spells[unit][spellID] then return end

    for _, value in ipairs(spells) do
      if unit == value.unit and spellID == value.spellID then
        if aura_env.UpdateEntry(unit, value.guid, spellID) then
          WeakAuras.ScanEvents("LYC_CC_TASK", aura_env.id)
        end
      end
    end


  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, subEvent, _, _, _, _, _, destGUID = ...
    if subEvent == "UNIT_DIED" then
      for _, cooldownData in ipairs(aura_env.cooldownQueue) do
        if cooldownData.guid == destGUID then
          WeakAuras.ScanEvents("LYC_CC_TASK", aura_env.id)
          break
        end
      end
    end
  elseif event == "GROUP_ROSTER_UPDATE" then
    aura_env.RebuildQueue()
  elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
    -- WeakAuras.ScanEvents("LYC_CC_TASK", aura_env.id)
    aura_env.lastTtsSpellID = nil
    aura_env.RebuildQueue()
  elseif event == "CHALLENGE_MODE_START" or event == "STATUS" then
    aura_env.RebuildQueue()
  end
end

-- {
--   isPlayer = {
--     display = "is player",
--     type = "bool"
--   },
--   next = {
--     display = "Next",
--     type = "bool"
--   }
-- }

-- CooldownListUpdate, CooldownListWipe, CooldownUpdate, CooldownAdded, LYC_CC_TASK, GROUP_ROSTER_UPDATE, PLAYER_REGEN_ENABLED, CHALLENGE_MODE_START, CLEU:UNIT_DIED, TRIGGER:2
