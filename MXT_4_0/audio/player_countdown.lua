
local this = aura_env

function this.countdown(timer)
  if timer > 0 then
    C_Timer.NewTimer(1, function () WeakAuras.ScanEvents("UPDATE_PLAYER_COUNTDOWN", timer - 1) end)
  end
end

-- local function countdown(timer)
--   timer = timer - 1
--   if timer > 0 then
--     this.countdownTimer = C_Timer.NewTimer(1, function () countdown(timer) end)
--   end
-- end

-- this.countdownStart = function (timer)
--   countdown(timer)
-- end


function (allstates, event, ...)
  allstates[""] = allstates[""] or {
    show = false,
    timer = 0,
    changed = true
  }

  local s = allstates[""]
  if event == "START_PLAYER_COUNTDOWN" then
    local time = select(2, ...)
    print(time)
    s.timer = time
    s.show = true
    aura_env.countdown(time)
    s.changed = true
  elseif event == "UPDATE_PLAYER_COUNTDOWN" then
    local time = select(1, ...)
    print(time)
    s.timer = time
    s.changed = true
    if time == 0 then
      s.show = false
    else
      aura_env.countdown(time)
      s.show = true
    end

  end
  return true
end


