-- EVENT
-- LYC_MOUNT_EVENT_DEFAULT,LYC_MOUNT_EVENT_ALT,LYC_MOUNT_EVENT_CTRL,LYC_MOUNT_EVENT_SHIFT
-- macro

-- /run local m = SecureCmdOptionParse("[mod:alt] ALT; [mod:ctrl] CTRL; [mod:shift] SHIFT; DEFAULT") WeakAuras.ScanEvents("LYC_MOUNT_EVENT_"..m)
function (event, ...)
  
  if string.find(event, "LYC_MOUNT_EVENT_") then
    local mod = string.gsub(event, "LYC_MOUNT_EVENT_", "")
    mod = string.lower(mod)
    if LYC_MOUNT.summon then
      LYC_MOUNT.summon(mod)
    end
  end

end



