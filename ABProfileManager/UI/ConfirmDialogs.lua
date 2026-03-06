local _, ns = ...

local ConfirmDialogs = {}
ns.UI.ConfirmDialogs = ConfirmDialogs

function ConfirmDialogs:Initialize()
    if self._initializedDialogs or not StaticPopupDialogs then
        return
    end

    StaticPopupDialogs["ABPM_CONFIRM_ACTION"] = {
        text = "%s",
        button1 = ACCEPT,
        button2 = CANCEL,
        OnShow = function(dialog)
            if dialog.button1 then
                dialog.button1:SetText(ACCEPT)
            end
            if dialog.button2 then
                dialog.button2:SetText(CANCEL)
            end
        end,
        OnAccept = function(_, data)
            if data and data.onAccept then
                data.onAccept()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["ABPM_CONFIRM_DELETE_SOURCE"] = {
        text = "%s",
        button1 = DELETE,
        button2 = CANCEL,
        OnAccept = function(_, data)
            if data and data.onAccept then
                data.onAccept()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    self._initializedDialogs = true
end

function ConfirmDialogs:ShowConfirm(text, onAccept)
    if not StaticPopup_Show then
        if onAccept then
            onAccept()
        end
        return
    end

    StaticPopup_Show("ABPM_CONFIRM_ACTION", text, nil, {
        onAccept = onAccept,
    })
end

function ConfirmDialogs:ShowDeleteConfirm(text, onAccept)
    if not StaticPopup_Show then
        if onAccept then
            onAccept()
        end
        return
    end

    StaticPopup_Show("ABPM_CONFIRM_DELETE_SOURCE", text, nil, {
        onAccept = onAccept,
    })
end
