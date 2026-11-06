--[[
  Classic Era (1.14.4 / 1.15.x) API compatibility shims for AutoEquip.

  Blizzard gradually moved bag APIs under C_Container, item helpers under
  C_Item, and replaced Interface Options with the Settings panel. This file
  restores the old global call shapes so the rest of the addon can stay
  unchanged.
]]

local _, SELFAQ = ...

local function noop() end

-- Container APIs: globals removed after Classic Era 1.14.4
if C_Container then
    if not GetContainerNumSlots then
        GetContainerNumSlots = C_Container.GetContainerNumSlots
    end

    if not GetContainerItemID then
        GetContainerItemID = C_Container.GetContainerItemID
    end

    if not GetContainerItemLink then
        GetContainerItemLink = C_Container.GetContainerItemLink
    end

    if not PickupContainerItem then
        PickupContainerItem = C_Container.PickupContainerItem
    end

    if not ContainerIDToInventoryID then
        ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID
    end

    -- Old GetContainerItemInfo returned multiple values; C_Container returns a table.
    if not GetContainerItemInfo then
        GetContainerItemInfo = function(bag, slot)
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if not info then
                return
            end
            return info.iconFileID, info.stackCount, info.isLocked, info.quality,
                info.isReadable, info.hasLoot, info.hyperlink, info.isFiltered,
                info.hasNoValue, info.itemID, info.isBound
        end
    end
end

-- Item APIs: globals removed / namespaced after Classic Era 1.15.2
if C_Item then
    if not GetItemInfo and C_Item.GetItemInfo then
        GetItemInfo = C_Item.GetItemInfo
    end

    if not GetItemCount and C_Item.GetItemCount then
        GetItemCount = C_Item.GetItemCount
    end

    if not GetItemSpell and C_Item.GetItemSpell then
        GetItemSpell = C_Item.GetItemSpell
    end

    if not EquipItemByName and C_Item.EquipItemByName then
        EquipItemByName = C_Item.EquipItemByName
    end

    if not GetItemIcon then
        if C_Item.GetItemIconByID then
            GetItemIcon = C_Item.GetItemIconByID
        elseif C_Item.GetItemIcon then
            GetItemIcon = C_Item.GetItemIcon
        end
    end
end

-- Item cooldown: prefer C_Container (Classic Era), then C_Item (retail-shaped)
if not GetItemCooldown then
    if C_Container and C_Container.GetItemCooldown then
        GetItemCooldown = C_Container.GetItemCooldown
    elseif C_Item and C_Item.GetItemCooldown then
        GetItemCooldown = function(itemInfo)
            local startTime, duration, enable = C_Item.GetItemCooldown(itemInfo)
            if enable == true then
                enable = 1
            elseif enable == false then
                enable = 0
            end
            return startTime, duration, enable
        end
    end
end

