local _, ns = ...

local ProfileManager = {}
ns.Modules.ProfileManager = ProfileManager

local function enrichSnapshot(snapshot, templateName)
    local currentCharacter = ns.DB:GetCharacterKey()
    local currentRecord = ns.DB:RefreshCharacterRecord()

    snapshot.sourceType = ns.Constants.SOURCE_KIND.TEMPLATE
    snapshot.sourceKey = templateName
    snapshot.characterKey = currentCharacter
    snapshot.class = currentRecord and currentRecord.class or "UNKNOWN"
    snapshot.specID = currentRecord and currentRecord.specID or 0
    snapshot.savedAt = date("%Y-%m-%d %H:%M:%S")
    return snapshot
end

function ProfileManager:Initialize()
    self.lastSelectedSource = nil
end

function ProfileManager:CaptureCurrentBars(templateName)
    ns.Utils.Debug(string.format("Capturing bars for template:%s", tostring(templateName)))
    local snapshot, err = ns.Modules.ActionBarScanner:ScanAll()
    if not snapshot then
        return nil, err
    end

    return enrichSnapshot(snapshot, templateName)
end

function ProfileManager:SaveTemplate(templateName)
    templateName = ns.Utils.SanitizeSingleLine(templateName or "")
    if templateName == "" then
        return nil, ns.L("error_template_name_required")
    end

    local snapshot, err = self:CaptureCurrentBars(templateName)
    if not snapshot then
        return nil, err
    end

    ns.DB:SetTemplate(templateName, snapshot)
    ns.Utils.Debug(string.format("Saved template '%s'", templateName))
    return snapshot
end

function ProfileManager:GetUniqueTemplateName(baseName)
    local trimmed = ns.Utils.SanitizeSingleLine(baseName or "")
    if trimmed == "" then
        trimmed = "템플릿"
    end

    local candidate = trimmed
    local index = 2
    while ns.DB:HasTemplate(candidate) do
        candidate = string.format("%s %d", trimmed, index)
        index = index + 1
    end

    return candidate
end

function ProfileManager:DuplicateTemplate(sourceName, targetName)
    sourceName = ns.Utils.SanitizeSingleLine(sourceName or "")
    if sourceName == "" then
        return nil, ns.L("error_duplicate_source_first")
    end

    local source, err = self:GetSource(ns.Constants.SOURCE_KIND.TEMPLATE, sourceName)
    if not source then
        return nil, err
    end

    targetName = ns.Utils.SanitizeSingleLine(targetName or "")
    if targetName == "" or targetName == sourceName then
        targetName = self:GetUniqueTemplateName(sourceName .. " 복제")
    elseif ns.DB:HasTemplate(targetName) then
        targetName = self:GetUniqueTemplateName(targetName)
    end

    local copy = ns.Utils.DeepCopy(source)
    copy.sourceType = ns.Constants.SOURCE_KIND.TEMPLATE
    copy.sourceKey = targetName
    copy.savedAt = date("%Y-%m-%d %H:%M:%S")

    ns.DB:SetTemplate(targetName, copy)
    ns.Utils.Debug(string.format("Duplicated template '%s' -> '%s'", sourceName, targetName))
    return copy
end

function ProfileManager:ListTemplates()
    return ns.Utils.SortedKeys(ns.DB:GetTemplates())
end

function ProfileManager:DeleteSource(kind, key)
    key = ns.Utils.SanitizeSingleLine(key or "")
    if kind ~= ns.Constants.SOURCE_KIND.TEMPLATE then
        return nil, ns.L("error_invalid_source_kind")
    end

    return ns.DB:DeleteTemplate(key)
end

function ProfileManager:GetSource(kind, key)
    key = ns.Utils.SanitizeSingleLine(key or "")
    if kind ~= ns.Constants.SOURCE_KIND.TEMPLATE then
        return nil, ns.L("error_invalid_source_kind")
    end

    local template = ns.DB:GetTemplate(key)
    if template then
        return template
    end

    return nil, ns.L("error_template_not_found", key or "unknown")
end

function ProfileManager:GetSourceDetails(kind, key)
    local source, err = self:GetSource(kind, key)
    if not source then
        return nil, err
    end

    return {
        kind = kind,
        key = key,
        kindLabel = ns.L("source_kind_template"),
        label = ns.Utils.FormatSourceLabel(kind, key),
        savedAt = source.savedAt,
        characterKey = source.characterKey,
        class = source.class,
        specID = source.specID,
        source = source,
    }
end

function ProfileManager:ExecuteApplySource(kind, key, selection)
    local source, err = self:GetSource(kind, key)
    if not source then
        return nil, err
    end

    local plan, planErr = ns.Modules.RangeCopyManager:BuildApplyPlan(source, selection)
    if not plan then
        return nil, planErr
    end

    ns.Utils.Debug(string.format("Applying template %s with %s", key, plan.selection.summary))
    return ns.Modules.ActionBarApplier:ApplyPlan(plan)
end

function ProfileManager:ExecuteClearSelection(selection)
    local plan, err = ns.Modules.RangeCopyManager:BuildClearPlan(selection)
    if not plan then
        return nil, err
    end

    return ns.Modules.ActionBarApplier:ApplyPlan(plan)
end

function ProfileManager:RunConfirmedOperation(confirmText, executor, callbacks)
    callbacks = callbacks or {}

    local function complete(result, err)
        if callbacks.onComplete then
            callbacks.onComplete(result, err)
        end

        ns:RefreshUI()
    end

    local function execute()
        local result, err = executor()
        if not result and err then
            ns.Utils.Print(err)
            ns:SafeCall(ns.UI.MainWindow, "SetStatus", err)
        end
        complete(result, err)
    end

    if ns.DB:ShouldConfirmActions() then
        ns.UI.ConfirmDialogs:ShowConfirm(confirmText, execute)
        return true
    end

    execute()
    return true
end

function ProfileManager:RequestApplySource(kind, key, selection, callbacks)
    local source, err = self:GetSource(kind, key)
    if not source then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, err)
        end
        return nil, err
    end

    local plan, planErr = ns.Modules.RangeCopyManager:BuildApplyPlan(source, selection)
    if not plan then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, planErr)
        end
        return nil, planErr
    end

    local confirmText = ns.L(
        "confirm_apply_text",
        plan.source.key or key,
        plan.selection.summary,
        plan.selection.clearBeforeApply and ns.L("source_details_yes") or ns.L("source_details_no")
    )

    return self:RunConfirmedOperation(confirmText, function()
        return ns.Modules.ActionBarApplier:ApplyPlan(plan)
    end, callbacks)
end

function ProfileManager:RequestClearSelection(selection, callbacks)
    local plan, err = ns.Modules.RangeCopyManager:BuildClearPlan(selection)
    if not plan then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, err)
        end
        return nil, err
    end

    local confirmText = ns.L("confirm_clear_text", plan.selection.summary, #plan.logicalSlots)

    if plan.selection.mode == ns.Constants.APPLY_MODE.FULL then
        confirmText = confirmText .. "\n\n" .. ns.L("confirm_clear_full_warning")
    end

    return self:RunConfirmedOperation(confirmText, function()
        return ns.Modules.ActionBarApplier:ApplyPlan(plan)
    end, callbacks)
end
