--[[
  Classic Era (1.14.4 / 1.15.x) API compatibility shims for AutoEquip.

  Blizzard gradually moved bag APIs under C_Container, item helpers under
  C_Item, and replaced Interface Options with the Settings panel. This file
  restores the old global call shapes so the rest of the addon can stay
  unchanged.
]]

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

-- Settings panel replaced InterfaceOptions_* on Classic Era ~1.15.5+
if not InterfaceOptions_AddCategory and Settings and Settings.RegisterCanvasLayoutCategory then
    function InterfaceOptions_AddCategory(frame)
        if frame.parent then
            local parent = Settings.GetCategory(frame.parent)
            if parent then
                local subcategory = Settings.RegisterCanvasLayoutSubcategory(parent, frame, frame.name)
                if subcategory then
                    subcategory.ID = frame.name
                end
                return subcategory, parent
            end
        end

        local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
        if category then
            category.ID = frame.name
        end
        Settings.RegisterAddOnCategory(category)
        return category
    end
end

if not InterfaceOptionsFrame_OpenToCategory and Settings and Settings.OpenToCategory then
    function InterfaceOptionsFrame_OpenToCategory(categoryIDOrFrame)
        local categoryID = categoryIDOrFrame
        if type(categoryIDOrFrame) == "table" then
            categoryID = categoryIDOrFrame.name
        end
        if categoryID then
            Settings.OpenToCategory(categoryID)
        end
    end
end

if not NUM_BAG_SLOTS then
    NUM_BAG_SLOTS = 4
end
