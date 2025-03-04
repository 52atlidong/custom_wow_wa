
local this = aura_env

function this.CheckEnemy()

  local count = 0

  for i = 1, 40 do
    local unit = "nameplate"..i
    if UnitExists(unit) and UnitCanAttack("player", unit) then
      count = count + 1
    end
  end
  return count
end