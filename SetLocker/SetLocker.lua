SetLocker = {}

SetLockerUnitList = ZO_SortFilterList:Subclass()
SetLockerUnitList.defaults = {}

SetLocker.DEFAULT_TEXT = ZO_ColorDef:New(0.4627, 0.737, 0.7647, 1) -- scroll list row text color
SetLocker.SetLockerUnitList = nil
SetLocker.units = {}

SetLocker.name = "SetLocker"

SetLocker.filterStr = ""


SetLockerDefaultSetConfig = {
  sets = {},
  showDrops = false
}

-- Unit definition for the Scroll List

function SetLockerUnitList:New()
	local units = ZO_SortFilterList.New(self, SetLockerControl)
	return units
end

function SetLockerUnitList:Initialize(control)
	ZO_SortFilterList.Initialize(self, control)

	self.sortHeaderGroup:SelectHeaderByKey("Set")
	ZO_SortHeader_OnMouseExit(SetLockerControlHeadersSet)

	self.masterList = {}
	ZO_ScrollList_AddDataType(self.list, 1, "ScrollListUnitRow", 30, function(control, data) self:SetupUnitRow(control, data) end)
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
	self:RefreshData()
end

function SetLockerUnitList:BuildMasterList()
	self.masterList = {}
	local units = SetLocker.units
	for k, v in pairs(units) do
		local data = v
		data["Set"] = k
		table.insert(self.masterList, data)
	end
end

function SetLockerUnitList:FilterScrollList()
	local filterStr = SetLocker.filterStr
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

	if filterStr == nil or filterStr == "" then
		for i = 1, #self.masterList do
			local data = self.masterList[i]
			table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
		end
	else
		for i = 1, #self.masterList do
			local data = self.masterList[i]
			if string.find(string.lower(data.Set), string.lower(filterStr)) then
				table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
			end
		end
	end
end

function SetLockerUnitList:SortScrollList()
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	table.sort(scrollData, function(a, b)
							 if self.currentSortKey == "status" then
								if self.currentSortOrder then
									if a.data.Locked == b.data.Locked then
										return a.data.Set > b.data.Set
									else
										return a.data.Locked
									end
								else
									if a.data.Locked == b.data.Locked then
										return a.data.Set < b.data.Set
									else
										return b.data.Locked
									end
								end
							 else
							    if self.currentSortOrder then
									return a.data.Set > b.data.Set
								else
								    return a.data.Set < b.data.Set
								end
							 end
							end)
end

function SetLockerUnitList:SetupUnitRow(control, data)
	control.data = data
	control.Set = GetControl(control, "Set")
	control.Locked = GetControl(control, "Locked")

	control.Set:SetText(data.Set)
	
	if data.Locked == false then
		control.Locked:SetText(GetString(SI_SETLOCKER_NOLOCK_DISPLAY))
	else
		control.Locked:SetText(GetString(SI_SETLOCKER_LOCK_DISPLAY))
	end

	control.Set.normalColor = SetLocker.DEFAULT_TEXT
	control.Locked.normalColor = SetLocker.DEFAULT_TEXT

	ZO_SortFilterList.SetupRow(self, control, data)
end

function SetLockerUnitList:Refresh()
	self:RefreshData()
end


-- SetLocker logic

function SetLocker.OpenResetQ(control)
	SetLockerResetQ:SetHidden(false)
end

function SetLocker.CloseResetQ(control)
	SetLockerResetQ:SetHidden(true)
end

function SetLocker.ShowLoot(control)
	SetLocker.savedVariables.showDrops = not SetLocker.savedVariables.showDrops
	
	if SetLocker.savedVariables.showDrops then 
		SetLockerControl_ShowLoot_Button:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerControl_ShowLoot_Button:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
end

function SetLocker.SearchbarChange()
	SetLocker.filterStr = SetLockerControl_Text:GetText()
	SetLocker.SetLockerUnitList:FilterScrollList()
	SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.MouseEnter(control)
	SetLocker.SetLockerUnitList:Row_OnMouseEnter(control)
end

function SetLocker.MouseExit(control)
	SetLocker.SetLockerUnitList:Row_OnMouseExit(control)
end

