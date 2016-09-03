--[[
    @Package       RepSwap
    @Description   Changes your watched reputation based on the faction you last gained rep with
    @Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
    @Repo          http://github.com/Fluxflashor/RepSwap
    @File          Core.lua
    ]]

local REPSWAP, RepSwap = ...;
local EventFrame = CreateFrame("FRAME", "RepSwap_EventFrame");

--local about = LibStub("tekKonfig-AboutPanel").new(nil, "RepSwap");
local L = RepSwapL;
local SF = string.format;

-- Editing below this line may cause the AddOn to stop behaving properly.
-- Hell, you may have fucked something up in the config so if you have any
-- doubts please revert your changes. This addon was tested by Fluxflashor
-- before being uploaded to Curse.com so it's your fault if it breaks!


RepSwap.AddonName = REPSWAP
RepSwap.Author = GetAddOnMetadata(REPSWAP, "Author")
RepSwap.Version = GetAddOnMetadata(REPSWAP, "Version")
RepSwap.FactionTable = { }
RepSwap.PlayerGuildName = ""
RepSwap.SessionReputation = { }

-- Saved Variable Defaults
RepSwapDB = {
    SuppressWarnings = false,
    AddOnDisabled = false,
    LDBDisplayPercent = false,
    TestMode = false,
}

--[[ Checks if an variable is inside of a table ]]
function table.contains(table, element)
    for key, value in pairs(table) do
        if key == element then
            return true
        end
    end
    return false
end

function RepSwap:MessageUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(SF("|cfffa8000RepSwap|r: %s", message));
end

function RepSwap:WarnUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(SF("|cfffa8000RepSwap|r: |cffc41f3b%s|r", message));
end

function RepSwap:TestModeMessage(message)
    if RepSwapDB.TestMode then
        DEFAULT_CHAT_FRAME:AddMessage(SF("|cfffa8000RepSwap (TestMode)|r: %s", message));
    end
end

function RepSwap:CreateFactionTable()
    -- This creates an table of all factions the player has encountered.
    local factionTable = { };
    local numFactions = GetNumFactions();

    if (numFactions ~= 0) then
        for i=1, numFactions do
            local factionName = select(1, GetFactionInfo(i));
            if factionName ~= nil then
                factionTable[factionName] = i;
                RepSwap:TestModeMessage(SF("[Name] %s [ID] %s", factionName, factionTable[factionName]));
            end
        end
    end

    RepSwap.FactionTable = factionTable;
    return RepSwap.FactionTable;
end

function RepSwap:FactionIsInTable(factionName)
    if table.contains(RepSwap.FactionTable, factionName) then
       RepSwap:TestModeMessage("YARRR");
       return true;
    end
    return false;
end

function RepSwap:GetFactionIndexFromTable(factionName)
    -- Returns the factionIndex of the faction

    -- If the faction table is empty, we need to populate it.
    if next(RepSwap.FactionTable) == nil then
        RepSwap:TestModeMessage(SF("Faction Table was empty.. building table.", factionName));
        RepSwap:CreateFactionTable();
    end

    if not RepSwap:FactionIsInTable(factionName) then
        RepSwap:TestModeMessage(SF("Faction '%s' was not in the faction table.", factionName));
        RepSwap:CreateFactionTable();

        if RepSwap:FactionIsInTable(factionName) then
            RepSwap:MessageUser(SF(L["NEW_FACTION_DISCOVERED"], factionName));
        else
            RepSwap:TestModeMessage(SF("Unable to place this faction in the faction table."));
            return nil;
        end
    end

    RepSwap:TestModeMessage(SF("Faction: %s. FactionIndex: %s.", factionName, RepSwap.FactionTable[factionName]));
    return RepSwap.FactionTable[factionName];
end

function RepSwap:UpdateWatchedFaction(factionName)
    -- Updates our tracked reputation on the blizzard reputation bar
    RepSwap:TestModeMessage("UpdateWatchedFaction Running..");
    local factionIndex = RepSwap:GetFactionIndexFromTable(factionName);
    if factionIndex ~= nil then
        RepSwap:TestModeMessage("UpdateWatchedFaction's factionIndex was not nil");
        SetWatchedFactionIndex(factionIndex);
    end
end

function RepSwap:AddSessionReputation(factionName, reputationGain)
    -- Adds all session based reputation gains to a common table to use with LDB

    if RepSwap.SessionReputation[factionName] ~= nil then
        if RepSwapDB.TestMode then
            RepSwap:MessageUser(SF("The key, %s, exists inside SessionReputation Table.", factionName))
        end
        RepSwap.SessionReputation[factionName] = RepSwap.SessionReputation[factionName] + reputationGain
    else
        if RepSwapDB.TestMode then
            RepSwap:MessageUser(SF("The key, %s, does not exist inside SessionReputation Table.", factionName))
        end
        RepSwap.SessionReputation[factionName] = reputationGain
    end
end

function RepSwap:RegisterEvents()
    EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
    EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    EventFrame:RegisterEvent("PLAYER_GUILD_UPDATE");
    EventFrame:RegisterEvent("UPDATE_FACTION");
end

