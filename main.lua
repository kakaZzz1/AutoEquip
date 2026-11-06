local _, SELFAQ = ...

local debug = SELFAQ.debug
local clone = SELFAQ.clone
local diff = SELFAQ.diff
local L = SELFAQ.L
local initSV = SELFAQ.initSV
local loopSlots = SELFAQ.loopSlots
local chatInfo = SELFAQ.chatInfo
local chatInfo = SELFAQ.chatInfo
local popupInfo = SELFAQ.popupInfo


-- 主函数 --

-- 小地图按钮
local icon = LibStub("LibDBIcon-1.0")

local MiniIconLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AutoEquip", {
        type = "data source",
        text = "AutoEquip",
        icon = 136115,
        OnClick = function()
            -- Always open standalone settings; Blizzard Settings.OpenToCategory
            -- is unreliable for this addon's canvas panels on Classic Era.
            SELFAQ.openSettings(SELFAQ.general or SELFAQ.top)
        end,
        OnEnter = function(owner)
            local anchor = owner:GetBottom() < GetScreenHeight() / 2 and 'ANCHOR_TOP' or 'ANCHOR_BOTTOM'
            GameTooltip:SetOwner(owner, anchor)
            GameTooltip:SetText(L["AutoEquip "]..SELFAQ.version)
            GameTooltip:AddDoubleLine("|cffffffffClick: Open settings|r")
            GameTooltip:Show()
        end,
        OnLeave = GameTooltip_Hide,
})

icon:Register("MiniIcon", MiniIconLDB)


-- 注入按键设置页面
for k,v in pairs(SELFAQ.gearSlots) do
    _G["BINDING_NAME_AUTOEQUIP_BUTTON"..v] = SELFAQ.slotToName[v]
end

for i=1,9 do
    _G["BINDING_NAME_AUTOEQUIP_SUIT"..i] = L["Suit "]..i
end

_G["BINDING_NAME_AUTOEQUIP_TAKEOFF"] = L["Takeoff"]

-- _G.BINDING_NAME_AUTOEQUIP_BUTTON14 = L['Trinket Slot ']..2
_G.BINDING_HEADER_AUTOEQUIP_INVENTORYBAR_BUTTON = L["Equipment Bar Button"]
_G.BINDING_HEADER_AUTOEQUIP_SUPER_EQUIP = L["Super Equip"]

-- 注册事件
SELFAQ.main = CreateFrame("Frame")

-- 计数器
SELFAQ.main.TimeSinceLastUpdate = 0
-- 函数执行间隔时间
SELFAQ.main.Interval = 0.5
SELFAQ.main.garbageCount = 0

