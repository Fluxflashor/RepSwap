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

local RepSwapLDB = DataBroker:NewDataObject("RepSwap", {
	type = "data source",
	icon = "Interface\\Icons\\Achievement_reputation_08",
	label = REPSWAP,
	text = "Faction - Standing 0/0",
	OnTooltipShow = function(tooltip)
	
		FactionName, FactionStandingId, ReputationMin, ReputationMax, TotalReputationEarned = GetWatchedFactionInfo();
		ReputationStandingLabel = getglobal("FACTION_STANDING_LABEL"..FactionStandingId);
		ReputationStandingLabelNext = getglobal("FACTION_STANDING_LABEL"..FactionStandingId+1);
		ReputationEarnedForThisStandingId = TotalReputationEarned - ReputationMin;
		ReputationCapForThisStandingId = ReputationMax - TotalReputationEarned + ReputationEarnedForThisStandingId;
		ReputationToReachNextStandingId = ReputationCapForThisStandingId - ReputationEarnedForThisStandingId;
	
		tooltip:AddLine("RepSwap", 1, 1, 1);
		tooltip:AddLine(" ");
		tooltip:AddLine(" ");
		tooltip:AddLine(string.format("%s", FactionName), nil, nil, nil);
		tooltip:AddDoubleLine(string.format("%s", ReputationStandingLabel), string.format("%s / %s", ReputationEarnedForThisStandingId, ReputationCapForThisStandingId), 1, 1, 1, 0, 1, 0);
		tooltip:AddLine(" ");
		tooltip:AddDoubleLine(string.format("Reputation til %s:", ReputationStandingLabelNext), string.format("%s", ReputationToReachNextStandingId), 1, 1, 1, 0, 1, 0);
		tooltip:Show();
	end
})

