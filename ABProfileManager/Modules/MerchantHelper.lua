local addonName, ns = ...

ns.Modules = ns.Modules or {}
local MerchantHelper = {}
ns.Modules.MerchantHelper = MerchantHelper

local OVERLAY_ALPHA    = 0.52
local MAX_MERCHANT_SLOTS = 12
local SCAN_COOLDOWN    = 0.8   -- 스캔 최소 간격 (초)
local lastScanTime     = 0

-- ============================================================
-- 아이템 보유/알려진 여부 판단
-- ============================================================

local function getItemSpellID(itemID)
    -- C_Item.GetItemSpell: (spellName, spellID) 또는 단일 숫자 반환 (API 버전별 상이)
    if C_Item and type(C_Item.GetItemSpell) == "function" then
        local ok, r1, r2 = pcall(C_Item.GetItemSpell, itemID)
        if ok then
            -- r2가 숫자이면 (name, spellID) 형식
            if type(r2) == "number" and r2 > 0 then return r2 end
            -- r1이 숫자이면 단일 spellID 반환 형식
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
    -- 전문기술 레시피 확인
    if C_TradeSkillUI and type(C_TradeSkillUI.IsRecipeKnown) == "function" then
        local ok3, k3 = pcall(C_TradeSkillUI.IsRecipeKnown, spellID)
        if ok3 and k3 then return true end
    end
    return false
end

local function isItemOwnedOrKnown(itemID, merchantIndex)
    if not itemID or itemID <= 0 then return false end

    -- 1. 장난감
    if type(PlayerHasToy) == "function" then
        local ok, has = pcall(PlayerHasToy, itemID)
        if ok and has then return true end
    end

    -- 2. 전문기술 레시피 (Midnight 신규 API: GetRecipeInfoForItemID)
    if C_TradeSkillUI and type(C_TradeSkillUI.GetRecipeInfoForItemID) == "function" then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfoForItemID, itemID)
        ns.Utils.Debug(string.format("[MerchantHelper] GetRecipeInfoForItemID(%d): ok=%s learned=%s",
            itemID, tostring(ok), tostring(info and info.learned)))
        if ok and info and info.learned then return true end
    else
        ns.Utils.Debug(string.format("[MerchantHelper] GetRecipeInfoForItemID 없음 (itemID=%d)", itemID))
    end

    -- 3. 도안/레시피 스펠 (spellID가 10000 이상일 때만 신뢰)
    local spellID = getItemSpellID(itemID)
    ns.Utils.Debug(string.format("[MerchantHelper] itemID=%d spellID=%s", itemID, tostring(spellID)))
    if spellID and spellID >= 10000 and isSpellKnownByPlayer(spellID) then return true end

    -- 4. 변신 외관
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

-- ============================================================
-- 상점 슬롯 버튼 탐색 (다중 명명 규칙 시도)
-- ============================================================

local buttonCache = {}  -- index → button 캐시 (매 스캔마다 리셋)

local function findMerchantButton(index)
    if buttonCache[index] then return buttonCache[index] end

    -- 방식 1: 기존 클래식 명명
    local btn = _G["MerchantItem" .. index .. "ItemButton"]
    if btn then
        buttonCache[index] = btn
        return btn
    end

    -- 방식 2: MerchantButton%d 명명 (일부 버전)
    btn = _G["MerchantButton" .. index]
    if btn then
        buttonCache[index] = btn
        return btn
    end

    -- 방식 3: MerchantFrame 자식 중 ItemButton 패턴 탐색 (느리므로 캐시 미스 시 1회)
    if not MerchantHelper._childScanDone then
        MerchantHelper._childScanDone = true
        if MerchantFrame then
            local childIndex = 1
            for _, child in ipairs({ MerchantFrame:GetChildren() }) do
                local name = child.GetName and child:GetName()
                if name and name:find("ItemButton") then
                    -- 자식에서 index 순서로 캐시
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

-- ============================================================
-- 아이템 ID 획득
-- ============================================================

local function getMerchantItemID(index)
    -- 시도 1: C_MerchantFrame.GetItemInfo (table 반환, Midnight 신규)
    if C_MerchantFrame then
        if type(C_MerchantFrame.GetItemInfo) == "function" then
            local ok, info = pcall(C_MerchantFrame.GetItemInfo, index)
            if ok and type(info) == "table" and info.itemID and info.itemID > 0 then
                return info.itemID
            end
        end
        -- 시도 2: C_MerchantFrame.GetMerchantItemID
        if type(C_MerchantFrame.GetMerchantItemID) == "function" then
            local ok, id = pcall(C_MerchantFrame.GetMerchantItemID, index)
            if ok and id and id > 0 then return id end
        end
    end
    -- 시도 3: GetMerchantItemLink → itemID 추출
    if type(GetMerchantItemLink) == "function" then
        local ok, link = pcall(GetMerchantItemLink, index)
        if ok and link then
            local id = tonumber(link:match("item:(%d+)"))
            if id and id > 0 then return id end
        end
    end
    -- 시도 4: 구 API GetMerchantItemInfo (반환: name,tex,price,qty,avail,purchasable,usable,extcost,curID,itemID)
    if type(GetMerchantItemInfo) == "function" then
        local ok, name, _, _, _, _, _, _, _, _, id = pcall(GetMerchantItemInfo, index)
        if ok and name and id and id > 0 then return id end
        -- 일부 버전은 9개 반환 (itemID 누락) → link에서 재시도
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

-- ============================================================
-- 단일 슬롯 오버레이 적용
-- ============================================================

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
        -- itemID 획득 실패: 아직 캐시 미로드일 수 있으므로 잠시 후 재시도
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

    -- 캐시 미적재 시 로드 후 재시도
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

-- ============================================================
-- 공개 API
-- ============================================================

function MerchantHelper:ScanAndMark()
    if not ns.DB or not ns.DB:IsMerchantHelperEnabled() then
        self:HideAllOverlays()
        return
    end

    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    -- throttle: MERCHANT_UPDATE가 연속 발화하는 것을 방지
    local now = GetTime and GetTime() or 0
    if now - lastScanTime < SCAN_COOLDOWN then return end
    lastScanTime = now

    -- 매 스캔마다 버튼 캐시 리셋 (페이지 넘김 등 대응)
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
    -- numItems가 여전히 0이면 버튼 존재 여부로 추론
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

    -- MerchantFrame_UpdateMerchantInfo 훅 (존재 시)
    if type(hooksecurefunc) == "function" and type(MerchantFrame_UpdateMerchantInfo) == "function" then
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
            C_Timer.After(0.15, function()
                ns:SafeCall(MerchantHelper, "ScanAndMark")
            end)
        end)
    end

    -- MERCHANT_FILTER_ITEM_UPDATE 훅 (Midnight 신규 이벤트 대응)
    -- 이 이벤트가 존재하면 상점이 열릴 때마다 추가 갱신됨

    ns.Utils.Debug("[MerchantHelper] 초기화 완료")
end
