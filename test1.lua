local this = aura_env
local suffix = this.id:gsub("General Options %- LWA %- ", "")
local CLASS = suffix:gsub("[%s%d]+$", "")
this.CLASS = CLASS

local CLASS_GROUP = WeakAuras.GetData(this.id).parent
local DYNAMIC_EFFECTS_GROUP = "Dynamic Effects - LWA - " .. suffix
local CORE_GROUP = "Core - LWA - " .. suffix
local LEFT_SIDE_GROUP = "Left Side - LWA - " .. suffix
local RIGHT_SIDE_GROUP = "Right Side - LWA - " .. suffix
local UTILITIES_GROUP = "Utilities - LWA - " .. suffix
local MAINTENANCE_GROUP = "Maintenance - LWA - " .. suffix
local RESOURCES_GROUP = "Resources - LWA - " .. suffix
local CAST_BAR = "Cast Bar - LWA - " .. suffix

local NB_CORE = 8
local CORE_WIDTH = 405
local CORE_HEIGHT = 48
local RESOURCES_HEIGHT = 0

LWA = LWA or {}
LWA[CLASS] = LWA[CLASS] or {}

local LWA = LWA[CLASS]

local config = nil
LWA.configs = LWA.configs or {}
LWA.configs["general"] = this.config

this.resources = nil
this.parentFrame = nil


local WeakAuras, C_Timer, time, min, max, floor, ceil, fmod, Round, pairs, ipairs, type, unpack, tinsert, FormatLargeNumber, DECIMAL_SEPARATOR = WeakAuras, C_Timer, time, min, max, floor, ceil, math.fmod, Round, pairs, ipairs, type, unpack, tinsert, FormatLargeNumber, DECIMAL_SEPARATOR
local SharedMedia = LibStub("LibSharedMedia-3.0")


if WeakAuras.IsImporting() then
  local function CheckImport()
    if WeakAuras.IsImporting() or not this.isImporting then return end
    
    this.isImporting:Cancel()
    this.isImporting = false
    
    C_Timer.After(1, function()
        WeakAuras.ScanEvents("LWA_INIT", true)
    end)
  end
  
  this.isImporting = C_Timer.NewTicker(0.5, CheckImport)
else
  this.isImporting = false
end

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

local function tmerge(...)
  local ts = {...}
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

local function CalcSpacing(spacing)
  local s, bs, bo, s2 = spacing, config.style.border_size, config.style.border_offset
  
  if bs > 0 then
    s2 = max(bs, bo)
  else
    s2 = 0
  end
  
  if s > 0 then
    s = s + (s2 * 2)
  else
    s = s2
  end
  
  return s
end

local function UpdateAnchorFrame(skipCore)
  if this.isImporting then return end
  
  local config = LWA.GetConfig()
  local h1 = config.core.height
  local s1 = CalcSpacing(config.core.spacing)
  local m1 = config.core.margin
  local h, y = max(1, CORE_HEIGHT + RESOURCES_HEIGHT + s1 + m1), 0
  
  if 1 == h % 2 then
    h = h + 1
  end
  
  SetRegionSize(this.region, CORE_WIDTH, h)
  
  if config.core.resources_position == 1 then -- Above
    y = y + RESOURCES_HEIGHT + s1 + m1
  end
  
  if config.core.overflow_position == 1 then -- Above
    y = y + max(CORE_HEIGHT, h1) - h1
  end
  
  this.region:SetOffset(0, y)
  
  local function RepositionGroups()
    local configs = { config.core, config.utility, config.maintenance }
    
    for i, g in ipairs({ CORE_GROUP, UTILITIES_GROUP, MAINTENANCE_GROUP }) do
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