SELFAQ.onMainUpdate = function(self, elapsed)

    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;  

    -- 每秒执行执行一次
    if (self.TimeSinceLastUpdate > self.Interval) then

        -- 重新计时
        self.TimeSinceLastUpdate = 0;

        self.garbageCount = self.garbageCount + 1

        if self.garbageCount > 5 then
            -- collectgarbage("collect")
            self.garbageCount = 0
        end

        -- 以能读取到物品信息为基准，开始执行
        -- 尝试过在ADDON_LOADED等事件中初始化，发现无法读取物品信息，所以改为现在这个逻辑
        if GetItemInfo(12930) == nil then
            debug("not ready")
            return
        end

        -- 插件初始化，包括构建选项菜单
        if not SELFAQ.init then

            -- 初始化全局变量

            SUITAQ = initSV(SUITAQ, {})

            -- for i=1,9 do
            --     SUITAQ[i] = initSV(SUITAQ[i], {})
            -- end

            AQSV = initSV(AQSV, {})
            AQSV.usableItems = initSV(AQSV.usableItems, SELFAQ.usable)
            AQSV.usableChests = initSV(AQSV.usableChests, SELFAQ.usableChests)
            AQSV.enable = initSV(AQSV.enable, true)
            AQSV.enableBattleground = initSV(AQSV.enableBattleground, true)
            AQSV.disableSlot14 = initSV(AQSV.disableSlot14, false)
            AQSV.enableCarrot = initSV(AQSV.enableCarrot, true)
            AQSV.enableSwim = initSV(AQSV.enableSwim, true)
            AQSV.slot13 = initSV(AQSV.slot13, 0)
            AQSV.slot14 = initSV(AQSV.slot14, 0)
            AQSV.queue13 = initSV(AQSV.queue13, {})
            AQSV.queue14 = initSV(AQSV.queue14, {})

            AQSV.x = initSV(AQSV.x, 200)
            AQSV.y = initSV(AQSV.y, 0)
            AQSV.point = initSV(AQSV.point, "CENTER")
            AQSV.locked = initSV(AQSV.locked, false)
            AQSV.enableItemBar = initSV(AQSV.enableItemBar, true)
            AQSV.enableItemBarSlot = initSV(AQSV.enableItemBarSlot, {})

            AQSV.raidTrinkets = initSV(AQSV.raidTrinkets, {})
            AQSV.pveTrinkets = initSV(AQSV.pveTrinkets, {})
            AQSV.pvpTrinkets = initSV(AQSV.pvpTrinkets, {})
            AQSV.pvpMode = initSV(AQSV.pvpMode, false)
            AQSV.reverseCooldownUnit = initSV(AQSV.reverseCooldownUnit, true)

            AQSV.carrotBackup = initSV(AQSV.carrotBackup, 0)
            AQSV.backup8 = initSV(AQSV.backup8, 0)
            AQSV.backup10 = initSV(AQSV.backup10, 0)
            AQSV.backup1 = initSV(AQSV.backup1, 0)
            AQSV.backup6 = initSV(AQSV.backup6, 0)
            AQSV.backup16 = initSV(AQSV.backup16, 0)
            AQSV.backup17 = initSV(AQSV.backup17, 0)

            AQSV.slot13Locked = initSV(AQSV.slot13Locked, false)
            AQSV.slot14Locked = initSV(AQSV.slot14Locked, false)

            AQSV.slot13LockedCD = initSV(AQSV.slot13LockedCD, false)
            AQSV.slot14LockedCD = initSV(AQSV.slot14LockedCD, false)
            
            AQSV.slot13LockedTime = initSV(AQSV.slot13LockedTime, 0)
            AQSV.slot14LockedTime = initSV(AQSV.slot14LockedTime, 0)
            AQSV.slot13LockedTime = 0
            AQSV.slot14LockedTime = 0

            AQSV.xBuff = initSV(AQSV.xBuff, 200)
            AQSV.yBuff = initSV(AQSV.yBuff, 80)
            AQSV.pointBuff = initSV(AQSV.pointBuff, "CENTER")

            AQSV.enableBuff = initSV(AQSV.enableBuff, true)
            AQSV.buffLocked = initSV(AQSV.buffLocked, false)

            AQSV.forcePriority = initSV(AQSV.forcePriority, false)

            AQSV.buffNames = initSV(AQSV.buffNames, L["Unstable Power, Mind Quickening"])
            AQSV.additionItems = initSV(AQSV.additionItems, "14023/0")
            AQSV.blockItems = initSV(AQSV.blockItems, "6219,5956")
            AQSV.ignoreBoss = initSV(AQSV.ignoreBoss, "")

            AQSV.barZoom = initSV(AQSV.barZoom, 1)
            AQSV.buffZoom = initSV(AQSV.buffZoom, 1)
            AQSV.hideBackdrop = initSV(AQSV.hideBackdrop, false)

            AQSV.suit = initSV(AQSV.suit, {})
            AQSV.suit[73] = initSV(AQSV.suit[73], {})
            AQSV.suit[74] = initSV(AQSV.suit[74], {})
            AQSV.suit[70] = initSV(AQSV.suit[70], {})
            AQSV.currentSuit = initSV(AQSV.currentSuit, 0)
            AQSV.enableSuit = initSV(AQSV.enableSuit, false)
            AQSV.enableAutoSuit70 = initSV(AQSV.enableAutoSuit70, false)
            AQSV.enableTargetSuit70 = initSV(AQSV.enableTargetSuit70, false)

            AQSV.itemsPerColumn = initSV(AQSV.itemsPerColumn, 4)
            AQSV.customSlots = initSV(AQSV.customSlots, {})
            AQSV.hideItemQueue = initSV(AQSV.hideItemQueue, false)
            AQSV.hideTooltip = initSV(AQSV.hideTooltip, false)
            AQSV.shiftLeftShowDropdown = initSV(AQSV.shiftLeftShowDropdown, false)
            AQSV.buttonSpacing = initSV(AQSV.buttonSpacing, 3)
            AQSV.buttonSpacingNew = initSV(AQSV.buttonSpacingNew, 0)


            AQSV.cloakBackup = initSV(AQSV.cloakBackup, 0)

            AQSV.simpleTooltip = initSV(AQSV.simpleTooltip, false)

            AQSV.disableMouseover = initSV(AQSV.disableMouseover, false)
            AQSV.hidePopupInfo = initSV(AQSV.hidePopupInfo, false)
            AQSV.hideQuickButton = initSV(AQSV.hideQuickButton, false)
            AQSV.hideTakeoffButton = initSV(AQSV.hideTakeoffButton, false)

            AQSV.popupX = initSV(AQSV.popupX, 0)
            AQSV.popupY = initSV(AQSV.popupY, 320)

            AQSV.enableMembersTarget = initSV(AQSV.enableMembersTarget, false)
            AQSV.raidTargetThreshold = initSV(AQSV.raidTargetThreshold, 1)

            AQSV.enableRaidQueue = initSV(AQSV.enableRaidQueue, false)

            AQSV.enableFixedPosition = initSV(AQSV.enableFixedPosition, false)

            AQSV.enableAccInstance = initSV(AQSV.enableAccInstance, false)
            AQSV.forceAcc = initSV(AQSV.forceAcc, true)
            AQSV.pauseAccWhenTarget = initSV(AQSV.pauseAccWhenTarget, true)
            AQSV.pauseAccWhenTargetFriend = initSV(AQSV.pauseAccWhenTargetFriend, true)
            AQSV.pauseAccWhenTargetMember = initSV(AQSV.pauseAccWhenTargetMember, true)

            AQSV.quickButtonZoom = initSV(AQSV.quickButtonZoom, 1)
            AQSV.quickButtonLocked = initSV(AQSV.quickButtonLocked, false)
            AQSV.splitQuickButton = initSV(AQSV.splitQuickButton, false)
            AQSV.quickButtonX = initSV(AQSV.quickButtonX, 0)
            AQSV.quickButtonY = initSV(AQSV.quickButtonY, 0)
            AQSV.quickButtonPosition = initSV(AQSV.quickButtonPosition, "CENTER")

            AQSV.enableLR = initSV(AQSV.enableLR, false)
            AQSV.enableQuickEquip = initSV(AQSV.enableQuickEquip, true)

            AQSV.hideItemLevel = initSV(AQSV.hideItemLevel, false)

            AQSV.enableMinimapIcon = initSV(AQSV.enableMinimapIcon, true)

            AQSV.enableTargetUndead = initSV(AQSV.enableTargetUndead, true)
            AQSV.enableInUndeadInstance = initSV(AQSV.enableInUndeadInstance, true)

            AQSV.undeadPosition = initSV(AQSV.undeadPosition, 1)

            if not AQSV.enableMinimapIcon then
                icon:Hide("MiniIcon")
            end

            if AQSV.slotStatus == nil then
                AQSV.slotStatus = {}
                for k,v in pairs(SELFAQ.slotToName) do
                    AQSV.slotStatus[k] = {
                        ["backup"] = 0,
                        ["locked"] = false,
                        ["lockedCD"] = false,
                        ["lockedTime"] = 0,
                    }
                end
            end

            SELFAQ.addonInit()
            SELFAQ.createItemBar()
            SELFAQ.createBuffIcon()
            SELFAQ.mainInit( )

            chatInfo(L["Loaded"])

            SELFAQ.init = true

        end

        -- 记录装备栏位置
        if SELFAQ.bar then
            local point, relativeTo, relativePoint, xOfs, yOfs = SELFAQ.bar:GetPoint()
            AQSV.x = xOfs
            AQSV.y = yOfs
            AQSV.point = point
        end

        -- 记录快捷按钮位置
        -- 已经分离才记录位置
        if SELFAQ.quickButton and SELFAQ.quickButton.split then
            local point, relativeTo, relativePoint, xOfs, yOfs = SELFAQ.quickButton:GetPoint()
            AQSV.quickButtonX = xOfs
            AQSV.quickButtonY = yOfs
            AQSV.quickButtonPosition = point
        end

        -- 记录buff提醒位置
        if SELFAQ.buff then
            local point, relativeTo, relativePoint, xOfs, yOfs = SELFAQ.buff:GetPoint()
            AQSV.xBuff = xOfs
            AQSV.yBuff = yOfs
            AQSV.pointBuff = point
        end

        -- collectgarbage("collect")
        -- UpdateAddOnMemoryUsage()
        -- print(string.format("%.2f mb", (GetAddOnMemoryUsage("AutoEquip") / 1024)))

        -- 装备栏队列应该不受开关影响

         -- 角色处在战斗状态或跑尸状态，不进行换饰品逻辑，退出函数
        if not SELFAQ.playerCanEquip() then
            return 
        end

        SELFAQ.checkAllWait()
        SELFAQ.checkSuperSuit()
        SELFAQ.checkSelfTarget()

        -- 插件整体开关，以角色为单位
        if not AQSV.enable then
            return
        end

        -- 战场开关
        if UnitInBattleground("player") and not AQSV.enableBattleground then
            return
        end

        SELFAQ.changeSuit()

        -- 整合团队目标处理
        SELFAQ.runTargetMemberRules()

        -- 自动更换饰品

        loopSlots(function(slot_id)
            if slot_id == 13 then
                SELFAQ.changeTrinket()
            else
                SELFAQ.changeItem(slot_id)
            end
        end)
        
    end
