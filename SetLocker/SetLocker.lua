SetLocker = {}

SetLockerUnitList = ZO_SortFilterList:Subclass()
SetLockerUnitList.defaults = {}

SetLocker.DEFAULT_TEXT = ZO_ColorDef:New(0.4627, 0.737, 0.7647, 1) -- scroll list row text color
SetLocker.SetLockerUnitList = nil
SetLocker.units = {}

SetLocker.name = "SetLocker"

SetLocker.filterStr = ""

SetLocker.currentSetDetailsSet = ""

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
	control.Expand = GetControl(control, "Expand")

	control.Set:SetText(data.Set)
	
	if data.Locked == false then
		control.Locked:SetText(GetString(SI_SETLOCKER_NOLOCK_DISPLAY))
	else
		control.Locked:SetText(GetString(SI_SETLOCKER_LOCK_DISPLAY))
	end
	
	if data.Set == SetLocker.currentSetDetailsSet then
		control.Expand:SetNormalTexture("esoui/art/buttons/minus_up.dds")
	else
		control.Expand:SetNormalTexture("esoui/art/buttons/plus_up.dds")
	end

	control.Set.normalColor = SetLocker.DEFAULT_TEXT
	control.Locked.normalColor = SetLocker.DEFAULT_TEXT

	ZO_SortFilterList.SetupRow(self, control, data)
end

function SetLockerUnitList:Refresh()
	self:RefreshData()
end


-- SetLocker logic

function SetLocker.resetItems()
	if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem == 0 then
		-- Set all to true
		for k,v in pairs(SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items) do
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items[k] = true
		end
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem = 22
	else
		-- set all to false
		for k,v in pairs(SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items) do
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items[k] = false
		end
		
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem = 0
	end
	
	-- update overall lock status
	if (SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait + SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem) == 0 then
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = false
		SetLocker.SyncLockStatus()
	else
		if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked == false then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = true
			SetLocker.SyncLockStatus()
		end
	end
	
	SetLocker.SetDetails(SetLocker.currentSetDetailsSet)
end

function SetLocker.resetTraits()
	if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait == 0 then
		-- Set all to true
		for k,v in pairs(SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits) do
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits[k] = true
		end
		
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait = 23
	else
		-- set all to false
		for k,v in pairs(SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits) do
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits[k] = false
		end
		
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait = 0
	end
	
	-- update overall lock status
	if (SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait + SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem) == 0 then
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = false
		SetLocker.SyncLockStatus()
	else
		if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked == false then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = true
			SetLocker.SyncLockStatus()
		end
	end
	
	SetLocker.SetDetails(SetLocker.currentSetDetailsSet)
end

function SetLocker.SyncLockStatus()
	for key, value in pairs(SetLocker.savedVariables.sets) do
		SetLocker.units[key] = {Locked = value.Locked}
	end
	SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.LockTrait(control, trait)
	local prev = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits[trait]
	SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Traits[trait] = not prev
	
	if prev == true then
		control:SetNormalTexture("esoui/art/cadwell/checkboxicon_unchecked.dds")
		-- check if now all are unchecked => locked shall be false in this case
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait - 1
		if (SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait + SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem) == 0 then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = false
			SetLocker.SyncLockStatus()
		end
	else
		control:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
		-- at least one is true, so locked must be set
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait + 1
		if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked == false then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = true
			SetLocker.SyncLockStatus()
		end
	end
end

function SetLocker.LockPiece(control, item)
	local prev = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items[item]
	SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Items[item] = not prev
	
	if prev == true then
		control:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
		-- check if now all are unchecked => locked shall be false in this case
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem - 1
		if (SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountTrait + SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem) == 0 then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = false
			SetLocker.SyncLockStatus()
		end
	else
		control:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
		-- at least one is true, so locked must be set
		SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem = SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].LockCountItem + 1
		if SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked == false then
			SetLocker.savedVariables.sets[SetLocker.currentSetDetailsSet].Locked = true
			SetLocker.SyncLockStatus()
		end
	end
end

