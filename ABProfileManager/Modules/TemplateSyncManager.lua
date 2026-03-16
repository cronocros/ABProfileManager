local _, ns = ...

local TemplateSyncManager = {}
ns.Modules.TemplateSyncManager = TemplateSyncManager

local ACTION = {
    FILL_EMPTY = "fill_empty",
    CLEAR_EXTRAS = "clear_extras",
    SYNC_DIFF = "sync_diff",
    EXACT = "exact_sync",
    AVAILABLE_ONLY = "available_only_sync",
}

local function buildEmptyRecord(logicalSlot)
    return {
        logicalSlot = logicalSlot,
        actualSlot = logicalSlot,
        kind = "empty",
        id = nil,
        name = nil,
        icon = ns.Constants.DEFAULT_ICON,
    }
end

local function cloneRecord(record, logicalSlot)
    if type(record) ~= "table" then
        return buildEmptyRecord(logicalSlot)
    end

    local copy = ns.Utils.DeepCopy(record)
    copy.logicalSlot = logicalSlot
    copy.actualSlot = copy.actualSlot or logicalSlot
    copy.kind = copy.kind or "empty"
    copy.icon = copy.icon or ns.Constants.DEFAULT_ICON
    return copy
end

local function isEmptyRecord(record)
    return not record or not record.kind or record.kind == "empty"
end

local function buildRecordSignature(record)
    if isEmptyRecord(record) then
        return "empty"
    end

    if record.kind == "spell" or record.kind == "item" or record.kind == "equipmentset" then
        return string.format("%s:%s", tostring(record.kind), tostring(record.id))
    end

    if record.kind == "macro" then
        return string.format(
            "macro:%s:%s",
            tostring(record.name or ""),
            tostring(record.macroBody or "")
        )
    end

    return string.format("%s:%s:%s", tostring(record.kind), tostring(record.id), tostring(record.name))
end

local function describeRecord(record)
    if isEmptyRecord(record) then
        return ns.L("compare_action_empty")
    end

    if record.name and record.name ~= "" then
        return record.name
    end

    if record.id then
        return string.format("%s %s", tostring(record.kind), tostring(record.id))
    end

    return tostring(record.kind or ns.L("compare_action_unknown"))
end

