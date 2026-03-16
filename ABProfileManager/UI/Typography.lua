local _, ns = ...

local Typography = {}
ns.UI.Typography = Typography

local FONT_PATH = UNIT_NAME_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local DEFAULT_DOMAIN = "ui"
local REGISTERED_TARGETS = setmetatable({}, { __mode = "k" })
local DOMAIN_BOUNDS = {
    ui = { min = -2, max = 6, default = 0 },
    tooltip = { min = -2, max = 6, default = 0 },
    statsOverlay = { min = -2, max = 6, default = 0 },
    professionOverlay = { min = -3, max = 6, default = 0 },
    mapOverlay = { min = -6, max = 12, default = 0 },
}

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function resolveDomain(domain)
    if DOMAIN_BOUNDS[domain] then
        return domain
    end

    return DEFAULT_DOMAIN
end

function Typography:GetBounds(domain)
    domain = resolveDomain(domain)
    return DOMAIN_BOUNDS[domain]
end

function Typography:GetFontPath()
    return FONT_PATH
end

function Typography:GetOffset(domain)
    domain = resolveDomain(domain)
    if ns.DB and ns.DB.GetTypographyOffset then
        return ns.DB:GetTypographyOffset(domain)
    end

    return self:GetBounds(domain).default
end

function Typography:GetSize(baseSize, options)
    options = options or {}
    local domain = resolveDomain(options.domain)
    local bounds = self:GetBounds(domain)
    local size = round(baseSize) + self:GetOffset(domain)
    local minSize = options.minSize or 8
    local maxSize = options.maxSize or 40

    if options.extraOffset then
        size = size + round(options.extraOffset)
    end

    size = clamp(size, minSize, maxSize)
    return size, bounds
end

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function applyRawFont(target, size, options)
    target:SetFont(options.fontPath or FONT_PATH, size, options.flags or "")

    if options.color and target.SetTextColor then
        target:SetTextColor(options.color[1], options.color[2], options.color[3], options.color[4] or 1)
    end
    if options.justifyH and target.SetJustifyH then
        target:SetJustifyH(options.justifyH)
    end
    if options.justifyV and target.SetJustifyV then
        target:SetJustifyV(options.justifyV)
    end
    if options.wordWrap ~= nil and target.SetWordWrap then
        target:SetWordWrap(options.wordWrap and true or false)
    end
    if options.nonSpaceWrap ~= nil and target.SetNonSpaceWrap then
        target:SetNonSpaceWrap(options.nonSpaceWrap and true or false)
    end
    if options.spacing and target.SetSpacing then
        target:SetSpacing(options.spacing)
    end
    if options.shadowOffset and target.SetShadowOffset then
        target:SetShadowOffset(options.shadowOffset[1], options.shadowOffset[2])
    end
    if options.shadowColor and target.SetShadowColor then
        target:SetShadowColor(
            options.shadowColor[1],
            options.shadowColor[2],
            options.shadowColor[3],
            options.shadowColor[4] or 1
        )
    end
end

function Typography:ApplyFont(target, baseSize, options)
    if not target or type(target.SetFont) ~= "function" then
        return nil
    end

    options = options or {}
    local size = self:GetSize(baseSize, options)
    applyRawFont(target, size, options)

    if not options.transient then
        REGISTERED_TARGETS[target] = {
            baseSize = baseSize,
            options = shallowCopy(options),
        }
    else
        REGISTERED_TARGETS[target] = nil
    end

    return size
end

function Typography:RefreshRegistered()
    for target, entry in pairs(REGISTERED_TARGETS) do
        if target and entry and type(target.SetFont) == "function" then
            local size = self:GetSize(entry.baseSize, entry.options)
            applyRawFont(target, size, entry.options)
        end
    end
end

function Typography:ApplyTooltip(tooltip, headerBaseSize, bodyBaseSize, options)
    if not tooltip or type(tooltip.NumLines) ~= "function" then
        return
    end

    options = options or {}
    local headerSize = self:GetSize(headerBaseSize or 13, { domain = "tooltip", minSize = 9, maxSize = 28 })
    local bodySize = self:GetSize(bodyBaseSize or 12, { domain = "tooltip", minSize = 9, maxSize = 28 })
    local bodyColor = options.bodyColor or { 0.92, 0.92, 0.88, 1 }
    local headerColor = options.headerColor or { 1, 0.86, 0.40, 1 }

    for index = 1, tooltip:NumLines() do
        local left = _G[tooltip:GetName() .. "TextLeft" .. index]
        local right = _G[tooltip:GetName() .. "TextRight" .. index]
        if left then
            local size = index == 1 and headerSize or bodySize
            left:SetFont(FONT_PATH, size, options.flags or "")
            if index == 1 then
                left:SetTextColor(headerColor[1], headerColor[2], headerColor[3], headerColor[4] or 1)
            else
                left:SetTextColor(bodyColor[1], bodyColor[2], bodyColor[3], bodyColor[4] or 1)
            end
        end
        if right then
            right:SetFont(FONT_PATH, bodySize, options.flags or "")
            right:SetTextColor(bodyColor[1], bodyColor[2], bodyColor[3], bodyColor[4] or 1)
        end
    end
end
