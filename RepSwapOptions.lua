local L = RepSwapL;

local options = {};
options.main = CreateFrame("Frame", "MyAddonPanel", UIParent);
options.main.name = L["TITLE"];
InterfaceOptions_AddCategory(options.main);

local title = options.main:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
title:SetPoint("TOPLEFT", 16, -16);
title:SetText(L["TITLE"]);

local desc = options.main:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
desc:SetPoint("TOPLEFT", 16, -32);
desc:SetText(L["DESCRIPTION"]);
desc:SetTextColor(0, 0, 0, 1);
