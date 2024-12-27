-- 核心 - 马戏团 - LYC 触发器2
-- 自定义:事件:GROUP_ROSTER_UPDATE
function (event, ...)
  local this = aura_env
  if "GROUP_ROSTER_UPDATE" == event then
    this.CheckGroupMembers()
  end
  return false
end

