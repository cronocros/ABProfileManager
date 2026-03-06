local _, ns = ...

local Scanner = {}
ns.Modules.ActionBarScanner = Scanner

local function buildBaseRecord(logicalSlot, actualSlot)
    return {
        logicalSlot = logicalSlot,
        actualSlot = actualSlot,
        kind = "empty",
        id = nil,
        name = nil,
        subType = nil,
        icon = ns.Constants.DEFAULT_ICON,
        status = actualSlot and "scanned" or "unsupported",
    }
end

local function getSpellInfoSafe(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, spellInfo.iconID
        end
    end

    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end

    return nil, nil
end

local function getItemNameSafe(itemID)
    if C_Item and C_Item.GetItemNameByID then
        local itemName = C_Item.GetItemNameByID(itemID)
        if itemName then
            return itemName
        end
    end

    if GetItemInfo then
        return GetItemInfo(itemID)
    end

    return nil
end

local function getItemIconSafe(itemID)
    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemID)
        if icon then
            return icon
        end
    end

    if GetItemInfoInstant then
        local _, _, _, _, icon = GetItemInfoInstant(itemID)
        return icon
    end

    return nil
end

function Scanner:Initialize()
    self.lastScan = nil
end

function Scanner:ScanLogicalSlot(logicalSlot)
    local actualSlot = ns.Modules.SlotMapper:ResolveActualSlot(logicalSlot, "scan")
    local record = buildBaseRecord(logicalSlot, actualSlot)
    if not actualSlot then
        return record
    end

    local kind, actionID, subType = GetActionInfo(actualSlot)
    record.icon = GetActionTexture(actualSlot) or record.icon
    record.subType = subType

    if not kind then
        return record
    end

    record.kind = kind
    record.id = actionID

    if kind == "spell" then
        local spellName, spellIcon = getSpellInfoSafe(actionID)
        record.name = spellName
        record.icon = spellIcon or record.icon
        return record
    end

    if kind == "macro" then
        local macroName, macroIcon, macroBody = GetMacroInfo(actionID)
        record.name = macroName
        record.icon = macroIcon or record.icon
        record.macroBody = macroBody
        return record
    end

    if kind == "item" then
        record.name = getItemNameSafe(actionID)
        record.icon = getItemIconSafe(actionID) or record.icon
        return record
    end

    if kind == "equipmentset" and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
        local setName, _, setIcon = C_EquipmentSet.GetEquipmentSetInfo(actionID)
        record.name = setName
        record.icon = setIcon or record.icon
        return record
    end

    record.name = kind
    return record
end

function Scanner:ScanRange(startSlot, endSlot)
    if not ns.Modules.SlotMapper then
        return nil, "Slot mapper is unavailable."
    end

    local normalizedStart, normalizedEnd, err = ns.Modules.SlotMapper:NormalizeSlotRange(startSlot, endSlot)
    if not normalizedStart then
        return nil, err
    end

    local snapshot = {
        range = {
            startSlot = normalizedStart,
            endSlot = normalizedEnd,
        },
        slots = {},
        scannedAt = date("%Y-%m-%d %H:%M:%S"),
    }

    for logicalSlot = normalizedStart, normalizedEnd do
        snapshot.slots[logicalSlot] = self:ScanLogicalSlot(logicalSlot)
    end

    self.lastScan = snapshot
    return snapshot
end

function Scanner:ScanAll()
    return self:ScanRange(ns.Constants.LOGICAL_SLOT_MIN, ns.Constants.LOGICAL_SLOT_MAX)
end
