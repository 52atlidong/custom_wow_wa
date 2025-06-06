local E = OmniCD[1]
local P = E.Party

local activeExBars = P.activeExBars
local extraBarKeys = P.extraBarKeys

local aoeCCIndex = E.profile.Party["party"].frame["aoeCC"]

local exKey = extraBarKeys[aoeCCIndex]

print(exKey)

local exBar = activeExBars[exKey]

if exBar then
  local db = exBar.db

  local icons = exBar.icons

  for index, value in ipairs(icons) do
    -- print(index)
    print(value.spellID)
    -- for k, v in ipairs(value) do
    --   print(k..v)
    -- end
  end

end