function SetLocker.MouseUp(control, button, upInside)
	local cd = control.data
	if cd.Locked == true then
		SetLocker.savedVariables.sets[cd.Set] = {Locked=false}
		cd.Locked = false
	else
	    SetLocker.savedVariables.sets[cd.Set] = {Locked=true}
		cd.Locked = true
	end
	SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.Close()
   SetLockerControl:SetHidden(true)
   SetGameCameraUIMode(false)
   SetLocker.GUIOpen = false
   SetLockerResetQ:SetHidden(true)
end

function SetLocker.LoadSetNames()
   local LibSets = LibSets
   if LibSets and LibSets.checkIfSetsAreLoadedProperly() then
      local setNames = LibSets.GetAllSetNames()
      for k, v in pairs(setNames) do
	     SetLocker.savedVariables.sets[v[GetCVar("Language.2")]] = { Locked = false}
      end
   else
      d("Could not load the set names!")
   end
end

function SetLocker.SetDefaultAndLanguage()
	SetLocker.savedVariables.sets = {}
    SetLocker.LoadSetNames()
	SetLocker.units = {}
    for key, value in pairs(SetLocker.savedVariables.sets) do
	   for k,v in pairs(value) do
	      SetLocker.units[key] = {[k] = v}
	   end
    end
	SetLockerResetQ:SetHidden(true)
    SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.Open()
   SetLocker.SetLockerUnitList:Refresh()
   SetLockerControl:SetHidden(SetLocker.GUIOpen)
   SetLocker.GUIOpen = not SetLocker.GUIOpen
   SetGameCameraUIMode(SetLocker.GUIOpen)
   if SetLocker.GUIOpen == false then
	 SetLockerResetQ:SetHidden(true)
   end
end

function SetLocker.OnItemPickup(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  local itemLink = GetItemLink(bagId, slotIndex, LINK_TYPE_ITEM)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)
  
  -- remove gender addition in some languages
  setName = setName:gsub("%^.*", "")
  
  if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == true then
      SetItemIsPlayerLocked(bagId, slotIndex, true)
  end
end

function SetLocker.OnLoot(eventCode, lootedBy, itemLink, quantity, itemSound, lootType, isNotStolen)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)
  local lootedPlayer = lootedBy:sub(1,-4)

  -- remove gender addition in some languages
  setName = setName:gsub("%^.*", "")

  if SetLocker.playerName ~= lootedPlayer and SetLocker.savedVariables.showDrops then
    if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == true then
	      local link = string.gsub(itemLink, "|H.", "|H" .. LINK_STYLE_BRACKETS)
		  local player = ZO_LinkHandler_CreatePlayerLink(lootedPlayer)
          d("SetLocker: " .. zo_strformat("<<t:1>>", player) .. ":" .. zo_strformat("<<t:1>>", link))
    end
  end
end

function SetLocker:Initialize()
  EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SetLocker.OnItemPickup)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
  EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_LOOT_RECEIVED, SetLocker.OnLoot)
  SetLocker.GUIOpen = false
  
  SetLocker.SetLockerUnitList = SetLockerUnitList:New()
  SetLocker.savedVariables = ZO_SavedVars:New("SetLockerSavedVariables", 1, nil, SetLockerDefaultSetConfig)
  SetLocker.playerName = GetUnitName("player")
  
  SetLockerControlShowLoot:SetText(GetString(SI_SETLOCKER_SHOWLOOT_LABEL))
  SetLockerResetQText:SetText(GetString(SI_SETLOCKER_RESETQ_LABEL))
  
  if SetLocker.savedVariables.sets == {} then
     SetLocker.LoadSetNames()
  end

  for key, value in pairs(SetLocker.savedVariables.sets) do
	 for k,v in pairs(value) do
	   SetLocker.units[key] = {[k] = v}
	 end
  end
  
  if SetLocker.savedVariables.showDrops then
	 SetLockerControl_ShowLoot_Button:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
  end
  
  SetLocker.SetLockerUnitList:Refresh()
end
 

function SetLocker.OnAddOnLoaded(event, addonName)
  if addonName == SetLocker.name then
    SetLocker:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_ADD_ON_LOADED, SetLocker.OnAddOnLoaded)