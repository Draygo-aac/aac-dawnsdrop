local api = require("api")

function string:endswith(ending)
    return ending == "" or self:sub(-#ending) == ending
end
settings = {}
-- First up is the addon definition!
-- This information is shown in the Addon Manager.
-- You also specify "unload" which is the function called when unloading your addon.
local dawnsdrop_addon = {
  name = "Dawnsdrop Check",
  author = "Delarme",
  desc = "Checks if you have dawnsdrop equipped",
  version = "1.5"
}

local defaultX = 330
local defaultY = 30

local invscreen

local function IsDawnsDropItem(item, slotIdx)
    if item == nil then
        return false
    end


    --api.Log:Info(item.name .. " " .. tostring(item.itemType))

    if invscreen ~= nil then
        list = invscreen:GetAlertItemList()
        for i = 1, #list do
            if list[i] == item.itemType then
                return true
            end
        end
        if invscreen:ShowEmptySlots() then
            if item.itemType == 0 then
                return true
            end
        end
        if invscreen:GetFilterDefaults() == false then
            return false
        end
    end

    if item.evolvingInfo ~= nil and item.evolvingInfo.remainTime ~= nil then
        local remainingtime = item.evolvingInfo.remainTime.year * 12 --year to month
        remainingtime = (remainingtime + item.evolvingInfo.remainTime.month) * 30.4 --month to day (avg)
        remainingtime = (remainingtime + item.evolvingInfo.remainTime.day) * 24 -- day to hours
        remainingtime = (remainingtime + item.evolvingInfo.remainTime.hour) * 60 -- hours to minutes
        remainingtime = (remainingtime + item.evolvingInfo.remainTime.minute) * 60 -- minutes to seconds
        remainingtime = math.floor(remainingtime + item.evolvingInfo.remainTime.second)
        if remainingtime <= 0 then
            return true
        end
    end

    if item.name:endswith("Fishing Rod") then
        return true
    end
    if item.name:endswith("Swimfins") then
        return true
    end
    if item.name == "Eternal Defiance" then
        return true
    end
    if item.equipSetInfo == nil then
        return false
    end

    if item.equipSetInfo.equipSetItemInfoDesc:endswith("Dawnsdrop Set") then
        return true
    end
    if item.equipSetInfo.equipSetItemInfoDesc == "Lullaby Pajamas" then
        return true
    end
    
return false
end

-- The Load Function is called as soon as the game loads its UI. Use it to initialize anything you need!




local dawnscanvas
local windowheight = 54



local EQUIP_SLOTS = {
--left values in order they appear on eq screen
1,
3,
4,
8,
6,
9,
5,
7,
--14 (hidden)
15,
--right values in order they appear on eq screen
2,
10,
11,
12,
13,
16,
17,
18,
19,
27, 

--and top center:
28 
}
local prev = {}

function GetSlotBackground(slotIdx)
    if slotIdx <= 21 then
        return SLOT_STYLE.EQUIP_ITEM[slotIdx]
    end
    if slotIdx == 27 then
        return SLOT_STYLE.EQUIP_ITEM[20]
    end
    if slotIdx == 28 then
        return SLOT_STYLE.EQUIP_ITEM[21]
    end
    return nil
end
local function HudUpdate()
    local current = {}
    for i=1, 20 do
        dawnscanvas.childitemIcons[i]:Show(false)
    end
    local founditem = false
    local k = 1
    local i = 0
    while i < #EQUIP_SLOTS do
        i = i + 1

        --api.Log:Info(i)
        local item = api.Equipment:GetEquippedItemTooltipText("player", EQUIP_SLOTS[i])
        if IsDawnsDropItem(item, EQUIP_SLOTS[i]) then
            founditem = true
            local slotbg = GetSlotBackground(EQUIP_SLOTS[i])
            local icon = dawnscanvas.childitemIcons[k] 
            icon:Show(true)
            F_SLOT.SetIconBackGround(dawnscanvas.childitemIcons[k], item.path)
            F_SLOT.ApplySlotSkin(icon, icon.back, slotbg)
            
            current[k] = item
            k = k + 1
        end
        if EQUIP_SLOTS[i] == 16 then
            if item.slotType == "2handed" then
                 i = i + 1
            end
        end

    end  
    k = k - 1
    dawnscanvas:SetExtent(20 + (46 * k), windowheight)
    dawnscanvas:Show(founditem)
    
    if #prev == #current then
        if #prev == 0 then
            return
        end
        for i = 1, #prev do
            if prev[i].itemType ~= current[i].itemType then
                prev = current
                api:Emit("DAWNSDROP_ALERT_UPDATE", current)
                return
            end
        end
        
    end
    -- changed
    if #prev == 0 then
        
        api:Emit("DAWNSDROP_ALERT_BEGIN")
        --api.Log:Info("Fire Begin Event")
    end
    prev = current
    if #current == 0 then
        
        api:Emit("DAWNSDROP_ALERT_UPDATE", current)
        api:Emit("DAWNSDROP_ALERT_END")
        --api.Log:Info("Fire Update End Event")

    else
        
        api:Emit("DAWNSDROP_ALERT_UPDATE", current)
        --api.Log:Info("Fire Update Event")

    end


end

local function OnEvent(this, event, ...)
    
    --api.Log:Info(event)
    if event == "UNIT_EQUIPMENT_CHANGED" then
        HudUpdate()
    end
end



--settings.WinX = 330
--settings.WinY = 20

function LoadFile()

	local file = "dawnsdrop\\data\\_global.lua"
	return api.File:Read(file)

end

function LoadData()
	local res, settingsdata = pcall(LoadFile)
	if res == true then
		return settingsdata
	end
    api.Log:Err(settingsdata)
	return nil
end

function SaveData(settings)


	api.File:Write("dawnsdrop\\data\\_global.lua", settings)
end


local function UpdatePos(x, y)


    settings.WinX = math.floor(x)
    settings.WinY = math.floor(y)

    dawnscanvas:SetWndPosition(settings.WinX, settings.WinY)
    SaveData(settings)
    --api.Log:Info(settings)
end


local function Load() 
  
    api.Log:Info("Loading dawnsdrop check...")
    settings = LoadData()
    dawnscanvas = require("dawnsdrop/dawnsdrop_view")
    
    if settings == nil then
        settings = {}
    end

    if settings.WinX == nil then
        settings.WinX = defaultX
    end
    if settings.WinY == nil then
        settings.WinY = defaultY
    end
    --if UI Scaling is in effect we cannot set this in load must wait for first UPDATE
    -- AGURU PLEASE
    --dawnscanvas:SetWndPosition(settings.WinX, settings.WinY)

    dawnscanvas:SetOnDragStopEvent(UpdatePos)
    dawnscanvas:SetHandler("OnEvent", OnEvent)
    dawnscanvas:RegisterEvent("UNIT_EQUIPMENT_CHANGED")
    --dawnscanvas:RegisterEvent("DAWNSDROP_ALERT_BEGIN")
    --dawnscanvas:RegisterEvent("DAWNSDROP_ALERT_UPDATE")
    --dawnscanvas:RegisterEvent("DAWNSDROP_ALERT_END")
    


    invscreen = require("dawnsdrop/inventory_screen_mod")
    invscreen.alertItemWnd.updateCallback = HudUpdate

    HudUpdate()
end
local first = true
local function OnUpdate()
    --for some reason if UI Scaling is in effect we cannot set the Anchor in Load()
    if first then
        first = false
        dawnscanvas:SetWndPosition(settings.WinX, settings.WinY)
    end
end


-- Unload is called when addons are reloaded.
-- Here you want to destroy your windows and do other tasks you find useful.
local function Unload()
    
    if dawnscanvas ~= nil then
        dawnscanvas:Show(false)
        dawnscanvas:Close()
        dawnscanvas:ReleaseHandler("OnEvent")
        dawnscanvas = nil
    end

    if invscreen ~= nil then
       invscreen:CloseAddon()
    end
end
api.On("UPDATE", OnUpdate)
-- Here we make sure to bind the functions we defined to our addon. This is how the game knows what function to use!
dawnsdrop_addon.OnLoad = Load
dawnsdrop_addon.OnUnload = Unload

return dawnsdrop_addon 