function LWA.GetConfig(grp, force)
  local default = {
    style = {
      border_offset = 1,
      border_size = 1,
      border_icons = true,
      border_resources = true,
      border_color = { [1] = 0, [2] = 0, [3] = 0, [4] = 1 },
      zoom = 30,
      resource_texture = "Solid",
    },
    core = {
      font = "",
      font_size = 18,
      nb_min = 5,
      nb_max = 8,
      width = 48,
      height = 48,
      spacing = 3,
      width2 = 48,
      height2 = 48,
      spacing2 = 3,
      margin = 0,
      overflow_position = 2, -- Below
      resources_position = 2, -- Below
    },
    core2 = { -- Fake group
      width = 48,
      height = 48,
      spacing = 3,
    },
    utility = {
      font = "",
      font_size = 16,
      width = 38,
      height = 38,
      spacing = 3,
      margin = 10,
      nb_max = 10,
      limit_icons = false,
      behavior = 2, -- Always Show
    },
    top = {
      font = "",
      font_size = 16,
      width = 38,
      height = 38,
      spacing = 3,
      margin = 10,
    },
    side = {
      font = "",
      font_size = 16,
      width = 38,
      height = 38,
      spacing = 3,
      margin = 3,
      grow_direction = 1,
      nb = 60,
    },
    maintenance = {
      font = "",
      font_size = 16,
      width = 36,
      height = 36,
      spacing = 0,
      margin = 10,
      nb_max = 10,
      limit_icons = false,
    },
    alpha = {
      global = 100,
      ooc = 100,
      mounted = 0,
      skyriding_only = false,
      ignore_enemy = true,
      ignore_friendly = true,
    },
    resources = {
      health_bar = {
        format = 1
      },
      mana_bar = {
        format = 1
      }
    },
  }
  
  if force or not config or WeakAuras.IsOptionsOpen() then
    config = tmerge(
      default,
      LWA.configs["general"],
      LWA.configs["class"] or {}
    )
    
    -- Special case for Core's Overflow
    config.core2 = {
      width = config.core.width2,
      height = config.core.height2,
      spacing = config.core.spacing2,
      font = config.core.font,
      font_size = config.core.font_size,
    }
  end
  
  if grp then
    return config[grp] or {}
  end
  
  return config
end

local function UpdateSubRegions(region, subCfg, applyBorders)
  if region and #region.subRegions > 0 then
    local config = LWA.GetConfig()
    local bSize, bOffset, r, g, b, a = 0, 0 -- Border
    local cfgFont, cfgSize, currentFont, currentSize, flags
    
    if applyBorders then
      bSize = config.style.border_size
      bOffset = config.style.border_offset
      r, g, b, a = unpack(config.style.border_color)
    end
    
    if subCfg then
      cfgFont = subCfg.font
      cfgSize = subCfg.font_size or 14
      
      if cfgFont then
        cfgFont = SharedMedia:Fetch("font", cfgFont)
      end
    end
    
    for _, subRegion in ipairs(region.subRegions) do
      if "subborder" == subRegion.type then
        subRegion:SetVisible(bSize > 0)
        
        if bSize > 0 then
          region:AnchorSubRegion(subRegion, "area", region.regionType == "aurabar" and "bar", nil, bOffset, bOffset)
          
          local bd = subRegion:GetBackdrop()
          bd.edgeSize = bSize
          subRegion:SetBackdrop(bd)
          subRegion:SetBorderColor(r, g, b, a)
        end
      elseif "subtext" == subRegion.type and cfgFont then
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
  
  local config = LWA.GetConfig()
  local zoom = config.style.zoom / 100
  local subCfg = config[key]
  
  region:SetAnchor(selfPoint, region.relativeTo, region.relativePoint)
  
  if region.SetZoom then
    region:SetZoom(min(1, zoom + (region.extraZoom or 0)))
  end
  
  SetRegionSize(region, subCfg.width, subCfg.height)
  
  UpdateSubRegions(region, subCfg, config.style.border_icons)
end

local function UpdateResource(region, index, nb, inCombat)
  if not region then return end
  
  index = max(1, index or 1)
  nb = max(1, nb or 1)
  
  if not inCombat then
    local config, subCfg = LWA.GetConfig(), {}
    
    local w, h = CORE_WIDTH, 20
    
    if nb > 1 then
      local s = CalcSpacing(config.core.spacing)
      
      w = (w + s) / nb - s
    end
    
    local cg = region.configGroup
    
    if cg and config.resources[cg] then
      subCfg = config.resources[cg]
      h = subCfg.height or 20
    end
    
    local lastW, lastH = region.width, region.height
    
    SetRegionSize(region, w, h)
    
    UpdateSubRegions(region, subCfg, config.style.border_resources)
    
    if config.style.resource_texture then
      region.textureSource = "LSM"
      region:SetStatusBarTextureLSM(config.style.resource_texture)
      
      if region.overlaysTexture then
        for i, _ in ipairs(region.overlaysTexture) do
          region.overlaysTexture[i] = config.style.resource_texture
        end
      end
    end
    
    if lastW ~= w or lastH ~= h then
      region.bar:Update()
    end
    
    if region.bar.spark then
      region.bar.spark:SetHeight(max(15, Round(h * 2)))
    end
  end
  
  this.UpdateBar({ region = region }, index, nb)
