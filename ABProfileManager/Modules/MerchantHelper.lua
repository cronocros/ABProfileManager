local addonName, ns = ...

ns.Modules = ns.Modules or {}
local MerchantHelper = {}
ns.Modules.MerchantHelper = MerchantHelper

local OVERLAY_ALPHA    = 0.52
local MAX_MERCHANT_SLOTS = 12
local SCAN_COOLDOWN    = 0.8
local lastScanTime     = 0

local function getItemSpellID(itemID)

    if C_Item and type(C_Item.GetItemSpell) == "function" then
        local ok, r1, r2 = pcall(C_Item.GetItemSpell, itemID)
        if ok then

            if type(r2) == "number" and r2 > 0 then return r2 end

            if type(r1) == "number" and r1 > 0 then return r1 end
        end
    end
    if type(GetItemSpell) == "function" then
        local ok, r1, r2 = pcall(GetItemSpell, itemID)
        if ok then
            if type(r2) == "number" and r2 > 0 then return r2 end
            if type(r1) == "number" and r1 > 0 then return r1 end
        end
    end
    return nil
end

local function isSpellKnownByPlayer(spellID)
    if not spellID then return false end
    local ok1, k1 = pcall(IsSpellKnown, spellID)
    if ok1 and k1 then return true end
    if type(IsPlayerSpell) == "function" then
        local ok2, k2 = pcall(IsPlayerSpell, spellID)
        if ok2 and k2 then return true end
    end

    if C_TradeSkillUI and type(C_TradeSkillUI.IsRecipeKnown) == "function" then
        local ok3, k3 = pcall(C_TradeSkillUI.IsRecipeKnown, spellID)
        if ok3 and k3 then return true end
    end
    return false
end

local function isItemOwnedOrKnown(itemID, merchantIndex)
    if not itemID or itemID <= 0 then return false end

    if type(PlayerHasToy) == "function" then
        local ok, has = pcall(PlayerHasToy, itemID)
        if ok and has then return true end
    end

    if C_TradeSkillUI and type(C_TradeSkillUI.GetRecipeInfoForItemID) == "function" then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfoForItemID, itemID)
        ns.Utils.Debug(string.format("[MerchantHelper] GetRecipeInfoForItemID(%d): ok=%s learned=%s",
            itemID, tostring(ok), tostring(info and info.learned)))
        if ok and info and info.learned then return true end
    else
        ns.Utils.Debug(string.format("[MerchantHelper] GetRecipeInfoForItemID 없음 (itemID=%d)", itemID))
    end

    local spellID = getItemSpellID(itemID)
    ns.Utils.Debug(string.format("[MerchantHelper] itemID=%d spellID=%s", itemID, tostring(spellID)))
    if spellID and spellID >= 10000 and isSpellKnownByPlayer(spellID) then return true end

    if merchantIndex and type(GetMerchantItemLink) == "function" then
        local ok, itemLink = pcall(GetMerchantItemLink, merchantIndex)
        if ok and itemLink and C_TransmogCollection
            and type(C_TransmogCollection.PlayerHasTransmogByItemInfo) == "function" then
            local ok2, hasTransmog = pcall(C_TransmogCollection.PlayerHasTransmogByItemInfo, itemLink)
            if ok2 and hasTransmog then return true end
        end
    end

    return false
end

local buttonCache = {}

local function findMerchantButton(index)
    if buttonCache[index] then return buttonCache[index] end

    local btn = _G["MerchantItem" .. index .. "ItemButton"]
    if btn then
        buttonCache[index] = btn
        return btn
    end

    btn = _G["MerchantButton" .. index]
    if btn then
        buttonCache[index] = btn
        return btn
    end

    if not MerchantHelper._childScanDone then
        MerchantHelper._childScanDone = true
        if MerchantFrame then
            local childIndex = 1
            for _, child in ipairs({ MerchantFrame:GetChildren() }) do
                local name = child.GetName and child:GetName()
                if name and name:find("ItemButton") then

                    if not buttonCache[childIndex] then
                        buttonCache[childIndex] = child
                    end
                    childIndex = childIndex + 1
                end
            end
        end
        return buttonCache[index]
    end

    return nil
end

