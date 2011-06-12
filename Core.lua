--[[ 
	@Package       RepSwap
	@Description   Changes your watched reputation based on the faction you last gained rep with
	@Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
	@Repo          http://github.com/Fluxflashor/RepSwap
	@File          Core.lua 
	]]

local REPSWAP, RepSwap = ...;
local EventFrame = CreateFrame("FRAME", "RepSwap_EventFrame");

local about = LibStub("tekKonfig-AboutPanel").new(nil, "RepSwap")

-- Editing below this line may cause the AddOn to stop behaving properly.
-- Hell, you may have fucked something up in the config so if you have any
-- doubts please revert your changes. This addon was tested by Fluxflashor
-- before being uploaded to Curse.com so it's your fault if it breaks!

RepSwap = {
	AddonName = REPSWAP,
	Author = GetAddOnMetadata(REPSWAP, "Author"),
	Version = GetAddOnMetadata(REPSWAP, "Version"),
	FactionTable = { },
	PlayerGuildName = "",
	SetupFactionTable = true
}

-- This is used during development. It is spammy as fuck so don't enable it
RepSwap.TestMode = false;

-- Saved Variable Defaults
RepSwapDB = {
	SuppressWarnings = false,
	AddOnDisabled = false,
	LDBDisplayPercent = false
}

function RepSwap:MessageUser(message)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cfffa8000RepSwap|r: %s", message));
end

function RepSwap:WarnUser(message)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cfffa8000RepSwap|r: |cffc41f3b%s|r", message));
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
		if (RepSwap.TestMode) then
			RepSwap:MessageUser(string.format("FactionName: %s. FactionID: %s.", factionName, i));
		end
	end
	
	return factionTable;
end

function RepSwap:GetFactionIndexFromTable(factionName, factionTable)
	-- Returns the factionIndex of the faction
	if (RepSwap.TestMode) then
		RepSwap:MessageUser(string.format("Faction: %s. FactionIndex: %s.", factionName, factionTable[factionName]));
	end
	return factionTable[factionName];
end

function RepSwap:UpdateWatchedFaction(factionIndex)
	-- Updates our tracked reputation on the blizzard reputation bar
	SetWatchedFactionIndex(factionIndex);
end

function RepSwap:RegisterEvents()
	EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	EventFrame:RegisterEvent("PLAYER_GUILD_UPDATE");
	EventFrame:RegisterEvent("PLAYER_LOGOUT");
	EventFrame:RegisterEvent("UPDATE_FACTION");
end

function RepSwap:Enable(enable)
	if (enable) then
		RepSwapDB.AddOnDisabled = false;
		EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
		RepSwap.SetupFactionTable = true;
		RepSwap:MessageUser("Enabled Automagic Reputation Swapping =)");
	else
		RepSwapDB.AddOnDisabled = true;
		EventFrame:UnregisterEvent("COMBAT_TEXT_UPDATE");
		RepSwap.FactionTable = { };
		RepSwap:MessageUser("Disabled Automagic Reputation Swapping =(");
	end
end

SLASH_REPSWAP1 = "/rs";
SLASH_REPSWAP2 = "/repswap";
SlashCmdList["REPSWAP"] = function (msg) RepSwap:SlashHandler(msg) end;

function RepSwap:Initialize()
	EventFrame:RegisterEvent("ADDON_LOADED");
	EventFrame:SetScript("OnEvent", function (self, event, ...) RepSwap:EventHandler(self, event, ...); end );
end

function RepSwap:SlashHandler(msg)
	local command = "";
	
	if (msg) then
		command = string.lower(msg);
	end
	
	if (command == "" or command == "help" or command == "usage") then
		RepSwap:MessageUser("Slash Command Usage");
		RepSwap:MessageUser("  help    - Displays 'Slash Command Usage'.");
		RepSwap:MessageUser("  disable - Disables RepSwap.");
		RepSwap:MessageUser("  enable  - Enables RepSwap.");
		RepSwap:MessageUser("  warnoff - Disables Warnings.");
		RepSwap:MessageUser("  warnon  - Enables Warnings.");
	elseif (command == "off" or command == "disable") then
		-- Disable the addon
		RepSwap:Enable(false);
	elseif (command == "on" or command == "enable") then
		-- Enable the addon
		RepSwap:Enable(true);
	elseif (command == "warnon" or command == "won") then
		-- Enables Warnings
		RepSwapDB.SuppressWarnings = false;
		RepSwap:MessageUser("Warnings are now being hidden.");
	elseif (command == "warnoff" or command == "woff") then
		-- Diables Warnings
		RepSwapDB.SuppressWarnings = true;
		RepSwap:MessageUser("Warnings are now being shown.");
	end
end

