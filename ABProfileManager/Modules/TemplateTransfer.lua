local _, ns = ...

local TemplateTransfer = {}
ns.Modules.TemplateTransfer = TemplateTransfer

local EXPORT_PREFIX = "ABPM1"
local MAX_IMPORT_BYTES = 262144
local MAX_IMPORT_LINES = 512
local MAX_NAME_LENGTH = 80
local MAX_CLASS_LENGTH = 32
local MAX_CHARACTER_LENGTH = 80
local MAX_SAVED_AT_LENGTH = 32
local MAX_SUBTYPE_LENGTH = 64
local MAX_ICON_LENGTH = 256
local MAX_MACRO_NAME_LENGTH = 128
local MAX_MACRO_BODY_LENGTH = 4096
local ALLOWED_KINDS = {
    empty = true,
    spell = true,
    item = true,
    macro = true,
}

local function encodeValue(value)
    local text = tostring(value or "")
    return (text:gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

local function decodeValue(value)
    local text = tostring(value or "")
    return (text:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

local function splitLine(line)
    local parts = {}
    local buffer = ""

    for index = 1, #line do
        local char = string.sub(line, index, index)
        if char == "|" then
            parts[#parts + 1] = buffer
            buffer = ""
        else
            buffer = buffer .. char
        end
    end

    parts[#parts + 1] = buffer
    return parts
end

local function validateLength(value, maxLength, errKey)
    value = tostring(value or "")
    if #value > maxLength then
        return nil, ns.L(errKey)
    end

    return value
end

local function decodeSingleLine(value, maxLength, errKey)
    local decoded = ns.Utils.SanitizeSingleLine(decodeValue(value or ""))
    return validateLength(decoded, maxLength, errKey)
end

local function decodeMultiline(value, maxLength, errKey)
    local decoded = ns.Utils.RemoveControlChars(decodeValue(value or ""), true) or ""
    return validateLength(decoded, maxLength, errKey)
end

local function buildSlotLine(logicalSlot, record)
    return table.concat({
        "slot",
        tostring(logicalSlot),
        encodeValue(record.kind or "empty"),
        encodeValue(record.id or ""),
        encodeValue(record.name or ""),
        encodeValue(record.subType or ""),
        encodeValue(record.icon or ""),
        encodeValue(record.macroBody or ""),
    }, "|")
end

function TemplateTransfer:Initialize()
end

function TemplateTransfer:ExportTemplate(templateName)
    local template, err = ns.Modules.ProfileManager:GetSource(ns.Constants.SOURCE_KIND.TEMPLATE, templateName)
    if not template then
        return nil, err
    end

    local lines = {
        EXPORT_PREFIX,
        table.concat({ "name", encodeValue(template.sourceKey or templateName) }, "|"),
        table.concat({ "class", encodeValue(template.class or "") }, "|"),
        table.concat({ "spec", tostring(template.specID or 0) }, "|"),
        table.concat({ "character", encodeValue(template.characterKey or "") }, "|"),
        table.concat({ "savedAt", encodeValue(template.savedAt or "") }, "|"),
    }

    for logicalSlot = ns.Constants.LOGICAL_SLOT_MIN, ns.Constants.LOGICAL_SLOT_MAX do
        local record = template.slots and template.slots[logicalSlot]
        if record and record.kind and record.kind ~= "empty" then
            lines[#lines + 1] = buildSlotLine(logicalSlot, record)
        end
    end

    return table.concat(lines, "\n")
end

function TemplateTransfer:ImportTemplate(serializedText, overrideName)
    local text = ns.Utils.Trim(serializedText or "")
    if text == "" then
        return nil, ns.L("transfer_error_empty")
    end

    if #text > MAX_IMPORT_BYTES then
        return nil, ns.L("transfer_error_too_large")
    end

    local lines = {}
    for line in string.gmatch(text, "[^\r\n]+") do
        lines[#lines + 1] = line
        if #lines > MAX_IMPORT_LINES then
            return nil, ns.L("transfer_error_too_many_lines")
        end
    end

    if lines[1] ~= EXPORT_PREFIX then
        return nil, ns.L("transfer_error_invalid_prefix")
    end

    local meta = {}
    local slots = {}
    local seenSlots = {}

    for index = 2, #lines do
        local parts = splitLine(lines[index])
        local key = parts[1]

        if key == "slot" then
            local logicalSlot = tonumber(parts[2] or "")
            if logicalSlot and logicalSlot >= ns.Constants.LOGICAL_SLOT_MIN and logicalSlot <= ns.Constants.LOGICAL_SLOT_MAX then
                if seenSlots[logicalSlot] then
                    return nil, ns.L("transfer_error_duplicate_slot")
                end
                seenSlots[logicalSlot] = true

                local kind, kindErr = decodeSingleLine(parts[3] or "empty", 16, "transfer_error_invalid_format")
                if not kind or not ALLOWED_KINDS[kind] then
                    return nil, kindErr or ns.L("transfer_error_invalid_action_kind")
                end

                local icon, iconErr = decodeSingleLine(parts[7] or "", MAX_ICON_LENGTH, "transfer_error_invalid_format")
                if iconErr then
                    return nil, iconErr
                end

                local actionName, nameErr = decodeSingleLine(parts[5] or "", MAX_MACRO_NAME_LENGTH, "transfer_error_invalid_format")
                if nameErr then
                    return nil, nameErr
                end

                local subType, subTypeErr = decodeSingleLine(parts[6] or "", MAX_SUBTYPE_LENGTH, "transfer_error_invalid_format")
                if subTypeErr then
                    return nil, subTypeErr
                end

                local macroBody, bodyErr = decodeMultiline(parts[8] or "", MAX_MACRO_BODY_LENGTH, "transfer_error_invalid_format")
                if bodyErr then
                    return nil, bodyErr
                end

                slots[logicalSlot] = {
                    logicalSlot = logicalSlot,
                    actualSlot = logicalSlot,
                    kind = kind,
                    id = tonumber(decodeValue(parts[4] or "")),
                    name = actionName,
                    subType = subType,
                    icon = icon ~= "" and icon or ns.Constants.DEFAULT_ICON,
                    macroBody = macroBody,
                    status = "imported",
                }
            end
        elseif key and parts[2] then
            meta[key] = parts[2]
        end
    end

    local templateName = ns.Utils.SanitizeSingleLine(overrideName or "")
    local overrideLengthOk, overrideErr = validateLength(templateName, MAX_NAME_LENGTH, "transfer_error_name_too_long")
    if overrideErr then
        return nil, overrideErr
    end
    templateName = overrideLengthOk or ""
    if templateName == "" then
        local metaName, nameErr = decodeSingleLine(meta.name or "", MAX_NAME_LENGTH, "transfer_error_name_too_long")
        if nameErr then
            return nil, nameErr
        end
        templateName = metaName
    end

    if templateName == "" then
        return nil, ns.L("transfer_error_missing_name")
    end

    local className, classErr = decodeSingleLine(meta.class or "", MAX_CLASS_LENGTH, "transfer_error_invalid_format")
    if classErr then
        return nil, classErr
    end

    local characterKey, charErr = decodeSingleLine(meta.character or "", MAX_CHARACTER_LENGTH, "transfer_error_invalid_format")
    if charErr then
        return nil, charErr
    end

    local savedAt, savedErr = decodeSingleLine(meta.savedAt or "", MAX_SAVED_AT_LENGTH, "transfer_error_invalid_format")
    if savedErr then
        return nil, savedErr
    end

    local specText, specErr = decodeSingleLine(meta.spec or "0", 16, "transfer_error_invalid_format")
    if specErr then
        return nil, specErr
    end

    local snapshot = {
        sourceType = ns.Constants.SOURCE_KIND.TEMPLATE,
        sourceKey = templateName,
        characterKey = characterKey ~= "" and characterKey or ns.DB:GetCharacterKey(),
        class = className ~= "" and className or "UNKNOWN",
        specID = tonumber(specText or "0") or 0,
        savedAt = savedAt ~= "" and savedAt or date("%Y-%m-%d %H:%M:%S"),
        scannedAt = date("%Y-%m-%d %H:%M:%S"),
        range = {
            startSlot = ns.Constants.LOGICAL_SLOT_MIN,
            endSlot = ns.Constants.LOGICAL_SLOT_MAX,
        },
        slots = slots,
    }

    ns.DB:SetTemplate(templateName, snapshot)
    return snapshot
end
