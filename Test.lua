-- LYC MOUNT INIT
-- config
-- default alt ctrl shift
-- custom
LYC_MOUNT = LYC_MOUNT or {}
LYC_MOUNT.configs = aura_env.config

local function InitModData(modData)
    modData["flyable"] = {}
    modData["swimming"] = {}
    modData["normal"] = {}
end



local function PlayerHasAura(spellId)
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if aura then
        return true
    end
    return false
end

local function Split(input, delimiter)
    local pos, arr = 0, {}
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function LYC_MOUNT.isDisable(name)
    local disables = LYC_MOUNT.disables
    if disables then
        for _, disable in ipairs(disables) do
            if string.find(name, disable) then
                return true
            end
        end
    end
    return false
end

LYC_MOUNT.disables = Split(LYC_MOUNT.configs.disables, "\n")

LYC_MOUNT["default"] = {}
LYC_MOUNT["alt"] = {}
LYC_MOUNT["ctrl"] = {}
LYC_MOUNT["shift"] = {}

InitModData(LYC_MOUNT["default"])
InitModData(LYC_MOUNT["alt"])
InitModData(LYC_MOUNT["ctrl"])
InitModData(LYC_MOUNT["shift"])

LYC_MOUNT["feixing"] = {}
LYC_MOUNT["dimian"] = {}
LYC_MOUNT["shuixia"] = {}


-- 水栖
C_MountJournal.SetSearch("")
C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)
C_MountJournal.SetTypeFilter(1, false)
C_MountJournal.SetTypeFilter(2, false)
C_MountJournal.SetTypeFilter(3, true)
C_MountJournal.SetTypeFilter(5, false)

local mountCount = C_MountJournal.GetNumDisplayedMounts();

for i = 1, mountCount, 1 do
    local name, _, _, _, isUsable, _, _, _, _, _, _, id = C_MountJournal.GetDisplayedMountInfo(i);
    local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
    
    local isDisable = LYC_MOUNT.isDisable(name)
    
    if not isDisable then
        table.insert(LYC_MOUNT["shuixia"], id)
    end
end

-- print("水下坐骑数:" .. (#LYC_MOUNT["shuixia"]))

-- 飞行
C_MountJournal.SetSearch("")
C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)
C_MountJournal.SetTypeFilter(1, false)
C_MountJournal.SetTypeFilter(2, true)
C_MountJournal.SetTypeFilter(3, false)
C_MountJournal.SetTypeFilter(5, false)

mountCount = C_MountJournal.GetNumDisplayedMounts();

for i = 1, mountCount, 1 do
    local name, _, _, _, isUsable, _, _, _, _, _, _, id = C_MountJournal.GetDisplayedMountInfo(i);
    local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
    
    local isDisable = LYC_MOUNT.isDisable(name)
    
    if not isDisable then
        table.insert(LYC_MOUNT["feixing"], id)
    end
end

-- print("飞行坐骑数:" .. (#LYC_MOUNT["feixing"]))


-- 地面
C_MountJournal.SetSearch("")
C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)
C_MountJournal.SetTypeFilter(1, true)
C_MountJournal.SetTypeFilter(2, false)
C_MountJournal.SetTypeFilter(3, false)
C_MountJournal.SetTypeFilter(5, false)

mountCount = C_MountJournal.GetNumDisplayedMounts();

for i = 1, mountCount, 1 do
    local name, _, _, _, isUsable, _, _, _, _, _, _, id = C_MountJournal.GetDisplayedMountInfo(i);
    local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
    
    local isDisable = LYC_MOUNT.isDisable(name)
    
    if not isDisable then
        table.insert(LYC_MOUNT["dimian"], id)
    end
end

-- print("地面坐骑数:" .. (#LYC_MOUNT["dimian"]))

-- 指定
C_MountJournal.SetSearch("")
C_MountJournal.SetDefaultFilters()
C_MountJournal.SetCollectedFilterSetting(2, false)

mountCount = C_MountJournal.GetNumDisplayedMounts();

for i = 1, mountCount, 1 do
    local name, _, _, _, isUsable, _, _, _, _, _, _, id = C_MountJournal.GetDisplayedMountInfo(i);
    local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
    
    -- if not isDisable then
    for _, mod in ipairs({ "default", "alt", "ctrl", "shift" }) do
        for _, type in ipairs({ "flyable", "swimming", "normal" }) do
            local str = LYC_MOUNT.configs[mod][type] or ""
            if string.find(str, name) then
                table.insert(LYC_MOUNT[mod][type], id)
            end
        end
    end
end

C_MountJournal.SetDefaultFilters()

function LYC_MOUNT.summon(mod)

  if IsMounted() then
    Dismount()
    return
  end

    local availableMounts = {}
    
    local isFlyableArea = IsFlyableArea()
    
    -- print(GetMirrorTimerInfo(2))
    
    local name, _, _, scale = GetMirrorTimerInfo(2)
    
    local isSubmerged = name and scale == -1
    
    -- /run print(GetMirrorTimerInfo(2))
    -- /run print(IsSubmerged())
    -- /run print(IsSwimming())
    if isSubmerged then
        for _, id in ipairs(LYC_MOUNT[mod]["swimming"]) do
            local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
            if isUsable then
                table.insert(availableMounts, id)
            end
        end
    elseif isFlyableArea then
        for _, id in ipairs(LYC_MOUNT[mod]["flyable"]) do
            local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
            if isUsable then
                table.insert(availableMounts, id)
            end
        end
    end
    
    if #availableMounts == 0 then
        for _, id in ipairs(LYC_MOUNT[mod]["normal"]) do
            local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
            if isUsable then
                table.insert(availableMounts, id)
            end
        end
    end
    
    
    
    if #availableMounts == 0 then
        
        if LYC_MOUNT.configs.useSystem then
            C_MountJournal.SummonByID(0)
            return
        end
        
        -- 动态随机
        if isSubmerged then
            -- 水下
            local dynamicFly = PlayerHasAura(404464)
            
            for _, id in ipairs(LYC_MOUNT["shuixia"]) do
                local _, _, _, _, typeId = C_MountJournal.GetMountInfoExtraByID(id)
                local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
                
                if isUsable and not (dynamicFly and typeId == 436) then
                    table.insert(availableMounts, id)
                end
            end
        elseif IsFlyableArea() then
            -- 可飞行区域
            for _, id in ipairs(LYC_MOUNT["feixing"]) do
                local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
                if isUsable then
                    table.insert(availableMounts, id)
                end
            end
        else
            --
            local _, _, _, _, isUsable1 = C_MountJournal.GetMountInfoByID(LYC_MOUNT["feixing"][1])
            local _, _, _, _, isUsable2 = C_MountJournal.GetMountInfoByID(LYC_MOUNT["dimian"][1])
            if not LYC_MOUNT.configs.onlyGround and isUsable1 then
                for _, id in ipairs(LYC_MOUNT["feixing"]) do
                    local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
                    if isUsable then
                        table.insert(availableMounts, id)
                    end
                end
            end
            if isUsable2 then
                for _, id in ipairs(LYC_MOUNT["dimian"]) do
                    local _, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(id)
                    if isUsable then
                        table.insert(availableMounts, id)
                    end
                end
            end
        end
    end
    
    if #availableMounts > 0 then
        local id = availableMounts[math.random(#availableMounts)]
        C_MountJournal.SummonByID(id)
    end
end