end

local throttledInitHandler, throttledInitLastRun = nil, 0

function this.ThrottledInit()
  if throttledInitHandler or this.isImporting then return end
  
  local currentTime, delay = time(), 0.25
  
  if throttledInitLastRun > currentTime - 0.5 then
    delay = max(0.25, currentTime - throttledInitLastRun)
  end
  
  throttledInitHandler = C_Timer.NewTimer(delay, function()
      WeakAuras.ScanEvents("LWA_INIT")
  end)
end

function this.Init()
  if this.isImporting then return end
  
  throttledInitLastRun = time()
  
  local config = LWA.GetConfig(nil, true)
  local isOptionsOpen = WeakAuras.IsOptionsOpen()
  local zoom = config.style.zoom / 100
  
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
      local castBar = WeakAuras.GetRegion(CAST_BAR)
      
      if castBar then
        castBar:SetScale(scale)
      end
    end
  end
  
  if isOptionsOpen then
    NB_CORE = config.core.nb_max
  else
    NB_CORE = max(4, config.core.nb_min, min(NB_CORE, config.core.nb_max))
    
    local castBar = WeakAuras.GetRegion(CAST_BAR)
    
    if castBar then
      castBar:SetParent(UIParent)
      
      if this.parentFrame then
        castBar:SetScale(this.parentFrame:GetScale())
      end
    end
  end
  
  local spacing = CalcSpacing(config.core.spacing)
  
  CORE_WIDTH = NB_CORE * (config.core.width + spacing) - spacing
  
  local grpRegion = WeakAuras.GetRegion(CORE_GROUP)
  
  if grpRegion then
    grpRegion:PositionChildren()
    
    if not isOptionsOpen then
      NB_CORE = max(4, config.core.nb_min, min(#grpRegion.sortedChildren, config.core.nb_max))
      
      CORE_WIDTH = NB_CORE * (config.core.width + spacing) - spacing
    end
    
    this.region:SetRegionWidth(CORE_WIDTH)
  end
  
  this.UpdateResources()
  
  for _, g in ipairs({ DYNAMIC_EFFECTS_GROUP, LEFT_SIDE_GROUP, RIGHT_SIDE_GROUP }) do
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
    local config = LWA.GetConfig()
    
    local totalHeight, nb = 0, 0
    local h1 = config.core.height
    local s1 = CalcSpacing(config.core.spacing)
    local m1 = config.core.margin
    local y = 0
    
    if config.core.resources_position == 2 then -- Below
      y = max(CORE_HEIGHT, h1) + s1 + m1
    end
    
    grpRegion:SetOffset(0, -y)
    
    local isOptionsOpen = WeakAuras.IsOptionsOpen()
    local resRegion, isVisible, regionType
    local w, h, cg = 0, 0
    
    y = 0
    
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
          y = y + h + s1
        end
      end
    end
    
    RESOURCES_HEIGHT = totalHeight + max(nb - 1, 0) * CalcSpacing(config.core.spacing)
  end
  
  UpdateAnchorFrame()
end

function this.UpdateBar(aura, i, nb)
  local config = LWA.GetConfig("resources")
  local e = aura or aura_env
  local region = e and e.region
  local cg = region and region.configGroup
  
  if not (region and region:IsVisible() and cg and config[cg]) then return end
  
  local cs = region.colorState or ""
  
  if cs ~= "" then
    cs = cs .. "_"
  end
  
  cg = config[cg]
  
  local c1, c2 = cg[cs .. "color1"], cg[cs .. "color2"]
  
  if c1 and c2 then
    nb = max(1, min(region.indexMax or 99, nb or 1))
    i = min(nb, max(1, region.index or i or 1)) - (region.indexOffset or 0)
    
    local bar = region.bar
    
    if cg[cs .. "gradient"] and cg[cs .. "gradient"] < 3 then
      if nb > 1 and 1 == cg[cs .. "gradient"] then
        local function MixRGB(c1, c2, pos)
          pos = 1 - (pos or 0.5)
          
          return {
            (c1[1] * pos) + (c2[1] * (1 - pos)),
            (c1[2] * pos) + (c2[2] * (1 - pos)),
            (c1[3] * pos) + (c2[3] * (1 - pos)),
            (c1[4] * pos) + (c2[4] * (1 - pos))
          }
        end
        
        local cc1, cc2 = c1, c2
        
        if i > 1 then
          c1 = MixRGB(cc1, cc2, (i - 1) / nb)
        end
        
        c2 = MixRGB(cc1, cc2, i / nb)
      end
      
      local orientation = "HORIZONTAL"
      
      if 2 == cg[cs .. "gradient"] then
        orientation = "VERTICAL"
        
        local tmp = c1
        c1 = c2
        c2 = tmp
      end
      
      region.enableGradient = true
      region.gradientOrientation = orientation
      region.barColor2 = c2
      region:Color(unpack(c1))
    else
      region.enableGradient = false
      region:Color(unpack(c1))
    end
    
    if region.ot then
      region.ot:SetColorTexture(unpack(c2))
    end
  end
end

function LWA.GrowCore(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local w1 = config.core.width
  local h1 = config.core.height
  local s1 = CalcSpacing(config.core.spacing)
  local w2 = config.core.width2
  local h2 = config.core.height2
  local s2 = CalcSpacing(config.core.spacing2)
  local m1 = config.core.margin
  
  local maxCore = min(nb, config.core.nb_max)
  local maxOverflow = nb - maxCore
  local x, y
  local xOffset = ((maxCore - 1) * (w1 + s1) / 2)
  local yOffset = h1
  local nbPerRow = floor((CORE_WIDTH + s2) / (w2 + s2)) or 1
  local coreHeight = h1 + (ceil(maxOverflow / nbPerRow) * (h2 + s2))
  local oldWidth, oldHeight = CORE_WIDTH, CORE_HEIGHT
  
  if maxOverflow > 0 then
    coreHeight = coreHeight + max(s1, s2) - s2
  end
  
  CORE_HEIGHT = coreHeight
  
  if not WeakAuras.IsOptionsOpen() then
    NB_CORE = max(4, config.core.nb_min, maxCore)
    
    CORE_WIDTH = NB_CORE * (w1 + s1) - s1
  end
  
  UpdateAnchorFrame(true)
  
  if oldWidth ~= CORE_WIDTH or oldHeight ~= CORE_HEIGHT then
    this.UpdateResources()
  end
  
  if config.core.resources_position == 1 then  -- Above
    yOffset = h1 + RESOURCES_HEIGHT + s1 + m1
  end
  
  if config.core.overflow_position == 1 then  -- Above
    yOffset = yOffset + coreHeight - h1
  end
  
  for i, regionData in ipairs(activeRegions) do
    x = (i - 1) * (w1 + s1) - xOffset
    y = -yOffset
    
    UpdateIcon(regionData.region, "core", "BOTTOM")
    
    newPositions[i] = { x, y }
    
    if i == maxCore then break end
  end
  
  if maxOverflow > 0 then
    local i2, m, anchor, yMult
    
    xOffset = ((maxCore - 1) * (w2 + s2) / 2)
    yOffset = h1
    
    if config.core.overflow_position == 1 then -- Above
      yOffset = yOffset - h2 + max(s1, s2) - s2 - coreHeight
      yMult = 1
      anchor = "BOTTOM"
      
      if config.core.resources_position == 1 then  -- Above
        yOffset = yOffset - RESOURCES_HEIGHT - s1 - m1
      end
    else
      if config.core.resources_position == 1 then  -- Above
        yOffset = yOffset + RESOURCES_HEIGHT + s1 + m1
      end
      
      yOffset = yOffset - h2
      yMult = -1
      anchor = "TOP"
    end
    
    for i, regionData in ipairs(activeRegions) do
      if i > maxCore then
        i2 = i - maxCore
        m = (i2 % nbPerRow)
        
        if m == 1 then
          xOffset = (min(nb - i, nbPerRow - 1)) * (w2 + s2) / 2
          yOffset = yOffset + h2 + s2
        end
        
        if m == 0 then
          m = nbPerRow
        end
        
        x = (m - 1) * (w2 + s2) - xOffset
        y = yOffset * yMult
        
        UpdateIcon(regionData.region, "core2", anchor)
        
        newPositions[i] = { x, y }
      end
    end
  end
end

function LWA.GrowDynamicEffects(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local maxCore = min(nb, NB_CORE)
  
  local w1 = config.core.width
  local s1 = CalcSpacing(config.core.spacing)
  
  local w2 = config.top.width
  local h2 = config.top.height
  local s2 = CalcSpacing(config.top.spacing)
  
  local xOffset = (maxCore - 1) * (w1 + s1) / 2
  local yOffset = config.top.margin + max(s1, s2) - s2 - h2
  local x, y, m
  
  local nbPerRow = floor((CORE_WIDTH + s2) / (w2 + s2)) or 1
  
  for i, regionData in ipairs(activeRegions) do
    m = (i % nbPerRow)
    
    if m == 1 then
      xOffset = (min(nb - i, nbPerRow - 1)) * (w2 + s2) / 2
      yOffset = yOffset + h2 + s2
    end
    
    if m == 0 then
      m = nbPerRow
    end
    
    x = (m - 1) * (w2 + s2) - xOffset
    y = yOffset
    
    UpdateIcon(regionData.region, "top", "BOTTOM")
    
    newPositions[i] = { x, y }
  end
end

function LWA.GrowSide(newPositions, activeRegions, xMult)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local w = config.side.width
  local h = config.side.height
  local s2 = CalcSpacing(config.side.spacing)
  local s1 = CalcSpacing(config.core.spacing)
  local h1 = config.core.height
  local m1 = config.core.margin
  
  local baseX, baseY = config.side.margin + max(s1, s2), 0
  local xOffset, yOffset, yMult = 0, 0, 1
  local nbPerRC, m = min(config.side.nb, nb)
  local grow = config.side.grow_direction
  local anchor
  
  if config.core.resources_position == 2 and config.core.overflow_position == 2 then -- Below
    if grow == 2 or grow == 4 then -- Upward
      baseY = baseY - config.top.margin
    end
  else
    if config.core.resources_position == 1 then -- Above
      baseY = baseY + RESOURCES_HEIGHT + s1 + m1
    end
    
    if config.core.overflow_position == 1 then -- Above
      baseY = baseY + max(CORE_HEIGHT, h1) - h1
    end
  end
  
  xMult = xMult or 1
  
  if xMult < 0 then
    anchor = "TOPRIGHT"
  else
    anchor = "TOPLEFT"
  end
  
  if grow == 3 or grow == 4 then -- Horizontal
    if grow == 4 then -- Upward
      yOffset = -baseY
      yMult = -1
    else
      yOffset = baseY - h - s2
    end
    
    for i, regionData in ipairs(activeRegions) do
      m = (i % nbPerRC)
      
      if m == 1 or (nbPerRC == 1 and i == 1) then
        xOffset = baseX
        yOffset = yOffset + h + s2
      end
      
      UpdateIcon(regionData.region, "side", anchor)
      
      newPositions[i] = { xOffset * xMult, -yOffset * yMult }
      
      xOffset = xOffset + w + s2
    end
  else
    xOffset = baseX - w - s2
    
    if grow == 2 then -- Upward
      baseY = -baseY + h + s2
      yOffset = baseY
      yMult = -1
    else
      yOffset = -h - s2
    end
    
    for i, regionData in ipairs(activeRegions) do
      m = (i % nbPerRC)
      
      if m == 1 or (nbPerRC == 1 and i == 1) then
        xOffset = xOffset + w + s2
        yOffset = baseY
      end
      
      UpdateIcon(regionData.region, "side", anchor)
      
      newPositions[i] = { xOffset * xMult, -yOffset * yMult }
      
      yOffset = yOffset + h + s2
    end
  end
end

function LWA.GrowUtilities(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local w1 = config.core.width
  local s1 = CalcSpacing(config.core.spacing)
  
  local w2 = config.utility.width
  local h2 = config.utility.height
  local s2 = CalcSpacing(config.utility.spacing)
  
  local maxCore, nbPerRow
  
  if config.utility.limit_icons then
    nbPerRow = config.utility.nb_max
    maxCore = min(nb, nbPerRow)
  else
    maxCore = min(nb, NB_CORE)
    nbPerRow = floor((CORE_WIDTH + s2) / (w2 + s2)) or 1
  end
  
  local xOffset = (maxCore - 1) * (w2 + s2) / 2
  local yOffset = config.utility.margin + max(s1, s2) - s2 - h2
  local x, y, m
  
  for i, regionData in ipairs(activeRegions) do
    m = (i % nbPerRow)
    
    if m == 1 then
      xOffset = (min(nb - i, nbPerRow - 1)) * (w2 + s2) / 2
      yOffset = yOffset + h2 + s2
    end
    
    if m == 0 then
      m = nbPerRow
    end
    
    x = (m - 1) * (w2 + s2) - xOffset
    y = -yOffset
    
    UpdateIcon(regionData.region, "utility", "TOP")
    
    newPositions[i] = { x, y }
  end
end

function LWA.GrowMaintenance(newPositions, activeRegions)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local w1 = config.core.width
  local s1 = CalcSpacing(config.core.spacing)
  
  local w2 = config.maintenance.width
  local h2 = config.maintenance.height
  local s2 = CalcSpacing(config.maintenance.spacing)
  
  local maxCore, nbPerRow
  
  if config.maintenance.limit_icons then
    nbPerRow = config.maintenance.nb_max
    maxCore = min(nb, nbPerRow)
  else
    maxCore = min(nb, NB_CORE)
    nbPerRow = floor((CORE_WIDTH + s2) / (w2 + s2)) or 1
  end
  
  local xOffset = (maxCore - 1) * (w2 + s2) / 2
  local yOffset = config.maintenance.margin + config.utility.margin + max(CalcSpacing(config.utility.spacing), s2) - s2 - h2
  local x, y, m
  
  for i, regionData in ipairs(activeRegions) do
    m = (i % nbPerRow)
    
    if m == 1 then
      xOffset = (min(nb - i, nbPerRow - 1)) * (w2 + s2) / 2
      yOffset = yOffset + h2 + s2
    end
    
    if m == 0 then
      m = nbPerRow
    end
    
    x = (m - 1) * (w2 + s2) - xOffset
    y = -yOffset
    
    UpdateIcon(regionData.region, "maintenance", "TOP")
    
    newPositions[i] = { x, y }
  end
end

function LWA.GrowDynamicResource(newPositions, activeRegions, inCombat)
  local nb = #activeRegions
  
  if nb <= 0 then return end
  
  local config = LWA.GetConfig()
  
  local s = CalcSpacing(config.core.spacing)
  local w = (CORE_WIDTH + s) / nb
  local xOffset, x = (CORE_WIDTH - w + s) / 2
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

local function round(num, decimals)
  local mult = 10^(decimals or 0)
  
  return Round((num or 0) * mult) / mult
end

local barFormats = {
  "value",
  "kvalue",
  "value (percent)",
  "kvalue (percent)",
  "percent",
}

function LWA.UpdateBarText(value, percent, format)
  local text = barFormats[format] or "value"
  value = value or 0
  percent = percent or 0
  
  text = text:gsub("percent", round(percent, 0))
  
  if 2 == format or 4 == format then
    local rem = fmod(value, 1000) or 0
    
    if rem >= 950 or value >= 1000000 then
      rem = 0
    end
    
    text = text:gsub("kvalue", FormatLargeNumber(Round((value - rem) / 1000)) .. "." .. Round(rem / 100) .. " K"):gsub("%.0 K", " K"):gsub("%.", DECIMAL_SEPERATOR)
  else
    text = text:gsub("value", value)
  end
  
  return text
end

