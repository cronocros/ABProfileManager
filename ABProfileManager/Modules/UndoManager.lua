local _, ns = ...

local UndoManager = {}
ns.Modules.UndoManager = UndoManager

function UndoManager:Initialize()
    self.lastSnapshot = nil
end

function UndoManager:HasUndo()
    return self.lastSnapshot ~= nil
end

function UndoManager:Clear()
    self.lastSnapshot = nil
end

function UndoManager:CapturePlan(plan)
    if not plan or type(plan.logicalSlots) ~= "table" or #plan.logicalSlots == 0 then
        return nil, ns.L("undo_unavailable")
    end

    local snapshot = {
        capturedAt = date("%Y-%m-%d %H:%M:%S"),
        selection = ns.Utils.DeepCopy(plan.selection or {}),
        logicalSlots = ns.Utils.DeepCopy(plan.logicalSlots or {}),
        entries = {},
        key = plan.key,
        type = plan.type,
        source = ns.Utils.DeepCopy(plan.source or {}),
    }

    for _, logicalSlot in ipairs(plan.logicalSlots) do
        snapshot.entries[logicalSlot] = ns.Modules.ActionBarScanner:ScanLogicalSlot(logicalSlot)
    end

    self.lastSnapshot = snapshot
    ns.Utils.Debug(string.format("Undo snapshot captured for %s (%d slots)", tostring(plan.key), #snapshot.logicalSlots))
    return snapshot
end

function UndoManager:BuildUndoPlan(snapshot)
    if not snapshot or type(snapshot.entries) ~= "table" then
        return nil, ns.L("undo_unavailable")
    end

    return {
        type = "apply",
        selection = ns.Utils.DeepCopy(snapshot.selection or {}),
        logicalSlots = ns.Utils.DeepCopy(snapshot.logicalSlots or {}),
        entries = ns.Utils.DeepCopy(snapshot.entries or {}),
        clearBeforeApply = true,
        source = {
            kind = "undo",
            key = "undo",
            label = ns.L("undo_button"),
        },
        key = string.format("undo:%s", tostring(snapshot.capturedAt or time())),
    }
end

function UndoManager:RequestUndo(callbacks)
    callbacks = callbacks or {}

    local snapshot = self.lastSnapshot
    if not snapshot then
        if callbacks.onComplete then
            callbacks.onComplete(nil, ns.L("undo_unavailable"))
        end
        return nil, ns.L("undo_unavailable")
    end

    local plan, err = self:BuildUndoPlan(snapshot)
    if not plan then
        if callbacks.onComplete then
            callbacks.onComplete(nil, err)
        end
        return nil, err
    end

    local confirmText = ns.L(
        "confirm_undo_text",
        snapshot.selection and snapshot.selection.summary or ns.L("selection_mode_full"),
        #plan.logicalSlots
    )

    return ns.Modules.ProfileManager:RunConfirmedOperation(confirmText, function()
        local result, applyErr = ns.Modules.ActionBarApplier:ApplyPlan(plan, {
            skipUndoCapture = true,
        })
        if not result then
            return nil, applyErr
        end

        self.lastSnapshot = nil
        result.message = ns.L(
            "undo_completed",
            snapshot.selection and snapshot.selection.summary or ns.L("selection_mode_full"),
            result.applied,
            result.cleared,
            result.missing,
            result.invalid
        )
        return result
    end, callbacks)
end
