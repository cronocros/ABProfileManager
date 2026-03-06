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

    printHelp()
end
