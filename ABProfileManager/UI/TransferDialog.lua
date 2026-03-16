local _, ns = ...

local TransferDialog = {}
ns.UI.TransferDialog = TransferDialog

local function setStatus(message)
    ns:SafeCall(ns.UI.MainWindow, "SetStatus", message)
end

local function layoutButtons(frame, showCopy)
    frame.secondaryButton:ClearAllPoints()
    frame.secondaryButton:SetPoint("BOTTOMRIGHT", -28, 22)

    if showCopy then
        frame.copyButton:Show()
        frame.copyButton:ClearAllPoints()
        frame.copyButton:SetPoint("RIGHT", frame.secondaryButton, "LEFT", -10, 0)
        frame.primaryButton:ClearAllPoints()
        frame.primaryButton:SetPoint("RIGHT", frame.copyButton, "LEFT", -10, 0)
    else
        frame.copyButton:Hide()
        frame.primaryButton:ClearAllPoints()
        frame.primaryButton:SetPoint("RIGHT", frame.secondaryButton, "LEFT", -10, 0)
    end
end

local function buildFrame()
    local frame = CreateFrame("Frame", "ABPMTransferDialog", UIParent, "BackdropTemplate")
    frame:SetSize(680, 470)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0.02, 0.04, 0.07, 0.96)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", 22, -18)
    frame.title:SetTextColor(1, 0.86, 0.42, 1)
    ns.UI.Widgets.ApplyFont(frame.title, 15, { domain = "ui" })

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    frame.helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.helpText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -12)
    frame.helpText:SetWidth(636)
    frame.helpText:SetJustifyH("LEFT")
    frame.helpText:SetJustifyV("TOP")
    frame.helpText:SetTextColor(0.92, 0.92, 0.9, 1)
    ns.UI.Widgets.ApplyFont(frame.helpText, 12, { domain = "ui" })

    frame.nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.nameLabel:SetPoint("TOPLEFT", frame.helpText, "BOTTOMLEFT", 0, -14)
    frame.nameLabel:SetTextColor(1, 0.83, 0.36, 1)
    ns.UI.Widgets.ApplyFont(frame.nameLabel, 13, { domain = "ui" })

    frame.nameInput = ns.UI.Widgets.CreateEditBox(frame, 260, 24)
    frame.nameInput:SetPoint("TOPLEFT", frame.nameLabel, "BOTTOMLEFT", 0, -8)

    frame.textArea = ns.UI.Widgets.CreateScrollEditBox(frame, 636, 250, false)
    frame.textArea:SetPoint("TOPLEFT", frame.nameInput, "BOTTOMLEFT", 0, -16)

    frame.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.statusText:SetPoint("TOPLEFT", frame.textArea, "BOTTOMLEFT", 0, -10)
    frame.statusText:SetWidth(636)
    frame.statusText:SetJustifyH("LEFT")
    frame.statusText:SetTextColor(0.82, 0.88, 0.98, 1)
    ns.UI.Widgets.ApplyFont(frame.statusText, 11, { domain = "ui" })

    frame.primaryButton = ns.UI.Widgets.CreateButton(frame, "", 140, 28)

    frame.secondaryButton = ns.UI.Widgets.CreateButton(frame, "", 120, 28)
    frame.copyButton = ns.UI.Widgets.CreateButton(frame, "", 110, 28)
    layoutButtons(frame, true)

    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.secondaryButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

function TransferDialog:Initialize()
end

function TransferDialog:GetFrame()
    if not self.frame then
        self.frame = buildFrame()
    end
    return self.frame
end

function TransferDialog:ShowExport(templateName)
    local frame = self:GetFrame()
    local exportText, err = ns.Modules.TemplateTransfer:ExportTemplate(templateName)
    if not exportText then
        setStatus(err)
        return
    end

    frame.mode = "export"
    frame.title:SetText(ns.L("transfer_export_title"))
    frame.helpText:SetText(ns.L("transfer_export_help"))
    frame.nameLabel:SetText(ns.L("transfer_export_name", templateName))
    frame.nameLabel:Show()
    frame.nameInput:Hide()
    frame.textArea:SetEditable(false)
    frame.textArea:SetText(exportText)
    frame.statusText:SetText("")
    frame.statusText:SetText(ns.Utils.FormatStatusMessage(ns.L("transfer_export_status")))
    frame.primaryButton:SetText(ns.L("transfer_select_all"))
    frame.copyButton:SetText(ns.L("transfer_copy"))
    frame.secondaryButton:SetText(ns.L("transfer_close"))
    layoutButtons(frame, true)
    frame.primaryButton:SetScript("OnClick", function()
        frame.textArea:FocusAndHighlight()
    end)
    frame.copyButton:SetScript("OnClick", function()
        frame.textArea:FocusAndHighlight()
        frame.statusText:SetText("")
        frame.statusText:SetText(ns.Utils.FormatStatusMessage(ns.L("transfer_copy_ready")))
        setStatus(ns.L("transfer_copy_ready"))
    end)
    frame:Show()
end

function TransferDialog:ShowImport(onImported)
    local frame = self:GetFrame()
    frame.mode = "import"
    frame.title:SetText(ns.L("transfer_import_title"))
    frame.helpText:SetText(ns.L("transfer_import_help"))
    frame.nameLabel:SetText(ns.L("transfer_import_name"))
    frame.nameLabel:Show()
    frame.nameInput:Show()
    frame.nameInput:SetText("")
    frame.textArea:SetEditable(true)
    frame.textArea:SetText("")
    frame.statusText:SetText("")
    frame.primaryButton:SetText(ns.L("transfer_import_action"))
    frame.secondaryButton:SetText(ns.L("transfer_cancel"))
    layoutButtons(frame, false)
    frame.primaryButton:SetScript("OnClick", function()
        local snapshot, err = ns.Modules.TemplateTransfer:ImportTemplate(frame.textArea:GetText(), frame.nameInput:GetText())
        if not snapshot then
            frame.statusText:SetText("")
            frame.statusText:SetText(ns.Utils.FormatStatusMessage(err or ns.L("transfer_error_invalid_format")))
            return
        end

        ns:SetSelectedSource(ns.Constants.SOURCE_KIND.TEMPLATE, snapshot.sourceKey)
        frame.statusText:SetText("")
        frame.statusText:SetText(ns.Utils.FormatStatusMessage(ns.L("transfer_import_success", snapshot.sourceKey)))
        setStatus(ns.L("transfer_import_success", snapshot.sourceKey))
        frame:Hide()
        ns:RefreshUI()

        if onImported then
            onImported(snapshot)
        end
    end)
    frame:Show()
    frame.nameInput:SetFocus()
end
