local addonName, ns = ...

ns.Modules = ns.Modules or {}
local MailHistory = {}
ns.Modules.MailHistory = MailHistory

local MAX_HISTORY_NAMES = 100
local MAX_NAME_LENGTH = 64
local DROPDOWN_MAX_VISIBLE = 8
local DROPDOWN_ROW_HEIGHT = 20

-- 드롭다운 프레임
local dropdownFrame = nil
local dropdownRows = {}

local function sanitizeName(name)
    if not name or type(name) ~= "string" then return nil end
    name = ns.Utils.Trim(name)
    if #name == 0 or #name > MAX_NAME_LENGTH then return nil end
    if name:find("[<>\"']") then return nil end
    return name
end

local function getRealmSuffix()
    if type(GetRealmName) == "function" then
        return GetRealmName() or "Unknown"
    end
    return "Unknown"
end

local function buildNameKey(name)
    if name and name:find("-", 1, true) then return name end
    return (name or "") .. "-" .. getRealmSuffix()
end

-- ============================================================
-- DB 접근 (ns.DB:GetMailHistorySettings() 경유, names 서브테이블 보장)
-- ============================================================

function MailHistory:GetHistory()
    if not ns.DB then return { names = {} } end
    local settings = ns.DB:GetMailHistorySettings()
    settings.names = settings.names or {}
    return settings
end

function MailHistory:GetNames()
    local history = self:GetHistory()
    history.names = history.names or {}
    return history.names
end

function MailHistory:RecordSend(recipientName)
    recipientName = sanitizeName(recipientName)
    if not recipientName then return end

    local key = buildNameKey(recipientName)
    local names = self:GetNames()
    names[key] = names[key] or { count = 0 }
    names[key].count = (names[key].count or 0) + 1
    names[key].lastSent = time()
    names[key].displayName = recipientName

    -- 최대 개수 초과 시 가장 오래된 항목 제거
    local keys = {}
    for k, v in pairs(names) do
        keys[#keys + 1] = { key = k, lastSent = v.lastSent or 0 }
    end

    if #keys > MAX_HISTORY_NAMES then
        table.sort(keys, function(a, b) return a.lastSent < b.lastSent end)
        local toRemove = #keys - MAX_HISTORY_NAMES
        for i = 1, toRemove do
            names[keys[i].key] = nil
        end
    end
end

function MailHistory:DeleteName(key)
    self:GetNames()[key] = nil
end

function MailHistory:ClearAll()
    self:GetHistory().names = {}
end

function MailHistory:GetMatchingNames(prefix)
    if not prefix or prefix == "" then return {} end
    prefix = string.lower(prefix)
    local names = self:GetNames()
    local results = {}

    for key, data in pairs(names) do
        local displayName = data.displayName or key
        if string.lower(displayName):sub(1, #prefix) == prefix
            or string.lower(key):sub(1, #prefix) == prefix then
            results[#results + 1] = {
                key = key,
                displayName = displayName,
                lastSent = data.lastSent or 0,
                count = data.count or 1,
            }
        end
    end

    table.sort(results, function(a, b) return a.lastSent > b.lastSent end)
    return results
end

-- ============================================================
-- 드롭다운 UI
-- ============================================================

local function ensureDropdown()
    if dropdownFrame then return dropdownFrame end

    dropdownFrame = CreateFrame("Frame", "ABPMMailHistoryDropdown", UIParent, "BackdropTemplate")
    dropdownFrame:SetFrameStrata("TOOLTIP")
    dropdownFrame:SetFrameLevel(100)
    dropdownFrame:Hide()

    if dropdownFrame.SetBackdrop then
        dropdownFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left=2, right=2, top=2, bottom=2 },
        })
        dropdownFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
        dropdownFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
    end

    return dropdownFrame
end

