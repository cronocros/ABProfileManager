local _, ns = ...

local TomTomBridge = {}
ns.Modules.TomTomBridge = TomTomBridge

function TomTomBridge:Initialize()
    self.lastWaypoint = nil
end

function TomTomBridge:IsAvailable()
    return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

function TomTomBridge:ClearLastWaypoint()
    if not self.lastWaypoint or not self:IsAvailable() then
        self.lastWaypoint = nil
        return
    end

    local uid = self.lastWaypoint
    self.lastWaypoint = nil

    if type(TomTom.IsValidWaypoint) == "function" then
        local ok, valid = pcall(TomTom.IsValidWaypoint, TomTom, uid)
        if ok and valid and type(TomTom.RemoveWaypoint) == "function" then
            pcall(TomTom.RemoveWaypoint, TomTom, uid)
        end
        return
    end

    if type(TomTom.RemoveWaypoint) == "function" then
        pcall(TomTom.RemoveWaypoint, TomTom, uid)
    end
end

function TomTomBridge:AddWaypoint(mapID, x, y, title)
    if not self:IsAvailable() then
        return nil, ns.L("tomtom_missing")
    end

    mapID = tonumber(mapID)
    x = tonumber(x)
    y = tonumber(y)
    if not mapID or not x or not y then
        return nil, ns.L("tomtom_waypoint_unavailable")
    end

    self:ClearLastWaypoint()

    local ok, uid = pcall(TomTom.AddWaypoint, TomTom, mapID, x / 100, y / 100, {
        title = title or ns.L("professions_overlay_title"),
        from = "ABPM",
        persistent = false,
        minimap = true,
        world = true,
        crazy = true,
        silent = true,
    })
    if not ok or not uid then
        return nil, ns.L("tomtom_waypoint_unavailable")
    end

    self.lastWaypoint = uid
    return uid
end
