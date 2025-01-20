-- general option init
local this = aura_env
local suffix = this.id:gsub("通用设置 %- LYC %- ", "")
local CLASS = suffix:gsub("[%s%d]+$", "")
this.CLASS = CLASS
-- print(CLASS)

local CLASS_GROUP = WeakAuras.GetData(this.id).parent
local BUFF_EFFECTS_GROUP = "重要光环 - LYC - " .. suffix
local DR_EFFECTS_GROUP = "一般光环 - LYC -" .. suffix
local CORE_GROUP = "主体 - LYC - " .. suffix
local SUB_GROUP = "次要 - LYC - " .. suffix
local RESOURCES_GROUP = "资源 - LYC - " .. suffix

local NB_CORE = 10
local CORE_WIDTH = 405
local CORE_HEIGHT = 48
local RESOURCES_HEIGHT = 0

LYC = LYC or {}
LYC[CLASS] = LYC[CLASS] or {}

local LYC = LYC[CLASS]

local config = nil
LYC.configs = LYC.configs or {}
LYC.configs["general"] = this.config

this.resources = nil
this.parentFrame = nil

local WeakAuras, C_Timer, time, min, max, floor, ceil, fmod, Round, pairs, ipairs, type, unpack, tinsert, FormatLargeNumber, DECIMAL_SEPARATOR =
WeakAuras, C_Timer, time, min, max, floor, ceil, math.fmod, Round, pairs, ipairs, type, unpack, tinsert,
FormatLargeNumber, DECIMAL_SEPARATOR
local SharedMedia = LibStub("LibSharedMedia-3.0")

-- table 复制
local function tclone(t1)
  local t = {}
  
  if t1 then
    for k, v in pairs(t1) do
      if "table" == type(v) then
        v = tclone(v)
      end
      
      if "string" == type(k) then
        t[k] = v
      else
        tinsert(t, v)
      end
    end
  end
  
  return t
end

-- table 合并
local function tmerge(...)
  local ts = { ... }
  local t = tclone(ts[1])
  local t2
  
  for i = 2, #ts do
    t2 = ts[i] or {}
    
    for k, v in pairs(t2) do
      if "table" == type(v) then
        v = tclone(v)
        
        if t[k] and #t[k] == 0 then
          t[k] = tmerge(t[k], v)
        else
          t[k] = v
        end
      else
        t[k] = v
      end
    end
  end
  
  return t
end

local function SetRegionSize(r, w, h)
  r:SetRegionWidth(w)
  r:SetRegionHeight(h)
end

local function UpdateAnchorFrame(skipCore)
  if this.isImporting then return end
  
  local h, y = max(1, CORE_HEIGHT + RESOURCES_HEIGHT), 0
  
  if 1 == h % 2 then
    h = h + 1
  end
  SetRegionSize(this.region, CORE_WIDTH, h)
  
  local function RepositionGroups()
    local configs = { config.core, config.core }
    
    for i, g in ipairs({ CORE_GROUP, SUB_GROUP }) do
      if not (skipCore and CORE_GROUP == g) then
        g = WeakAuras.GetRegion(g)
        
        if g then
          g:PositionChildren()
          if 0 == #g.sortedChildren then
            g:SetHeight(configs[i].height)
            g.currentHeight = configs[i].height
          end
        end
      end
    end
  end
  
  if skipCore then
    C_Timer.After(0.05, RepositionGroups)
  else
    RepositionGroups()
  end
end

-- 如果整个wa正在导入 每0.5 判断WA是否正在导入
if WeakAuras.IsImporting() then
  -- 判断是否导入完成 如果完成 1秒后发送初始化事件
  local function CheckImport()
    if WeakAuras.IsImporting() or not this.isImporting then return end
    this.isImporting:Cancel()
    this.isImporting = false
    C_Timer.After(1, function()
        WeakAuras.ScanEvents("LYC_INIT", true)
    end)
  end
  
  this.isImporting = C_Timer.NewTicker(0.5, CheckImport)
else
  this.isImporting = false
end