end


function SELFAQ.mainInit()

    SLASH_AQCMD1 = "/aq";
    SLASH_AQCMD2 = "/autoequip";
    SLASH_AQCMD2 = "/ae";
    function SlashCmdList.AQCMD(msg)

        debug(msg)

        local number = tonumber(msg)
        if number and number >= 0 and number <= 9 then
            SELFAQ.superEquipSuit(number)
        end

        if msg == "" then
            SELFAQ.enableAutoEuquip()

        elseif msg == "settings" then
             SELFAQ.openSettings(SELFAQ.top)

        elseif msg == "pvp" then
            SELFAQ. enablePvpMode()

        elseif msg == "takeoff" then
             for k,v in pairs(AQSV.slotStatus) do
                 SELFAQ.setLocker(k)
             end
             SELFAQ.takeoffAll()
             chatInfo(L["|cFF00FF00Takeoff|r all equipments"])
             popupInfo(L["|cFF00FF00Takeoff|r all equipments"])

        elseif msg == "unlock" then
             for k,v in pairs(AQSV.slotStatus) do
                 SELFAQ.cancelLocker(k)
             end
             chatInfo(L["|cFF00FF00Unlocked|r all equipment buttons"])
             popupInfo(L["|cFF00FF00Unlocked|r all equipment buttons"])

        elseif msg == "lock" then
             for k,v in pairs(AQSV.slotStatus) do
                 SELFAQ.setLocker(k)
             end
             chatInfo(L["|cFF00FF00Locked|r all equipment buttons"])
             popupInfo(L["|cFF00FF00Locked|r all equipment buttons"])

        elseif msg == "70" or msg == "73" or msg == "74"   then
            -- EquipItemByName(19891, 17)
            if SELFAQ.playerCanEquip()  then
                SELFAQ.needSuit = tonumber(msg)
            else
                chatInfo(L["|cFF00FF00In combat|r"])
            end

        elseif strfind(msg, "ipc") then

            -- items per column
            local n = tonumber(strmatch(msg, "%d+"))

            if n > 0 then
                AQSV.itemsPerColumn = n
            end

        elseif strfind(msg, "bs") then

            -- equipment button spacing
            local n = tonumber(strmatch(msg, "%d+"))

            if n >= 0 then
                AQSV.buttonSpacingNew = n
                chatInfo(L["Set Equipment button spacing to "]..SELFAQ.color("00FF00", n).."."..L[" Please reload UI manually (/reload)."])
            end

        elseif strfind(msg, "rm") then

            -- equipment button spacing
            local n = tonumber(strmatch(msg, "%d+"))

            if n > 0 then
                AQSV.raidTargetThreshold = n
                chatInfo(L["Set threshold of member's target to "]..AQSV.raidTargetThreshold)
            end

        elseif strfind(msg, "dm") then

            if strfind(msg, "1") then
                AQSV.disableMouseover = true
                chatInfo(L["|cFFFF0000Disable|r  the display of item list when moseover"])
            elseif strfind(msg, "0") then
                AQSV.disableMouseover = false
                chatInfo(L["|cFF00FF00Enable|r the display of item list when moseover"])
            end

        elseif strfind(msg, "ceb") then

            local _, str = strsplit(" ", msg)

            if tonumber(str) == 0 then
                chatInfo(L["Custom equipment bar was |cFFFF0000CANCELED|r."]..L[" Please reload UI manually (/reload)."])
                AQSV.customSlots = {}
                return
            end

            str = string.gsub(str,"，", ",")

            local t = {strsplit(",", strtrim(str))}

            local new = {}

            for k,v in pairs(t) do
                v = tonumber(v)
                if v and v >= 1 and v <= 18 and v~= 4 and not tContains(new, v) then
                    table.insert(new, v)
                end
            end

            if #new > 0 then
                chatInfo(L["Custom equipment bar |cFF00FF00SUCCESS|r."]..L[" Please reload UI manually (/reload)."])
                AQSV.customSlots = new
            end

        elseif strfind(msg, "pp") then

            local _, str = strsplit(" ", msg)

            str = string.gsub(str,"，", ",")

            local x,y = strsplit(",", strtrim(str))

            x = tonumber(x)
            y = tonumber(y)

            if x and y then
                AQSV.popupX = x
                AQSV.popupY = y
                chatInfo(L["Set popup info to a new position"])
                popupInfo(L["Set popup info to a new position"])
            end


        elseif strfind(msg, "hiq") then

            if strfind(msg, "1") then
                AQSV.hideItemQueue = true
                chatInfo(L["|cFFFF0000Hide|r item queue"])
            elseif strfind(msg, "0") then
                AQSV.hideItemQueue = false
                chatInfo(L["|cFF00FF00Show|r item queue"])
            end

        elseif strfind(msg, "resetp") then

            AQSV.x = 200
            AQSV.y = 0
            AQSV.point = "CENTER"
            C_UI.Reload()

        elseif strfind(msg, "resetpb") then

            AQSV.quickButtonX  = 0
            AQSV.quickButtonY  = 0
            AQSV.quickButtonPosition  = "CENTER"
            C_UI.Reload()

        end
    end

    SELFAQ.main:RegisterEvent("UNIT_INVENTORY_CHANGED")
    SELFAQ.main:RegisterEvent("UPDATE_BINDINGS")

    SELFAQ.main:RegisterEvent("PLAYER_REGEN_ENABLED")
    SELFAQ.main:RegisterEvent("PLAYER_ALIVE")                       -- 未释放复活
    SELFAQ.main:RegisterEvent("PLAYER_UNGHOST")                 -- 从鬼混复活

    SELFAQ.main:RegisterEvent("PLAYER_TARGET_CHANGED") 
    -- SELFAQ.main:RegisterEvent("UNIT_TARGET") 

    SELFAQ.main:RegisterEvent("BAG_UPDATE") 
    SELFAQ.main:RegisterEvent("PLAYER_ENTERING_WORLD") 
    -- SELFAQ.main:RegisterEvent("ZONE_CHANGED_NEW_AREA") 
    -- SELFAQ.main:RegisterEvent("ZONE_CHANGED_INDOORS") 
    -- SELFAQ.main:RegisterEvent("ZONE_CHANGED") 

    SELFAQ.main:SetScript("OnEvent", function( self, event, arg1 )
        if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
            for k,v in pairs(SELFAQ.slots) do
                SELFAQ.updateItemButton( v )
            end

             if SELFAQ.playerCanEquip()  then
                -- 战斗中毒药减少会触发该事件
                SELFAQ.runEquipmentRules()
             end

            -- if SELFAQ.showingSlot then
            --     SELFAQ.showDropdown(SELFAQ.showingSlot, SELFAQ.showingPosition, true)
            -- end

        end

        if event == "UPDATE_BINDINGS" then
            SELFAQ.bindingSlot()
        end

        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" then
            local zonetext = GetSubZoneText() == "" and GetZoneText() or GetSubZoneText()
            debug(GetSubZoneText())
            debug(GetZoneText())
            -- local uiMapID = C_Map.GetBestMapForUnit("player")
            -- debug(uiMapID)
            -- print(UnitPosition("player"))
            
        end

        -- 脱离战斗的事件
        -- 复活也是脱战事件
        if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then

            -- 脱战也要判断一下其他状态
            if not SELFAQ.playerCanEquip() then
                return 
            end

            SELFAQ.checkAllWait()

            if not AQSV.enable then
                return
            end

            SELFAQ.runLeaveCombatRules()
            
            -- 避免每次脱离战斗都触发
            if AQSV.enableSuit and AQSV.enableAutoSuit70 and AQSV.currentSuit > 70 and SELFAQ.inInstance() then
                SELFAQ.needSuit = 70
            end

            -- 执行一系列更换逻辑

            SELFAQ.changeSuit()

            -- 自动更换饰品
            loopSlots(function(slot_id)
                if slot_id == 13 then
                    SELFAQ.changeTrinket()
                else
                    SELFAQ.changeItem(slot_id)
                end
            end)
        end


        -- if event == "UNIT_TARGET" then
        --     -- debug(arg1)

        --     if not SELFAQ.playerCanEquip() then
        --         return 
        --     end

        --     if not AQSV.enableSuit then
        --         return
        --     end

        --     if arg1 == "player" then

        --     else
        --         SELFAQ.checkAndFireChangeSuit(arg1.."target")
        --     end
  
        -- end

        if event == "PLAYER_ENTERING_WORLD" then
            
            SELFAQ.runEnterRules()

        end

        if event == "BAG_UPDATE" then
            SELFAQ.updateAllItems( )
        end

        if event == "PLAYER_TARGET_CHANGED" then

            if not SELFAQ.playerCanEquip() then
                return 
            end

            SELFAQ.checkSelfTarget()

        end

    end)