--[[
  Settings panel replaced InterfaceOptions_* on Classic Era 1.15.3+.

  IMPORTANT: Always override Blizzard's deprecated shims when Settings exists.
  Blizzard_Deprecated.InterfaceOptionsFrame_OpenToCategory has a long-standing
  bug (`type(arg == "string")`) and passes Frame objects into
  Settings.OpenToCategory, so minimap/slash clicks open nothing.
]]
if Settings and Settings.RegisterCanvasLayoutCategory then
    SELFAQ.settingsCategories = SELFAQ.settingsCategories or {}

    function InterfaceOptions_AddCategory(frame)
        if not frame or not frame.name then
            return
        end

        -- Canvas layout panels require these even when empty.
        frame.OnCommit = frame.okay or frame.OnCommit or noop
        frame.OnDefault = frame.default or frame.OnDefault or noop
        frame.OnRefresh = frame.refresh or frame.OnRefresh or noop

        if frame.parent then
            local parent = SELFAQ.settingsCategories[frame.parent] or Settings.GetCategory(frame.parent)
            if parent then
                local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(parent, frame, frame.name)
                if subcategory then
                    subcategory.ID = frame.name
                    frame.settingsCategory = subcategory
                    SELFAQ.settingsCategories[frame.name] = subcategory
                end
                if layout and layout.AddAnchorPoint then
                    layout:AddAnchorPoint("TOPLEFT", 10, -10)
                    layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10)
                end
                return subcategory, parent
            end
        end

        local category, layout = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
        if category then
            -- Name-as-ID is required for Settings.OpenToCategory("AutoEquip")
            category.ID = frame.name
            frame.settingsCategory = category
            SELFAQ.settingsCategories[frame.name] = category
        end
        if layout and layout.AddAnchorPoint then
            layout:AddAnchorPoint("TOPLEFT", 10, -10)
            layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10)
        end

        if Settings.RegisterAddOnCategory then
            Settings.RegisterAddOnCategory(category)
        else
            Settings.RegisterCategory(category)
        end
        return category
    end

    local function openSettingsCategory(name, expandParentName)
        if not name then
            return false
        end

        if expandParentName then
            local parent = SELFAQ.settingsCategories[expandParentName] or Settings.GetCategory(expandParentName)
            if parent and parent.HasSubcategories and parent:HasSubcategories() then
                parent.expanded = true
            end
        end

        local category = SELFAQ.settingsCategories[name] or Settings.GetCategory(name)
        if category then
            if category.HasSubcategories and category:HasSubcategories() then
                category.expanded = true
            end
            local id = category.ID
            if category.GetID then
                id = category:GetID() or id
            end
            Settings.OpenToCategory(id or name)
            return true
        end

        Settings.OpenToCategory(name)
        return true
    end

    function InterfaceOptionsFrame_OpenToCategory(categoryIDOrFrame)
        if type(categoryIDOrFrame) == "table" then
            local name = categoryIDOrFrame.name
            local parentName = categoryIDOrFrame.parent
            -- Prefer the exact panel; if subcategory open fails on some clients,
            -- fall back to the top-level parent.
            if openSettingsCategory(name, parentName) then
                return
            end
            if parentName then
                openSettingsCategory(parentName)
            end
            return
        end

        openSettingsCategory(categoryIDOrFrame)
    end
elseif not InterfaceOptions_AddCategory then
    -- Neither Settings nor legacy Interface Options: keep init from erroring.
    function InterfaceOptions_AddCategory(frame)
        SELFAQ.settingsCategories = SELFAQ.settingsCategories or {}
        if frame and frame.name then
            SELFAQ.settingsCategories[frame.name] = frame
        end
    end
end

local function ensureStandaloneSettings()
    if SELFAQ.standaloneSettings then
        return SELFAQ.standaloneSettings
    end

    local f = CreateFrame("Frame", "AutoEquipStandaloneSettings", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(760, 560)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "AutoEquipStandaloneSettings")

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0, 0, 0, 0.92)
    end

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -12)
    title:SetText("AutoEquip")
    f.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    SELFAQ.standaloneSettings = f
    return f
end

-- Unified opener used by minimap / slash / UI buttons.
-- Classic Era Settings.OpenToCategory is unreliable for addon canvas panels,
-- so minimap/slash always open a standalone window.
function SELFAQ.openSettings(panel)
    panel = panel or SELFAQ.general or SELFAQ.top
    if not panel then
        print("|cffff9900AutoEquip:|r 设置尚未初始化。请先 /reload，并确认角色已完全进入世界。")
        print("|cffff9900AutoEquip:|r 若持续失败，请执行 /console scriptErrors 1 后再 /reload 查看报错。")
        return
    end

    local host = ensureStandaloneSettings()
    local content = panel
    -- Prefer the full General page when opening from the top landing page
    if panel == SELFAQ.top and SELFAQ.general then
        content = SELFAQ.general
    end

    content:SetParent(host)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", 12, -36)
    content:SetPoint("BOTTOMRIGHT", -28, 12)
    content:Show()
    if content.SetVerticalScroll then
        content:SetVerticalScroll(0)
    end

    host:Show()
    host:Raise()
end

-- Keep Blizzard Settings registration for Esc > Options, but also expose a
-- direct opener that never depends on Settings.OpenToCategory.
function SELFAQ.openBlizzardSettings(panel)
    panel = panel or SELFAQ.top or SELFAQ.general
    if not panel then
        return
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        SELFAQ.openSettings(panel)
    end
end

if not NUM_BAG_SLOTS then
    NUM_BAG_SLOTS = 4
end
