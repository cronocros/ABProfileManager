local _, ns = ...

local SlotMapper = {}
ns.Modules.SlotMapper = SlotMapper

local function buildRange(startSlot, endSlot)
    local slots = {}
    for slot = startSlot, endSlot do
        slots[#slots + 1] = slot
    end
    return slots
end

local function isInRanges(slot, ranges)
    for _, range in ipairs(ranges) do
        if slot >= range[1] and slot <= range[2] then
            return true
        end
    end

    return false
end

local MUTABLE_RANGES = {
    { 1, 120 },
    { 121, 132 },
    { 145, 180 },
}

local SCAN_RANGES = {
    { 1, 180 },
}

local BAR_LAYOUTS = {
    [1] = { slots = buildRange(1, 12), buttonPrefix = "ActionButton" },
    [2] = { slots = buildRange(61, 72), buttonPrefix = "MultiBarBottomLeftButton" },
    [3] = { slots = buildRange(49, 60), buttonPrefix = "MultiBarBottomRightButton" },
    [4] = { slots = buildRange(25, 36), buttonPrefix = "MultiBarRightButton" },
    [5] = { slots = buildRange(37, 48), buttonPrefix = "MultiBarLeftButton" },
    [6] = { slots = buildRange(145, 156), buttonPrefix = "MultiBar5Button" },
    [7] = { slots = buildRange(157, 168), buttonPrefix = "MultiBar6Button" },
    [8] = { slots = buildRange(169, 180), buttonPrefix = "MultiBar7Button" },
    [9] = { slots = buildRange(121, 132), buttonPrefix = "ActionButton", labelKey = "bar_name_flight" },
}

function SlotMapper:Initialize()
    self.logicalMin = ns.Constants.LOGICAL_SLOT_MIN
    self.logicalMax = ns.Constants.LOGICAL_SLOT_MAX
end

function SlotMapper:IsLogicalSlot(slot)
    return type(slot) == "number"
        and slot >= self.logicalMin
        and slot <= self.logicalMax
end

function SlotMapper:IsActualSlotMutable(actualSlot)
    return type(actualSlot) == "number" and isInRanges(actualSlot, MUTABLE_RANGES)
end

function SlotMapper:CanScanActualSlot(actualSlot)
    return type(actualSlot) == "number" and isInRanges(actualSlot, SCAN_RANGES)
end

function SlotMapper:IsMutableLogicalSlot(logicalSlot)
    return self:IsLogicalSlot(logicalSlot) and self:IsActualSlotMutable(logicalSlot)
end

function SlotMapper:GetBarLayout(barIndex)
    return BAR_LAYOUTS[barIndex]
end

function SlotMapper:GetBarRange(barIndex)
    local layout = self:GetBarLayout(barIndex)
    if not layout then
        return nil, nil, ns.L("error_invalid_bar")
    end

    return layout.slots[1], layout.slots[#layout.slots]
end

function SlotMapper:GetBarSlots(barIndex)
    local layout = self:GetBarLayout(barIndex)
    if not layout then
        return nil, ns.L("error_invalid_bar")
    end

    local slots = {}
    for index, slot in ipairs(layout.slots) do
        slots[index] = slot
    end

    return slots
end

function SlotMapper:GetVisibleButtonDescriptors()
    return BAR_LAYOUTS
end

function SlotMapper:GetBarDisplayName(barIndex)
    local layout = self:GetBarLayout(barIndex)
    if not layout then
        return ns.L("bar_name_generic", tonumber(barIndex) or 0)
    end

    if layout.labelKey then
        return ns.L(layout.labelKey)
    end

    return ns.L("bar_name_generic", barIndex)
end

function SlotMapper:GetBarIndexForLogicalSlot(logicalSlot)
    for barIndex, layout in pairs(BAR_LAYOUTS) do
        for position, slot in ipairs(layout.slots) do
            if slot == logicalSlot then
                return barIndex, position
            end
        end
    end

    return nil, nil
end

function SlotMapper:DescribeLogicalSlot(logicalSlot)
    local barIndex, position = self:GetBarIndexForLogicalSlot(logicalSlot)
    if barIndex and position then
        return ns.L("slot_descriptor_bar_named", self:GetBarDisplayName(barIndex), position)
    end

    return ns.L("slot_descriptor_generic", logicalSlot or 0)
end

function SlotMapper:NormalizeBarSet(selectedBars)
    local orderedBars = {}
    local seen = {}

    if type(selectedBars) ~= "table" then
        return nil, ns.L("error_invalid_bar_selection")
    end

    for _, rawBar in ipairs(selectedBars) do
        local barIndex = tonumber(rawBar)
        if not barIndex or not BAR_LAYOUTS[barIndex] then
            return nil, ns.L("error_invalid_bar")
        end

        barIndex = math.floor(barIndex)
        if not seen[barIndex] then
            orderedBars[#orderedBars + 1] = barIndex
            seen[barIndex] = true
        end
    end

    table.sort(orderedBars)

    if #orderedBars == 0 then
        return nil, ns.L("error_invalid_bar_selection")
    end

    return orderedBars
end

function SlotMapper:NormalizeSlotRange(startSlot, endSlot)
    if not self:IsLogicalSlot(startSlot) or not self:IsLogicalSlot(endSlot) then
        return nil, nil, ns.L("error_invalid_slot_range")
    end

    if startSlot > endSlot then
        startSlot, endSlot = endSlot, startSlot
    end

    return startSlot, endSlot
end

function SlotMapper:ResolveActualSlot(logicalSlot, intent)
    if not self:IsLogicalSlot(logicalSlot) then
        return nil, ns.L("error_invalid_logical_slot")
    end

    local actualSlot = logicalSlot
    if intent == "mutate" then
        if self:IsActualSlotMutable(actualSlot) then
            return actualSlot
        end
        return nil, ns.L("error_slot_mutation_blocked")
    end

    if intent == "scan" then
        if self:CanScanActualSlot(actualSlot) then
            return actualSlot
        end
        return nil, ns.L("error_slot_scan_blocked")
    end

    if self:CanScanActualSlot(actualSlot) or self:IsActualSlotMutable(actualSlot) then
        return actualSlot
    end

    return nil, ns.L("error_slot_actual_blocked")
end

function SlotMapper:GetOrderedSlotsForMode(mode, options)
    local orderedSlots = {}
    options = options or {}

    if mode == ns.Constants.APPLY_MODE.FULL then
        for slot = self.logicalMin, self.logicalMax do
            orderedSlots[#orderedSlots + 1] = slot
        end
        return orderedSlots
    end

    if mode == ns.Constants.APPLY_MODE.BAR then
        return self:GetBarSlots(options.barIndex)
    end

    if mode == ns.Constants.APPLY_MODE.BAR_RANGE then
        local startBar = tonumber(options.startBar)
        local endBar = tonumber(options.endBar)
        if not startBar or not endBar then
            return nil, ns.L("error_bar_range_requires")
        end

        if startBar > endBar then
            startBar, endBar = endBar, startBar
        end

        for barIndex = startBar, endBar do
            local barSlots, err = self:GetBarSlots(barIndex)
            if not barSlots then
                return nil, err
            end

            for _, slot in ipairs(barSlots) do
                orderedSlots[#orderedSlots + 1] = slot
            end
        end

        return orderedSlots
    end

    if mode == ns.Constants.APPLY_MODE.BAR_SET then
        local orderedBars, err = self:NormalizeBarSet(options.selectedBars)
        if not orderedBars then
            return nil, err
        end

        for _, barIndex in ipairs(orderedBars) do
            local barSlots, barErr = self:GetBarSlots(barIndex)
            if not barSlots then
                return nil, barErr
            end

            for _, slot in ipairs(barSlots) do
                orderedSlots[#orderedSlots + 1] = slot
            end
        end

        return orderedSlots
    end

    if mode == ns.Constants.APPLY_MODE.SLOT_RANGE then
        local startSlot, endSlot, err = self:NormalizeSlotRange(options.startSlot, options.endSlot)
        if not startSlot then
            return nil, err
        end

        for slot = startSlot, endSlot do
            orderedSlots[#orderedSlots + 1] = slot
        end

        return orderedSlots
    end

    return nil, ns.L("error_unsupported_apply_mode")
end

function SlotMapper:DescribeSelection(mode, options)
    if mode == ns.Constants.APPLY_MODE.FULL then
        return ns.L("selection_mode_full")
    end

    if mode == ns.Constants.APPLY_MODE.BAR then
        return ns.L("selection_mode_bar", self:GetBarDisplayName(tonumber(options.barIndex) or 0))
    end

    if mode == ns.Constants.APPLY_MODE.BAR_RANGE then
        return ns.L(
            "selection_mode_bar_range",
            self:GetBarDisplayName(tonumber(options.startBar) or 0),
            self:GetBarDisplayName(tonumber(options.endBar) or 0)
        )
    end

    if mode == ns.Constants.APPLY_MODE.SLOT_RANGE then
        return ns.L(
            "selection_mode_slot_range",
            tonumber(options.startSlot) or 0,
            tonumber(options.endSlot) or 0
        )
    end

    if mode == ns.Constants.APPLY_MODE.BAR_SET then
        local orderedBars = self:NormalizeBarSet(options.selectedBars)
        if not orderedBars then
            return ns.L("error_invalid_bar_selection")
        end

        local names = {}
        for _, barIndex in ipairs(orderedBars) do
            names[#names + 1] = self:GetBarDisplayName(barIndex)
        end

        return ns.L("selection_mode_bar_set", table.concat(names, ", "))
    end

    return ns.L("error_unsupported_apply_mode")
end