local function getMerchantItemID(index)

    if C_MerchantFrame then
        if type(C_MerchantFrame.GetItemInfo) == "function" then
            local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
            if ok and type(info) == "table" and info.itemID and info.itemID > 0 then
                return info.itemID
            end
        end

        if type(C_MerchantFrame.GetMerchantItemID) == "function" then
            local ok, id = pcall(C_MerchantFrame.GetMerchantItemID, index)
            if ok and id and id > 0 then return id end
        end
    end

    if type(GetMerchantItemLink) == "function" then
        local ok, link = pcall(GetMerchantItemLink, index)
        if ok and link then
            local id = tonumber(link:match("item:(%d+)"))
            if id and id > 0 then return id end
        end
    end

    if type(GetMerchantItemInfo) == "function" then
        local ok, name, _, _, _, _, _, _, _, _, id = pcall(GetMerchantItemInfo, index)
        if ok and name and id and id > 0 then return id end

        if ok and name then
            if type(GetMerchantItemLink) == "function" then
                local ok2, link = pcall(GetMerchantItemLink, index)
                if ok2 and link then
                    local lid = tonumber(link:match("item:(%d+)"))
                    if lid and lid > 0 then return lid end
                end
            end
        end
    end
    return nil
end

local function applySlotOverlay(index)
    local button = findMerchantButton(index)
    if not button then return end

    local overlayKey = "ABPMMerchantOverlay" .. index
    local overlay = button[overlayKey]
    if not overlay then
        overlay = CreateFrame("Frame", nil, button)
        overlay:SetAllPoints(button)
        overlay:SetFrameLevel(button:GetFrameLevel() + 5)
        overlay:EnableMouse(false)

        local tex = overlay:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(0, 0, 0, OVERLAY_ALPHA)
        overlay.dimTex = tex

        local label = overlay:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        label:SetPoint("CENTER", overlay, "CENTER", 0, 0)
        label:SetTextColor(0.80, 0.80, 0.80, 1)
        label:SetText(ns.L("merchant_known_label"))
        overlay.knownLabel = label

        button[overlayKey] = overlay
    end

    local itemID = getMerchantItemID(index)
    if not itemID then

        C_Timer.After(0.3, function()
            if MerchantFrame and MerchantFrame:IsShown() then
                local retryID = getMerchantItemID(index)
                if retryID then
                    applySlotOverlay(index)
                end
            end
        end)
        overlay:Hide()
        return
    end

    if C_Item and C_Item.IsItemDataCachedByID and not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemByID(itemID)
        C_Timer.After(0.4, function()
            applySlotOverlay(index)
        end)
        overlay:Hide()
        return
    end

    local owned = isItemOwnedOrKnown(itemID, index)
    ns.Utils.Debug(string.format("[MerchantHelper] 슬롯 %d: itemID=%d 보유=%s", index, itemID, tostring(owned)))
    if owned then
        overlay:Show()
    else
        overlay:Hide()
    end
end

function MerchantHelper:ScanAndMark()
    if not ns.DB or not ns.DB:IsMerchantHelperEnabled() then
        self:HideAllOverlays()
        return
    end

    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    local now = GetTime and GetTime() or 0
    if now - lastScanTime < SCAN_COOLDOWN then return end
    lastScanTime = now

    buttonCache = {}
    MerchantHelper._childScanDone = false

    local numItems = 0
    if C_MerchantFrame then
        for _, fname in ipairs({"GetNumMerchantEntries","GetMerchantItemCount","GetNumItems"}) do
            if type(C_MerchantFrame[fname]) == "function" then
                local ok, n = pcall(C_MerchantFrame[fname])
                if ok and n and n > 0 then numItems = n; break end
            end
        end
    end
    if numItems == 0 and type(GetMerchantNumItems) == "function" then
        local ok, n = pcall(GetMerchantNumItems)
        if ok then numItems = n or 0 end
    end

    if numItems == 0 then
        for i = 1, MAX_MERCHANT_SLOTS do
            if findMerchantButton(i) then numItems = i else break end
        end
    end

    ns.Utils.Debug(string.format("[MerchantHelper] 스캔: %d슬롯", numItems))

    for i = 1, math.min(numItems, MAX_MERCHANT_SLOTS) do
        applySlotOverlay(i)
    end

    for i = numItems + 1, MAX_MERCHANT_SLOTS do
        local button = findMerchantButton(i)
        if button then
            local overlayKey = "ABPMMerchantOverlay" .. i
            if button[overlayKey] then
                button[overlayKey]:Hide()
            end
        end
    end
end

function MerchantHelper:HideAllOverlays()
    for i = 1, MAX_MERCHANT_SLOTS do
        local button = findMerchantButton(i)
        if button then
            local overlayKey = "ABPMMerchantOverlay" .. i
            if button[overlayKey] then
                button[overlayKey]:Hide()
            end
        end
    end
end

function MerchantHelper:Initialize()
    if self._initialized then return end
    self._initialized = true

    if type(hooksecurefunc) == "function" and type(MerchantFrame_UpdateMerchantInfo) == "function" then
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
            C_Timer.After(0.15, function()
                ns:SafeCall(MerchantHelper, "ScanAndMark")
            end)
        end)
    end

    ns.Utils.Debug("[MerchantHelper] 초기화 완료")
end
