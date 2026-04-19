local _, ns = ...

local Commands = {}
ns.Commands = Commands

local function buildDefaultSelection()
    return {
        mode = ns.Constants.APPLY_MODE.FULL,
        barIndex = 1,
        startBar = 1,
        endBar = 2,
        startSlot = ns.Constants.LOGICAL_SLOT_MIN,
        endSlot = ns.Constants.LOGICAL_SLOT_MAX,
        clearBeforeApply = true,
    }
end

local function printHelp()
    ns.Utils.Print(ns.L("help_header"))
    ns.Utils.Print(ns.L("help_open"))
    ns.Utils.Print(ns.L("help_help"))
    ns.Utils.Print(ns.L("help_list"))
    ns.Utils.Print(ns.L("help_savetemplate"))
    ns.Utils.Print(ns.L("help_delete_template"))
    ns.Utils.Print(ns.L("help_undo"))
    ns.Utils.Print(ns.L("help_debug"))
    ns.Utils.Print(ns.L("help_apply_template"))
    ns.Utils.Print(ns.L("help_clear"))
    ns.Utils.Print(ns.L("help_quote"))
    ns.Utils.Print(ns.L("help_verifywp"))
    ns.Utils.Print("/abpm bankcheck   - 전투부대 은행 가용 상태 확인")
    ns.Utils.Print("/abpm bankreset   - 전투부대 은행 세션 강제 초기화")
end

local PROFESSION_NAME_MAP = {
    alchemy = true, blacksmithing = true, enchanting = true, engineering = true,
    herbalism = true, inscription = true, jewelcrafting = true, leatherworking = true,
    mining = true, skinning = true, tailoring = true, cooking = true, fishing = true,
}

local function runVerifyWaypoints(filterProfession)
    local waypoints = ns.Data and ns.Data.ProfessionKnowledgeWaypoints
    if not waypoints or not waypoints.treasures then
        ns.Utils.Print(ns.L("verifywp_no_data"))
        return
    end

    local tracker = ns.Modules and ns.Modules.ProfessionKnowledgeTracker
    local tomtom = ns.Modules and ns.Modules.TomTomBridge
    local count = 0
    local addedCount = 0

    for profession, items in pairs(waypoints.treasures) do
        if not filterProfession or string.lower(filterProfession) == profession then
            for questID, data in pairs(items) do
                count = count + 1
                local completed = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
                    and C_QuestLog.IsQuestFlaggedCompleted(questID)
                if not completed then
                    if tomtom and tomtom.AddWaypoint then
                        ns:SafeCall(tomtom, "AddWaypoint", data.mapID, data.x / 100, data.y / 100, data.title or tostring(questID))
                        addedCount = addedCount + 1
                    else
                        ns.Utils.Print(string.format("  [%s] %s - mapID:%d (%.2f, %.2f)",
                            profession, data.title or "?", data.mapID or 0, data.x or 0, data.y or 0))
                        addedCount = addedCount + 1
                    end
                end
            end
        end
    end

    if tomtom and tomtom.AddWaypoint then
        ns.Utils.Print(ns.L("verifywp_added", addedCount, count))
    else
        ns.Utils.Print(ns.L("verifywp_listed", addedCount, count))
    end
end

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function printList(titleKey, values)
    ns.Utils.Print(ns.L(titleKey))
    if #values == 0 then
        ns.Utils.Print("  " .. ns.L("no_items"))
        return
    end

    for _, value in ipairs(values) do
        ns.Utils.Print("  " .. value)
    end
end

local function isRangeToken(token)
    token = string.lower(token or "")
    return token == "full"
        or token == "bar"
        or token == "bars"
        or token == "slots"
        or token == "clear"
        or token == "noclear"
end

local function parseSelectionArgs(args, startIndex)
    local selection = buildDefaultSelection()
    local token = string.lower(args[startIndex] or "")
    local consumed = startIndex - 1

    if token == "" then
        return selection, consumed
    end

    if token == "full" then
        selection.mode = ns.Constants.APPLY_MODE.FULL
        consumed = startIndex
    elseif token == "bar" then
        selection.mode = ns.Constants.APPLY_MODE.BAR
        selection.barIndex = ns.Utils.SafeToNumber(args[startIndex + 1], nil)
        consumed = startIndex + 1
    elseif token == "bars" then
        selection.mode = ns.Constants.APPLY_MODE.BAR_RANGE
        selection.startBar = ns.Utils.SafeToNumber(args[startIndex + 1], nil)
        selection.endBar = ns.Utils.SafeToNumber(args[startIndex + 2], nil)
        consumed = startIndex + 2
    elseif token == "slots" then
        selection.mode = ns.Constants.APPLY_MODE.SLOT_RANGE
        selection.startSlot = ns.Utils.SafeToNumber(args[startIndex + 1], nil)
        selection.endSlot = ns.Utils.SafeToNumber(args[startIndex + 2], nil)
        consumed = startIndex + 2
    elseif token == "clear" then
        selection.clearBeforeApply = true
        consumed = startIndex
    elseif token == "noclear" then
        selection.clearBeforeApply = false
        consumed = startIndex
    else
        return nil, nil, ns.L("error_invalid_range_mode")
    end

    local nextToken = string.lower(args[consumed + 1] or "")
    if nextToken == "clear" then
        selection.clearBeforeApply = true
        consumed = consumed + 1
    elseif nextToken == "noclear" then
        selection.clearBeforeApply = false
        consumed = consumed + 1
    end

    local normalized, err = ns.Modules.RangeCopyManager:NormalizeSelection(selection)
    if not normalized then
        return nil, nil, err
    end

    return normalized, consumed
