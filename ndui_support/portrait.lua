-- local frame = oUF_Player

-- print(frame.unit)

local this = aura_env

local classcolorreaction = {
    ["WARRIOR"] = { r1 = 0.77646887302399, g1 = 0.60784178972244, b1 = 0.4274500310421 },
    ["PALADIN"] = { r1 = 0.95686066150665, g1 = 0.54901838302612, b1 = 0.72941017150879 },
    ["HUNTER"] = { r1 = 0.66666519641876, g1 = 0.82744914293289, b1 = 0.44705784320831 },
    ["ROGUE"] = { r1 = 0.99999779462814, g1 = 0.95686066150665, b1 = 0.40784224867821 },
    ["PRIEST"] = { r1 = 0.99999779462814, g1 = 0.99999779462814, b1 = 0.99999779462814 },
    ["DEATHKNIGHT"] = { r1 = 0.76862573623657, g1 = 0.11764679849148, b1 = 0.2274504750967 },
    ["SHAMAN"] = { r1 = 0, g1 = 0.4392147064209, b1 = 0.86666476726532 },
    ["MAGE"] = { r1 = 0.24705828726292, g1 = 0.78039044141769, b1 = 0.92156660556793 },
    ["WARLOCK"] = { r1 = 0.52941060066223, g1 = 0.53333216905594, b1 = 0.93333131074905 },
    ["MONK"] = { r1 = 0, g1 = 0.99999779462814, b1 = 0.59607714414597 },
    ["DRUID"] = { r1 = 0.99999779462814, g1 = 0.48627343773842, b1 = 0.039215601980686 },
    ["DEMONHUNTER"] = { r1 = 0.63921427726746, g1 = 0.1882348805666, b1 = 0.78823357820511 },
    ["EVOKER"] = { r1 = 0.19607843137255, g1 = 0.46666666666667, b1 = 0.53725490196078 },
    ["NPCFRIENDLY"] = { r1 = 0.2, g1 = 1, b1 = 0.2 },
    ["NPCNEUTRAL"] = { r1 = 0.89, g1 = 0.89, b1 = 0 },
    ["NPCUNFRIENDLY"] = { r1 = 0.94, g1 = 0.37, b1 = 0 },
    ["NPCHOSTILE"] = { r1 = 0.8, g1 = 0, b1 = 0 },
}

local function GetClassColorsRGB(unitclass)
    return {
        r = classcolorreaction[unitclass]["r1"],
        g = classcolorreaction[unitclass]["g1"],
        b = classcolorreaction
            [unitclass]["b1"]
    }
end

local function BlizzPortraitsPlayer()
    local frame = oUF_Player

    local name = "player"

    local scale = 0

    if not frame then return end
    if not frame.unit then return end

    if not frame.EltruismPortrait then
        frame.EltruismPortrait = CreateFrame("Frame", name .. "EltruismPortrait", frame)
        frame.EltruismPortrait:SetPoint("CENTER", frame)
        frame.EltruismPortrait:SetSize(64, 64)
        frame.EltruismPortrait:SetFrameLevel(frame:GetFrameLevel() + 18)
        frame.EltruismPortrait:SetFrameStrata(frame:GetFrameStrata())

        frame.EltruismPortrait.border = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitTexture", "OVERLAY",
            nil, 5)
        frame.EltruismPortrait.border:SetTexture(
            "Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\Portrait.tga")
        frame.EltruismPortrait.border:SetParent(frame.EltruismPortrait)
        frame.EltruismPortrait.border:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.Mask = frame.EltruismPortrait:CreateMaskTexture()
        frame.EltruismPortrait.Mask:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\mask.tga",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.EltruismPortrait.Mask:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.portrait = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitPortrait",
            "OVERLAY", nil, 4)
        frame.EltruismPortrait.portrait:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.edge = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitEdge", "OVERLAY", nil,
            6)
        frame.EltruismPortrait.edge:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\Edge.tga")
        frame.EltruismPortrait.edge:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.rare = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitRare", "OVERLAY", nil,
            7)
        frame.EltruismPortrait.rare:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\Rare.tga")
        frame.EltruismPortrait.rare:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.background = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitBackground",
            "OVERLAY", nil, -7)
        frame.EltruismPortrait.background:SetTexture(
        "Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\maskcircle.tga")
        frame.EltruismPortrait.background:SetAllPoints(frame.EltruismPortrait)
        frame.EltruismPortrait.background:SetVertexColor(1, 0, 0, 0)
    end

    if not frame.EltruismPortrait then return end



    frame.EltruismPortrait.portrait:SetMask("")
    frame.EltruismPortrait.portrait:Show()
    frame.EltruismPortrait.border:Show()
    frame.EltruismPortrait.rare:SetAlpha(0)
    frame.EltruismPortrait.edge:SetAlpha(1)

    SetPortraitTexture(frame.EltruismPortrait.portrait, frame.unit, true)

    frame.EltruismPortrait.portrait:AddMaskTexture(frame.EltruismPortrait.Mask)

    frame.EltruismPortrait.portrait:SetTexCoord(scale, 1 - scale, scale, 1 - scale)

    local _, unitclass = UnitClass(frame.unit)

    local classrgb = GetClassColorsRGB(unitclass)

    frame.EltruismPortrait.border:SetVertexColor(classrgb.r, classrgb.g, classrgb.b, 1)
    frame.EltruismPortrait.edge:SetVertexColor(classrgb.r, classrgb.g, classrgb.b, 1)
    -- frame.EltruismPortrait.rare:SetVertexColor(classrgb.r, classrgb.g, classrgb.b, 1)
    -- frame.EltruismPortrait.edge:SetTexCoord(0, 1, 0, 1)
    -- frame.EltruismPortrait.Mask:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\mask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

    -- frame.EltruismPortrait.background:SetVertexColor(1,0,0,0)

    frame.EltruismPortrait:Show()

    -- print(frame.Health)
