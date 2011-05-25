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

function RepSwap:MessageUser(message)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cfffa8000RepSwap|r: %s", message));
end

function RepSwap:CreateFactionTable()
	-- This creates an table of all factions the player has encountered.
	local factionTable = { };
	local numFactions = GetNumFactions();
	
	if (numFactions == 0) then
		return factionTable;
	end
	
	for i=1, numFactions do
		local factionName = select(1,GetFactionInfo(i));
		factionTable[factionName] = i;
		-- RepSwap:MessageUser(string.format("FactionName: %s. FactionID: %s.", factionName, i));
	end
	
	return factionTable;
end

function RepSwap:GetFactionIndexFromTable(factionName, factionTable)
	-- Returns the factionIndex of the faction
	-- RepSwap:MessageUser(string.format("Faction: %s. FactionIndex: %s.", factionName, factionTable));
	return factionTable[factionName];
end

function RepSwap:UpdateWatchedFaction(factionIndex)
	-- Updates our tracked reputation on the blizzard reputation bar
	SetWatchedFactionIndex(factionIndex);
end

function RepSwap:RegisterEvents()
	EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
end

function RepSwap:Initialize()
	RepSwap:MessageUser(string.format("AddOn Loaded. Version: %s. Author: %s.", RepSwap.Version, RepSwap.Author));
	RepSwap:RegisterEvents();
	EventFrame:SetScript("OnEvent", function (self, event, ...) RepSwap:EventHandler(self, event, ...); end );
end

function RepSwap:EventHandler(self, event, ...)
	if (event == "COMBAT_TEXT_UPDATE") then
		--SendChatMessage("COMBAT_TEXT_UPDATE", "OFFICER");
		local messageType, factionName --[[, reputation]] = ...; 
		if (messageType == "FACTION") then
			--SendChatMessage(string.format("%s passed for %s",messageType,event), "OFFICER");
			-- This is the correct event so we will now check to see if
			-- the reputation found is inside our faction index. If it is
			-- then we can tell it to change the watched faction
			
			factionIndex = RepSwap:GetFactionIndexFromTable(factionName, RepSwap.FactionTable);
			RepSwap:UpdateWatchedFaction(factionIndex);
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		--SendChatMessage("I have entered the World","OFFICER");
		RepSwap.PlayerGuildName = GetGuildInfo("player");
		RepSwap.FactionTable = RepSwap:CreateFactionTable();
	end
end
RepSwap:Initialize();