if not aura_env.saved then aura_env.saved = {} end

if not aura_env.config.general_settings.enable_weakaura then return end

local aura_env = aura_env
local auraData = WeakAuras.GetData(aura_env.id)
local auraVersion = auraData.version or 0

local LibOpenRaid = LibStub:GetLibrary("LibOpenRaid-1.0")
local AceComm = LibStub("AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

-- Cooldowns in the order they are listed in custom options
local orderedCooldowns = {
  {spellID = 368970, type = "DISPLACEMENT"}, -- Evoker: Tail Swipe
  {spellID = 192058, type = "STUN"}, -- Shaman: Capacitor Totem
  {spellID = 179057, type = "STUN"}, -- Demon Hunter: Chaos Nova
  {spellID = 119381, type = "STUN"}, -- Monk: Leg Sweep
  {spellID = 46968, type = "STUN"}, -- Warrior: Shockwave
  {spellID = 30283, type = "STUN"}, -- Warlock: Shadowfury
  {spellID = 8122, type = "FEAR"}, -- Priest: Psychic Scream
  {spellID = 115750, type = "DISORIENT"}, -- Paladin: Blinding Light
  {spellID = 99, type = "INCAPACITATE", specIDs = {
      [103] = true, -- Feral
      [104] = true, -- Guardian
      [105] = true, -- Restoration
    }
  }, -- Druid: Incapacitating Roar
  {spellID = 2094, type = "DISORIENT"}, -- Rogue: Blind (with Airborne Irritant)
  {spellID = 31661, type = "DISORIENT"}, -- Mage: Dragon's Breath
  {spellID = 5246, type = "FEAR"}, -- Warrior: Intimidating Shout
  {spellID = 207167, type = "DISORIENT"}, -- Death Knight: Blinding Sleet
  {spellID = 207684, type = "FEAR"}, -- Demon Hunter: Sigil of Misery
  {spellID = 197214, type = "INCAPACITATE"}, -- Shaman: Sundering
  {spellID = 157981, type = "DISPLACEMENT"}, -- Mage: Blast Wave
  {spellID = 51490, type = "DISPLACEMENT"}, -- Shaman: Thunderstorm
  {spellID = 132469, type = "DISPLACEMENT"}, -- Druid: Typhoon
  {spellID = 255654, type = "DISPLACEMENT"}, -- Highmountain Tauren: Bull Rush
  {spellID = 116844, type = "DISPLACEMENT"}, -- Monk: Ring of Peace
  {spellID = 357214, type = "DISPLACEMENT"}, -- Evoker: Wing Buffet
  {spellID = 202138, type = "DISPLACEMENT"}, -- Demon Hunter: Sigil of Chains
  {spellID = 99, type = "INCAPACITATE", specIDs = {
      [102] = true, -- Balance
    }
  }, -- Druid: Incapacitating Roar
  {spellID = 202137, type = "SILENCE"}, -- Demon Hunter: Sigil of Silence
}

-- Transform the ordered cooldowns table to a format that is more suitable to what we want to do (indexed by spell ID)
local trackedCooldowns = {}

for priority, cooldownInfo in ipairs(orderedCooldowns) do
  local spellID = cooldownInfo.spellID
  local specIDs = cooldownInfo.specIDs
  
  if specIDs then -- Spec specific priorities
    if not trackedCooldowns[spellID] then trackedCooldowns[spellID] = {} end
    
    for specID in pairs(specIDs) do
      trackedCooldowns[spellID][specID] = {type = cooldownInfo.type, priority = priority}
    end
  else -- Same priority for all specs
    trackedCooldowns[spellID] = {type = cooldownInfo.type, priority = priority}
  end
end

-- If a priority profile is selected in custom options, override the default priorities with it
local activeProfileName = aura_env.config.activeProfile

if activeProfileName ~= "" then
  for _, profile in ipairs(aura_env.config.profiles) do
    if profile.name == activeProfileName then
      for priority = 1, #orderedCooldowns do
        local enabled = profile["enable" .. priority] -- Set priority to -1 if disabled
        local cooldownIndex = profile[tostring(priority)]
        local cooldownInfo = orderedCooldowns[cooldownIndex]
        
        local spellID = cooldownInfo.spellID
        local specIDs = cooldownInfo.specIDs
        
        if specIDs then -- Spec specific priorities
          for specID in pairs(specIDs) do
            trackedCooldowns[spellID][specID].priority = enabled and priority or -1
          end
        else -- Same priority for all specs
          trackedCooldowns[spellID].priority = enabled and priority or -1
        end
      end
      
      break
    end
  end
end

-- Register LibOpenRaid callbacks
if not aura_env.region.callbacksRegistered then
  local id = aura_env.id
  
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
  
  aura_env.region.callbacksRegistered = true
end

-- Update an entry in the queue, or create it if it did not exist yet
function aura_env.UpdateEntry(unit, spellID, cooldownInfo)
  if not unit then return end
  if not UnitExists(unit) then return end
  if not spellID then return end
  if not trackedCooldowns[spellID] then return end
  if not cooldownInfo then return end
  if not aura_env.cooldownQueue then return end
  
  local GUID = UnitGUID(unit)
  local _, _, timeLeft, charges, _, _, _, duration = LibOpenRaid.GetCooldownStatusFromCooldownInfo(cooldownInfo)
  
  -- Try to update existing entry
  for _, cooldownData in ipairs(aura_env.cooldownQueue) do
    if cooldownData.GUID == GUID and cooldownData.spellID == spellID then
      cooldownData.expirationTime = timeLeft + GetTime()
      cooldownData.duration = duration
      cooldownData.charges = charges
      
      return true
    end
  end
  
  -- Create new entry
  local specID = WeakAuras.SpecForUnit(unit)
  local trackedCooldown = trackedCooldowns[spellID][specID] or trackedCooldowns[spellID]
  
  -- Only add entries that are enabled
  -- Disabled entries (in custom options) have a priority of -1
  if trackedCooldown.priority ~= -1 then
    table.insert(
      aura_env.cooldownQueue,
      {
        GUID = GUID,
        spellID = spellID,
        priority = trackedCooldown.priority,
        type = trackedCooldown.type,
        expirationTime = timeLeft + GetTime(),
        duration = duration,
        charges = charges
      }
    )
    
    return true
  end
end

function aura_env.printTable(tbl, indent)
  -- Set default indent to an empty string if not provided
  indent = indent or ""
  -- Check if the input is a table
  if type(tbl) ~= "table" then
    print(indent .. tostring(tbl))
    return
  end
  
  for key, value in pairs(tbl) do
    -- Format the key and value for printing
    local formattedKey = tostring(key)
    -- Check if the value is a table
    if type(value) == "table" then
      print(indent .. formattedKey .. ":")
      -- Recursively call printTable with a larger indent
      printTable(value, indent .. "  ")
    else
      print(indent .. formattedKey .. ": " .. tostring(value))
    end
  end
end

-- Rebuild the cooldown queue and request cooldown information for each entry
function aura_env.RebuildQueue()
  if aura_env.lastRebuild and aura_env.lastRebuild == GetTime() then return end
  
  aura_env.cooldownQueue = {}
  
  local allUnitsCooldown = LibOpenRaid.GetAllUnitsCooldown()
  
  if allUnitsCooldown then
    for unit, unitCooldowns in pairs(allUnitsCooldown) do
      for spellID, cooldownInfo in pairs(unitCooldowns) do
        if trackedCooldowns[spellID] then
          aura_env.UpdateEntry(unit, spellID, cooldownInfo)
        end
      end
    end
  end
  
  WeakAuras.ScanEvents("ASSIGNMENT_EVENT", aura_env.id)
end

-- Broadcasts your priority profile to the group
function aura_env.BroadcastProfile()
  if not (IsInGroup() and UnitIsGroupLeader("player")) then return end -- Only broadcast your profile when you are the group leader
  
  local serialized = LibSerialize:Serialize(trackedCooldowns)
  local compressed = LibDeflate:CompressDeflate(serialized)
  local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
  
  local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"
  
  AceComm:SendCommMessage("CCR_Broadcast", encoded, chatType)
end

-- Receives a priority profile from the group leader
local function ReceiveProfile(payload)
  if not aura_env.config.inherit then return end
  
  local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
  if not decoded then return end
  
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then return end
  
  local success, data = LibSerialize:Deserialize(decompressed)
  if not success then return end
  
  trackedCooldowns = data
  
  aura_env.RebuildQueue() -- Rebuild queue with updated priorities
end

-- Requests the priority profile from the group leader, if specified in custom options
local function RequestProfile()
  if not aura_env.config.inherit then return end -- If we do not want to inherit profiles, do not request
  
  if IsInGroup() and UnitIsGroupLeader("player") then return end -- If we are the group leader, there is no need to request profile
  
  local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"
  
  AceComm:SendCommMessage("CCR_Request", "", chatType)
end

-- Broadcast your aura version
function aura_env.BroadcastVersion()
  local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"
  
  AceComm:SendCommMessage("CCR_Version", tostring(auraVersion), chatType)
end

-- Receive version from other party members
local function ReceiveVersion(version)
  local versionsBehind = tonumber(version) - auraVersion
  
  if versionsBehind > 0 and (not aura_env.lastVersionWarning or aura_env.lastVersionWarning < GetTime() - 600) then
    print(string.format("|cfffc1e38Your Mythic+ CC Rotations Assignments aura is %d version%s behind. Please update from|r |cff57dbffhttps://wago.io/U0x6fFviT|r|cfffc1e38.|r", versionsBehind, versionsBehind > 1 and "s" or ""))
    
    aura_env.lastVersionWarning = GetTime()
  end
end

-- Register AceComm prefixes for transmitting profiles between group members
AceComm:RegisterComm("CCR_Request", function() aura_env.BroadcastProfile() end)
AceComm:RegisterComm("CCR_Broadcast", function(_, payload) ReceiveProfile(payload) end)
AceComm:RegisterComm("CCR_Version", function(_, payload) ReceiveVersion(payload) end)

-- Request priority profile from group leader (if applicable)
RequestProfile()

-- Play a preview sound when the default text-to-speech voice is changed in custom options
if aura_env.saved.ttsVoice and aura_env.config.ttsVoice ~= aura_env.saved.ttsVoice then
  C_VoiceChat.SpeakText(
    aura_env.config.ttsVoice,
    "Next",
    Enum.VoiceTtsDestination.LocalPlayback,
    C_TTSSettings and C_TTSSettings.GetSpeechRate() or 0,
    aura_env.config.ttsVolume
  )
end

aura_env.saved.ttsVoice = aura_env.config.ttsVoice

aura_env.lastMessageTime = aura_env.lastMessageTime or 0