function SetLocker.SetDetails(SetName)
	SetLocker.currentSetDetailsSet = SetName
	SetLockerLockDetails_Heading:SetText(SetName)
	
	local traits = SetLocker.savedVariables.sets[SetName].Traits
	local items = SetLocker.savedVariables.sets[SetName].Items
	
	-- Items
	
	if items["Head"] == true then
		SetLockerLockDetails_Head:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Head:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Shoulders"] == true then
		SetLockerLockDetails_Shoulders:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Shoulders:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end

	if items["Chest"] == true then
		SetLockerLockDetails_Chest:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Chest:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Hands"] == true then
		SetLockerLockDetails_Hands:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Hands:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Waist"] == true then
		SetLockerLockDetails_Waist:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Waist:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Legs"] == true then
		SetLockerLockDetails_Legs:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Legs:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Feet"] == true then
		SetLockerLockDetails_Feet:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Feet:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Amulet"] == true then
		SetLockerLockDetails_Amulet:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Amulet:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Ring"] == true then
		SetLockerLockDetails_Ring:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Ring:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Dagger"] == true then
		SetLockerLockDetails_Dagger:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Dagger:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Sword"] == true then
		SetLockerLockDetails_Sword:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Sword:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Axe"] == true then
		SetLockerLockDetails_Axe:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Axe:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Mace"] == true then
		SetLockerLockDetails_Mace:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Mace:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Bow"] == true then
		SetLockerLockDetails_Bow:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Bow:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Firestaff"] == true then
		SetLockerLockDetails_Fire:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Fire:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Icestaff"] == true then
		SetLockerLockDetails_Ice:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Ice:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Lightstaff"] == true then
		SetLockerLockDetails_Lightning:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Lightning:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Healstaff"] == true then
		SetLockerLockDetails_Heal:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Heal:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Greatsword"] == true then
		SetLockerLockDetails_GS:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_GS:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Battleaxe"] == true then
		SetLockerLockDetails_BA:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_BA:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Maul"] == true then
		SetLockerLockDetails_Maul:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Maul:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if items["Shield"] == true then
		SetLockerLockDetails_Shield:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Shield:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	-- Traits
	
	if traits["Divine"] == true then
		SetLockerLockDetails_Divine:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Divine:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Invigorating"] == true then
		SetLockerLockDetails_Invig:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Invig:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Impenetrable"] == true then
		SetLockerLockDetails_Impen:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Impen:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Infused"] == true then
		SetLockerLockDetails_Infused:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Infused:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Nirnhoned"] == true then
		SetLockerLockDetails_Nirn:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Nirn:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Reinforced"] == true then
		SetLockerLockDetails_Reinforced:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Reinforced:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Sturdy"] == true then
		SetLockerLockDetails_Sturdy:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Sturdy:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Training"] == true then
		SetLockerLockDetails_Training:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Training:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["WellFitted"] == true then
		SetLockerLockDetails_WellFit:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_WellFit:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Charged"] == true then
		SetLockerLockDetails_Charged:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Charged:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Defending"] == true then
		SetLockerLockDetails_Def:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Def:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Powered"] == true then
		SetLockerLockDetails_Powered:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Powered:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Precise"] == true then
		SetLockerLockDetails_Precise:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Precise:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Sharpened"] == true then
		SetLockerLockDetails_Sharp:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Sharp:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Decisive"] == true then
		SetLockerLockDetails_Decisive:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Decisive:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Arcane"] == true then
		SetLockerLockDetails_Arcane:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Arcane:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Bloodthirsty"] == true then
		SetLockerLockDetails_Blood:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Blood:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Harmony"] == true then
		SetLockerLockDetails_Harmony:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Harmony:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Healthy"] == true then
		SetLockerLockDetails_Healthy:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Healthy:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Protective"] == true then
		SetLockerLockDetails_Prot:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Prot:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Robust"] == true then
		SetLockerLockDetails_Robust:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Robust:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Swift"] == true then
		SetLockerLockDetails_Swift:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Swift:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
	
	if traits["Triune"] == true then
		SetLockerLockDetails_Triune:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
	else
		SetLockerLockDetails_Triune:SetNormalTexture("/esoui/art/cadwell/checkboxicon_unchecked.dds")
	end
end

function SetLocker.ExpandSet(control)
    local setName = control:GetParent().data.Set 

	if setName == SetLocker.currentSetDetailsSet then
		SetLockerLockDetails:SetHidden(true)
		SetLocker.currentSetDetailsSet = ""
	else
		SetLockerLockDetails:SetHidden(false)
		SetLocker.SetDetails(setName)
		SetLocker.currentSetDetailsSet = setName
	end
	
	SetLocker.SetLockerUnitList:Refresh()
