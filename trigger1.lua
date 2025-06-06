function(allstates, event, ...)
  if event == "OPTIONS" then
    for i = 1, aura_env.config.myTurnOnly and 1 or 2 do
      local spellID = i == 1 and 119381 or 179057 -- Leg Sweep/Chaos Nova
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
  elseif event == "ASSIGNMENT_EVENT" then
    local id = ...
    
    if id ~= aura_env.id then return end
    
    for _, state in pairs(allstates) do
      state.show = false
      state.changed = true
    end
    
    local currentTime = GetTime()
    local inCombat = InCombatLockdown()
    local currentlyAssignedState = allstates[1]
    
    if not inCombat then return true end 
    
    table.sort(
      aura_env.cooldownQueue,
      function(dataA, dataB)
        
        local unitA = aura_env.GUIDToUnit[dataA.GUID]
        local unitB = aura_env.GUIDToUnit[dataB.GUID]
        
        
        
        local deadA = UnitIsDeadOrGhost(unitA)
        local deadB = UnitIsDeadOrGhost(unitB)
        
        local connectedA = UnitIsConnected(unitA)
        local connectedB = UnitIsConnected(unitB)
        
        local inRangeA = UnitInRange(unitA)
        local inRangeB = UnitInRange(unitB)
        
        local readyA = dataA.charges >= 1 or dataA.expirationTime <= currentTime
        local readyB = dataB.charges >= 1 or dataB.expirationTime <= currentTime
        
        local currentlyAssignedA = currentlyAssignedState and dataA.GUID == currentlyAssignedState.GUID and dataA.spellID == currentlyAssignedState.spellID
        local currentlyAssignedB = currentlyAssignedState and dataB.GUID == currentlyAssignedState.GUID and dataB.spellID == currentlyAssignedState.spellID
        
        if deadA ~= deadB then
          return deadB
        elseif connectedA ~= connectedB then
          return connectedA
        elseif inRangeA ~= inRangeB then
          return inRangeA
        elseif readyA ~= readyB then
          return readyA
        elseif readyA then
          if dataA.priority ~= dataB.priority then
            return dataA.priority < dataB.priority
          else
            return dataA.GUID < dataB.GUID
          end
        else
          if dataA.expirationTime ~= dataB.expirationTime then
            return dataA.expirationTime < dataB.expirationTime
          else
            return dataA.GUID < dataB.GUID
          end
        end
      end
    )
    
    for i = 1, aura_env.config.myTurnOnly and 1 or 2 do
      local cooldownData = aura_env.cooldownQueue[i]
      
      if cooldownData and (not aura_env.config.myTurnOnly or cooldownData.GUID == WeakAuras.myGUID) then
        
        
        local isReady = cooldownData.charges >= 1 or cooldownData.expirationTime <= currentTime
        local GUID = cooldownData.GUID
        local spellName = C_Spell.GetSpellInfo(cooldownData.spellID).name
        
        local isPartyChatAnnouncementEnabled = aura_env.config.general_settings.enable_party_chat_announcement
        
        local icon = C_Spell.GetSpellInfo(cooldownData.spellID).iconID
        
        local unit = aura_env.GUIDToUnit[GUID]
        
        local playerName = UnitName(unit)
        
        
        if (currentTime - aura_env.lastMessageTime >= 5) and isReady then
          -- Update the last message sent time
          aura_env.lastMessageTime = currentTime
          
          -- Send the message to chat if the party chat is enabled
          if isPartyChatAnnouncementEnabled then
            SendChatMessage("[M+] Next CC: " .. playerName .. " - " .. spellName, "PARTY")
          end
        end
        
        
        
        
        allstates[i] = {
          show = true,
          changed = true,
          progressType = "timed",
          duration = cooldownData.duration,
          expirationTime = isReady and currentTime or cooldownData.expirationTime,
          GUID = GUID,
          unit = unit,
          isPlayer = UnitIsUnit(unit, "player"),
          spellID = cooldownData.spellID,
          spellName = spellName,
          type = cooldownData.type,
          icon = icon,
          next = i > 1,
          index = i,
          autoHide = false
        }
      end
    end
    
    if aura_env.config.tts then
      local nextAssignment = allstates[1]
      
      if not (nextAssignment and nextAssignment.show) then return true end
      
      local isMyAssignment = nextAssignment.GUID == WeakAuras.myGUID
      local playerChanged = nextAssignment.GUID ~= aura_env.lastAssignment.GUID
      local spellChanged = nextAssignment.spellID ~= aura_env.lastAssignment.spellID
      
      if isMyAssignment and (playerChanged or spellChanged) then
        C_VoiceChat.SpeakText(
          aura_env.config.ttsVoice,
          "Next",
          Enum.VoiceTtsDestination.LocalPlayback,
          C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
          aura_env.config.ttsVolume
        )
      end
      
      aura_env.lastAssignment.GUID = nextAssignment.GUID
      aura_env.lastAssignment.spellID = nextAssignment.spellID
    end
    
    return true
  elseif event == "TRIGGER" then
    local _, states = ...
    
  elseif event == "CooldownListUpdate" then
    local id, unit, unitCooldowns = ...
    
    if id ~= aura_env.id then return end
    
    local changed = false
    
    if unitCooldowns then
      for spellID, cooldownInfo in pairs(unitCooldowns) do
        if aura_env.UpdateEntry(unit, spellID, cooldownInfo) then
          changed = true
        end
      end
    end
    
    if changed then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end
  elseif event == "CooldownListWipe" then
    local id = ...
    
    if id ~= aura_env.id then return end
    
    aura_env.RebuildQueue()
  elseif event == "CooldownUpdate" then
    local id, unit, spellID, cooldownInfo = ...
    
    if id ~= aura_env.id then return end
    
    if aura_env.UpdateEntry(unit, spellID, cooldownInfo) then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end
  elseif event == "CooldownAdded" then
    local id, unit, spellID, cooldownInfo = ...
    
    if id ~= aura_env.id then return end
    
    if aura_env.UpdateEntry(unit, spellID, cooldownInfo) then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, subEvent, _, _, _, _, _, destGUID = ...
    
    if subEvent == "UNIT_DIED" and aura_env.GUIDToUnit[destGUID] then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end
  elseif event == "CLEU:UNIT_DIED" then
    local _, subEvent, _, _, _, _, _, destGUID = ...
    
    if subEvent == "UNIT_DIED" and aura_env.GUIDToUnit[destGUID] then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end
  elseif event == "GROUP_ROSTER_UPDATE" then
    local changed = false
    
    aura_env.GUIDToUnit = {}
    
    for unit in WA_IterateGroupMembers() do
      aura_env.GUIDToUnit[UnitGUID(unit)] = unit
    end
    
    for i, cooldownData in ipairs_reverse(aura_env.cooldownQueue) do
      if not aura_env.GUIDToUnit[cooldownData.GUID] then
        table.remove(aura_env.cooldownQueue, i)
        
        changed = true
      end
    end
    
    if changed then
      WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
    end    
  elseif event == "PLAYER_REGEN_ENABLED" then
    aura_env.lastAssignment = {}
    WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
  elseif event == "PLAYER_REGEN_DISABLED" then
    WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
  elseif event == "CHALLENGE_MODE_START" or event == "STATUS" then
    aura_env.lastAssignment = {}
    aura_env.GUIDToUnit = {}
    
    for unit in WA_IterateGroupMembers() do
      aura_env.GUIDToUnit[UnitGUID(unit)] = unit
    end
    
    aura_env.RebuildQueue()
  end
end

-- {
--   isPlayer = {
--     display = "Unit Is Player",
--     type = "bool"
--   },
--   next = {
--     display = "Next",
--     type = "bool"
--   }
-- }