end

local function CreatePorfraitFrameAndTexture(frame, name, invert, update)
    if not frame.EltruismPortrait then
        frame.EltruismPortrait = CreateFrame("Frame", name .. "EltruismPortrait", frame)
        -- frame.EltruismPortrait:SetPoint("BOTTOMLEFT", frame)
        -- frame.EltruismPortrait:SetSize(78, 78)
        frame.EltruismPortrait:SetFrameLevel(frame:GetFrameLevel() + 18)
        frame.EltruismPortrait:SetFrameStrata(frame:GetFrameStrata())

        frame.EltruismPortrait.border = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitTexture", "OVERLAY",
            nil, 5)
        frame.EltruismPortrait.border:SetTexture(
            "Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\Portrait.tga")
        frame.EltruismPortrait.border:SetParent(frame.EltruismPortrait)
        frame.EltruismPortrait.border:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.Mask = frame.EltruismPortrait:CreateMaskTexture()
        frame.EltruismPortrait.Mask:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\mask.tga",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.EltruismPortrait.Mask:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.portrait = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitPortrait",
            "OVERLAY", nil, 4)
        frame.EltruismPortrait.portrait:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.edge = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitEdge", "OVERLAY", nil,
            6)
        frame.EltruismPortrait.edge:SetTexture("Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\Edge.tga")
        frame.EltruismPortrait.edge:SetAllPoints(frame.EltruismPortrait)

        frame.EltruismPortrait.background = frame.EltruismPortrait:CreateTexture(name .. "EltruismPortraitBackground",
            "OVERLAY", nil, -7)
        frame.EltruismPortrait.background:SetTexture(
        "Interface\\Addons\\ElvUI_EltreumUI\\Media\\Textures\\Portrait\\mask.tga")
        frame.EltruismPortrait.background:SetAllPoints(frame.EltruismPortrait)
        frame.EltruismPortrait.background:SetVertexColor(1, 0, 0, 0)
    end

    if not frame.EltruismPortrait then return end

    SetPortraitTexture(frame.EltruismPortrait.portrait, frame.unit, true)
    frame.EltruismPortrait.portrait:AddMaskTexture(frame.EltruismPortrait.Mask)

    local _, unitclass = UnitClass(frame.unit)
    local classrgb = GetClassColorsRGB(unitclass)
    frame.EltruismPortrait.border:SetVertexColor(classrgb.r, classrgb.g, classrgb.b, 1)
    frame.EltruismPortrait.edge:SetVertexColor(classrgb.r, classrgb.g, classrgb.b, 1)

    frame.EltruismPortrait:SetPoint("BOTTOMLEFT", frame, -64 + 4, -4)
    frame.EltruismPortrait:SetSize(64, 64)
    frame.EltruismPortrait:Show()

end

CreatePorfraitFrameAndTexture(oUF_Player, "player", false, true)

-- ElvUI_mMediaTag\media\portraits\drop\drop_shadow.tga
-- EditMacro()