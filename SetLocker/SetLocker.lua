SetLocker = {}

SetLockerUnitList = ZO_SortFilterList:Subclass()
SetLockerUnitList.defaults = {}
ZO_CreateStringId("SI_BINDING_NAME_SETLOCKER_OPEN_CONFIG", "Open SetLocker Configuration")


SetLocker.DEFAULT_TEXT = ZO_ColorDef:New(0.4627, 0.737, 0.7647, 1) -- scroll list row text color
SetLocker.SetLockerUnitList = nil
SetLocker.units = {}

SetLockerUnitList.SORT_KEYS = {
		["Set"] = {} --,
		-- ["Locked"] = {tiebreaker="Set"},
}
 
SetLocker.name = "SetLocker"

-- Unit definition

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
--	self.sortFunction = function(listEntry1, listEntry2) return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, SetLockerUnitList.SORT_KEYS, self.currentSortOrder) end
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
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

	for i = 1, #self.masterList do
		local data = self.masterList[i]
		table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
	end
end

function SetLockerUnitList:SortScrollList()
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	table.sort(scrollData, function(a, b) return a.data.Set < b.data.Set end)
end

function SetLockerUnitList:SetupUnitRow(control, data)
	control.data = data
	control.Set = GetControl(control, "Set")
	control.Locked = GetControl(control, "Locked")

	control.Set:SetText(data.Set)
	control.Locked:SetText(data.Locked)

	control.Set.normalColor = SetLocker.DEFAULT_TEXT
	control.Locked.normalColor = SetLocker.DEFAULT_TEXT

	ZO_SortFilterList.SetupRow(self, control, data)
end

function SetLockerUnitList:Refresh()
	self:RefreshData()
end


-- SetLocker logic

function SetLocker.MouseEnter(control)
	SetLocker.SetLockerUnitList:Row_OnMouseEnter(control)
end

function SetLocker.MouseExit(control)
	SetLocker.SetLockerUnitList:Row_OnMouseExit(control)
end

function SetLocker.MouseUp(control, button, upInside)
	local cd = control.data
	if cd.Locked == "Yes" then
		SetLocker.savedVariables.sets[cd.Set] = {Locked="No"}
		cd.Locked = "No"
	else
	    SetLocker.savedVariables.sets[cd.Set] = {Locked="Yes"}
		cd.Locked = "Yes"
	end
	SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.Close()
   SetLockerControl:SetHidden(true)
   SetGameCameraUIMode(false)
   SetLocker.GUIOpen = false
end

function SetLocker.SetDefaultAndLanguage()
    SetLocker.savedVariables.sets = {}
    SetLocker.savedVariables = ZO_SavedVars:New("SetLockerSavedVariables", 1, nil, SetLockerDefaultSetConfig)
    for key, value in pairs(SetLocker.savedVariables.sets) do
	 for k,v in pairs(value) do
	   SetLocker.units[key] = {[k] = v}
	 end
    end
  
    SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.Open()
   SetLocker.SetLockerUnitList:Refresh()
   SetLockerControl:SetHidden(SetLocker.GUIOpen)
   SetLocker.GUIOpen = not SetLocker.GUIOpen
   SetGameCameraUIMode(SetLocker.GUIOpen)
end

function SetLocker.OnItemPickup(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  local itemLink = GetItemLink(bagId, slotIndex, LINK_TYPE_ITEM)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)

  if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == "Yes" then
      SetItemIsPlayerLocked(bagId, slotIndex, true)
      d("Locked a item of the Set" .. tostring(setName))
  end

  if setName ~= "" and SetLocker.units[tostring(setName)] == nil then
     d("Couldn't find the Set ".. tostring(setName))
  end

end

function SetLocker.OnLoot(eventCode, lootedBy, itemLink, quantity, itemSound, lootType, isNotStolen)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)
  -- I dont know why at the end there is always this garbage
  local lootedPlayer = lootedBy:sub(1,-4)

  if SetLocker.playerName ~= lootedPlayer then
     if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == "Yes" then
		 d("Player " .. tostring(lootedBy) .. " picked up " .. tostring(name) .. " of the set " .. tostring(setName))
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
  
  for key, value in pairs(SetLocker.savedVariables.sets) do
	 for k,v in pairs(value) do
	   SetLocker.units[key] = {[k] = v}
	 end
  end
  
  SetLocker.SetLockerUnitList:Refresh()
end
 

function SetLocker.OnAddOnLoaded(event, addonName)
  if addonName == SetLocker.name then
    SetLocker:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_ADD_ON_LOADED, SetLocker.OnAddOnLoaded)