function RepSwap:EventHandler(self, event, ...)
	if (event == "COMBAT_TEXT_UPDATE") then
		--SendChatMessage("COMBAT_TEXT_UPDATE", "OFFICER");
		local messageType, factionName --[[, reputation]] = ...; 
		if (messageType == "FACTION") then
			if (RepSwapDB.AddOnDisabled) then
				-- Do nothing :D
			else
				if (RepSwap.SetupFactionTable) then
					RepSwap.FactionTable = RepSwap:CreateFactionTable();
					RepSwap.SetupFactionTable = false;
				end
			
				if (RepSwap.TestMode) then
					SendChatMessage(string.format("%s passed for %s - Args: %s",messageType,event,factionName), "OFFICER");
				end
				
				-- This is the correct event so we will now check to see if
				-- the reputation found is inside our faction index. If it is
				-- then we can tell it to change the watched faction
				
				if (factionName == "Guild") then
					if (RepSwap.TestMode) then
						RepSwap:MessageUser("FactionName provided was 'Guild'.");
					end
					factionIndex = RepSwap:GetFactionIndexFromTable(RepSwap.PlayerGuildName, RepSwap.FactionTable);
				else
					if (RepSwap.TestMode) then
						RepSwap:MessageUser(string.format("FactionName provided was %s.", factionName));
					end
					factionIndex = RepSwap:GetFactionIndexFromTable(factionName, RepSwap.FactionTable);
				end
				RepSwap:UpdateWatchedFaction(factionIndex);
			end
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		-- Check to see if the player is in a guild so we can setup different rules for it
		RepSwap.IsInGuild = IsInGuild();
		if (RepSwap.IsInGuild) then
			RepSwap.PlayerGuildName = GetGuildInfo("player");
			if (RepSwap.TestMode) then
				RepSwap:MessageUser(string.format("Player's Guild Name: %s", RepSwap.PlayerGuildName));
			end
		end
		RepSwap.SetupFactionTable = true;
	elseif (event == "PLAYER_GUILD_UPDATE") then
		-- This fires when a player leaves or joins a new guild. Check to
		-- see if the player is in a guild currently and if they are then
		-- we can make sure we aren't checking for old guild names :p
		RepSwap.IsInGuild = IsInGuild();
		if (RepSwap.IsInGuild) then
			RepSwap.PlayerGuildName = GetGuildInfo("player");
			if (RepSwap.TestMode) then
				RepSwap:MessageUser(string.format("Player's Guild Name: %s", RepSwap.PlayerGuildName));
			end
		else
			if (RepSwap.TestMode) then
				RepSwap:MessageUser(string.format("Resetting Guild Name: %s", RepSwap.PlayerGuildName));
			end
			RepSwap.PlayerGuildName = "";
		end
	elseif (event == "PLAYER_LOGOUT") then
		-- Save our saved variables!
	elseif (event == "ADDON_LOADED") then
		local LoadedAddonName = ...;
		if (RepSwap.TestMode) then
			RepSwap:MessageUser(string.format("LoadedAddonName is %s", LoadedAddonName));
		end
		if (LoadedAddonName == AddonName) then
			if (RepSwap.Version == "@project-version@") then
				RepSwap.Version = "Development";
			end
			if (RepSwap.Author == "@project-author@") then
				RepSwap.Author = "Fluxflashor (Local)";
			end
			RepSwap:MessageUser(string.format("Loaded Version is %s. Author is %s.", RepSwap.Version, RepSwap.Author));
			if (RepSwap.TestMode) then
				RepSwap:MessageUser(string.format("%s is %s.", LoadedAddonName, AddonName));
			end
			if (RepSwapDB.AddOnDisabled) then
				if (RepSwap.TestMode) then
					RepSwap:MessageUser("Unregistering Events.");
				end
				if (not RepSwapDB.SuppressWarnings) then
					RepSwap:WarnUser("RepSwap is disabled. Your reputation bar will not change on rep gains. To re-enable it type '/rs on'.");
				end
				RepSwap:Enable(false);
			end
		end
		RepSwap:RegisterEvents()
	elseif (event == "UPDATE_FACTION") then
		
		local FactionName, FactionStandingId, ReputationMin, ReputationMax, TotalReputationEarned = GetWatchedFactionInfo();
		if not FactionName then
			-- FactionName isn't set don't do shit
		else
			RepSwap:MessageUser(FactionName .. " " .. FactionStandingId .. "" .. ReputationMin)
			local FactionStandingLabel = _G["FACTION_STANDING_LABEL"..FactionStandingId];
			local ReputationEarnedForThisStandingId = TotalReputationEarned - ReputationMin;
			local ReputationCapForThisStandingId = ReputationMax - TotalReputationEarned + ReputationEarnedForThisStandingId;
			local ReputationToReachNextStandingId = ReputationCapForThisStandingId - ReputationEarnedForThisStandingId;
			
			if (RepSwapDB.LDBDisplayPercent) then
				PercentEarnedForThisStandingId = floor(ReputationEarnedForThisStandingId * 100 / ReputationCapForThisStandingId);
				RepSwapLDB.text = string.format("%s - %s: %s%%", FactionName, FactionStandingLabel, PercentEarnedForThisStandingId);
			else
				RepSwapLDB.text = string.format("%s - %s: %s/%s", FactionName, FactionStandingLabel, ReputationEarnedForThisStandingId, ReputationCapForThisStandingId);
			end
		end
	end
end
RepSwap:Initialize();