end

local function parseTemplateApply(args)
    if string.lower(args[2] or "") ~= "template" then
        return nil, nil, ns.L("error_invalid_source_kind")
    end

    local rangeStartIndex = nil
    for index = 4, #args do
        if isRangeToken(args[index]) then
            rangeStartIndex = index
            break
        end
    end

    local templateEndIndex = rangeStartIndex and (rangeStartIndex - 1) or #args
    local templateName = ns.Utils.Trim(ns.Utils.JoinArgs(args, 3, templateEndIndex))
    if not templateName or templateName == "" then
        return nil, nil, ns.L("error_source_name_required")
    end

    local selection, _, err = parseSelectionArgs(args, rangeStartIndex or (#args + 1))
    if not selection then
        return nil, nil, err
    end

    return templateName, selection
end

function Commands:Initialize()
    if self._slashRegistered then
        return
    end

    SLASH_ABPROFILEMANAGER1 = "/abpm"
    SlashCmdList.ABPROFILEMANAGER = function(message)
        Commands:HandleSlash(message)
    end

    self._slashRegistered = true
end

function Commands:HandleSlash(message)
    local args = ns.Utils.SplitArgs(ns.Utils.Trim(message or ""))
    local command = string.lower(args[1] or "")
    ns.Utils.Debug("Slash command: " .. (message or ""))

    if command == "" then
        ns.UI.MainWindow:Toggle()
        return
    end

    if command == "help" then
        printHelp()
        return
    end

    if command == "list" then
        printList("templates", ns.Modules.ProfileManager:ListTemplates())
        return
    end

    if command == "savetemplate" or command == "save" then
        local templateName = ns.Utils.Trim(ns.Utils.JoinArgs(args, 2))
        ns.Modules.ProfileManager:RequestSaveTemplate(templateName, {
            onComplete = function(snapshot, err)
                if not snapshot then
                    ns.Utils.Print(err)
                    setStatus(err)
                    return
                end

                ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, snapshot.sourceKey)
                local statusMessage = ns.L("saved_template", snapshot.sourceKey)
                ns.Utils.Print(statusMessage)
                setStatus(statusMessage)
                ns:RefreshUI()
            end,
        })
        return
    end

    if command == "delete" then
        if string.lower(args[2] or "") ~= "template" then
            printHelp()
            return
        end

        local templateName = ns.Utils.Trim(ns.Utils.JoinArgs(args, 3))
        if templateName == "" then
            printHelp()
            return
        end

        ns.UI.ConfirmDialogs:ShowDeleteConfirm(
            ns.L("confirm_delete_text", ns.Utils.FormatSourceLabel(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)),
            function()
                local deleted, err = ns.Modules.ProfileManager:DeleteSource(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)
                if not deleted then
                    ns.Utils.Print(err)
                    setStatus(err)
                    return
                end

                local selectedSource = ns:GetSelectedSource()
                if selectedSource and selectedSource.kind == ns.Constants.SOURCE_KIND.TEMPLATE and selectedSource.key == templateName then
                    ns:SetSelectedSource(nil, nil)
                end

                local statusMessage = ns.L(
                    "deleted_source",
                    ns.Utils.FormatSourceLabel(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)
                )
                ns.Utils.Print(statusMessage)
                setStatus(statusMessage)
                ns:RefreshUI()
            end
        )
        return
    end

    if command == "ahdebug" then
        if not AuctionHouseFrame or not AuctionHouseFrame:IsVisible() then
            ns.Utils.Print("[AH Debug] 경매장을 먼저 열어주세요.")
            return
        end
        local mode = string.lower(args[2] or "ah")
        local results = {}
        local function getAnyText(f)
            local ok, result = pcall(function()
                if type(f.GetText) == "function" then
                    local t = f:GetText()
                    if t and t ~= "" then return t end
                end
                for _, r in ipairs({ f:GetRegions() }) do
                    if r and type(r.GetText) == "function" then
                        local t = r:GetText()
                        if t and t ~= "" then return t end
                    end
                end
                return nil
            end)
            return ok and result or nil
        end
        local function scanFrame(f, depth, maxDepth)
            if depth > maxDepth or not f then return end
            local text = getAnyText(f)
            if text then
                local ftype = f.GetObjectType and f:GetObjectType() or "?"
                local vis = (type(f.IsVisible) == "function" and f:IsVisible()) and "V" or "H"
                results[#results+1] = string.format("[d%d][%s][%s] %s", depth, ftype, vis, text)
            end
            for _, child in ipairs({ f:GetChildren() }) do
                scanFrame(child, depth + 1, maxDepth)
            end
        end
        if mode == "checks" then
            -- scan AuctionHouseFrame for all CheckButtons (by type, bypass text taint)
            ns.Utils.Print("[AH Debug] CheckButton 스캔 (d12):")
            local function scanChecks(f, depth, parentName)
                if depth > 12 or not f then return end
                local okv, vis = pcall(function() return f:IsVisible() end)
                local okn, name = pcall(function() return f:GetName() end)
                local ftype = f.GetObjectType and f:GetObjectType() or "?"
                if ftype == "CheckButton" then
                    local okc, checked = pcall(function() return f:GetChecked() end)
                    results[#results+1] = string.format("[d%d][%s][%s] name=%s parent=%s checked=%s",
                        depth, ftype, (okv and vis) and "V" or "H",
                        tostring(okn and name or "?"),
                        tostring(parentName or "?"),
                        tostring(okc and checked or "?"))
                end
                local okc2, children = pcall(function() return { f:GetChildren() } end)
                if okc2 then
                    local myName = (okn and name) or parentName
                    for _, child in ipairs(children) do
                        scanChecks(child, depth + 1, myName)
                    end
                end
            end
            scanChecks(AuctionHouseFrame, 0, "AuctionHouseFrame")
        elseif mode == "names" then
            -- scan AuctionHouseFrame for named frames (useful when text is tainted)
            ns.Utils.Print("[AH Debug] AuctionHouseFrame 이름 스캔 (d12):")
            local function scanNames(f, depth)
                if depth > 12 or not f then return end
                local ok, name = pcall(function() return f:GetName() end)
                local okv, vis = pcall(function() return f:IsVisible() end)
                if ok and name then
                    local ftype = f.GetObjectType and f:GetObjectType() or "?"
                    results[#results+1] = string.format("[d%d][%s][%s] %s", depth, ftype, (okv and vis) and "V" or "H", name)
                end
                local okc, children = pcall(function() return { f:GetChildren() } end)
                if okc then
                    for _, child in ipairs(children) do
                        scanNames(child, depth + 1)
                    end
                end
            end
            scanNames(AuctionHouseFrame, 0)
        elseif mode == "find" then
            -- search UIParent visible children for frames whose text contains keyword (depth 12)
            local keyword = ns.Utils.Trim(ns.Utils.JoinArgs(args, 3))
            ns.Utils.Print("[AH Debug] 키워드 검색: '" .. (keyword or "") .. "' (d12)")
            local function findByText(f, depth)
                if depth > 12 or not f then return end
                local text = getAnyText(f)
                if text then
                    local ok2, found = pcall(function()
                        return keyword == "" or string.find(text, keyword, 1, true)
                    end)
                    if ok2 and found then
                        local ftype = f.GetObjectType and f:GetObjectType() or "?"
                        local okv, vis = pcall(function() return f:IsVisible() end)
                        results[#results+1] = string.format("[d%d][%s][%s] %s", depth, ftype, (okv and vis) and "V" or "H", text)
                    end
                end
                local okc, children = pcall(function() return { f:GetChildren() } end)
                if okc then
                    for _, child in ipairs(children) do
                        findByText(child, depth + 1)
                    end
                end
            end
            for _, child in ipairs({ UIParent:GetChildren() }) do
                local ok, visible = pcall(function() return child:IsVisible() end)
                if ok and visible then
                    findByText(child, 0)
                end
            end
        elseif mode == "ui" then
            -- scan UIParent top-level children (visible only, depth 6)
            ns.Utils.Print("[AH Debug] UIParent 스캔 (visible, d6):")
            for _, child in ipairs({ UIParent:GetChildren() }) do
                local ok, visible = pcall(function() return child:IsVisible() end)
                if ok and visible then
                    scanFrame(child, 0, 6)
                end
            end
        else
            -- default: scan AuctionHouseFrame
            local childCount = select("#", AuctionHouseFrame:GetChildren())
            ns.Utils.Print("[AH Debug] AuctionHouseFrame 직계 자식 수: " .. childCount)
            scanFrame(AuctionHouseFrame, 0, 10)
        end
        ns.Utils.Print("[AH Debug] 결과 " .. #results .. "개:")
        for _, line in ipairs(results) do
            ns.Utils.Print("  " .. line)
        end
        return
    end

    if command == "log" then
        -- 디버그 로그를 팝업 EditBox에 출력 (복사 가능)
        local log = ns.Utils.GetDebugLog and ns.Utils.GetDebugLog() or {}
        if #log == 0 then
            ns.Utils.Print("디버그 로그가 없습니다. /abpm debug on 으로 활성화 후 재시도하세요.")
            return
        end
        local text = table.concat(log, "\n")
        -- 기존 팝업 재사용
        if ABPMLogPopup then ABPMLogPopup:Hide() end
        local popup = CreateFrame("Frame", "ABPMLogPopup", UIParent, "BackdropTemplate")
        popup:SetSize(580, 380)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("DIALOG")
        popup:SetClampedToScreen(true)
        if popup.SetBackdrop then
            popup:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
                tile=true, tileSize=32, edgeSize=32,
                insets={left=8,right=8,top=8,bottom=8} })
        end
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", function(f) f:StartMoving() end)
        popup:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

        local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() popup:Hide() end)

        -- 스크롤 프레임
        local sf = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -28)
        sf:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 38)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetWidth(510)
        eb:SetAutoFocus(false)
        eb:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "")
        eb:SetText(text)
        eb:HighlightText()
        sf:SetScrollChild(eb)

        local clrBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        clrBtn:SetSize(90, 22)
        clrBtn:SetPoint("BOTTOMLEFT", 14, 10)
        clrBtn:SetText("로그 지우기")
        clrBtn:SetScript("OnClick", function()
            if ns.Utils.ClearDebugLog then ns.Utils.ClearDebugLog() end
            eb:SetText("(로그 지움)")
        end)
        popup:Show()
        return
    end

    if command == "debug" then
        local mode = string.lower(args[2] or "toggle")
        if mode == "status" then
            local statusMessage = ns.L(
                "debug_status",
                ns.DB:IsDebugEnabled() and ns.L("debug_status_enabled") or ns.L("debug_status_disabled")
            )
            ns.Utils.Print(statusMessage)
            setStatus(statusMessage)
            return
        end

        local enabled
        if mode == "on" then
            enabled = true
        elseif mode == "off" then
            enabled = false
        else
            enabled = not ns.DB:IsDebugEnabled()
        end

        ns.DB:SetDebugEnabled(enabled)
        local statusMessage = enabled and ns.L("debug_enabled") or ns.L("debug_disabled")
        ns.Utils.Print(statusMessage)
        setStatus(statusMessage)
        ns:RefreshUI()
        return
    end

    if command == "clear" then
        local selection, _, err = parseSelectionArgs({ "", "slots", args[2], args[3] }, 2)
        if not selection then
            ns.Utils.Print(err)
            setStatus(err)
            return
        end

        ns.Modules.ProfileManager:RequestClearSelection(selection, {
            onComplete = function(result, clearErr)
                if not result then
                    setStatus(clearErr)
                    return
                end

                setStatus(result.message)
            end,
        })
        return
    end

    if command == "undo" then
        ns.Modules.UndoManager:RequestUndo({
            onComplete = function(result, undoErr)
                if not result then
                    ns.Utils.Print(undoErr)
                    setStatus(undoErr)
                    return
                end

                ns.Utils.Print(result.message)
                setStatus(result.message)
                ns:RefreshUI()
            end,
        })
        return
    end

    if command == "apply" then
        local templateName, selection, err = parseTemplateApply(args)
        if not templateName then
            ns.Utils.Print(err)
            setStatus(err)
            return
        end

        ns.Modules.ProfileManager:RequestApplySource(ns.Constants.SOURCE_KIND.TEMPLATE, templateName, selection, {
            onComplete = function(result, applyErr)
                if not result then
                    setStatus(applyErr)
                    return
                end

                ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)
                setStatus(result.message)
            end,
        })
        return
    end

    if command == "verifywp" then
        local filterProfession = ns.Utils.Trim(ns.Utils.JoinArgs(args, 2))
        if filterProfession == "" then
            filterProfession = nil
        end

        runVerifyWaypoints(filterProfession)
        return
    end

    if command == "bankcheck" then
        local ok = ns.ABPM_CanUseWarbandBank and ns.ABPM_CanUseWarbandBank()
        if ok then
            ns.Utils.Print("[ABPM] 전투부대 은행 사용 가능 상태입니다.")
        end
        return
    end

    if command == "bankreset" then
        if ns.ABPM_ResetBankSession then
            ns.ABPM_ResetBankSession()
        end
        return
    end

    printHelp()
end