end

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
		SetLocker.savedVariables.sets[cd.Set].Locked=false
		cd.Locked = false
	else
	    SetLocker.savedVariables.sets[cd.Set].Locked=true
		cd.Locked = true
		
		-- if there is no preconfig for the items and traits, set them all to true
		if SetLocker.savedVariables.sets[cd.Set].LockCountItem == 0 then
			for k,v in pairs(SetLocker.savedVariables.sets[cd.Set].Items) do
				SetLocker.savedVariables.sets[cd.Set].Items[k] = true
			end
			SetLocker.savedVariables.sets[cd.Set].LockCountItem = 22
			if SetLocker.currentSetDetailsSet == cd.Set then
				SetLocker.SetDetails(cd.Set)
			end
		end
		if SetLocker.savedVariables.sets[cd.Set].LockCountTrait == 0 then
			for k,v in pairs(SetLocker.savedVariables.sets[cd.Set].Traits) do
				SetLocker.savedVariables.sets[cd.Set].Traits[k] = true
			end
			SetLocker.savedVariables.sets[cd.Set].LockCountTrait = 23
			if SetLocker.currentSetDetailsSet == cd.Set then
				SetLocker.SetDetails(cd.Set)
			end
		end
	end
	SetLocker.SetLockerUnitList:Refresh()
end

function SetLocker.Close()
   SetLockerControl:SetHidden(true)
   SetGameCameraUIMode(false)
   SetLocker.GUIOpen = false
   SetLockerResetQ:SetHidden(true)
   SetLockerLockDetails:SetHidden(true)
   SetLocker.currentSetDetailsSet = ""   
end

function SetLocker.LoadSetNames()
   local LibSets = LibSets
   if LibSets and LibSets.checkIfSetsAreLoadedProperly() then
      local setNames = LibSets.GetAllSetNames()
      for k, v in pairs(setNames) do
	     SetLocker.savedVariables.sets[v[GetCVar("Language.2")]] = { Locked = false, Items = { Head = false, Shoulders = false, Hands = false, Chest = false, Waist = false, Legs = false, Feet = false, Amulet = false,
																							   Ring = false, Sword = false, Axe = false, Dagger = false, Mace = false, Firestaff = false, Icestaff = false, Lightstaff = false,
																							   Healstaff = false, Bow = false, Maul = false, Battleaxe = false, Greatsword = false, Shield = false,
																							 },
																					 Traits = {Divine = false, Infused = false, Sturdy = false, Bloodthirsty = false, Arcane = false, Healthy = false, Swift = false, Triune = false,
																					           Robust = false, Charged = false, Powered = false, Sharpened = false, Precise = false, Training = false, Harmony = false, Protective = false,
																							   Invigorating = false, Impenetrable = false, Nirnhoned = false, Reinforced = false, WellFitted = false, Defending = false, Decisive = false,
																					          },
																					 LockCountTrait = 0,
																					 LockCountItem = 0,
																							   
																   }
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
	   SetLocker.units[key] = {Locked = value.Locked}
    end
	SetLockerResetQ:SetHidden(true)
    SetLocker.SetLockerUnitList:Refresh()
	
	-- Hide possibly open set details
	if SetLocker.currentSetDetailsSet ~= "" then
		SetLockerLockDetails:SetHidden(true)
		SetLocker.currentSetDetailsSet = ""
		SetLocker.SetLockerUnitList:Refresh()
	end
end

function SetLocker.Open()
   SetLocker.SetLockerUnitList:Refresh()
   SetLockerControl:SetHidden(SetLocker.GUIOpen)
   SetLocker.GUIOpen = not SetLocker.GUIOpen
   SetGameCameraUIMode(SetLocker.GUIOpen)
   if SetLocker.GUIOpen == false then
	 SetLockerResetQ:SetHidden(true)
	 SetLockerLockDetails:SetHidden(true)
	 SetLocker.currentSetDetailsSet = ""
   end
end

