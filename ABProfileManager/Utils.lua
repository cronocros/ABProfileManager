local _, ns = ...

local Utils = {}
ns.Utils = Utils

function Utils.Print(message)
    print(string.format("|cff69ccf0%s|r: %s", ns.Constants.ADDON_PREFIX, message))
end

function Utils.Debug(message)
    if ns.DB and ns.DB.IsDebugEnabled and ns.DB:IsDebugEnabled() then
        Utils.Print("[debug] " .. tostring(message))
    end
end

function Utils.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[Utils.DeepCopy(key)] = Utils.DeepCopy(entry)
    end

    return copy
end

function Utils.MergeDefaults(target, defaults)
    if type(defaults) ~= "table" then
        return target
    end

    if type(target) ~= "table" then
        target = {}
    end

    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            target[key] = Utils.MergeDefaults(target[key], defaultValue)
        elseif target[key] == nil then
            target[key] = defaultValue
        end
    end

    return target
end

function Utils.Trim(value)
    if type(value) ~= "string" then
        return value
    end

    return value:match("^%s*(.-)%s*$")
end

function Utils.RemoveControlChars(value, keepNewlines)
    if type(value) ~= "string" then
        return value
    end

    if keepNewlines then
        value = value:gsub("[\0-\8\11\12\14-\31\127]", "")
        return value
    end

    value = value:gsub("[%c]", "")
    return value
end

function Utils.SanitizeSingleLine(value)
    value = Utils.Trim(Utils.RemoveControlChars(value or "", false) or "")
    if type(value) ~= "string" then
        return ""
    end

    value = value:gsub("[\r\n\t]", " ")
    value = value:gsub("%s+", " ")
    return Utils.Trim(value) or ""
end

function Utils.SplitArgs(input)
    local args = {}

    if not input or input == "" then
        return args
    end

    local current = ""
    local inQuotes = false

    for index = 1, #input do
        local character = input:sub(index, index)
        if character == "\"" then
            if inQuotes then
                args[#args + 1] = current
                current = ""
                inQuotes = false
            else
                if current ~= "" then
                    args[#args + 1] = current
                    current = ""
                end
                inQuotes = true
            end
        elseif character:match("%s") and not inQuotes then
            if current ~= "" then
                args[#args + 1] = current
                current = ""
            end
        else
            current = current .. character
        end
    end

    if current ~= "" then
        args[#args + 1] = current
    end

    return args
end

function Utils.SafeToNumber(value, fallback)
    local numeric = tonumber(value)
    if not numeric then
        return fallback
    end

    return math.floor(numeric)
end

function Utils.SortedKeys(tbl)
    local keys = {}

    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys)
    return keys
end

function Utils.TableCount(tbl)
    local count = 0

    for _ in pairs(tbl or {}) do
        count = count + 1
    end

    return count
end

function Utils.FormatSourceLabel(kind, key)
    if not kind or not key then
        return ns.L("source_none")
    end

    return ns.L("source_template", key)
end

function Utils.JoinArgs(args, startIndex, endIndex)
    if not args or not startIndex then
        return ""
    end

    endIndex = endIndex or #args
    if endIndex < startIndex then
        return ""
    end

    local parts = {}
    for index = startIndex, endIndex do
        if args[index] and args[index] ~= "" then
            parts[#parts + 1] = args[index]
        end
    end

    return table.concat(parts, " ")
end

function Utils.ParseNumberList(input)
    local values = {}

    if type(input) == "table" then
        for _, value in ipairs(input) do
            local numeric = Utils.SafeToNumber(value, nil)
            if numeric then
                values[#values + 1] = numeric
            end
        end
        return values
    end

    if type(input) ~= "string" then
        return values
    end

    for token in string.gmatch(input, "[^,%s]+") do
        local numeric = Utils.SafeToNumber(token, nil)
        if numeric then
            values[#values + 1] = numeric
        end
    end

    return values
end

function Utils.FormatStatusMessage(message)
    if type(message) ~= "string" or message == "" then
        return message
    end

    if message:match("^[●◆▲■] ") then
        return message
    end

    if message:match("^(성공|실패|안내):%s") or message:match("^(Success|Failure|Info):%s") then
        return message
    end

    local heading = message
    local rest = ""
    local firstLine, remaining = message:match("^([^\n]+)\n?(.*)$")
    if firstLine and firstLine ~= "" then
        heading = firstLine
        rest = remaining or ""
    end

    heading = heading:gsub("^%[(.-)%]$", "%1")

    local failureMarkers = {
        "실패",
        "오류",
        "찾을 수 없습니다",
        "올바르지",
        "유효하지",
        "지원하지",
        "할 수 없습니다",
        "필요합니다",
        "필요합니다.",
        "먼저",
        "경고",
        "unavailable",
        "invalid",
        "not found",
        "unsupported",
        "could not",
        "required",
        "cannot",
        "failed",
        "error",
    }

    local successMarkers = {
        "완료",
        "저장",
        "삭제",
        "가져왔",
        "변경했",
        "변경을",
        "업데이트",
        "대기열",
        "queued",
        "complete",
        "saved",
        "deleted",
        "imported",
        "enabled",
        "disabled",
        "changed",
    }

    local kind = "info"
    local lowerHeading = string.lower(heading)
    for _, marker in ipairs(failureMarkers) do
        if heading:find(marker, 1, true) or lowerHeading:find(string.lower(marker), 1, true) then
            kind = "failure"
            break
        end
    end

    if kind == "info" then
        for _, marker in ipairs(successMarkers) do
            if heading:find(marker, 1, true) or lowerHeading:find(string.lower(marker), 1, true) then
                kind = "success"
                break
            end
        end
    end

    local prefix = "● 안내: "
    if kind == "success" then
        prefix = "● 성공: "
    elseif kind == "failure" then
        prefix = "◆ 실패: "
    end

    if rest ~= "" then
        return prefix .. heading .. "\n" .. rest
    end

    return prefix .. heading
end
