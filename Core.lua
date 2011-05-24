--[[ 
	@Package       CopyCat
	@Description   Automated Trolling of Trade Chat
	@Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
	@Repo          http://github.com/Fluxflashor/CopyCat
	@File          Core.lua 
	]]

local AddonName, RepSwap = ...;
local EventFrame = CreateFrame("FRAME", "RepSwap_EventFrame")	;

-- Editing below this line may cause the AddOn to stop behaving properly.
-- Hell, you may have fucked something up in the config so if you have any
-- doubts please revert your changes. This addon was tested by Fluxflashor
-- before being uploaded to Curse.com so it's your fault if it breaks!

RepSwap.Author = "Fluxflashor";
RepSwap.Version = GetAddOnMetadata(AddonName, "Version");
RepSwap.TestMode = false;

function RepSwap:CreateFactionIndex()
	-- This creates an index of all factions the player has encountered.
end

function RepSwap:RegisterEvents()
	EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
end

function RepSwap:Initialize()
	RepSwap:RegisterEvents();
	RepSwap.FactionIndex = RepSwap:CreateFactionIndex();
	EventFrame:SetScript("OnEvent", function (self, event, ...) RepSwap:EventHandler(self, event, ...); end );
end

function Copycat:EventHandler(self, event, ...)
	if (event == "COMBAT_TEXT_UPDATE") then
		local messageType, faction --[[, reputation]] = ...; 
		if (messageType == "FACTION") then
			-- This is the correct event so we will now check to see if
			-- the reputation found is inside our faction index. If it is
			-- then we can tell it to change the watched faction
			
			factionIndex = RepSwap:GetFactionIndex(faction);
			RepSwap:UpdateWatchedFaction(factionIndex);
		end
	end
end
RepSwap:Initialize();