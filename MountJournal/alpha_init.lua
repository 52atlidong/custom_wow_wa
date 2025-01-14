local this = aura_env

LYC_MOUNTS = LYC_MOUNTS or {}

local factionName = UnitFactionGroup("player")

local faction = factionName == "Alliance" and 1 or 0

local mountIDs = {}
local flyMountIDs = {}

C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)

local mountsNum = C_MountJournal.GetNumDisplayedMounts()

for i = 1, mountsNum, 1 do
  local id = C_MountJournal.GetDisplayedMountID(i)
  if id == 1 then
    LYC_MOUNTS.firstMount = id;
  end
  table.insert(mountIDs, id)
end

C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)
C_MountJournal.SetTypeFilter(1, false)
C_MountJournal.SetTypeFilter(2, true)
C_MountJournal.SetTypeFilter(3, false)
C_MountJournal.SetTypeFilter(4, false)
C_MountJournal.SetTypeFilter(5, false)

mountsNum = C_MountJournal.GetNumDisplayedMounts()

for i = 1, mountsNum, 1 do
  local id = C_MountJournal.GetDisplayedMountID(i)

  if i == 1 then
    LYC_MOUNTS.firstFlyMount = id;
  end

  table.insert(flyMountIDs, id)
end

C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)
C_MountJournal.SetTypeFilter(1, true)
C_MountJournal.SetTypeFilter(2, false)
C_MountJournal.SetTypeFilter(3, false)
C_MountJournal.SetTypeFilter(4, false)
C_MountJournal.SetTypeFilter(5, false)

LYC_MOUNTS.mountIDs = mountIDs
LYC_MOUNTS.flyMountIDs = flyMountIDs

C_MountJournal.SetDefaultFilters()

this.region.icon:SetScript("OnEnter", function()
    WeakAuras.ScanEvents("LYC_MOUNT_MOUSE_ENTER")
end)

this.region.icon:SetScript("OnLeave", function()
    WeakAuras.ScanEvents("LYC_MOUNT_MOUSE_LEAVE")
end)

function LYC_MOUNTS.randomMount()
  
  local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(LYC_MOUNTS.firstMount)
  
  if not isUsable then
    return
  end
  
  local mountId
  while mountId == nil do
    local id = mountIDs[math.random(#mountIDs)]
    local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
    if isUsable then
      mountId = id
    end
  end
  C_MountJournal.SummonByID(mountId)
end

function LYC_MOUNTS.randomFlyMount()
  local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(LYC_MOUNTS.firstFlyMount)
  
  if not isUsable then
    return
  end
  local mountId
  while mountId == nil do
    local id = flyMountIDs[math.random(#flyMountIDs)]
    local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
    if isUsable then
      mountId = id
    end
  end
  C_MountJournal.SummonByID(mountId)
end

