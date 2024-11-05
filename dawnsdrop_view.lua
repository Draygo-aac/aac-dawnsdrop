dawnscanvas = api.Interface:CreateEmptyWindow("DawnsdropCheck", "UIParent")
--dawnscanvas:AddAnchor("TOPLEFT", "UIParent", 330, 20)
dawnscanvas:SetExtent(20 + (46 * 7), windowheight)


function dawnscanvas:SetWndPosition(x, y)
    dawnscanvas:AddAnchor("TOPLEFT", "UIParent", x, y)
end
function addIcon(dawnscanvas, num)
   icon = CreateItemIconButton("Item" .. num, dawnscanvas)
   --icon:Show(true)
   --F_SLOT.ApplySlotSkin(icon, icon.back, SLOT_STYLE.EQUIP_ITEM)
   icon:AddAnchor("TOP", dawnscanvas, "TOPLEFT", (44 * num) - 10, 4 )

   return icon
end


dawnscanvas.childitemIcons = {}
for i=1, 20 do
    dawnscanvas.childitemIcons[i] = addIcon(dawnscanvas, i)
end
  
dawnscanvas.bg = dawnscanvas:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
dawnscanvas.bg:SetTextureInfo("bg_quest")
dawnscanvas.bg:SetColor(0, 0, 0, 0.5)
dawnscanvas.bg:AddAnchor("TOPLEFT", dawnscanvas, 0, 0)
dawnscanvas.bg:AddAnchor("BOTTOMRIGHT", dawnscanvas, 0, 0)  
  


function dawnscanvas:OnDragStart(arg)
  if arg == nil then
    dawnscanvas:StartMoving()
    api.Cursor:ClearCursor()
    api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
    return
  end
  if arg == "LeftButton" and api.Input:IsShiftKeyDown() then
    dawnscanvas:StartMoving()
    api.Cursor:ClearCursor()
    api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
  end
end

dawnscanvas.DragEvt = nil

function dawnscanvas:SetOnDragStopEvent(evt)
    dawnscanvas.DragEvt = evt
end

function dawnscanvas:OnDragStop()
  dawnscanvas:StopMovingOrSizing()
  local x, y = dawnscanvas:GetOffset()

  api.Cursor:ClearCursor()
  if dawnscanvas.DragEvt ~= nil then
    dawnscanvas.DragEvt(x,y)
  end
end

dawnscanvas:SetHandler("OnDragStart", dawnscanvas.OnDragStart)
dawnscanvas:SetHandler("OnDragStop", dawnscanvas.OnDragStop)
if dawnscanvas.RegisterForDrag ~= nil then
    dawnscanvas:RegisterForDrag("LeftButton")
end
if dawnscanvas.EnableDrag ~= nil then
    dawnscanvas:EnableDrag(true)
end

function dawnscanvas:Close()
        dawnscanvas:ReleaseHandler("OnDragStart") 
        dawnscanvas:ReleaseHandler("OnDragStop")
end


return dawnscanvas