
local _, SELFAQ = ...

local debug = SELFAQ.debug
local clone = SELFAQ.clone
local diff = SELFAQ.diff
local L = SELFAQ.L
local player = SELFAQ.player
local GetItemTexture = SELFAQ.GetItemTexture
local otherSlot = SELFAQ.otherSlot

function SELFAQ.customSlots()
	if #AQSV.customSlots > 0 then
		SELFAQ.slots = AQSV.customSlots
	else
		-- 从设置页面读取
		local new = {}
		-- 确定装备栏个数
		for k,v in pairs(AQSV.enableItemBarSlot) do
			if v then
				table.insert(new, k)
			end
		end

		table.sort( new )
		SELFAQ.slots = SELFAQ.merge(SELFAQ.slots, new)
	end 
end

function SELFAQ.createItemBar()

	if SELFAQ.bar ~= nil then
		return
	end

	-- 选择BUTTON类似，才能触发鼠标事件
	local f = CreateFrame("Button", "AutoEquip_ItemBar", UIParent)
	SELFAQ.bar = f
	SELFAQ.list = {}
	SELFAQ.itemButtons = {}

	SELFAQ.customSlots()

	f:SetFrameStrata("MEDIUM")
	f:SetWidth(#SELFAQ.slots * (40 + AQSV.buttonSpacingNew) + 10)
	f:SetHeight(40)
	f:SetScale(AQSV.barZoom)

	-- 可以使用鼠标
	f:EnableMouse(true)

	SELFAQ.bar:SetMovable(not AQSV.locked)
	if AQSV.locked then
		-- 关闭拖动，同时不影响右键单击
		SELFAQ.bar:RegisterForDrag("")
	else
		SELFAQ.bar:RegisterForDrag("LeftButton")
	end

	-- 实现拖动
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local t = f:CreateTexture(nil, "BACKGROUND")
    f.texture = t
    -- 有材质才能设置颜色和透明度
	t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	
	SELFAQ.hideBackdrop()

	-- 尺寸和位置覆盖
	t:SetAllPoints(f)

  	f:SetFrameLevel(1)

  	-- 初始化位置
	f:SetPoint(AQSV.point, AQSV.x, AQSV.y)

	-- 换装备时更新按钮


	-- 创建右键菜单
	SELFAQ.createMenu()

	-- 绘制冷却时间
	f.TimeSinceLastUpdate = 0
	-- 函数执行间隔时间
	f.Interval = 0.1
	f:SetScript("OnUpdate", SELFAQ.cooldownUpdate)

	-- 创建按钮
	for k,v in pairs(SELFAQ.slots) do
		SELFAQ.createItemButton( v, k )
	end

	-- 装备栏不显示的槽都解锁
	for k,v in pairs(AQSV.slotStatus) do
    	if not tContains(SELFAQ.slots, k) then
    		SELFAQ.cancelLocker(k)
    	end
    end

	-- 创建PVP标识
	local pvpIcon = CreateFrame("Frame", nil, f)
	pvpIcon:SetSize(20,20)
	pvpIcon:SetPoint("TOPLEFT", f, -23, 0)

	local pvpTexture = pvpIcon:CreateTexture(nil, "BACKGROUND")
	pvpTexture:SetTexture(132147)
	pvpTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	pvpTexture:SetAllPoints(pvpIcon)

	if AQSV.pvpMode then
		pvpIcon:Show()
	else
		pvpIcon:Hide()
	end

	SELFAQ.pvpIcon = pvpIcon

	-- 设置里是否启用装备栏
	if AQSV.enableItemBar then
		f:Show()
	else
		f:Hide()
	end

	-- 暂时不开放
	if AQSV.enableQuickEquip then
		SELFAQ.buildCharactor()
	end

	SELFAQ.createQuickButton()
	SELFAQ.updateButtonSwitch()
	SELFAQ.bindingSlot( )
end

function SELFAQ.buildCharactor()

	SELFAQ.cSlots = {}
	SELFAQ.cSlots[1] = _G["CharacterHeadSlot"]
	SELFAQ.cSlots[2] = _G["CharacterNeckSlot"]
	SELFAQ.cSlots[3] = _G["CharacterShoulderSlot"]
	SELFAQ.cSlots[5] = _G["CharacterChestSlot"]
	SELFAQ.cSlots[6] = _G["CharacterWaistSlot"]
	SELFAQ.cSlots[7] = _G["CharacterLegsSlot"]
	SELFAQ.cSlots[8] = _G["CharacterFeetSlot"]
	SELFAQ.cSlots[9] = _G["CharacterWristSlot"]
	SELFAQ.cSlots[10] = _G["CharacterHandsSlot"]
	SELFAQ.cSlots[11] = _G["CharacterFinger0Slot"]
	SELFAQ.cSlots[12] = _G["CharacterFinger1Slot"]
	SELFAQ.cSlots[13] = _G["CharacterTrinket0Slot"]
	SELFAQ.cSlots[14] = _G["CharacterTrinket1Slot"]
	SELFAQ.cSlots[15] = _G["CharacterBackSlot"]
	SELFAQ.cSlots[16] = _G["CharacterMainHandSlot"]
	SELFAQ.cSlots[17] = _G["CharacterSecondaryHandSlot"]
	SELFAQ.cSlots[18] = _G["CharacterRangedSlot"]



	for k,v in pairs(SELFAQ.cSlots) do
		
		v:SetScript("OnEnter", function(self)
			SELFAQ.showCharactorTooltip(self, k)
			SELFAQ.showDropdown(k+100, 1)
		end)

		v:SetScript("OnLeave", function(self)
			SELFAQ.hideTooltip()
			SELFAQ.hideItemDropdown( 0.5 )
		end)

	end

	
end

function SELFAQ.hideBackdrop(  )
	if AQSV.hideBackdrop then
		SELFAQ.bar.texture:SetVertexColor(0, 0, 0, 0)
	else
		SELFAQ.bar.texture:SetVertexColor(0, 0, 0, 0.9)
	end
end

function  SELFAQ.createMenu()

	local menuFrame = CreateFrame("Frame", nil, SELFAQ.bar, "UIDropDownMenuTemplate")

	local menu = {}

	menu[1] = {}
	menu[1]["text"] = " "..L["Enable AutoEquip function"]
	menu[1]["checked"] = AQSV.enable
	menu[1]["func"] = function()
		SELFAQ.enableAutoEuquip()
	end

	menu[2] = {}
	menu[2]["text"] = L[" Enable PVP queue"]
	menu[2]["checked"] = AQSV.pvpMode
	menu[2]["func"] = function()
		SELFAQ.enablePvpMode()
	end

	menu[3] = {}
	menu[3]["text"] = L[" Settings"]
	menu[3]["func"] = function()
		InterfaceOptionsFrame_OpenToCategory(SELFAQ.general);
		InterfaceOptionsFrame_OpenToCategory(SELFAQ.general);
	end

	menu[4] = {}
	menu[4]["text"] = L[" Lock frame"]
	menu[4]["checked"] = AQSV.locked
	menu[4]["func"] = function()
		AQSV.locked = not AQSV.locked
		SELFAQ.lockItemBar()
	end

	menu[5] = {}
	menu[5]["text"] = L[" Close"]
	menu[5]["func"] = function()
		menuFrame:Hide()
	end

	SELFAQ.menu = menuFrame
	SELFAQ.menuList = menu

	SELFAQ.bar:RegisterForClicks("RightButtonDown");
	SELFAQ.bar:SetScript('OnClick', function(self, button)
	    EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU")
	end)
end

function SELFAQ.lockItemBar()
	
	SELFAQ.menuList[4]["checked"] = AQSV.locked

	SELFAQ.bar:SetMovable(not AQSV.locked)
	if AQSV.locked then
		SELFAQ.bar:RegisterForDrag("")
	else
		SELFAQ.bar:RegisterForDrag("LeftButton")
	end

	SELFAQ.f.checkbox["locked"]:SetChecked(AQSV.locked)
end

function SELFAQ.createItemButton( slot_id, position )

	local button = CreateFrame("Button", "AQBTN"..slot_id, SELFAQ.bar, "SecureActionButtonTemplate")
	button:SetSize(40, 40)

	local itemId = GetInventoryItemID("player", slot_id)
	local itemTexture = ""
	if itemId then
		itemTexture = GetItemTexture(itemId)
	else
		_, itemTexture = GetInventorySlotInfo(SELFAQ.slotName[slot_id])
	end

	button.itemId = itemId

	-- 不然会继承parent的按键设置（AnyUp+AnyDown 兼容 Classic Era 1.15+）
	button:RegisterForClicks("AnyUp", "AnyDown")

	-- 左键触发物品
	button:SetAttribute("type1", "item")

	-- 饰品切换后自动匹配点击功能
    button:SetAttribute("slot", slot_id)

    -- 右键解锁
    button:SetAttribute("type2", "unlockSlot")
    button.unlockSlot = function( ... )
    	if AQSV.slotStatus[slot_id].locked then
    		SELFAQ.cancelLocker(slot_id)
    	else
    		SELFAQ.setLocker(slot_id)
    	end
    end

    -- 右键解锁
    button:SetAttribute("shift-type1", "showDropdown")
    button.showDropdown = function( ... )
    	if AQSV.shiftLeftShowDropdown or AQSV.disableMouseover  then
    		SELFAQ.showDropdown(slot_id, position)
    	end
    end

  	button:SetFrameLevel(2)
  	-- 高亮材质
  	button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")

  	-- button:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Background", edgeSize = 2})
  	SELFAQ.fixSetBackdrop(button, {edgeFile = "Interface\\AddOns\\AutoEquip\\Textures\\S.blp", edgeSize = 2})
  	--button:SetBackdrop({edgeFile = "Interface\\AddOns\\AutoEquip\\Textures\\S.blp", edgeSize = 2})

	button:SetBackdropBorderColor(0,0,0,1);
	-- button:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	

    local t = button:CreateTexture(nil, "BACKGROUND")
    -- 贴上物品的材质
	t:SetTexture(itemTexture)
	t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	t:SetAllPoints(button)
	button.texture = t

	-- 文字单独一个frame，因为要盖住冷却动画
	local tf = CreateFrame("Frame", nil, button)
	tf:SetAllPoints(button)
	tf:SetFrameLevel(4)

	local text = tf:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
	-- text:SetShadowColor(0, 0, 0, 1)
	-- text:SetShadowOffset(1, -1)
    text:SetPoint("TOPLEFT", button, 2, 8)
    
    button.text = text

    -- 显示快捷键

	local stext = tf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	stext:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	-- stext:SetTextColor(255,255,255)
	-- text:SetShadowColor(0, 0, 0, 1)
	-- text:SetShadowOffset(1, -1)
	-- stext:SetText("ASJ")
    -- stext:SetFrameLevel(7)
    stext:SetPoint("BOTTOMLEFT", button, 1, 1)
    stext:Hide()
    
    button.shortcut = stext

    -- 冷却动画层
    local cooldown = CreateFrame("Frame", nil, button)
    -- 设0不成功
    cooldown:SetSize(40, 1)
    cooldown:SetPoint("TOPLEFT", button, 0, 0)
    cooldown:SetFrameLevel(3)

   	local t1 = cooldown:CreateTexture(nil, "BACKGROUND")
	t1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	t1:SetVertexColor(0, 0, 0, 0.7)
	t1:SetAllPoints(cooldown)
	
	button.cooldown = cooldown

	-- 饰品队列层
    local wait = CreateFrame("Frame", nil, button, "BackdropTemplate")
    -- 设0不成功
    wait:SetSize(20, 20)
    wait:SetPoint("BOTTOMRIGHT", button, 0, 0)
    wait:SetFrameLevel(6)
    wait:Hide()
    -- wait:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Background", edgeSize = 2})
  	wait:SetBackdrop({edgeFile = "Interface\\AddOns\\AutoEquip\\Textures\\S.blp", edgeSize = 2})

	wait:SetBackdropBorderColor(0,0,0,1);

   	local t2 = wait:CreateTexture(nil, "BACKGROUND")
	t2:SetAllPoints(wait)
	
	button.waitFrame = wait
	button.wait = t2

	-- 锁定层
    local locker = CreateFrame("Frame", nil, button)
    -- 设0不成功
    locker:SetSize(16, 16)
    locker:SetPoint("BOTTOMRIGHT", button, 0, 2)
    locker:SetFrameLevel(5)

   	local t3 = locker:CreateTexture(nil, "BACKGROUND")
	t3:SetAllPoints(locker)
	t3:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons.blp")
	t3:SetTexCoord(0, 0.25, 0, 1)

	if AQSV.slotStatus[slot_id].locked then
		t3:Show()
	else
		t3:Hide()
	end
	
	button.locker = t3

	-- 自动队列开关显示
    local icon = CreateFrame("Frame", nil, button)
    -- 设0不成功
    icon:SetSize(12, 12)
    icon:SetPoint("BOTTOMRIGHT", button, 0, 2)
    icon:SetFrameLevel(4)

   	local icont = icon:CreateTexture(nil, "BACKGROUND")
	icont:SetAllPoints(icon)
	icont:SetTexture(1116940)
	icont:SetTexCoord(456/512, 480/512, 92/512, 116/512)
	-- icont:SetTexture("Interface\\AddOns\\AutoEquip\\Textures\\S.blp")

	icont:Hide()
	
	button.icon = icont

	-- button:RegisterForClicks("RightButtonDown");
	-- button:SetScript('OnClick', function(self, button)
	--     EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU")
	-- end)

	-- 按钮定位
   	button:SetPoint("TOPLEFT", SELFAQ.bar, (position - 1) * (40 + AQSV.buttonSpacingNew), 0)
   	button:Show()

   	-- 显示tooltip
   	button:SetScript("OnEnter", function(self)
   		
		SELFAQ.showTooltip(self, "inventory", button.itemId, slot_id)

		if AQSV.disableMouseover then
			return
		end

		if UnitAffectingCombat("player") and AQSV.shiftLeftShowDropdown then
			return
		end
		SELFAQ.showDropdown(slot_id, position)

	end)
   	button:SetScript("OnLeave", function( self )
   		SELFAQ.hideTooltip()
   		SELFAQ.hideItemDropdown( 0.5 )
   	end)

   	-- 缓存
   	SELFAQ.slotFrames[slot_id] = button
end

function SELFAQ.updateButtonSwitch()
	SELFAQ.loopSlots(function(slot_id)
        if SELFAQ.slotFrames[slot_id] then
        	if AQSV.enable then
            	SELFAQ.slotFrames[slot_id].icon:Show()
            else
            	SELFAQ.slotFrames[slot_id].icon:Hide()
            end
        end

        if slot_id == 13 and SELFAQ.slotFrames[14] then
        	if AQSV.enable then
           		SELFAQ.slotFrames[14].icon:Show()
           	else
           		SELFAQ.slotFrames[14].icon:Hide()
           	end
        end
    end)
end

function SELFAQ.showDropdown(slot_id, position, update)
	-- 更新物品在背包里的位置
	-- SELFAQ.updateItemInBags()

	local pass_id = slot_id

	if slot_id > 100 then
		slot_id = slot_id - 100
	end

	-- 显示可用饰品的下拉框
	if not update then
		SELFAQ.itemDropdownTimestamp = nil
	end

	SELFAQ.showingSlot = slot_id
	SELFAQ.showingPosition = position

	if AQSV.enableLR and pass_id == 14 then
		position = position -1 
	end

	local index = 1
	local itemId1 = GetInventoryItemID("player", slot_id)
	local itemId2 = GetInventoryItemID("player", otherSlot(slot_id))

	for k,v in pairs(SELFAQ.items[slot_id]) do
		-- 推算出真实id
		local rid = SELFAQ.reverseId(v)
		
		if v ~= itemId1 and v ~= itemId2 and v > 0 then
			-- 把位置信息传递过去
			SELFAQ.createItemDropdown(v, (40 + AQSV.buttonSpacingNew) * (position - 1), index, pass_id)
			index = index + 1
		elseif SELFAQ.itemButtons[v] then
			SELFAQ.itemButtons[v]:Hide()
		end
	end

	for k,v in pairs(SELFAQ.itemButtons) do
		if v.inSlot ~= slot_id then
			v:Hide()
		end
	end
end

function SELFAQ.hideItemDropdown( delay )
	-- 设置计时
	SELFAQ.itemDropdownTimestamp = GetTime()
	SELFAQ.itemDropdownDelay =  delay
end

-- 在update里执行
function SELFAQ.doHideItemDropdown()
	if SELFAQ.itemDropdownTimestamp then
		if GetTime() - SELFAQ.itemDropdownTimestamp > SELFAQ.itemDropdownDelay then
			for k,v in pairs(SELFAQ.itemButtons) do
	   			v:Hide()
	   		end
	   		SELFAQ.itemDropdownTimestamp = nil
			SELFAQ.showingSlot = nil
			SELFAQ.showingPosition = nil
		end
	end
end

-- 创建饰品下拉框
function SELFAQ.createItemDropdown(item_id, x, position, slot_id)

	if item_id == 0 then
		return
	end

	local pass_id = slot_id

	if slot_id > 100 then
		slot_id = slot_id - 100
	end

	local rid = SELFAQ.reverseId(item_id)
	-- print(rid)

	-- 分列，计算位置
	position = position - 1
		
	local newX = math.floor(position / AQSV.itemsPerColumn)
	local newY = position % AQSV.itemsPerColumn + 1

	-- 如果已经创建过物品图层，只修改位置
	-- if SELFAQ.itemButtons[item_id] then

	-- 	if pass_id > 100 then
	-- 		SELFAQ.itemButtons[item_id]:SetPoint("TOPLEFT", SELFAQ.cSlots[slot_id], x + newY * (40 + AQSV.buttonSpacingNew), (40 + AQSV.buttonSpacingNew) * newX)
	-- 		SELFAQ.itemButtons[item_id]:SetScale(1)
	-- 	else
	-- 		SELFAQ.itemButtons[item_id]:SetPoint("TOPLEFT", SELFAQ.bar, x + newX * (40 + AQSV.buttonSpacingNew), 5+(40 + AQSV.buttonSpacingNew) * newY)
	-- 		SELFAQ.itemButtons[item_id]:SetScale(AQSV.barZoom)
	-- 	end

		
	-- 	SELFAQ.itemButtons[item_id]:Show()
	-- 	-- 点击图标是获取正确的slot
	-- 	SELFAQ.itemButtons[item_id].inSlot = slot_id
	-- 	return
	-- end

	-- local button = CreateFrame("Button", nil, UIParent)

	-- if pass_id > 100 then
	-- 	button:SetPoint("TOPLEFT", SELFAQ.cSlots[slot_id], x + newY * (40 + AQSV.buttonSpacingNew), (40 + AQSV.buttonSpacingNew) * newX)
	-- 	button:SetScale(1)
	-- else
	-- 	button:SetPoint("TOPLEFT", SELFAQ.bar, x + newX * (40 + AQSV.buttonSpacingNew), 5+(40 + AQSV.buttonSpacingNew) * newY)
	-- 	button:SetScale(AQSV.barZoom)
	-- end

 --   	button:Show()


   	local button

   	if SELFAQ.itemButtons[item_id] then
   		button = SELFAQ.itemButtons[item_id]
   	else
   		button = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
   	end

   	button.pass_id = pass_id

   	if pass_id > 100 then
   		if pass_id > 115 then
   			button:SetPoint("TOPLEFT", SELFAQ.cSlots[slot_id], x + newX * (40 + AQSV.buttonSpacingNew) -2, 2+(40 + AQSV.buttonSpacingNew) * newY)
   		else
   			button:SetPoint("TOPLEFT", SELFAQ.cSlots[slot_id], x + newY * (40 + AQSV.buttonSpacingNew) + 1, (40 + AQSV.buttonSpacingNew) * - newX + 1)
   		end
		
		button:SetScale(1)
	else
		button:SetPoint("TOPLEFT", SELFAQ.bar, x + newX * (40 + AQSV.buttonSpacingNew), 5+(40 + AQSV.buttonSpacingNew) * newY)
		button:SetScale(AQSV.barZoom)
	end

   	button:Show()

   	if SELFAQ.itemButtons[item_id] then
   		SELFAQ.itemButtons[item_id].inSlot = slot_id
		return
   	end

	
	button:SetFrameStrata("HIGH")

	button:SetSize(40, 40)

	local itemTexture = GetItemTexture(rid)

  	button:SetFrameLevel(100)
  	-- 高亮材质
  	button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")

  	-- button:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Background", edgeSize = 2});
  	button:SetBackdrop({edgeFile = "Interface\\AddOns\\AutoEquip\\Textures\\S.blp", edgeSize = 2})
	button:SetBackdropBorderColor(0,0,0,1);
	

    local t = button:CreateTexture(nil, "BACKGROUND")
    -- 贴上物品的材质
	t:SetTexture(itemTexture)
	-- 取消边框
	t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	t:SetAllPoints(button)
	button.texture = t

	-- 文字单独一个frame，因为要盖住冷却动画
	local tf = CreateFrame("Frame", nil, button)
	tf:SetAllPoints(button)
	tf:SetFrameLevel(101)

	local text = tf:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
	-- text:SetShadowColor(0, 0, 0, 1)
	-- text:SetShadowOffset(1, -1)
    text:SetPoint("TOPLEFT", button, 1,-1)
    text:SetJustifyH("LEFT")
    
    button.text = text

    -- 装备等级
    if not AQSV.hideItemLevel then
		local lf = CreateFrame("Frame", nil, button)
		lf:SetAllPoints(button)
		lf:SetFrameLevel(101)

		local level = lf:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		level:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
		-- text:SetShadowColor(0, 0, 0, 1)
		-- text:SetShadowOffset(1, -1)
	    level:SetPoint("BOTTOMLEFT", button, 1,1)
	    level:SetJustifyH("LEFT")
	    level:SetText(SELFAQ.getItemLevel(rid))
	end

	-- 按钮定位
   	

   	button:SetScript("OnEnter", function(self)
   		-- 停掉隐藏下拉框的计时器
		SELFAQ.itemDropdownTimestamp = nil

		local bag,slot = SELFAQ.reverseBagSlot(item_id)

		-- print(item_id, bag, slot)

		SELFAQ.showTooltip( self, "bag", item_id, bag, slot, button.pass_id)
	end)
   	button:SetScript("OnLeave", function( self )
   		-- 开启隐藏计时
   		SELFAQ.hideItemDropdown( 0.5 )
   		SELFAQ.hideTooltip()
   	end)

	button.inSlot = slot_id

   	button:EnableMouse(true)
   	button:RegisterForClicks("AnyDown");
	button:SetScript('OnClick', function(self, b)

		-- 点击后立即隐藏下拉框
	    for k,v in pairs(SELFAQ.itemButtons) do
   			v:Hide()
   		end

   		local slot = button.inSlot

   		if AQSV.enableLR and (button.inSlot == 13 or button.inSlot == 14) then
   			if b == "RightButton" then
   				slot = 14
   			end
   			if b == "LeftButton" then
   				slot = 13
   			end
   		end

        if not SELFAQ.playerCanEquip() then
        	-- 缓存起来
        	SELFAQ.setWait(item_id, slot)
            return 
        else
        	-- 立即装备
        	SELFAQ.equipWait(item_id, slot)
        end
       
	end)

   	-- 缓存
   	SELFAQ.itemButtons[item_id] = button
end

-- 更新按钮材质
function SELFAQ.updateItemButton( slot_id )
	local itemId = GetInventoryItemID("player", slot_id)
	local button = SELFAQ.slotFrames[slot_id]

	button.itemId = itemId

	local itemTexture = ""
	if itemId then
		itemTexture = GetItemTexture(itemId)
	else
		_, itemTexture = GetInventorySlotInfo(SELFAQ.slotName[slot_id])
	end

	if button then
		button.texture:SetTexture(itemTexture)
	end
end

function SELFAQ.bindingSlot( )
	if UnitAffectingCombat("player") then return end

	for k,v in pairs(SELFAQ.slotFrames) do
		ClearOverrideBindings(v)

		v.shortcut:SetText("")
		v.shortcut:Hide()

		local keys = {GetBindingKey("AUTOEQUIP_BUTTON"..k)}

		for k1,v1 in pairs(keys) do

			if v1 and v1 ~= "" then
				SetOverrideBindingClick(v, false, v1, "AQBTN"..k)
				local s = SELFAQ.shortKey(v1)
				v.shortcut:SetText(s)
				v.shortcut:Show()
			end
		end
	end

	for i=1,9 do
		if SELFAQ.qbs[i] then
			local v = SELFAQ.qbs[i]
			ClearOverrideBindings(v)

			local keys = {GetBindingKey("AUTOEQUIP_SUIT"..i)}

			for k1,v1 in pairs(keys) do

				if v1 and v1 ~= "" then
					SetOverrideBindingClick(v, false, v1, "AQQB"..i)
				end
			end
		end
		
	end

	do
		local v = SELFAQ.qbs[11]
		ClearOverrideBindings(v)

		local keys = {GetBindingKey("AUTOEQUIP_TAKEOFF")}

		for k1,v1 in pairs(keys) do

			if v1 and v1 ~= "" then
				SetOverrideBindingClick(v, false, v1, "AQQB11")
			end
		end
	end


end

-- 绘制下方的饰品队列
function SELFAQ.createCooldownUnit( item_id, position )
	local f = CreateFrame("Frame", nil, SELFAQ.bar, "BackdropTemplate")
	-- f:SetPoint("TOPLEFT", SELFAQ.bar, 0 , - (40 + AQSV.buttonSpacingNew) - (position - 1) * 23)
	f:SetSize(20, 20)

	-- f:SetBackdrop({edgeFile = "Interface/Tooltips/UI-Tooltip-Background", edgeSize = 2});
  	f:SetBackdrop({edgeFile = "Interface\\AddOns\\AutoEquip\\Textures\\S.blp", edgeSize = 2})
	f:SetBackdropBorderColor(0,0,0,1);

	local t = f:CreateTexture(nil, "BACKGROUND")
	t:SetTexture(GetItemTexture(item_id))
	-- 取消边框
	t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	t:SetAllPoints(f)

	local text = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
	-- text:SetShadowColor(0, 0, 0, 1)
	-- text:SetShadowOffset(1, -1)
    text:SetPoint("TOP", f, 20, -1)
    text:SetJustifyH("LEFT")

    f.text = text

	-- f:Show()

	return f
end

function SELFAQ.showCharactorTooltip(button, slot_id)
	
	local tooltip = _G["GameTooltip"]
	-- local tooltip = CreateFrame( "GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate" )
	-- tooltip:ClearLines()

	tooltip:SetOwner(button,"ANCHOR_RIGHT")
	-- tooltip:SetPoint("TOPRIGHT", button)
	-- tooltip:SetOwner(button)
	-- GameTooltip_SetDefaultAnchor(tooltip, UIParent)
	-- tooltip:SetOwner(button, ANCHOR_LEFT, 0,0)

	tooltip:SetInventoryItem("player", slot_id)
	-- tooltip:Show()
end

function SELFAQ.showTooltip( button, t, item_id, arg1, arg2, pass_id )

	if not AQSV.hideTooltip then
		local tooltip = _G["GameTooltip"]
	    tooltip:ClearLines()

	    -- AQSV.simpleTooltip = true

	    if AQSV.simpleTooltip then
	    	tooltip:SetOwner(button, ANCHOR_LEFT, 0, -35)
	    	-- tooltip:SetPoint("BOTTOMLEFT",button,0,-20)

    		local link = SELFAQ.GetItemLink(item_id)
			tooltip:SetText(link)

	    else
	    	if pass_id and pass_id > 100 then
				tooltip:SetOwner(button, "ANCHOR_RIGHT")
				-- GameTooltip_SetDefaultAnchor(tooltip, button)
			else
		    	tooltip:SetOwner(UIParent)
				GameTooltip_SetDefaultAnchor(tooltip, UIParent)
			end

			if t == "inventory" then
				tooltip:SetInventoryItem("player", arg1)
			elseif t == "bag" then
				tooltip:SetBagItem(arg1, arg2)
			end
	    end
		
	    tooltip:Show()
	end

end

function SELFAQ.hideTooltip()
	local tooltip = _G["GameTooltip"]
    tooltip:Hide()
end

function SELFAQ.cooldownUpdate( self, elapsed )
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;  

    if (self.TimeSinceLastUpdate > self.Interval) then
    	-- 重新计时
        self.TimeSinceLastUpdate = 0

        SELFAQ.doHideItemDropdown()

		-- 计算饰品下拉框的冷却时间
		for k,v in pairs(SELFAQ.itemButtons) do
			-- if SELFAQ.itemButtons[v] then
				-- 获取饰品的冷却状态
				local rid = SELFAQ.reverseId(k)

			    local start, duration, enable = GetItemCooldown(rid)
			    -- 剩余冷却时间
			    local rest =(duration - GetTime() + start)

			    -- 在队列中的显示冷却时间
			    if duration > 0 and rest > 0 then
			    	local text = SELFAQ.getCooldownText(rest)

			    	v.text:SetText(text)
			    else
					v.text:SetText()
			    end
			-- end
		end

		-- 计算图标上的冷却时间
    	for key,value in pairs(SELFAQ.slots) do
    		local itemId = GetInventoryItemID("player", value)

    		if itemId then
    			-- 获取饰品的冷却状态
			    local start, duration, enable = GetItemCooldown(itemId)
			    -- 剩余冷却时间
			    local rest = duration - GetTime() + start

			    local button = SELFAQ.slotFrames[value]

			    if duration > 0 and rest > 0 then
			    	local text = SELFAQ.getCooldownText(rest)

			    	button.text:SetText(text)
			    	local height = (rest/duration)*40
			    	button.cooldown:SetHeight(height)
			    else
					button.text:SetText()
					button.cooldown:SetHeight(1)
			    end
			else
				local button = SELFAQ.slotFrames[value]
				-- 装备被换下，清空倒计时
				button.text:SetText()
				button.cooldown:SetHeight(1)
    		end


    		-- 判断是否是需要更换的slot
    		if tContains(SELFAQ.needSlots, value)  then

    			-- print(value)

    			local slot_id = value

	    		-- 计算冷却队列
				local queue = SELFAQ.buildQueueRealtime(slot_id)

				-- print(queue)

				wipe(SELFAQ.empty2)

				local slotIds = SELFAQ.empty2

			    slotIds[1] = GetInventoryItemID("player", slot_id)

			    if slot_id == 13 then
			    	slotIds[2] = GetInventoryItemID("player", 14)
			    end

			    -- local slotIds = {slot13Id, slot14Id}

			    -- -- 算出等待换上的饰品
			    local wait = diff(queue, slotIds)

			    if SELFAQ.list[slot_id] == nil then
			    	SELFAQ.list[slot_id] = {}
			    end

			    -- 根据顺序创建图标，或者使其显示
			    for k,v in pairs(wait) do

			    	-- if tContains(SELFAQ.slots, v) then

				    	if not SELFAQ.list[slot_id][v] then
				    		SELFAQ.list[slot_id][v] = SELFAQ.createCooldownUnit(v, k)
				    	end
				    		-- SELFAQ.list[v]:SetPoint("TOPLEFT", SELFAQ.bar, 0 , -(40 + AQSV.buttonSpacingNew) - (k - 1) * 23)

				    	if not AQSV.hideItemQueue then
				    		SELFAQ.list[slot_id][v]:Show()

				    		local point, relativeTo, relativePoint, xOfs, yOfs = SELFAQ.slotFrames[slot_id]:GetPoint()

					    	if AQSV.reverseCooldownUnit then
					    		SELFAQ.list[slot_id][v]:SetPoint("TOPLEFT", SELFAQ.bar, xOfs , 30 + (k - 1) * 23)
					    	else
					    		SELFAQ.list[slot_id][v]:SetPoint("TOPLEFT", SELFAQ.bar, xOfs , -(43) - (k - 1) * 23)
					    	end
				    	else
				    		SELFAQ.list[slot_id][v]:Hide()
				    	end

				    -- end
			    	
			    end

			    if not AQSV.hideItemQueue then
				    -- 计算队列冷却时间
				    for k,v in pairs(SELFAQ.list[slot_id]) do
				    	-- 如果已经换上了，隐藏
				    	if not tContains(wait, k) then
				    		v:Hide()
				    	else
				    		-- 获取饰品的冷却状态
						    local start, duration, enable = GetItemCooldown(k)
						    -- 剩余冷却时间
						    local rest = (duration - GetTime() + start)

						    -- 在队列中的显示冷却时间
						    if duration > 0 and rest > 0 then
						    	local text = SELFAQ.getCooldownText(rest)

						    	v.text:SetText(text)
						    else
								v.text:SetText()
						    end
				    	end
				    end
				end

    		end

		end

    end
end

SELFAQ.createQuickButton = function()
	
	local f = SELFAQ.bar

	if AQSV.splitQuickButton then
		f = UIParent
	end

	local quickButton = CreateFrame("Frame", "AutoEquip_QuickButton", f)

	quickButton:SetSize(20, 35)
	quickButton:Show()

	local t = quickButton:CreateTexture(nil, "BACKGROUND")
    quickButton.texture = t
    -- 有材质才能设置颜色和透明度
	t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")

	-- 尺寸和位置覆盖
	t:SetAllPoints(quickButton)

	quickButton.texture = t

	SELFAQ.quickButton = quickButton
	SELFAQ.qbs = {}

	SELFAQ.renderQuickButton()
end

SELFAQ.renderQuickButton = function()

	if not AQSV.hideQuickButton then
		SELFAQ.quickButton:Show()
	else
		SELFAQ.quickButton:Hide()
	end

	if AQSV.splitQuickButton then

		local f = SELFAQ.quickButton
		local t = f.texture

		f.split = true

		f:SetPoint(AQSV.quickButtonPosition, AQSV.quickButtonX , AQSV.quickButtonY)

		f:SetScale(AQSV.quickButtonZoom)
		
		-- 实现拖动
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop",f.StopMovingOrSizing)

	  	-- 可以使用鼠标
		f:EnableMouse(true)

		f:SetMovable(not AQSV.quickButtonLocked)

		if AQSV.quickButtonLocked then
			f:RegisterForDrag("")
			t:SetVertexColor(0, 0, 0, 0)
		else
			f:RegisterForDrag("LeftButton")
			t:SetVertexColor(0, 0, 0, 0.9)
		end

	  	f:SetScript("OnEnter", function(self)
			SELFAQ.showQBMoveTooltip()
		end)

		f:SetScript("OnLeave", function(self)
			SELFAQ.hideTooltip()
		end)

	else
		if AQSV.reverseCooldownUnit then
			SELFAQ.quickButton:SetPoint("TOPLEFT", SELFAQ.bar, 0 , -45)
		else
			SELFAQ.quickButton:SetPoint("TOPLEFT", SELFAQ.bar, 0 , 30)
		end

		SELFAQ.quickButton.texture:SetVertexColor(0, 0, 0, 0)
	end

	local step = 0

	for i=1,9 do
		local number = i

		if SUITAQ[number]['enable'] then
			SELFAQ.createQBOne(i, step, true, function()
				SlashCmdList.AQCMD(tostring(i))
			end)
			step = step + 1
		else
			SELFAQ.createQBOne(i, step, false, function()
			end)
		end
	end

	SELFAQ.createQBOne(11, step, true, function()
		if not AQSV.hideTakeoffButton then
			SlashCmdList.AQCMD("takeoff")
		end
	end)
	step = step + 1

	if AQSV.enableSuit then

		SELFAQ.createQBOne(70, step, AQSV.enableSuit, function()
			SlashCmdList.AQCMD("70")
		end)
		step = step + 1

		SELFAQ.createQBOne(73, step, AQSV.enableSuit, function()
			SlashCmdList.AQCMD("73")
		end)
		step = step + 1

		SELFAQ.createQBOne(74, step, AQSV.enableSuit, function()
			SlashCmdList.AQCMD("74")
		end)
		step = step + 1

	else

		SELFAQ.createQBOne(70, step, AQSV.enableSuit, function()
		end)

		SELFAQ.createQBOne(73, step, AQSV.enableSuit, function()
		end)

		SELFAQ.createQBOne(74, step, AQSV.enableSuit, function()
		end)
	end

	SELFAQ.createQBOne(80, step, true, function()
		SlashCmdList.AQCMD("unlock")
	end)
	step = step + 1

	SELFAQ.createQBOne(81, step, true, function()
		SlashCmdList.AQCMD("")
	end)
	step = step + 1

	
	if AQSV.currentSuit > 0 and SELFAQ.qbs[AQSV.currentSuit] then
		SELFAQ.qbs[AQSV.currentSuit]:LockHighlight()
	end
end

SELFAQ.createQBOne = function(word, order, show, func)
	
	local f = SELFAQ.bar
	local quickButton = SELFAQ.quickButton

	local position = "TOPLEFT"

	if AQSV.splitQuickButton then
		position = "BOTTOMLEFT"
	end

	if SELFAQ.qbs[word] then
		if show then
			SELFAQ.qbs[word]:SetPoint(position, quickButton, 20 * order , 0)
			SELFAQ.qbs[word]:Show()
		else
			SELFAQ.qbs[word]:Hide()
		end

		return
	elseif not show then
		return
	end

	local button = CreateFrame("Button", "AQQB"..word, quickButton, "SecureActionButtonTemplate")

	button.hl = false

	SELFAQ.qbs[word] = button

	button:SetSize(20, 20)

	button:SetPoint(position, quickButton, 20 * order , 0)


	-- button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
	button:SetHighlightTexture("Interface\\AddOns\\AutoEquip\\Textures\\H.blp", "ADD")


 --  	button:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
	-- button:SetBackdropBorderColor(0,0,0,0.9)
	-- button:SetBackdropColor(0,0,0,1)

	if word ~= 74 and word ~= 11 and word ~= 80 and word ~= 81 then

		local text

		if word < 70 then
			text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		else
			text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		end

		text:SetFont(STANDARD_TEXT_FONT, 12)
	    text:SetPoint("CENTER", button, 1, 0)
	    text:SetText(word)
	end

    local t = button:CreateTexture(nil, "BACKGROUND")
	t:SetTexture("Interface\\AddOns\\AutoEquip\\Textures\\B.blp")

	if word == 74 then
		t:SetTexCoord(0, 0.125, 0, 0.5)
	elseif word == 11 then
		t:SetTexCoord(0, 0.125, 0.5, 1)
	elseif word == 80 then
		t:SetTexCoord(0.375, 0.5, 0, 0.5)
	elseif word == 81 then
		t:SetTexCoord(0.125, 0.25, 0, 0.5)
	else
		t:SetTexCoord(0.5, 0.625, 0, 0.5)
	end
	
	t:SetAllPoints(button)

	-- 不然会继承parent的按键设置（AnyUp+AnyDown 兼容 Classic Era 1.15+）
	button:RegisterForClicks("AnyUp", "AnyDown")
	button:Show()

    -- 右键解锁
    button:SetAttribute("type", "qbFunc")
    button.qbFunc = function()
    	func()
    end

    -- 显示tooltip
   	button:SetScript("OnEnter", function(self)
		SELFAQ.showQBTooltip(self, word)

	end)
   	button:SetScript("OnLeave", function( self )
   		SELFAQ.hideTooltip()
   	end)
end

function SELFAQ.showQBTooltip( button, word )

	if not AQSV.hideTooltip then
		local tooltip = _G["GameTooltip"]
	    tooltip:ClearLines()


    	tooltip:SetOwner(button, "ANCHOR_NONE")
    	tooltip:SetPoint("BOTTOM", button, "TOP" )
    	-- tooltip:SetPoint("BOTTOMLEFT",button,0,-20)
		
		if word <= 9 then

			if SUITAQ[word]["note"] ~= nil and SUITAQ[word]["note"] ~= "" then
				tooltip:AddLine(SELFAQ.color("00FF00", SUITAQ[word]["note"]))
			else
				tooltip:AddLine(L["Suit "]..SELFAQ.color("00FF00", word))
			end

			for k,v in pairs(SELFAQ.items) do

				if SUITAQ[word]["slot"..k] and SUITAQ[word]["slot"..k] > 0 then

                    local link = SELFAQ.GetItemLink(SUITAQ[word]["slot"..k])

                    tooltip:AddLine(link)

                end
			end

		elseif word == 11 then

			tooltip:AddLine(SELFAQ.color("FF0000", L["Takeoff"]))

		elseif word == 80 then

			tooltip:AddLine(L["|cFF00FF00Unlocked|r all equipment buttons"])

		elseif word == 81 then

			tooltip:AddLine(L["AutoEquip |cFF00FF00ON|r/|cFFFF0000OFF|r"])

		elseif word >= 70 then

			tooltip:AddLine(L["Suit "..L[word]])

			for k,v in pairs(SELFAQ.items) do

				if AQSV.suit[word][k] and AQSV.suit[word][k] > 0 then

                    local link = SELFAQ.GetItemLink(AQSV.suit[word][k])

                    tooltip:AddLine(link)

                end
			end

		end

		
	    tooltip:Show()
	end

end


function SELFAQ.showQBMoveTooltip()

	if not AQSV.quickButtonLocked then

		local tooltip = _G["GameTooltip"]
	    tooltip:ClearLines()


		tooltip:SetOwner(SELFAQ.quickButton, "ANCHOR_NONE")
		tooltip:SetPoint("BOTTOM", SELFAQ.quickButton, "TOP" )
		-- tooltip:SetPoint("BOTTOMLEFT",button,0,-20)
		
		tooltip:AddLine(L["Left-Drag: Move Frame"])
		tooltip:AddLine(SELFAQ.color("FFFFFF", L["Lock frame in Settings"]))
		
	    tooltip:Show()
	end

end