function RepSwap:Enable(enable)
    if (enable) then
        RepSwapDB.AddOnDisabled = false;
        EventFrame:RegisterEvent("COMBAT_TEXT_UPDATE");
        RepSwap.SetupFactionTable = true;
        RepSwap:MessageUser(L["SCMD_MSG_ENABLE"]);
    else
        RepSwapDB.AddOnDisabled = true;
        EventFrame:UnregisterEvent("COMBAT_TEXT_UPDATE");
        RepSwap.FactionTable = { };
        RepSwap:MessageUser(L["SCMD_MSG_DISABLE"]);
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
        RepSwap:MessageUser(L["SCMD_INFO_USAGE"]);
        RepSwap:MessageUser(L["SCMD_INFO_HELP"]);
        RepSwap:MessageUser(L["SCMD_INFO_DISABLE"]);
        RepSwap:MessageUser(L["SCMD_INFO_ENABLE"]);
        RepSwap:MessageUser(L["SCMD_INFO_WARN_OFF"]);
        RepSwap:MessageUser(L["SCMD_INFO_WARN_ON"]);
    elseif (command == "off" or command == "disable") then
        -- Disable the addon
        RepSwap:Enable(false);
    elseif (command == "on" or command == "enable") then
        -- Enable the addon
        RepSwap:Enable(true);
    elseif (command == "warnon" or command == "won") then
        -- Enables Warnings
        RepSwapDB.SuppressWarnings = false;
        RepSwap:MessageUser(L["SCMD_MSG_WARNINGS_ON"]);
    elseif (command == "warnoff" or command == "woff") then
        -- Diables Warnings
        RepSwapDB.SuppressWarnings = true;
        RepSwap:MessageUser(L["SCMD_MSG_WARNINGS_OFF"]);
    elseif (command == "debugon") then
        RepSwapDB.TestMode = true;
        RepSwap:MessageUser(L["SCMD_MSG_DEBUG_ON"]);
    elseif (command == "debugoff") then
        RepSwapDB.TestMode = false;
        RepSwap:MessageUser(L["SCMD_MSG_DEBUG_OFF"]);
    end
end

function RepSwap:EventHandler(self, event, ...)
    if (event == "COMBAT_TEXT_UPDATE") then

        --SendChatMessage("COMBAT_TEXT_UPDATE", "OFFICER");
        local messageType, factionName, reputationGain = ...;
        if (messageType == "FACTION") then
            if (RepSwapDB.AddOnDisabled) then
                -- Do nothing :D
            else

                --[[if (RepSwap.SetupFactionTable) then
                    RepSwap.FactionTable = RepSwap:CreateFactionTable();
                    RepSwap.SetupFactionTable = false;
                end]]



                if (RepSwapDB.TestMode) then
                    SendChatMessage(SF("%s passed for %s - Args: %s",messageType,event,factionName), "OFFICER");
                end

                -- This is the correct event so we will now check to see if
                -- the reputation found is inside our faction index. If it is
                -- then we can tell it to change the watched faction

                if (factionName == "Guild") then
                    if (RepSwapDB.TestMode) then
                        RepSwap:MessageUser("FactionName provided was 'Guild'.");
                    end
                    RepSwap:TestModeMessage("factionName provided was 'Guild'.");
                    factionName = RepSwap.PlayerGuildName;
                end

                RepSwap:UpdateWatchedFaction(factionName);
                RepSwap:AddSessionReputation(factionName, reputationGain);
            end
        end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        -- Check to see if the player is in a guild so we can setup different rules for it
        RepSwap.IsInGuild = IsInGuild();
        if (RepSwap.IsInGuild) then
            RepSwap.PlayerGuildName = GetGuildInfo("player");
            if (RepSwapDB.TestMode) then
                RepSwap:MessageUser(SF("Player's Guild Name: %s", RepSwap.PlayerGuildName));
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
            if (RepSwapDB.TestMode) then
                RepSwap:MessageUser(SF("Player's Guild Name: %s", RepSwap.PlayerGuildName));
            end
        else
            if (RepSwapDB.TestMode) then
                RepSwap:MessageUser(SF("Resetting Guild Name: %s", RepSwap.PlayerGuildName));
            end
            RepSwap.PlayerGuildName = "";
        end
    elseif (event == "ADDON_LOADED") then
        local LoadedAddonName = ...;
        if (RepSwapDB.TestMode) then
            RepSwap:MessageUser(SF("LoadedAddonName is %s", LoadedAddonName));
        end
        if (LoadedAddonName == AddonName) then
            if (RepSwap.Version == "@project-version@") then
                RepSwap.Version = "Development";
            end
            if (RepSwap.Author == "@project-author@") then
                RepSwap.Author = "Fluxflashor (Local)";
            end
            RepSwap:MessageUser(SF(L["ADDON_LOADED"], RepSwap.Version, RepSwap.Author));
            if (RepSwapDB.TestMode) then
                RepSwap:MessageUser(SF("%s is %s.", LoadedAddonName, AddonName));
            end
            if (RepSwapDB.AddOnDisabled) then
                if (RepSwapDB.TestMode) then
                    RepSwap:MessageUser("Unregistering Events.");
                end
                if (not RepSwapDB.SuppressWarnings) then
                    RepSwap:WarnUser(L["WARN_ADDON_DISABLED"]);
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
            local FactionStandingLabel = _G["FACTION_STANDING_LABEL"..FactionStandingId];
            local ReputationEarnedForThisStandingId = TotalReputationEarned - ReputationMin;
            local ReputationCapForThisStandingId = ReputationMax - TotalReputationEarned + ReputationEarnedForThisStandingId;
            local ReputationToReachNextStandingId = ReputationCapForThisStandingId - ReputationEarnedForThisStandingId;

            if (RepSwapDB.LDBDisplayPercent) then
                PercentEarnedForThisStandingId = floor(ReputationEarnedForThisStandingId * 100 / ReputationCapForThisStandingId);
                RepSwapLDB.text = SF("%s - %s: %s%%", FactionName, FactionStandingLabel, PercentEarnedForThisStandingId);
            else
                RepSwapLDB.text = SF("%s - %s: %s/%s", FactionName, FactionStandingLabel, ReputationEarnedForThisStandingId, ReputationCapForThisStandingId);
            end
        end
    end
end
RepSwap:Initialize();
