local inventory = ADDON:GetContent(UIC.BAG)
local alertItemsBtn

CreateCheckButton = api._Library.UI.CreateCheckButton
CreateTooltip = api._Library.UI.CreateTooltip
--checkButton = require('dawnsdrop/util/check_button')

settings = api.GetSettings("dawnsdrop")

ALERT_BUTTTONSKIN = {
	drawableType = "drawable",
	path = "ui/button/mailbox.dds",
	coords = {
		normal = {
			0,
			66,
			32,
			32
		},
		over = {
			33,
			66,
			32,
			32
		},
		click = {
			65,
			66,
			32,
			32
		},
		disable = {
			97,
			66,
			32,
			32
		}
	},
	width = 40,
	height = 40
}

function LoadFile()

	local uid = api.Unit:GetUnitId("player")
	local myname = api.Unit:GetUnitNameById(uid)
	local file = "dawnsdrop\\data\\" .. myname .. ".lua"
	return api.File:Read(file)

end

function LoadData()
	local res, characterdata = pcall(LoadFile)
	if res == true then
		return characterdata
	end
	return nil
end

function SaveData(settings)

	local uid = api.Unit:GetUnitId("player")
	local myname = api.Unit:GetUnitNameById(uid)
	api.File:Write("dawnsdrop\\data\\" .. myname .. ".lua", settings)
end

local charsettings = LoadData()
if charsettings == nil then
	charsettings = {}
end
-- import old settings
if settings.filter ~= nil then
	if charsettings.filter == nil then
		charsettings.filter = {}
		for i = 1, 50 do
			charsettings.filter[i] = settings.filter[i]
		end
	end
	settings.filter = nil
	if settings.defaults ~= nil then
		charsettings.defaults = settings.defaults
		settings.defaults = nil
	end
	api.SaveSettings()
	SaveData(charsettings)
end

if charsettings.defaults == nil then
	charsettings.defaults = true
end
if charsettings.emptyslots == nil then
	charsettings.emptyslots = true
end
if charsettings.filter == nil then
	charsettings.filter = {}
	for i = 1, 50 do
		charsettings.filter[i] = {
		itemTypeString = "nil",
		itemType = nil, 
		path = ""
		}
		
	end
else
	--correct serialization
	for i = 1, 50 do
		if charsettings.filter[i].itemTypeString ~= nil and charsettings.filter[i].itemTypeString ~= "nil" then
			charsettings.filter[i].itemType = tonumber(charsettings.filter[i].itemTypeString)
		end
	end
end

--api.Log:Info(inventory)
if inventory.alertItemsBtn ~= nil then
	--api.Log:Info("Alert button already loaded")
	alertItemsBtn = inventory.alertItemsBtn
end
if inventory.alertItemsBtn ~= nil then
	inventory.alertItemsBtn:Show(false)
	inventory.alertItemsBtn = nil
end

if inventory.alertItemsBtn == nil then
	alertItemsBtn = inventory:CreateChildWidget("button", "alertitemsButton", 0, true)
	inventory.alertItemsBtn = alertItemsBtn
end
inventory.alertItemsBtn:RemoveAllAnchors()
--inventory.alertItemsBtn:SetText("Alert Items")

api.Interface:ApplyButtonSkin(inventory.alertItemsBtn, ALERT_BUTTTONSKIN)
--inventory.alertItemsBtn.info = "Alert Items"
CreateTooltip("alerttooltip", inventory.alertItemsBtn, "Alert Items")

inventory.alertItemsBtn:AddAnchor("BOTTOMLEFT", inventory, 242, -18)

function alertItemsBtn:SetCallback(delegate)
	--api.Log:Info("SetCallback")
	alertItemsBtn.CallBack = delegate
end

function CallOnClick()

	if alertItemsBtn.CallBack ~= nil then
		--api.Log:Info("CallOnClick")
		alertItemsBtn.CallBack()
	end
end

alertItemsBtn:SetHandler("OnClick", CallOnClick)

local alertItemWnd = api.Interface:CreateWindow("alertItemWnd", "Alert Items", 300, 550)
inventory.alertItemWnd = alertItemWnd
alertItemWnd:AddAnchor("TOPLEFT", inventory, -300, 0)
alertItemWnd.updateCallback = nil
filterlist = {}

function TriggerCallback()
	if alertItemWnd.updateCallback ~= nil then
		alertItemWnd.updateCallback()
	end

end

function GenerateFilter()
	local retlist = {}
	local k = 1
	for i = 1, 50 do
		if charsettings.filter[i].itemType ~= nil then
			retlist[k] = charsettings.filter[i].itemType
			k = k + 1
		end
	end
	filterlist = retlist
end

function ShowAlertItemWnd()
	--api.Log:Info("ShowAlertItemWnd")
	alertItemWnd:Show(true)
end
alertItemsBtn:SetCallback(ShowAlertItemWnd)

function addIcon(window, row, col)
	local num = row * 5 + col
	icon = CreateItemIconButton("Item" .. num, window)
	F_SLOT.ApplySlotSkin(icon, icon.back, SLOT_STYLE.BAG_DEFAULT)
	icon:AddAnchor("TOP", window, "TOPLEFT", (44 * col) + 15, 48 + (row * 44))
	icon.num = num
	return icon
end
alertItemWnd.items = {}

