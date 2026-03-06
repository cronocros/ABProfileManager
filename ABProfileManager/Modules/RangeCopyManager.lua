local _, ns = ...

local RangeCopyManager = {}
ns.Modules.RangeCopyManager = RangeCopyManager

local function defaultSelection()
    return {
        mode = ns.Constants.APPLY_MODE.FULL,
        barIndex = 1,
        startBar = 1,
        endBar = 2,
        selectedBars = { 1, 2 },
        barSetText = "1, 2",
        startSlot = ns.Constants.LOGICAL_SLOT_MIN,
        endSlot = ns.Constants.LOGICAL_SLOT_MAX,
        clearBeforeApply = true,
    }
end

function RangeCopyManager:Initialize()
    self.lastPlan = nil
end

function RangeCopyManager:NormalizeSelection(selection)
    local normalized = ns.Utils.DeepCopy(selection or {})
    local defaults = defaultSelection()

    for key, value in pairs(defaults) do
        if normalized[key] == nil then
            normalized[key] = value
        end
    end

    normalized.mode = normalized.mode or defaults.mode
    normalized.barIndex = ns.Utils.SafeToNumber(normalized.barIndex, defaults.barIndex)
    normalized.startBar = ns.Utils.SafeToNumber(normalized.startBar, defaults.startBar)
    normalized.endBar = ns.Utils.SafeToNumber(normalized.endBar, defaults.endBar)
    normalized.barSetText = ns.Utils.Trim(normalized.barSetText or defaults.barSetText or "")
    if type(normalized.selectedBars) ~= "table" or #normalized.selectedBars == 0 then
        normalized.selectedBars = ns.Utils.ParseNumberList(normalized.barSetText)
    end
    if #normalized.selectedBars == 0 then
        normalized.selectedBars = ns.Utils.DeepCopy(defaults.selectedBars)
    end
    local normalizedBars, barErr = ns.Modules.SlotMapper:NormalizeBarSet(normalized.selectedBars)
    if normalized.mode == ns.Constants.APPLY_MODE.BAR_SET and not normalizedBars then
        return nil, barErr
    end
    if normalizedBars then
        normalized.selectedBars = normalizedBars
        normalized.barSetText = table.concat(normalizedBars, ", ")
    end
    normalized.startSlot = ns.Utils.SafeToNumber(normalized.startSlot, defaults.startSlot)
    normalized.endSlot = ns.Utils.SafeToNumber(normalized.endSlot, defaults.endSlot)
    normalized.clearBeforeApply = not not normalized.clearBeforeApply

    local orderedSlots, err = ns.Modules.SlotMapper:GetOrderedSlotsForMode(normalized.mode, normalized)
    if not orderedSlots then
        return nil, err
    end

    normalized.logicalSlots = orderedSlots
    normalized.summary = ns.Modules.SlotMapper:DescribeSelection(normalized.mode, normalized)
    return normalized
end

function RangeCopyManager:BuildApplyPlan(source, selection)
    if not source or type(source.slots) ~= "table" then
        return nil, ns.L("error_source_unavailable")
    end

    local normalized, err = self:NormalizeSelection(selection)
    if not normalized then
        return nil, err
    end

    local plan = {
        type = "apply",
        selection = normalized,
        logicalSlots = normalized.logicalSlots,
        entries = {},
        clearBeforeApply = normalized.clearBeforeApply,
        source = {
            kind = source.sourceType,
            key = source.sourceKey,
            label = ns.Utils.FormatSourceLabel(source.sourceType, source.sourceKey),
        },
        key = string.format(
            "apply:%s:%s:%s:%s",
            source.sourceType or "unknown",
            source.sourceKey or "unknown",
            normalized.summary,
            tostring(normalized.clearBeforeApply)
        ),
    }

    for _, logicalSlot in ipairs(normalized.logicalSlots) do
        plan.entries[logicalSlot] = ns.Utils.DeepCopy(source.slots[logicalSlot] or {
            logicalSlot = logicalSlot,
            actualSlot = logicalSlot,
            kind = "empty",
        })
    end

    self.lastPlan = plan
    return plan
end

function RangeCopyManager:BuildClearPlan(selection)
    local normalized, err = self:NormalizeSelection(selection)
    if not normalized then
        return nil, err
    end

    local plan = {
        type = "clear",
        selection = normalized,
        logicalSlots = normalized.logicalSlots,
        clearBeforeApply = true,
        entries = {},
        key = string.format("clear:%s", normalized.summary),
    }

    self.lastPlan = plan
    return plan
end