-- 读取配置
function LYC.GetConfig(grp, force)
  local default = {
    core = {
      number = 10,
      width = 48,
      height = 48
    },
    core1 = {
      number = 8,
      width = 48,
      height = 48
    },
    core2 = {
      number = 7,
      width = 48,
      height = 48
    },
    effect = {
      width = 40,
      height = 40,
      top = 4
    },
    manaBar = {},
    holyPower = {
      height = 10
    },
  }
  
  if force or not config or WeakAuras.IsOptionsOpen() then
    config = tmerge(
      default,
      LYC.configs["general"],
      LYC.configs["class"] or {}
    )
  end
  
  if grp then
    return config[grp] or {}
  end
  
  return config
end

local function UpdateSubRegions(region, subConfig)
  if region and #region.subRegions > 0 then
    local config = LYC.GetConfig()
    local cfgFont, cfgSize, currentFont, currentSize, flags
    
    if subConfig then
      cfgFont = subConfig.font
      cfgSize = subConfig.fontSize or 14
      
      if cfgFont then
        cfgFont = SharedMedia:Fetch("font", cfgFont)
      end
    end
    
    for _, subRegion in ipairs(region.subRegions) do
      if "subtext" == subRegion.type and cfgFont then
        currentFont, currentSize, flags = subRegion.text:GetFont()
        if currentFont ~= cfgFont or currentSize ~= cfgSize then
          subRegion.text:SetFont(cfgFont, cfgSize, flags)
        end
      end
    end
  end
end

local function UpdateIcon(region, key, selfPoint)
  if not region then return end
  
  local config = LYC.GetConfig()
  local subCfg = config[key]
  
  region:SetAnchor(selfPoint, region.relativeTo, region.relativePoint)
  
  SetRegionSize(region, subCfg.width, subCfg.height)
end

-- 更新资源条
local function UpdateResource(region, index, nb, inCombat)
  if not region then return end
  
  index = max(1, index or 1)
  nb = max(1, nb or 1)
  
  if not inCombat then
    local config, subConfig = LYC.GetConfig(), {}
    local w, h = CORE_WIDTH, 20
    
    if nb > 1 then
      w = w / nb
    end
    
    local cg = region.configGroup
    
    if cg and config[cg] then
      subConfig = config[cg]
      h = subConfig.height or 20
    end
    
    local lastW, lastH = region.width, region.height
    
    SetRegionSize(region, w, h)
    
    UpdateSubRegions(region, subConfig)
    
    if lastW ~= w or lastH ~= h then
      region.bar:Update()
    end
    
    if region.bar.spark then
      region.bar.spark:SetHeight(h)
    end
  end
  
  this.UpdateBar({ region = region }, index, nb)
end

local throttledInitHandler, throttledInitLastRun = nil, 0

-- 延迟初始化 每250ms 尝试初始化
function this.ThrottledInit()
  if throttledInitHandler or this.isImporting then return end
  
  local currentTime, delay = time(), 0.25
  
  if throttledInitLastRun > currentTime - 0.5 then
    delay = max(0.25, currentTime - throttledInitLastRun)
  end
  
  throttledInitHandler = C_Timer.NewTimer(delay, function()
      WeakAuras.ScanEvents("LYC_INIT")
  end)
end

function this.Init()
  if this.isImporting then return end
  
  throttledInitLastRun = time()
  
  local config = LYC.GetConfig(nil, true)
  local isOptionsOpen = WeakAuras.IsOptionsOpen()
  
  if throttledInitHandler then
    throttledInitHandler:Cancel()
    throttledInitHandler = nil
  end
  
  if not this.parentFrame then
    this.parentFrame = WeakAuras.GetRegion(CLASS_GROUP)
  end
  
  if this.parentFrame and not this.parentFrame.SetRealScale then
    this.parentFrame.SetRealScale = this.parentFrame.SetScale
    
    this.parentFrame.SetScale = function(self, scale)
      this.parentFrame:SetRealScale(scale)
      -- castBar
    end
  end
  if isOptionsOpen then
    NB_CORE = config.core.number
  else
    NB_CORE = max(10, config.core.number)
  end
  
  local hSpacing = config.layout.hSpacing
  
  CORE_WIDTH = NB_CORE * (config.core.width + hSpacing) - hSpacing
  this.UpdateResources();
  
  for _, g in ipairs({ DR_EFFECTS_GROUP, BUFF_EFFECTS_GROUP }) do
    g = WeakAuras.GetRegion(g)
    
    if g then
      g:PositionChildren()
    end
  end
end