function SetLocker.ShallBeLocked(setName, itemT, traitT, weaponT)
	
	local eso2item_translation = {
			[EQUIP_TYPE_CHEST] = "Chest",
			[EQUIP_TYPE_FEET] = "Feet",
			[EQUIP_TYPE_HAND] = "Hands",
			[EQUIP_TYPE_HEAD] = "Head",
			[EQUIP_TYPE_LEGS] = "Legs",
			[EQUIP_TYPE_NECK] = "Amulet",
			[EQUIP_TYPE_RING] = "Ring",
			[EQUIP_TYPE_SHOULDERS] = "Shoulders",
			[EQUIP_TYPE_WAIST] = "Waist",
	}

	local eso2trait_translation = {
		[ITEM_TRAIT_TYPE_ARMOR_DIVINES] = "Divine",
		[ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = "Impenetrable",
		[ITEM_TRAIT_TYPE_ARMOR_INFUSED] = "Infused",
		[ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = "Nirnhoned",
		[ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = "Reinforced",
		[ITEM_TRAIT_TYPE_ARMOR_STURDY] = "Sturdy",
		[ITEM_TRAIT_TYPE_ARMOR_TRAINING] = "Training",
		[ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = "WellFitted",
		[ITEM_TRAIT_TYPE_JEWELRY_ARCANE] = "Arcane",
		[ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY] = "Bloodthirsty",
		[ITEM_TRAIT_TYPE_JEWELRY_HARMONY] = "Harmony",
		[ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] = "Healthy",
		[ITEM_TRAIT_TYPE_JEWELRY_INFUSED] = "Infused",
		[ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE] = "Protective",
		[ITEM_TRAIT_TYPE_JEWELRY_ROBUST] = "Robust",
		[ITEM_TRAIT_TYPE_JEWELRY_SWIFT] = "Swift",
		[ITEM_TRAIT_TYPE_JEWELRY_TRIUNE] = "Triune",
		[ITEM_TRAIT_TYPE_WEAPON_CHARGED] = "Charged",
		[ITEM_TRAIT_TYPE_WEAPON_DECISIVE] = "Decisive",
		[ITEM_TRAIT_TYPE_WEAPON_DEFENDING] = "Defending",
		[ITEM_TRAIT_TYPE_WEAPON_INFUSED] = "Infused",
		[ITEM_TRAIT_TYPE_WEAPON_NIRNHONED] = "Nirnhoned",
		[ITEM_TRAIT_TYPE_WEAPON_POWERED] = "Powered",
		[ITEM_TRAIT_TYPE_WEAPON_PRECISE] = "Precise",
		[ITEM_TRAIT_TYPE_WEAPON_SHARPENED] = "Sharpened",
		[ITEM_TRAIT_TYPE_WEAPON_TRAINING] = "Training",
	}
	
	local eso2weapon_translation = {
		[WEAPONTYPE_AXE] = "Axe",
		[WEAPONTYPE_BOW] = "Bow",
		[WEAPONTYPE_DAGGER] = "Dagger",
		[WEAPONTYPE_FIRE_STAFF] = "Firestaff",
		[WEAPONTYPE_FROST_STAFF] = "Icestaff",
		[WEAPONTYPE_HAMMER] = "Mace",
		[WEAPONTYPE_HEALING_STAFF] = "Healstaff",
 		[WEAPONTYPE_LIGHTNING_STAFF] = "Lightstaff",
		[WEAPONTYPE_SHIELD] = "Shield",
		[WEAPONTYPE_SWORD] = "Sword",
		[WEAPONTYPE_TWO_HANDED_AXE] = "Battleaxe",
		[WEAPONTYPE_TWO_HANDED_HAMMER] = "Maul",
		[WEAPONTYPE_TWO_HANDED_SWORD] = "Greatsword",
	}
	
	local itemLock = false
	local traitLock = false
	
	if (itemT == EQUIP_TYPE_TWO_HAND or itemT == EQUIP_TYPE_ONE_HAND or itemT == EQUIP_TYPE_OFF_HAND or itemT == EQUIP_TYPE_MAIN_HAND) then
		if weaponT ~= WEAPONTYPE_NONE then
			itemLock = SetLocker.savedVariables.sets[setName].Items[eso2weapon_translation[weaponT]]
		end
	else
		itemLock = SetLocker.savedVariables.sets[setName].Items[eso2item_translation[itemT]]
	end
	
	if traitT ~= ITEM_TRAIT_TYPE_WEAPON_ORNATE and traitT ~= ITEM_TRAIT_TYPE_NONE and traitT ~= ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS and traitT ~= ITEM_TRAIT_TYPE_ARMOR_ORNATE
     	and traitT ~= ITEM_TRAIT_TYPE_JEWELRY_INTRICATE and traitT ~= ITEM_TRAIT_TYPE_ARMOR_INTRICATE and traitT ~= ITEM_TRAIT_TYPE_JEWELRY_ORNATE
		and traitT ~= ITEM_TRAIT_TYPE_WEAPON_INTRICATE
	then
		traitLock = SetLocker.savedVariables.sets[setName].Traits[eso2trait_translation[traitT]]
	end
	
	return itemLock and traitLock
end

function SetLocker.OnItemPickup(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  local itemLink = GetItemLink(bagId, slotIndex, LINK_TYPE_ITEM)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)
  local weaponT = GetItemLinkWeaponType(itemLink)
  
  -- remove gender addition in some languages
  setName = setName:gsub("%^.*", "")
  
  if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == true and SetLocker.ShallBeLocked(setName, equipT, trait, weaponT) == true then
      SetItemIsPlayerLocked(bagId, slotIndex, true)
  end
end

function SetLocker.OnLoot(eventCode, lootedBy, itemLink, quantity, itemSound, lootType, isNotStolen)
  local name = GetItemLinkName(itemLink)
  local hasSet,setName,x,y,z,setID = GetItemLinkSetInfo(itemLink)
  local trait = GetItemLinkTraitInfo(itemLink)
  local q,w,e,equipT = GetItemLinkInfo(itemLink)
  local lootedPlayer = lootedBy:sub(1,-4)
  local weaponT = GetItemLinkWeaponType(itemLink)

  -- remove gender addition in some languages
  setName = setName:gsub("%^.*", "")

  if SetLocker.playerName ~= lootedPlayer and SetLocker.savedVariables.showDrops then
    if setName ~= "" and SetLocker.units[tostring(setName)] ~= nil and SetLocker.units[tostring(setName)].Locked == true and SetLocker.ShallBeLocked(setName, equipT, trait, weaponT) == true then
	      local link = string.gsub(itemLink, "|H.", "|H" .. LINK_STYLE_BRACKETS)
		  local player = ZO_LinkHandler_CreatePlayerLink(lootedPlayer)
          d("SetLocker: " .. zo_strformat("<<t:1>>", player) .. ":" .. zo_strformat("<<t:1>>", link))
    end
  end
end

function SetLocker.InitSetPieceTraitSelector()
	SetLockerLockDetails_SP:SetText(GetString(SI_SETLOCKER_SETPIECE))
	SetLockerLockDetails_HeadLabel:SetText(GetString(SI_SETLOCKER_SP_HELM))
	SetLockerLockDetails_ShouldersLabel:SetText(GetString(SI_SETLOCKER_SP_SHOULDER))
	SetLockerLockDetails_ChestLabel:SetText(GetString(SI_SETLOCKER_SP_CHEST))
	SetLockerLockDetails_HandsLabel:SetText(GetString(SI_SETLOCKER_SP_HAND))
	SetLockerLockDetails_WaistLabel:SetText(GetString(SI_SETLOCKER_SP_WAIST))
	SetLockerLockDetails_LegsLabel:SetText(GetString(SI_SETLOCKER_SP_LEG))
	SetLockerLockDetails_FeetLabel:SetText(GetString(SI_SETLOCKER_SP_FEET))
	SetLockerLockDetails_AmuletLabel:SetText(GetString(SI_SETLOCKER_SP_NECK))
	SetLockerLockDetails_RingLabel:SetText(GetString(SI_SETLOCKER_SP_RING))
	SetLockerLockDetails_DaggerLabel:SetText(GetString(SI_SETLOCKER_SP_DAGGER))
	SetLockerLockDetails_SwordLabel:SetText(GetString(SI_SETLOCKER_SP_SWORD))
	SetLockerLockDetails_AxeLabel:SetText(GetString(SI_SETLOCKER_SP_AXE))
	SetLockerLockDetails_MaceLabel:SetText(GetString(SI_SETLOCKER_SP_MACE))
	SetLockerLockDetails_FireLabel:SetText(GetString(SI_SETLOCKER_SP_INFS))
	SetLockerLockDetails_IceLabel:SetText(GetString(SI_SETLOCKER_SP_ICES))
	SetLockerLockDetails_HealLabel:SetText(GetString(SI_SETLOCKER_SP_HEALS))
	SetLockerLockDetails_LightningLabel:SetText(GetString(SI_SETLOCKER_SP_LIGHTS))
	SetLockerLockDetails_GSLabel:SetText(GetString(SI_SETLOCKER_SP_GS))
	SetLockerLockDetails_BALabel:SetText(GetString(SI_SETLOCKER_SP_BA))
	SetLockerLockDetails_MaulLabel:SetText(GetString(SI_SETLOCKER_SP_MAUL))
	SetLockerLockDetails_BowLabel:SetText(GetString(SI_SETLOCKER_SP_BOW))
	SetLockerLockDetails_ShieldLabel:SetText(GetString(SI_SETLOCKER_SP_SHIELD))
	
	SetLockerLockDetails_T:SetText(GetString(SI_SETLOCKER_TRAITS))
	SetLockerLockDetails_DivineLabel:SetText(GetString(SI_SETLOCKER_TRAIT_DIVINE))
	SetLockerLockDetails_InvigLabel:SetText(GetString(SI_SETLOCKER_TRAIT_INVIG))
	SetLockerLockDetails_ImpenLabel:SetText(GetString(SI_SETLOCKER_TRAIT_IMPEN))
	SetLockerLockDetails_InfusedLabel:SetText(GetString(SI_SETLOCKER_TRAIT_INFUSED))
	SetLockerLockDetails_NirnLabel:SetText(GetString(SI_SETLOCKER_TRAIT_NIRN))
	SetLockerLockDetails_ReinforcedLabel:SetText(GetString(SI_SETLOCKER_TRAIT_REINFORCED))
	SetLockerLockDetails_SturdyLabel:SetText(GetString(SI_SETLOCKER_TRAIT_STURDY))
	SetLockerLockDetails_TrainingLabel:SetText(GetString(SI_SETLOCKER_TRAIT_TRAIN))
	SetLockerLockDetails_WellFitLabel:SetText(GetString(SI_SETLOCKER_TRAIT_WELLF))
	SetLockerLockDetails_ChargedLabel:SetText(GetString(SI_SETLOCKER_TRAIT_CHARGED))
	SetLockerLockDetails_DefLabel:SetText(GetString(SI_SETLOCKER_TRAIT_DEF))
	SetLockerLockDetails_PoweredLabel:SetText(GetString(SI_SETLOCKER_TRAIT_POW))
	SetLockerLockDetails_PreciseLabel:SetText(GetString(SI_SETLOCKER_TRAIT_PRECISE))
	SetLockerLockDetails_SharpLabel:SetText(GetString(SI_SETLOCKER_TRAIT_SHARP))
	SetLockerLockDetails_DecisiveLabel:SetText(GetString(SI_SETLOCKER_TRAIT_DEC))
	SetLockerLockDetails_ArcaneLabel:SetText(GetString(SI_SETLOCKER_TRAIT_ARCANE))
	SetLockerLockDetails_BloodLabel:SetText(GetString(SI_SETLOCKER_TRAIT_BLOOD))
	SetLockerLockDetails_HarmonyLabel:SetText(GetString(SI_SETLOCKER_TRAIT_HARM))
	SetLockerLockDetails_HealthyLabel:SetText(GetString(SI_SETLOCKER_TRAIT_HEAL))
	SetLockerLockDetails_ProtLabel:SetText(GetString(SI_SETLOCKER_TRAIT_PROT))
	SetLockerLockDetails_RobustLabel:SetText(GetString(SI_SETLOCKER_TRAIT_ROBUST))
	SetLockerLockDetails_SwiftLabel:SetText(GetString(SI_SETLOCKER_TRAIT_SWIFT))
	SetLockerLockDetails_TriuneLabel:SetText(GetString(SI_SETLOCKER_TRAIT_TRIUNE))
end

function SetLocker:Initialize()
  EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, SetLocker.OnItemPickup)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BACKPACK)
  EVENT_MANAGER:AddFilterForEvent(SetLocker.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
  EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_LOOT_RECEIVED, SetLocker.OnLoot)
  SetLocker.GUIOpen = false
  
  SetLocker.SetLockerUnitList = SetLockerUnitList:New()
  SetLocker.savedVariables = ZO_SavedVars:New("SetLockerSavedVariables", 2, nil, SetLockerDefaultSetConfig)
  SetLocker.playerName = GetUnitName("player")
  
  SetLockerControlShowLoot:SetText(GetString(SI_SETLOCKER_SHOWLOOT_LABEL))
  SetLockerResetQText:SetText(GetString(SI_SETLOCKER_RESETQ_LABEL))
  
  if SetLocker.savedVariables.sets == {} then
     SetLocker.LoadSetNames()
  end

  for key, value in pairs(SetLocker.savedVariables.sets) do
	SetLocker.units[key] = {Locked = value.Locked}
  end
  
  if SetLocker.savedVariables.showDrops then
	 SetLockerControl_ShowLoot_Button:SetNormalTexture("/esoui/art/cadwell/checkboxicon_checked.dds")
  end

  SetLocker.InitSetPieceTraitSelector()
  SetLocker.SetLockerUnitList:Refresh()
end
 

function SetLocker.OnAddOnLoaded(event, addonName)
  if addonName == SetLocker.name then
    SetLocker:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(SetLocker.name, EVENT_ADD_ON_LOADED, SetLocker.OnAddOnLoaded)