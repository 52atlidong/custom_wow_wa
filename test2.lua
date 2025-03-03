function(event, ...)
  local arg1, arg2 = ...
  local this = aura_env
  
  
  if "LYC_INIT" == event and not arg1 then
    this.Init()
  elseif "LYC_UPDATE_BAR" == event and arg1 then
    this.UpdateBar(...)
  elseif "LYC_UPDATE_RESOURCES" == event then
    this.UpdateResources()
  elseif "PLAYER_ENTERING_WORLD" == event then
    if arg1 or arg2 then
      this.ThrottledInit()
      
      C_Timer.After(2, function ()
          WeakAuras.ScanEvents("LYC_INIT", true)
      end)
    end
  else
    if this and this.ThrottledInit then
      this.ThrottledInit()
    end
  end
  return true
end

