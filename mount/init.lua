-- LYC MOUNT INIT
-- config
-- default alt ctrl shift
-- type 1完全随机 2随机地面 3随机飞行 4指定随机
-- custom
LYC_MOUNT = LYC_MOUNT or {}
LYC_MOUNT.configs = aura_env.config

-- print(LYC_MOUNT.configs['shift'].custom)

local function CanFly(typeId)
  if typeId == 424 or typeId == 402 or typeId == 445 or typeId == 436 or typeId == 437 or typeId == 444 or typeId == 407 then
    return true
  end
  return false
end

LYC_MOUNT['default'] = {}
LYC_MOUNT['alt'] = {}
LYC_MOUNT['ctrl'] = {}
LYC_MOUNT['shift'] = {}


C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)

local mountCount = C_MountJournal.GetNumDisplayedMounts();
-- print('坐骑数量:' .. mountCount)



for i = 1, mountCount, 1 do
  local name, _, _, _, isUsable, _, _, _, _, _, _, id = C_MountJournal.GetDisplayedMountInfo(i);
  local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
  local canFly = CanFly(typeId)

  for _, mod in ipairs({ 'default', 'alt', 'ctrl', 'shift' }) do
    local type = LYC_MOUNT.configs[mod].type

    local available = false

    if type == 1 then
      available = true
    elseif type == 2 then
      if not canFly then
        available = true
      end
    elseif type == 3 then
      if canFly then
        available = true
      end
    elseif type == 4 then
      if string.find(LYC_MOUNT.configs[mod].custom, name) then
        available = true
      end
    end

    if available then
      table.insert(LYC_MOUNT[mod], id)
    end
  end
end

C_MountJournal.SetDefaultFilters()

function LYC_MOUNT.summon(mod)
  if LYC_MOUNT[mod] and (#LYC_MOUNT[mod] > 0) then
    local mounts = LYC_MOUNT[mod]
    local id = mounts[math.random(#mounts)]
    local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)

    if isUsable then
      C_MountJournal.SummonByID(id)
    end
  end
end
