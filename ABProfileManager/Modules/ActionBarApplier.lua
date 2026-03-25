local _, ns = ...

local ActionBarApplier = {}
ns.Modules.ActionBarApplier = ActionBarApplier

local function findMacroIndex(slotRecord)
    local macroName = slotRecord.name
    local macroBody = slotRecord.macroBody
    local globalMacros, characterMacros = GetNumMacros()
    local totalMacros = (globalMacros or 0) + (characterMacros or 0)
    local nameMatches = {}
    local exactMatches = {}

    for macroIndex = 1, totalMacros do
        local name, _, body = GetMacroInfo(macroIndex)
        if name == macroName then
            nameMatches[#nameMatches + 1] = macroIndex
            if not macroBody or body == macroBody then
                exactMatches[#exactMatches + 1] = macroIndex
            end
        end
    end

    if macroBody and #exactMatches == 0 and #nameMatches > 0 then
        return nil, ns.L("error_macro_body_mismatch")
    end

    if #exactMatches > 0 then
        return exactMatches[1]
    end

    if #nameMatches == 1 then
        return nameMatches[1]
    end

    if #nameMatches > 1 then
        return nil, ns.L("error_macro_ambiguous")
    end

    return nil, ns.L("error_macro_missing")
end

local function safeIsSpellKnown(spellID)
    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    end

    if IsSpellKnown then
        return IsSpellKnown(spellID)
    end

    return false
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

local function itemIsAvailable(itemID)
    if not itemID then
        return false
    end

    if PlayerHasToy and PlayerHasToy(itemID) then
        return true
    end

    if GetItemCount then
        local itemCount = GetItemCount(itemID, false, false)
        if itemCount and itemCount > 0 then
            return true
        end
    end

    return false
end

local function getSelectionSlotCount(plan)
    return plan.logicalSlots and #plan.logicalSlots or 0
end

local function getCursorSummary()
    if type(GetCursorInfo) ~= "function" then
        return nil, nil
    end

    local cursorKind, cursorID = GetCursorInfo()
    return cursorKind, cursorID
end

local function verifyPlacement(actualSlot, slotRecord)
    local placedKind, placedID = GetActionInfo(actualSlot)
    if not placedKind then
        return false
    end

    if slotRecord.kind == "macro" then
        if placedKind ~= "macro" then
            return false
        end

        local macroName, _, macroBody = GetMacroInfo(placedID)
        if slotRecord.name and macroName ~= slotRecord.name then
            return false
        end

        if slotRecord.macroBody and macroBody ~= slotRecord.macroBody then
            return false
        end

        return true
    end

    if slotRecord.kind == "spell" or slotRecord.kind == "item" then
        return placedKind == slotRecord.kind and placedID == slotRecord.id
    end

    return placedKind == slotRecord.kind
end

function ActionBarApplier:Initialize()
    self.pendingQueue = {}
    self.pendingGhosts = {}
end

function ActionBarApplier:GetPendingGhosts()
    return self.pendingGhosts
end

function ActionBarApplier:QueueOperation(operation)
    ns.Utils.Debug("Queueing operation: " .. tostring(operation.key))
    for index, existingOperation in ipairs(self.pendingQueue) do
        if existingOperation.key == operation.key then
            self.pendingQueue[index] = operation
            return
        end
    end

    self.pendingQueue[#self.pendingQueue + 1] = operation
end

function ActionBarApplier:RegisterPendingGhost(logicalSlot, slotRecord, reason, retryable)
    ns.Utils.Debug(string.format("Registering ghost for slot %d (%s)", logicalSlot, tostring(reason)))
    self.pendingGhosts[logicalSlot] = {
        logicalSlot = logicalSlot,
        slotRecord = ns.Utils.DeepCopy(slotRecord),
        reason = reason,
        retryable = retryable,
    }
end

function ActionBarApplier:ClearPendingGhost(logicalSlot)
    self.pendingGhosts[logicalSlot] = nil
end

function ActionBarApplier:DismissPendingGhost(logicalSlot)
    if not self.pendingGhosts[logicalSlot] then
        return false
    end

    self:ClearPendingGhost(logicalSlot)
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
    return true
end

function ActionBarApplier:CanResolveRecord(slotRecord)
    if isEmptyRecord(slotRecord) then
        return true
    end

    local kind = slotRecord.kind
    local actionID = slotRecord.id

    if kind == "spell" then
        if not actionID or not safeIsSpellKnown(actionID) then
            return false, ns.L("error_spell_missing"), "missing"
        end

        return true
    end

    if kind == "macro" then
        if not actionID and not slotRecord.name then
            return false, ns.L("error_macro_incomplete"), "missing"
        end

        local macroIndex, macroErr = findMacroIndex(slotRecord)
        if not macroIndex then
            return false, macroErr or ns.L("error_macro_missing"), "missing"
        end

        return true
    end

    if kind == "item" then
        if not actionID then
            return false, ns.L("error_item_incomplete"), "missing"
        end

        if itemIsAvailable(actionID) then
            return true
        end

        return false, ns.L("error_action_pickup_failed"), "missing"
    end

    return false, string.format("%s: %s", ns.L("error_unsupported_action_type"), tostring(kind)), "unsupported"
end

function ActionBarApplier:ClearLogicalSlot(logicalSlot)
    local actualSlot, err = ns.Modules.SlotMapper:ResolveActualSlot(logicalSlot, "mutate")
    if not actualSlot then
        return false, err, "invalid"
    end

    local hadAction = HasAction(actualSlot)
    ClearCursor()
    PickupAction(actualSlot)
    ClearCursor()
    return true, hadAction and "cleared" or "empty", "ok"
end

function ActionBarApplier:VerifyClearedSlot(logicalSlot)
    local actualSlot, err = ns.Modules.SlotMapper:ResolveActualSlot(logicalSlot, "mutate")
    if not actualSlot then
        return false, err, "invalid"
    end

    if not HasAction(actualSlot) then
        return true, "empty", "ok"
    end

    return self:ClearLogicalSlot(logicalSlot)
end

function ActionBarApplier:PlaceCursorIntoLogicalSlot(logicalSlot)
    if InCombatLockdown and InCombatLockdown() then
        return false, ns.L("combat_lockdown_active"), "blocked"
    end

    local actualSlot, err = ns.Modules.SlotMapper:ResolveActualSlot(logicalSlot, "mutate")
    if not actualSlot then
        return false, err, "invalid"
    end

    local cursorKind, cursorID = getCursorSummary()
    if not cursorKind then
        return false, ns.L("error_action_pickup_failed"), "missing"
    end

    ns.Utils.Debug(string.format("Placing cursor action into slot %d (%s:%s)", actualSlot, tostring(cursorKind), tostring(cursorID)))
    PlaceAction(actualSlot)

    if not GetActionInfo(actualSlot) then
        ns.Utils.Debug(string.format("PlaceAction failed for slot %d while cursor held %s:%s", actualSlot, tostring(cursorKind), tostring(cursorID)))
        return false, ns.L("error_action_place_failed"), "missing"
    end

    self:ClearPendingGhost(logicalSlot)
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
    return true, "applied", "ok"
end

function ActionBarApplier:PickupFromRecord(slotRecord)
    local resolvable, resolveErr, resolveCategory = self:CanResolveRecord(slotRecord)
    if not resolvable then
        return false, resolveErr, resolveCategory
    end

    local kind = slotRecord.kind
    local actionID = slotRecord.id

    if kind == "spell" then
        ClearCursor()
        if C_Spell and C_Spell.PickupSpell then
            C_Spell.PickupSpell(actionID)
        else
            PickupSpell(actionID)
        end
    elseif kind == "macro" then
        if not actionID and not slotRecord.name then
            return false, ns.L("error_macro_incomplete"), "missing"
        end

        local macroIndex, macroErr = findMacroIndex(slotRecord)
        if not macroIndex then
            return false, macroErr or ns.L("error_macro_missing"), "missing"
        end

        ClearCursor()
        PickupMacro(macroIndex)
    elseif kind == "item" then
        if not actionID then
            return false, ns.L("error_item_incomplete"), "missing"
        end

        ClearCursor()
        if PlayerHasToy and PlayerHasToy(actionID) and C_ToyBox and C_ToyBox.PickupToyBoxItem then
            C_ToyBox.PickupToyBoxItem(actionID)
        else
            PickupItem(actionID)
        end
    else
        return false, string.format("%s: %s", ns.L("error_unsupported_action_type"), tostring(kind)), "unsupported"
    end

    if not GetCursorInfo() then
        ClearCursor()
        return false, ns.L("error_action_pickup_failed"), "missing"
    end

    return true
end

function ActionBarApplier:PlaceRecord(logicalSlot, slotRecord)
    local actualSlot, err = ns.Modules.SlotMapper:ResolveActualSlot(logicalSlot, "mutate")
    if not actualSlot then
        return false, err, "invalid"
    end

    if not slotRecord or slotRecord.kind == "empty" then
        self:ClearPendingGhost(logicalSlot)
        return true, "empty", "ok"
    end

    local pickedUp, pickupErr, category = self:PickupFromRecord(slotRecord)
    if not pickedUp then
        ClearCursor()
        return false, pickupErr, category
    end

    PlaceAction(actualSlot)
    ClearCursor()

    if not verifyPlacement(actualSlot, slotRecord) then
        return false, ns.L("error_action_place_failed"), "missing"
    end

    self:ClearPendingGhost(logicalSlot)
    return true, "applied", "ok"
end

function ActionBarApplier:BuildResultMessage(result)
    local message

    if result.queued then
        message = ns.L("operation_queued")
    elseif result.type == "clear" then
        message = ns.L(
            "result_clear",
            result.cleared,
            result.invalid,
            result.selected
        )
    else
        message = ns.L(
            "result_apply",
            result.applied,
            result.cleared,
            result.missing,
            result.unsupported,
            result.invalid,
            result.selected
        )
    end

    if result.skippedUnavailable and result.skippedUnavailable > 0 then
        message = string.format("%s\n%s", message, ns.L("sync_result_skipped_unavailable", result.skippedUnavailable))
    end

    return message
end

function ActionBarApplier:ApplyPlan(plan, options)
    if not plan or type(plan.logicalSlots) ~= "table" then
        return nil, ns.L("error_apply_plan_invalid")
    end

    options = options or {}

    ns.Utils.Debug(string.format("ApplyPlan start: %s / %s", tostring(plan.type), tostring(plan.key)))

    if InCombatLockdown and InCombatLockdown() then
        self:QueueOperation(plan)
        local queuedResult = {
            queued = true,
            type = plan.type,
            selected = getSelectionSlotCount(plan),
        }
        queuedResult.message = self:BuildResultMessage(queuedResult)
        ns:SafeCall(ns.UI.MainWindow, "SetStatus", queuedResult.message)
        ns.Utils.Print(queuedResult.message)
        return queuedResult
    end

    if not options.skipUndoCapture and ns.Modules.UndoManager then
        ns.Modules.UndoManager:CapturePlan(plan)
    end

    local result = {
        type = plan.type,
        queued = false,
        selected = getSelectionSlotCount(plan),
        applied = 0,
        cleared = 0,
        missing = 0,
        unsupported = 0,
        invalid = 0,
        skippedUnavailable = plan.skippedUnavailable or 0,
    }

    if plan.type == "clear" or plan.clearBeforeApply then
        local clearedSlots = {}
        local invalidSlots = {}

        for _, logicalSlot in ipairs(plan.logicalSlots) do
            local cleared, state, category = self:ClearLogicalSlot(logicalSlot)
            if cleared and state == "cleared" and not clearedSlots[logicalSlot] then
                result.cleared = result.cleared + 1
                clearedSlots[logicalSlot] = true
            elseif not cleared and category == "invalid" and not invalidSlots[logicalSlot] then
                result.invalid = result.invalid + 1
                invalidSlots[logicalSlot] = true
            end

            if plan.type == "clear" then
                self:ClearPendingGhost(logicalSlot)
            end
        end

        for _, logicalSlot in ipairs(plan.logicalSlots) do
            local cleared, state, category = self:VerifyClearedSlot(logicalSlot)
            if cleared and state == "cleared" and not clearedSlots[logicalSlot] then
                result.cleared = result.cleared + 1
                clearedSlots[logicalSlot] = true
            elseif not cleared and category == "invalid" and not invalidSlots[logicalSlot] then
                result.invalid = result.invalid + 1
                invalidSlots[logicalSlot] = true
            end

            if plan.type == "clear" then
                self:ClearPendingGhost(logicalSlot)
            end
        end
    end

    if plan.type == "apply" then
        for _, logicalSlot in ipairs(plan.logicalSlots) do
            local slotRecord = plan.entries[logicalSlot]
            local applied, reason, category = self:PlaceRecord(logicalSlot, slotRecord)

            if applied and reason == "applied" then
                result.applied = result.applied + 1
            elseif not applied and category == "missing" then
                result.missing = result.missing + 1
                self:RegisterPendingGhost(logicalSlot, slotRecord, reason, true)
            elseif not applied and category == "unsupported" then
                result.unsupported = result.unsupported + 1
                self:RegisterPendingGhost(logicalSlot, slotRecord, reason, false)
            elseif not applied and category == "invalid" then
                result.invalid = result.invalid + 1
            end

            if slotRecord and slotRecord.kind == "empty" then
                self:ClearPendingGhost(logicalSlot)
            end
        end
    end

    result.message = self:BuildResultMessage(result)
    ns.Utils.Debug(result.message)
    ns:SafeCall(ns.Modules.GhostManager, "RefreshGhosts")
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", result.message)
    ns.Utils.Print(result.message)
    return result
end

function ActionBarApplier:FlushQueue()
    if #self.pendingQueue == 0 then
        return
    end

    ns.Utils.Debug(string.format("Flushing %d queued operations", #self.pendingQueue))
    local queuedOperations = self.pendingQueue
    self.pendingQueue = {}

    for _, operation in ipairs(queuedOperations) do
        local result, err = self:ApplyPlan(operation)
        if not result and err then
            ns.Utils.Print(err)
        end
    end
end

function ActionBarApplier:ReconcilePendingGhosts()
    if not self.pendingGhosts then
        return 0
    end

    local removed = 0
    for logicalSlot, ghostEntry in pairs(self.pendingGhosts) do
        local currentRecord = ns.Modules.ActionBarScanner and ns.Modules.ActionBarScanner:ScanLogicalSlot(logicalSlot)
        if currentRecord and not isEmptyRecord(currentRecord) then
            ns.Utils.Debug(string.format(
                "Clearing pending ghost for slot %d after slot changed (%s)",
                logicalSlot,
                buildRecordSignature(ghostEntry and ghostEntry.slotRecord)
            ))
            self:ClearPendingGhost(logicalSlot)
            removed = removed + 1
        end
    end

    return removed
end

function ActionBarApplier:RetryPendingGhosts()
    if InCombatLockdown and InCombatLockdown() then
        ns.Utils.Debug("Skipping ghost retry while in combat")
        return
    end

    local cursorKind, cursorID = getCursorSummary()
    if cursorKind then
        ns.Utils.Debug(string.format("Skipping ghost retry because cursor is busy (%s:%s)", tostring(cursorKind), tostring(cursorID)))
        return
    end

    local ghostCount = ns.Utils.TableCount(self.pendingGhosts)
    if ghostCount > 0 then
        ns.Utils.Debug(string.format("Retrying %d ghost slots", ghostCount))
    end
    for logicalSlot, ghostEntry in pairs(self.pendingGhosts) do
        local currentRecord = ns.Modules.ActionBarScanner and ns.Modules.ActionBarScanner:ScanLogicalSlot(logicalSlot)
        if currentRecord and not isEmptyRecord(currentRecord) then
            self:ClearPendingGhost(logicalSlot)
        elseif ghostEntry.retryable then
            self:PlaceRecord(logicalSlot, ghostEntry.slotRecord)
        end
    end
end
