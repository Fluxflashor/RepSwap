--[[ 
	@Package       RepSwap
	@Description   Adds LibDataBroker-1.1 support to RepSwap
	@Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
	@Repo          http://github.com/Fluxflashor/RepSwap
	@File          RepSwapLDB.lua 
	]]
	
local DataBroker = LibStub("LibDataBroker-1.1", true);
if not DataBroker then return end

local REPSWAP, RepSwap = ...;

RepSwapLDB = DataBroker:NewDataObject("RepSwap", {
	type = "data source",
	icon = "Interface\\Icons\\Achievement_reputation_08",
	label = REPSWAP,
	text = "No Faction Tracked",
	OnClick = function(self, button)
		if (button == "LeftButton") then
			FactionName, FactionStandingId, ReputationMin, ReputationMax, TotalReputationEarned = GetWatchedFactionInfo();
			if FactionName then
				FactionStandingLabel = getglobal("FACTION_STANDING_LABEL"..FactionStandingId);
				FactionStandingLabelNext = getglobal("FACTION_STANDING_LABEL"..FactionStandingId+1);
				ReputationEarnedForThisStandingId = TotalReputationEarned - ReputationMin;
				ReputationCapForThisStandingId = ReputationMax - TotalReputationEarned + ReputationEarnedForThisStandingId;
				ReputationToReachNextStandingId = ReputationCapForThisStandingId - ReputationEarnedForThisStandingId;
				PercentEarnedForThisStandingId = floor(ReputationEarnedForThisStandingId * 100 / ReputationCapForThisStandingId);
				PercentToReachNextStandingId = 100 - PercentEarnedForThisStandingId;
				if (RepSwapDB.LDBDisplayPercent) then
					RepSwapDB.LDBDisplayPercent = false;
					RepSwapLDB.text = string.format("%s - %s: %s%%", FactionName, FactionStandingLabel, PercentEarnedForThisStandingId);
				else
					RepSwapDB.LDBDisplayPercent = true;
					RepSwapLDB.text = string.format("%s - %s: %s/%s", FactionName, FactionStandingLabel, ReputationEarnedForThisStandingId, ReputationCapForThisStandingId);
				end
			end
		end
	end,
	OnTooltipShow = function(tooltip)
	
		local FactionName, FactionStandingId, ReputationMin, ReputationMax, TotalReputationEarned = GetWatchedFactionInfo();
		if FactionName then
			local FactionStandingLabel = _G["FACTION_STANDING_LABEL"..FactionStandingId];
			local FactionStandingLabelNext = _G["FACTION_STANDING_LABEL"..FactionStandingId+1];
			local ReputationEarnedForThisStandingId = TotalReputationEarned - ReputationMin;
			local ReputationCapForThisStandingId = ReputationMax - TotalReputationEarned + ReputationEarnedForThisStandingId;
			local ReputationToReachNextStandingId = ReputationCapForThisStandingId - ReputationEarnedForThisStandingId;
			local PercentEarnedForThisStandingId = floor(ReputationEarnedForThisStandingId * 100 / ReputationCapForThisStandingId);
			local PercentToReachNextStandingId = 100 - PercentEarnedForThisStandingId;
		
			tooltip:AddLine("RepSwap", 1, 1, 1);
			tooltip:AddLine(" ");
			tooltip:AddLine(string.format("%s", FactionName), nil, nil, nil);
			tooltip:AddDoubleLine(string.format("%s", FactionStandingLabel), string.format("%s / %s (%s%%)", ReputationEarnedForThisStandingId, ReputationCapForThisStandingId, PercentEarnedForThisStandingId), 1, 1, 1, 0, 1, 0);
			tooltip:AddLine(" ");
			tooltip:AddDoubleLine(string.format("Reputation til %s:", FactionStandingLabelNext), string.format("%s (%s%%)", ReputationToReachNextStandingId, PercentToReachNextStandingId), 1, 1, 1, 0, 1, 0);
			tooltip:AddLine(" ");
			tooltip:AddLine(string.format("Reputation earned this session"), nil, nil, nil);

			for factionName, reputationGainedThisSession in pairs(RepSwap.SessionReputation) do
				--if RepSwap.TestMode then
				    RepSwap:MessageUser(string.format("%s %s", factionName, reputationGainedThisSession))
                --end
                tooltip:AddDoubleLine(string.format("%s", factionName), string.format("%s", reputationGainedThisSession), 1, 1, 1, 0, 1, 0)
			end
			--[[
			if (RepSwapDB.LDBDisplayPercent) then
				tooltip:AddLine("Hint: Left-click to display progress as fraction.", 0, 1, 0);
			else
				tooltip:AddLine("Hint: Left-click to display progress as percentage.", 0, 1, 0)
			end]]
			tooltip:AddLine(" ");
			tooltip:AddLine("Hint: Left-click to switch the displayed reputation as percentage or fraction.", 0, 1, 0, 1);
			tooltip:Show();
		end
	end
})