end

SELFAQ.checkSelfTarget = function()
    
    -- 自动骑乘判断
    if AQSV.pauseAccWhenTarget then

        if not UnitIsDead("target") and not UnitIsFriend("player", "target") then
            SELFAQ.targetEnemy = true
        else
            SELFAQ.targetEnemy = false
        end

        if GetUnitName("target") == nil then
            SELFAQ.targetEnemy = false
        end
    else
        SELFAQ.targetEnemy = false
    end

    if AQSV.pauseAccWhenTargetFriend then

        if not UnitIsDead("target") and UnitIsFriend("player", "target") then
            SELFAQ.targetFriend = true
        else
            SELFAQ.targetFriend = false
        end

        if GetUnitName("target") == nil then
            SELFAQ.targetFriend = false
        end
    else
        SELFAQ.targetFriend = false
    end

    -- 目标是亡灵
    if true then
        if not UnitIsDead("target") and (UnitCreatureType("target") == "亡灵" or UnitCreatureType("target") == "恶魔") then
            SELFAQ.targetUndead = true
        else
            SELFAQ.targetUndead = false
        end

        if GetUnitName("target") == nil then
            SELFAQ.targetUndead = false
        end
    end

    -- 目标不是亡灵
    if true then
        -- 目标活着，并且不是友善的，不是亡灵
        if not UnitIsDead("target") and not UnitIsFriend("player", "target") and not (UnitCreatureType("target") == "亡灵" or UnitCreatureType("target") == "恶魔") then
            SELFAQ.targetNotUndead = true
        else
            SELFAQ.targetNotUndead = false
        end

        if GetUnitName("target") == nil then
            SELFAQ.targetNotUndead = false
        end
    end


    -- 超级换装
    local number = SELFAQ.checkTargetRules("target")

    if number then
        SELFAQ.superEquipSuit(number)
    end

    -- 73+套装
    if not AQSV.enable then
        return
    end

    if not SELFAQ.inInstance() then
        return
    end

    SELFAQ.checkAndFireChangeSuit("target")
end

SELFAQ.main:SetScript("OnUpdate", SELFAQ.onMainUpdate)