function ClearAlertItem(ev)
	F_SLOT.SetIconBackGround(alertItemWnd.items[ev.num], nil)

	charsettings.filter[ev.num] = {
	itemTypeString = "nil",
	itemType = nil, 
	path = ""
	}
	SaveData(charsettings)
	GenerateFilter()
	TriggerCallback()
end

function AddAlertItem(ev, bagitem)

	if bagitem.itemType == nil then
		return
	end

	F_SLOT.SetIconBackGround(alertItemWnd.items[ev.num], bagitem.path)
	--alertItemWnd.items[ev.num].helditem = bagitem.itemType
	charsettings.filter[ev.num] = {
		itemTypeString = string.format("%.f", bagitem.itemType),
		itemType = math.floor(bagitem.itemType), 
		path = bagitem.path
	}

	api.Cursor:ClearCursor()
	SaveData(charsettings)
	GenerateFilter()
	TriggerCallback()
end

function TryAddAlertItem(ev)
	local bagnum = api.Cursor:GetCursorPickedBagItemIndex()
	--api.Log:Info(tostring(bagnum))
	if bagnum == 0 then
		ClearAlertItem(ev)
		return
	end
	local bagitem = api.Bag:GetBagItemInfo(1, bagnum)

	--api.Log:Info(bagitem.itemType)
	--api.File:Write("bagitem.txt", bagitem)
	if bagitem.item_impl == "weapon" then
		AddAlertItem(ev, bagitem)
	end
	if bagitem.item_impl == "armor" then
		AddAlertItem(ev, bagitem)
	end
	if bagitem.item_impl == "accessory" then
		AddAlertItem(ev, bagitem)
	end
	if bagitem.item_impl == "backpack" then
		AddAlertItem(ev, bagitem)
	end
end

function OnClickAlertItem(ev, clicktype)
	if clicktype == "RightButton" then
		ClearAlertItem(ev)
		return
	end
	if clicktype == "LeftButton" then
		TryAddAlertItem(ev)
	end
end

for i = 0, 9 do
	for k = 1, 5 do
		num = i*5+k
		alertItemWnd.items[num] = addIcon(alertItemWnd, i, k)

		alertItemWnd.items[num]:SetHandler("OnClick", OnClickAlertItem)
		
		alertItemWnd.items[num]:SetHandler("OnDragReceive", TryAddAlertItem)
		
		if charsettings.filter[num].itemType ~= nil then
			--api.Log:Info(tostring(num) .. " " .. tostring(settings.filter[num].itemType ))
			AddAlertItem(alertItemWnd.items[num], charsettings.filter[num])
		end
	end
end
GenerateFilter()

local defaultslabel = alertItemWnd:CreateChildWidget("label", "defaultsLabel", 0, true)
defaultslabel:AddAnchor("BOTTOMLEFT", alertItemWnd, 115, -50)
defaultslabel:SetText("Filter Defaults:")
defaultslabel.style:SetAlign(2)
ApplyTextColor(defaultslabel, FONT_COLOR.DEFAULT)

alertItemWnd.defaultscheckbutton = CreateCheckButton("defaultscheckbutton", alertItemWnd, nil)
alertItemWnd.defaultscheckbutton:AddAnchor("BOTTOMLEFT", alertItemWnd, 120, -35)
alertItemWnd.defaultscheckbutton:SetButtonStyle("default")
alertItemWnd.defaultscheckbutton:Show(true)
alertItemWnd.defaultscheckbutton.onClickDel = nil
function OnCheckChanged()
	charsettings.defaults = alertItemWnd.defaultscheckbutton:GetChecked()
	SaveData(charsettings)
	TriggerCallback()
end

alertItemWnd.defaultscheckbutton:SetHandler("OnCheckChanged", OnCheckChanged)
alertItemWnd.defaultscheckbutton:SetChecked(charsettings.defaults)

local emptyslotslabel = alertItemWnd:CreateChildWidget("label", "emptyslotslabel", 0, true)
emptyslotslabel:AddAnchor("BOTTOMLEFT", alertItemWnd, 115, -35)
emptyslotslabel:SetText("Empty Slots:")
emptyslotslabel.style:SetAlign(2)
ApplyTextColor(emptyslotslabel, FONT_COLOR.DEFAULT)
alertItemWnd.emptyslotscheckbutton = CreateCheckButton("emptyslotscheckbutton", alertItemWnd, nil)

alertItemWnd.emptyslotscheckbutton:AddAnchor("BOTTOMLEFT", alertItemWnd, 120, -20)
alertItemWnd.emptyslotscheckbutton:SetButtonStyle("default")
alertItemWnd.emptyslotscheckbutton:Show(true)
alertItemWnd.emptyslotscheckbutton.onClickDel = nil
function OnEmptyCheckChanged()
	charsettings.emptyslots = alertItemWnd.emptyslotscheckbutton:GetChecked()
	SaveData(charsettings)
	TriggerCallback()
end

alertItemWnd.emptyslotscheckbutton:SetHandler("OnCheckChanged", OnEmptyCheckChanged)
alertItemWnd.emptyslotscheckbutton:SetChecked(charsettings.emptyslots)

function inventory:CloseAddon()
	alertItemsBtn:ReleaseHandler("OnClick")
	alertItemsBtn:Show(false)
	alertItemWnd:Show(false)
	alertItemWnd = nil
end

function inventory:GetAlertItemList()
	return filterlist
end
function inventory:GetFilterDefaults()
	return charsettings.defaults
end
function inventory:ShowEmptySlots()
	return charsettings.emptyslots
end

return inventory