local function ensureDropdownRow(index)
    local parent = ensureDropdown()
    if dropdownRows[index] then return dropdownRows[index] end

    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(DROPDOWN_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -((index - 1) * DROPDOWN_ROW_HEIGHT + 4))
    row:SetPoint("RIGHT", parent, "RIGHT", -4, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.3, 0.3, 0.6, 0.5)

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    nameText:SetPoint("LEFT", row, "LEFT", 2, 0)
    nameText:SetTextColor(0.90, 0.90, 1.00, 1)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local deleteBtn = CreateFrame("Button", nil, row)
    deleteBtn:SetSize(16, 16)
    deleteBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    deleteBtn:SetNormalFontObject(GameFontHighlightSmall)
    deleteBtn:GetFontString():SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    deleteBtn:GetFontString():SetText("×")
    deleteBtn:GetFontString():SetTextColor(0.80, 0.40, 0.40, 1)
    row.deleteBtn = deleteBtn

    dropdownRows[index] = row
    return row
end

local currentDropdownData = {}

local function hideDropdown()
    if dropdownFrame then dropdownFrame:Hide() end
    currentDropdownData = {}
end

local function showDropdown(editBox, matches)
    if not editBox or #matches == 0 then
        hideDropdown()
        return
    end

    local dropdown = ensureDropdown()
    local visibleCount = math.min(#matches, DROPDOWN_MAX_VISIBLE)
    currentDropdownData = matches

    dropdown:SetSize(editBox:GetWidth() or 150, visibleCount * DROPDOWN_ROW_HEIGHT + 8)

    local ok = pcall(function()
        dropdown:ClearAllPoints()
        dropdown:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -2)
    end)
    if not ok then return end

    for i = 1, visibleCount do
        local row = ensureDropdownRow(i)
        local match = matches[i]
        row.nameText:SetText(match.displayName)
        row.currentKey = match.key
        row.currentName = match.displayName

        row:SetScript("OnClick", function()
            if editBox and editBox.SetText then
                local baseName = match.displayName
                if baseName:find("-", 1, true) then
                    baseName = baseName:match("^([^%-]+)")
                end
                pcall(function()
                    editBox:SetText(baseName or match.displayName)
                    editBox:SetCursorPosition(#(baseName or match.displayName))
                end)
            end
            hideDropdown()
        end)

        row.deleteBtn:SetScript("OnClick", function()
            MailHistory:DeleteName(match.key)
            hideDropdown()
        end)

        row:Show()
    end

    for i = visibleCount + 1, #dropdownRows do
        dropdownRows[i]:Hide()
    end

    dropdown:Show()
    dropdown:Raise()
end

-- ============================================================
-- EditBox 훅 (MAIL_SHOW 이후 lazy 연결)
-- ============================================================

function MailHistory:HookSendMailEditBox()
    if self._editBoxHooked then return end
    local editBox = SendMailNameEditBox
    if not editBox then return end
    self._editBoxHooked = true

    local function onTextChanged(eb)
        if not ns.DB or not ns.DB:IsMailHistoryEnabled() then
            hideDropdown()
            return
        end
        local text = ""
        local ok = pcall(function() text = eb:GetText() or "" end)
        if not ok or text == "" then
            hideDropdown()
            return
        end
        local matches = MailHistory:GetMatchingNames(text)
        if #matches == 0 then
            hideDropdown()
        else
            showDropdown(eb, matches)
        end
    end

    local ok = pcall(function()
        editBox:HookScript("OnTextChanged", onTextChanged)
        editBox:HookScript("OnHide",         hideDropdown)
        editBox:HookScript("OnEscapePressed", hideDropdown)
    end)

    if ok then
        ns.Utils.Debug("[MailHistory] SendMailNameEditBox 훅 완료")
    else
        self._editBoxHooked = false
        ns.Utils.Debug("[MailHistory] SendMailNameEditBox 훅 실패")
    end
end

-- ============================================================
-- 초기화
-- ============================================================

function MailHistory:Initialize()
    if self._initialized then return end
    self._initialized = true

    -- SendMailNameEditBox 는 우편함을 처음 열 때 생성됨 → MAIL_SHOW 이후 훅
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("MAIL_SHOW")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "MAIL_SHOW" then
            C_Timer.After(0.1, function()
                MailHistory:HookSendMailEditBox()
            end)
        end
    end)

    -- 혹시 이미 열려있을 경우 즉시 시도
    if SendMailNameEditBox then
        self:HookSendMailEditBox()
    end

    ns.Utils.Debug("[MailHistory] 초기화 완료")
end