hooksecurefunc("SetUIVisibility", function(isVisible)
    if isVisible and this and this.ThrottledInit then
      this.ThrottledInit()
    end
end)

function this.UpdateResources()
  if this.isImporting then return end
  
  local grpRegion = WeakAuras.GetRegion(RESOURCES_GROUP)
  
  if not this.resources then
    local grpData = WeakAuras.GetData(RESOURCES_GROUP)
    
    this.resources = grpData and grpData.controlledChildren
  end
  
  if grpRegion and this.resources and #this.resources > 0 then
    local config = LYC.GetConfig()
    
    local totalHeight, nb = 0, 0
    
    grpRegion:SetOffset(0, 0)
    
    local isOptionsOpen = WeakAuras.IsOptionsOpen()
    local resRegion, isVisible, regionType
    local w, h, cg = 0, 0
    local y = 0
    for _, resId in ipairs(this.resources) do
      resRegion = WeakAuras.GetRegion(resId)
      
      if resRegion then
        isVisible = isOptionsOpen
        regionType = resRegion.regionType
        h = 0
        if "aurabar" == regionType then
          isVisible = isVisible or resRegion:IsVisible()
          UpdateResource(resRegion)
          
          h = resRegion.height
        elseif "dynamicgroup" == regionType then
          local nbChild = 0
          local childRegions = {}
          
          for _, region in pairs(resRegion.controlledChildren) do
            if region and region[""] then
              nbChild = nbChild + 1
              
              childRegions[region[""].regionData.dataIndex] = region[""].regionData.region
              
              isVisible = isVisible or region[""].regionData.region:IsVisible()
            end
          end
          
          resRegion.childYOffset = -y
          h = 0
          for i, region in ipairs(childRegions) do
            UpdateResource(region, i, nbChild)
            
            h = max(h, region.height)
            region:SetYOffset(-y)
          end
          
          if h <= 0 then
            h = 20
          end
        end
        
        if isVisible then
          nb = nb + 1
          if "dynamicgroup" == regionType then
            resRegion:PositionChildren()
          else
            resRegion:SetOffset(0, -y)
          end
          
          totalHeight = totalHeight + h
          y = y + h
        end
      end
    end
    
    RESOURCES_HEIGHT = totalHeight
  end
  
  UpdateAnchorFrame()
end

-- 更新条
function this.UpdateBar(aura, i, nb)
  local config = LYC.GetConfig()
  local e = aura or aura_env
  local region = e and e.region
  local cg = region and region.configGroup
  
  if not (region and region:IsVisible() and cg and config[cg]) then return end
  
  local cs = region.colorState or ""
  
  
  if cs ~= "" then
    cs = cs .. "Color"
  else
    cs = "color"
  end
  cg = config[cg]
  local c1 = cg[cs]
  if c1 then
    region.enableGradient = false
    region:Color(unpack(c1))
  end
end

-- 计算主体技能位置
function LYC.GrowCore(newPositions, activeRegions)
  local nb = #activeRegions
  if nb <= 0 then return end
  
  local config = LYC.GetConfig()
  
  local width = config.core.width
  local height = config.core.height
  
  local hSpacing = config.layout.hSpacing
  local vSpacing = config.layout.vSpacing
  
  local key = "core"
  local maxCore = min(nb, config.core.number)
  local x, y
  local xOffset = ((maxCore - 1) * (width + hSpacing) / 2)
  local yOffset = height + RESOURCES_HEIGHT + vSpacing
  local nbPerRow = floor((CORE_WIDTH + hSpacing) / (width + hSpacing)) or 1
  local coreHeight = height
  local oldWidth, oldHeight = CORE_WIDTH, CORE_HEIGHT
  
  if not WeakAuras.IsOptionsOpen() then
    NB_CORE = max(4, config.core.number)
    CORE_WIDTH = NB_CORE * (width + hSpacing) - hSpacing
  end
  
  if oldWidth ~= CORE_WIDTH then
    this.UpdateResources()
  end
  
  for i, regionData in ipairs(activeRegions) do
    local realI = i
    if i == config.core.number + 1 then
      nb = nb - config.core.number
      maxCore = min(nb, config.core.number)
      xOffset = ((maxCore - 1) * (width + hSpacing) / 2)
      yOffset = yOffset + height + vSpacing
      coreHeight = coreHeight + height + vSpacing
    end
    if i > config.core.number then
      realI = realI - config.core.number
    end
    
    x = (realI - 1) * (width + hSpacing) - xOffset
    y = -yOffset
    
    UpdateIcon(regionData.region, key, "BOTTOM")
    newPositions[i] = { x, y }
    
    if i == config.core.number * 2 then break end
  end
  
  CORE_HEIGHT = coreHeight
  UpdateAnchorFrame(true)
