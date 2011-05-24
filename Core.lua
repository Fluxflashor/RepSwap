--[[ 
	@Package       RepSwap
	@Description   Changes your watched reputation based on the faction you last gained rep with
	@Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
	@Repo          http://github.com/Fluxflashor/RepSwap
	@File          Core.lua 
	]]

local AddonName, RepSwap = ...;
local EventFrame = CreateFrame("FRAME", "RepSwap_EventFrame");

-- Editing below this line may cause the AddOn to stop behaving properly.
-- Hell, you may have fucked something up in the config so if you have any
-- doubts please revert your changes. This addon was tested by Fluxflashor
-- before being uploaded to Curse.com so it's your fault if it breaks!

RepSwap.Author = "Fluxflashor";
RepSwap.Version = GetAddOnMetadata(AddonName, "Version");
RepSwap.TestMode = false;
RepSwap.FactionTable = { };

function RepSwap:CreateFactionTable()
	-- This creates an table of all factions the player has encountered.
	local factionTable = { };
	local numFactions = GetNumFactions();
	
	if (numFactions == 0) then
		return factionTable;
	end
	
	for (i=1, numFactions) do
		local factionName, _, _, _, _, _, _, _, _, _, _, _, _, _ = GetFactionInfoByID(i);
		factionTable[factionName] = i;
	end
	
	return factionTable;
end

function RepSwap:GetFactionIndexFromTable(factionName, factionTable)
	-- Returns the factionIndex of the faction
	return factionTable[factionName];
end

function RepSwap:UpdateWatchedFaction(factionIndex)
	-- Updates our tracked reputation on the blizzard reputation bar
	SetWatchedFactionIndex(factionIndex);
end

function RepSwap:RegisterEvents()
	EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
end

function RepSwap:Initialize()
	RepSwap:RegisterEvents();
	RepSwap.FactionTable = RepSwap:CreateFactionTable();
	EventFrame:SetScript("OnEvent", function (self, event, ...) RepSwap:EventHandler(self, event, ...); end );
end

function RepSwap:EventHandler(self, event, ...)
	if (event == "COMBAT_TEXT_UPDATE") then
		local messageType, factionName --[[, reputation]] = ...; 
		if (messageType == "FACTION") then
			-- This is the correct event so we will now check to see if
			-- the reputation found is inside our faction index. If it is
			-- then we can tell it to change the watched faction
			
			factionIndex = RepSwap:GetFactionIndexFromTable(factionName, RepSwap.FactionTable);
			RepSwap:UpdateWatchedFaction(factionIndex);
		end
	end
end
RepSwap:Initialize();