local function buildSubsetPlan(planType, comparison, logicalSlots, entries, clearBeforeApply, actionKey, meta)
    local plan = {
        type = planType,
        selection = {
            mode = comparison.selection.mode,
            summary = ns.L("sync_slot_count_summary", #logicalSlots),
            clearBeforeApply = clearBeforeApply and true or false,
        },
        logicalSlots = logicalSlots,
        entries = entries or {},
        clearBeforeApply = clearBeforeApply and true or false,
        source = {
            kind = comparison.kind,
            key = comparison.key,
            label = ns.Utils.FormatSourceLabel(comparison.kind, comparison.key),
        },
        actionKey = actionKey,
        key = string.format("sync:%s:%s:%s:%d", actionKey, comparison.kind, comparison.key, #logicalSlots),
    }

    if type(meta) == "table" then
        for key, value in pairs(meta) do
            plan[key] = value
        end
    end

    return plan
end

function TemplateSyncManager:Initialize()
    self.lastComparison = nil
end

function TemplateSyncManager:GetActionKeys()
    return ACTION
end

function TemplateSyncManager:CompareTemplate(kind, key, selection)
    local template, err = ns.Modules.ProfileManager:GetSource(kind, key)
    if not template then
        return nil, err
    end

    local normalized, selectionErr = ns.Modules.RangeCopyManager:NormalizeSelection(selection)
    if not normalized then
        return nil, selectionErr
    end

    local comparison = {
        kind = kind,
        key = key,
        template = template,
        selection = normalized,
        selected = #normalized.logicalSlots,
        same = 0,
        missingOnCurrent = 0,
        extrasOnCurrent = 0,
        changed = 0,
        diffs = {},
        currentSlots = {},
        templateSlots = {},
    }

    for _, logicalSlot in ipairs(normalized.logicalSlots) do
        local currentRecord = cloneRecord(ns.Modules.ActionBarScanner:ScanLogicalSlot(logicalSlot), logicalSlot)
        local templateRecord = cloneRecord(template.slots[logicalSlot], logicalSlot)
        comparison.currentSlots[logicalSlot] = currentRecord
        comparison.templateSlots[logicalSlot] = templateRecord

        local currentEmpty = isEmptyRecord(currentRecord)
        local templateEmpty = isEmptyRecord(templateRecord)
        local category = "same"

        if currentEmpty and templateEmpty then
            category = "same"
        elseif currentEmpty and not templateEmpty then
            category = "missing_on_current"
            comparison.missingOnCurrent = comparison.missingOnCurrent + 1
        elseif not currentEmpty and templateEmpty then
            category = "extra_on_current"
            comparison.extrasOnCurrent = comparison.extrasOnCurrent + 1
        elseif buildRecordSignature(currentRecord) ~= buildRecordSignature(templateRecord) then
            category = "changed"
            comparison.changed = comparison.changed + 1
        else
            category = "same"
        end

        if category == "same" then
            comparison.same = comparison.same + 1
        else
            comparison.diffs[#comparison.diffs + 1] = {
                logicalSlot = logicalSlot,
                slotLabel = ns.Modules.SlotMapper:DescribeLogicalSlot(logicalSlot),
                category = category,
                current = currentRecord,
                template = templateRecord,
            }
        end
    end

    comparison.different = comparison.missingOnCurrent + comparison.extrasOnCurrent + comparison.changed
    comparison.message = self:FormatComparison(comparison)
    self.lastComparison = comparison
    return comparison
end

function TemplateSyncManager:FormatComparison(comparison)
    if not comparison then
        return ns.L("compare_none_text")
    end

    local lines = {
        ns.L("section_compare_basis"),
        ns.L("compare_summary_template", comparison.key),
        ns.L("compare_summary_range", comparison.selection.summary),
        ns.L("compare_summary_selected", comparison.selected),
        "",
        ns.L("section_compare_summary"),
        ns.L("compare_summary_same", comparison.same),
        ns.L("compare_summary_missing", comparison.missingOnCurrent),
        ns.L("compare_summary_extra", comparison.extrasOnCurrent),
        ns.L("compare_summary_changed", comparison.changed),
    }

    if comparison.different == 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = ns.L("compare_no_difference")
        return table.concat(lines, "\n")
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = ns.L("compare_preview_header")

    for index, diff in ipairs(comparison.diffs) do
        if diff.category == "missing_on_current" then
            lines[#lines + 1] = ns.L(
                "compare_row_missing",
                diff.slotLabel,
                describeRecord(diff.template)
            )
        elseif diff.category == "extra_on_current" then
            lines[#lines + 1] = ns.L(
                "compare_row_extra",
                diff.slotLabel,
                describeRecord(diff.current)
            )
        else
            lines[#lines + 1] = ns.L(
                "compare_row_changed",
                diff.slotLabel,
                describeRecord(diff.current),
                describeRecord(diff.template)
            )
        end
    end

    return table.concat(lines, "\n")
end

function TemplateSyncManager:BuildPlanForAction(comparison, actionKey)
    if not comparison then
        return nil, ns.L("compare_none_text")
    end

    if actionKey == ACTION.EXACT then
        return ns.Modules.RangeCopyManager:BuildApplyPlan(comparison.template, {
            mode = comparison.selection.mode,
            barIndex = comparison.selection.barIndex,
            startBar = comparison.selection.startBar,
            endBar = comparison.selection.endBar,
            selectedBars = ns.Utils.DeepCopy(comparison.selection.selectedBars),
            barSetText = comparison.selection.barSetText,
            startSlot = comparison.selection.startSlot,
            endSlot = comparison.selection.endSlot,
            clearBeforeApply = true,
        })
    end

    local targetSlots = {}
    local entries = {}
    local planType = "apply"
    local clearBeforeApply = false
    local skippedUnavailable = 0

    for _, diff in ipairs(comparison.diffs) do
        if actionKey == ACTION.FILL_EMPTY and diff.category == "missing_on_current" then
            targetSlots[#targetSlots + 1] = diff.logicalSlot
            entries[diff.logicalSlot] = cloneRecord(diff.template, diff.logicalSlot)
        elseif actionKey == ACTION.CLEAR_EXTRAS and diff.category == "extra_on_current" then
            targetSlots[#targetSlots + 1] = diff.logicalSlot
        elseif actionKey == ACTION.SYNC_DIFF then
            targetSlots[#targetSlots + 1] = diff.logicalSlot
            entries[diff.logicalSlot] = cloneRecord(diff.template, diff.logicalSlot)
            clearBeforeApply = true
        elseif actionKey == ACTION.AVAILABLE_ONLY then
            if diff.category == "extra_on_current" then
                targetSlots[#targetSlots + 1] = diff.logicalSlot
                clearBeforeApply = true
            elseif not isEmptyRecord(diff.template) then
                local canApply = ns.Modules.ActionBarApplier and ns.Modules.ActionBarApplier:CanResolveRecord(diff.template)
                if canApply then
                    targetSlots[#targetSlots + 1] = diff.logicalSlot
                    entries[diff.logicalSlot] = cloneRecord(diff.template, diff.logicalSlot)
                    clearBeforeApply = true
                else
                    skippedUnavailable = skippedUnavailable + 1
                end
            end
        end
    end

    if #targetSlots == 0 then
        if actionKey == ACTION.AVAILABLE_ONLY and skippedUnavailable > 0 then
            return nil, ns.L("sync_available_only_no_applicable", skippedUnavailable)
        end

        return nil, ns.L("sync_nothing_to_do")
    end

    if actionKey == ACTION.CLEAR_EXTRAS then
        planType = "clear"
        return buildSubsetPlan(planType, comparison, targetSlots, {}, true, actionKey)
    end

    return buildSubsetPlan(planType, comparison, targetSlots, entries, clearBeforeApply, actionKey, {
        skippedUnavailable = skippedUnavailable,
    })
end

function TemplateSyncManager:GetConfirmText(actionKey, comparison, plan)
    if actionKey == ACTION.FILL_EMPTY then
        return ns.L("sync_confirm_fill_empty", comparison.key, #plan.logicalSlots, comparison.selection.summary)
    end

    if actionKey == ACTION.CLEAR_EXTRAS then
        return ns.L("sync_confirm_clear_extras", comparison.key, #plan.logicalSlots, comparison.selection.summary)
    end

    if actionKey == ACTION.SYNC_DIFF then
        return ns.L("sync_confirm_sync_diff", comparison.key, #plan.logicalSlots, comparison.selection.summary)
    end

    if actionKey == ACTION.AVAILABLE_ONLY then
        return ns.L(
            "sync_confirm_available_only",
            comparison.key,
            #plan.logicalSlots,
            comparison.selection.summary,
            plan.skippedUnavailable or 0
        )
    end

    return ns.L("sync_confirm_exact", comparison.key, comparison.selection.summary)
end

function TemplateSyncManager:RequestSyncAction(kind, key, selection, actionKey, callbacks)
    local comparison, err = self:CompareTemplate(kind, key, selection)
    if not comparison then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, err)
        end
        return nil, err
    end

    local plan, planErr = self:BuildPlanForAction(comparison, actionKey)
    if not plan then
        if callbacks and callbacks.onComplete then
            callbacks.onComplete(nil, planErr)
        end
        return nil, planErr
    end

    local confirmText = self:GetConfirmText(actionKey, comparison, plan)
    return ns.Modules.ProfileManager:RunConfirmedOperation(confirmText, function()
        return ns.Modules.ActionBarApplier:ApplyPlan(plan)
    end, callbacks, true)
end