end

-- 计算主体技能位置
function LYC.GrowSub(newPositions, activeRegions)
  local nb = #activeRegions
  if nb <= 0 then return end
  
  local config = LYC.GetConfig()
  
  local width = config.core1.width
  local height = config.core1.height
  
  local hSpacing = config.layout.hSpacing
  local vSpacing = config.layout.vSpacing
  
  local key = "core1"
  local maxCore = min(nb, config.core1.number)
  local x, y
  local xOffset = ((maxCore - 1) * (width + hSpacing) / 2)
  
  local yOffset = height + RESOURCES_HEIGHT + vSpacing + CORE_HEIGHT + vSpacing
  
  for i, regionData in ipairs(activeRegions) do
    x = (i - 1) * (width + hSpacing) - xOffset
    y = -yOffset
    UpdateIcon(regionData.region, key, "BOTTOM")
    newPositions[i] = { x, y }
    if i == NB_CORE then break end
  end
end

-- 增益光环
function LYC.GrowBuffEffects(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LYC.GetConfig()
  
  local maxCore = min(nb, NB_CORE)
  
  local width = config.effect.width
  local height = config.effect.height
  
  local hSpacing = config.layout.hSpacing
  local vSpacing = config.layout.vSpacing
  
  local top = config.effect.top
  
  local xOffset = (maxCore - 1) * (width + hSpacing) / 2
  local yOffset = height + vSpacing - height + top + vSpacing
  local nbPerRow = floor((CORE_WIDTH + hSpacing) / (width + hSpacing)) or 1
  
  local x, y, m
  
  for i, regionData in ipairs(activeRegions) do
    m = (i % nbPerRow)
    if m == 1 then
      xOffset = (min(nb - i, nbPerRow - 1)) * (width + hSpacing) / 2
      yOffset = yOffset + height + vSpacing
    end
    
    if m == 0 then
      m = nbPerRow
    end
    
    x = (m - 1) * (width + hSpacing) - xOffset
    y = yOffset
    
    UpdateIcon(regionData.region, "effect", "BOTTOM")
    
    newPositions[i] = { x, y }
  end
end

-- 减伤光环位置
function LYC.GrowDrEffects(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LYC.GetConfig()
  
  local maxCore = min(nb, NB_CORE)
  
  local width = config.effect.width
  local height = config.effect.height
  
  local hSpacing = config.layout.hSpacing
  local vSpacing = config.layout.vSpacing
  local top = config.effect.top
  
  local xOffset = (maxCore - 1) * (width + hSpacing) / 2
  local yOffset = vSpacing - height + top
  local nbPerRow = floor((CORE_WIDTH + hSpacing) / (width + hSpacing)) or 1
  
  local x, y, m
  
  for i, regionData in ipairs(activeRegions) do
    m = (i % nbPerRow)
    if m == 1 then
      xOffset = (min(nb - i, nbPerRow - 1)) * (width + hSpacing) / 2
      yOffset = yOffset + height + vSpacing
    end
    
    if m == 0 then
      m = nbPerRow
    end
    
    x = (m - 1) * (width + hSpacing) - xOffset
    y = yOffset
    
    UpdateIcon(regionData.region, "effect", "BOTTOM")
    
    newPositions[i] = { x, y }
  end
end

-- 更新动态条位置 横向
function LYC.GrowDynamicResource(newPositions, activeRegions, inCombat)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LYC.GetConfig()
  
  local w = CORE_WIDTH / nb
  local xOffset, x = (CORE_WIDTH - w) / 2
  local childYOffset = aura_env.region.childYOffset or 0
  
  for i, regionData in ipairs(activeRegions) do
    x = (i - 1) * w - xOffset
    
    if not this.isImporting then
      UpdateResource(regionData.region, i, nb, inCombat)
      regionData.region:SetYOffset(childYOffset)
    end
    
    newPositions[i] = { x, 0 }
  end
end

