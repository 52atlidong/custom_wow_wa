-- 大米 - 马戏团 - LYC 触发器2
-- 自定义:事件:CHALLENGE_MODE_START,COMBAT_LOG_EVENT_UNFILTERED:UNIT_DIED,COMBAT_LOG_EVENT_UNFILTERED:ENVIRONMENTAL_DAMAGE,COMBAT_LOG_EVENT_UNFILTERED:SWING_DAMAGE,COMBAT_LOG_EVENT_UNFILTERED:SPELL_PERIODIC_DAMAGE,COMBAT_LOG_EVENT_UNFILTERED:SPELL_DAMAGE,COMBAT_LOG_EVENT_UNFILTERED:RANGE_DAMAGE,CHALLENGE_MODE_COMPLETED
-- COMBAT_LOG_EVENT_UNFILTERED:UNIT_DIED,
function (event, ...)
  local this = aura_env

  if not UnitIsGroupLeader("player") then
    return false
  end

  if "CHALLENGE_MODE_START" == event then
    -- 大米开始
    this.HandleStartMythic()
  elseif "COMBAT_LOG_EVENT_UNFILTERED" then
    local time, subevent, _, _, _, _, _, guid, _ = ...

    if (not guid) or (not strfind(guid, "Player")) then
      return false
    end
    if "SWING_DAMAGE" == subevent then
      local overkill = select(13, ...)
      if overkill > 0 then
        this.overkillSources[guid] = "SWING"
      end
    elseif "SPELL_PERIODIC_DAMAGE" == subevent or "SPELL_DAMAGE" == subevent or "RANGE_DAMAGE" == subevent or "SPELL_BUIDING" == subevent then
      local spellID = select(12, ...)

      -- 技能 dot 范围
      local overkill = select(16, ...)
      if overkill > 0 then
        -- this.HandleDie(guid, sourceName)
        this.overkillSources[guid] = "SPELL"..","..spellID
      end
    elseif "ENVIRONMENTAL_DAMAGE" == subevent then
      -- 环境伤害
      local type = select(12, ...)
      this.overkillSources[guid] = type
    elseif "UNIT_DIED" == subevent then
      local overkillSource = this.overkillSources[guid] or "Unknown"
      print("die"..overkillSource)
      this.HandleDie(guid, overkillSource)
      this.overkillSources[guid] = nil
    end

  end
end
