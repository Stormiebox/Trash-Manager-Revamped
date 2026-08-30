package.path = package.path .. ";data/scripts/lib/?.lua"

include("stringutility")
include("utility")
include("callable")
local SellableInventoryItem = include("sellableinventoryitem")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TrashMan
TrashMan = {}

-- Client-side UI element handles
local systemsBox
local minTechBox
local maxTechBox
local checkBoxes    = {}
local checkBoxAllianz = {}
local listBoxes     = {}
local checkBoxTurrets
local checkBoxSystems
local checkBoxTemplates
local previewLabel
local statsLabel
local presetLabels  = {}

local NUM_PRESETS       = 3
local PRESET_KEY_PREFIX = "TMR_Preset_"

local function addMaterialRow(matType, px, py)
    local material = Material(matType)
    checkBoxes[matType] = window:createCheckBox(Rect(px, py, px + 20, py + 20), "", "")
    local lbl = window:createLabel(vec2(px + 25, py), material.name, 15)
    lbl.color = material.color
    listBoxes[matType] = window:createComboBox(Rect(px + 150, py, px + 330, py + 20), "")
    for rType = RarityType.Petty, RarityType.Legendary do
        listBoxes[matType]:addEntry(Rarity(rType).name)
    end
end

function TrashMan.getIcon()
    return "data/textures/icons/trash-can.png"
end

function TrashMan.interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local craft  = player.craft
    if craft == nil then return false end
    return craft.index == Entity().index
end

function TrashMan.initUI()
    local res  = getResolution()
    local size = vec2(510, 817)
    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Trash Man"%_t)

    window.caption         = "Trash Man"%_t
    window.showCloseButton = 1
    window.moveable        = 1
    window.clickThrough    = 0

    local c1 = 10
    local c2 = 30
    local py = 10
    local lh = 20
    local dy = 30

    -- Inventory stats bar
    statsLabel = window:createLabel(vec2(c1, py), "Inventory: loading..."%_t, 14)
    statsLabel.color = ColorRGB(0.55, 0.85, 1.0)
    py = py + dy

    window:createFrame(Rect(c1, py, 492, py + 2))
    py = py + 10

    -- Item type toggles
    window:createLabel(vec2(c1, py), "Item Types to Mark"%_t, 15)
    py = py + dy

    checkBoxTurrets = window:createCheckBox(Rect(c2, py, c2 + 20, py + 20), "", "")
    checkBoxTurrets.checked = true
    window:createLabel(vec2(c2 + 25, py), "Turrets"%_t, 14)

    checkBoxSystems = window:createCheckBox(Rect(c2 + 135, py, c2 + 155, py + 20), "", "")
    checkBoxSystems.checked = true
    window:createLabel(vec2(c2 + 160, py), "Systems"%_t, 14)

    checkBoxTemplates = window:createCheckBox(Rect(c2 + 270, py, c2 + 290, py + 20), "", "")
    checkBoxTemplates.checked = true
    window:createLabel(vec2(c2 + 295, py), "Templates"%_t, 14)
    py = py + dy

    window:createFrame(Rect(c1, py, 492, py + 2))
    py = py + 10

    -- System upgrade rarity
    window:createLabel(vec2(c1, py), "Systems to trash"%_t, 15)
    py = py + dy
    systemsBox = window:createComboBox(Rect(c2, py, c2 + 300, py + lh), "")
    systemsBox:addEntry("None"%_t)
    for rType = RarityType.Petty, RarityType.Legendary do
        systemsBox:addEntry(Rarity(rType).name)
    end
    py = py + dy

    -- Per-material turret rarity
    window:createLabel(vec2(c1, py), "Turrets to trash"%_t, 15)
    py = py + dy
    for mat = MaterialType.Iron, MaterialType.Avorion do
        addMaterialRow(mat, c2, py)
        py = py + dy
    end

    -- Alliance toggle
    checkBoxAllianz[0] = window:createCheckBox(Rect(c2, py, c2 + 20, py + 20), "", "")
    window:createLabel(vec2(c2 + 25, py), "Alliance Inventory"%_t, 15)

    local qLabel = window:createLabel(vec2(435, py), " ?", 15)
    qLabel.tooltip = "Select which types of inventory items to mark as trash. These items will not be destroyed or immediately sold. Instead, the next time you visit the appropriate merchant they can be sold with the merchant's Sell Trash button.\nItems marked as favorites will not be trashed!\n\nTemplates: Turret blueprints stored in inventory.\nUnmark Filter: Unmarks only items that match your active filters."%_t
    py = py + dy

    -- Action buttons
    local bw = 106
    local bg = 6
    window:createButton(Rect(c2,           py, c2+bw,        py+32), "Mark"%_t,          "onMarkTrashPressed").maxTextSize      = 13
    window:createButton(Rect(c2+bw+bg,     py, c2+bw*2+bg,   py+32), "Unmark All"%_t,    "onUnmarkAllPressed").maxTextSize      = 13
    window:createButton(Rect(c2+bw*2+bg*2, py, c2+bw*3+bg*2, py+32), "Unmark Filter"%_t, "onUnmarkFilteredPressed").maxTextSize = 13
    window:createButton(Rect(c2+bw*3+bg*3, py, c2+bw*4+bg*3, py+32), "Preview"%_t,       "onPreviewTrashPressed").maxTextSize   = 13
    py = py + dy + 4

    -- Consolidate button (full width, always private->alliance)
    local consolidateBtn = window:createButton(Rect(c2, py, c2 + 452, py + 32), "Consolidate Inventory to Vault"%_t, "onConsolidatePressed")
    consolidateBtn.maxTextSize = 14
    consolidateBtn.tooltip = "Transfers all unequipped, non-favorite turrets, blueprints, and subsystems from your private inventory directly into the Alliance Vault. Requires alliance membership. Items that are already equipped are not affected."%_t
    py = py + dy + 10

    -- Preview result label
    previewLabel = window:createLabel(vec2(c2, py), "Preview: not run yet"%_t, 14)
    previewLabel.color = ColorRGB(1.0, 1.0, 1.0)
    py = py + dy

    window:createFrame(Rect(c1, py, 492, py + 2))
    py = py + 10

    -- Tech level filter
    window:createLabel(vec2(c1, py), "Tech Level Filter (optional)"%_t, 15)
    py = py + dy
    minTechBox = window:createComboBox(Rect(c2,       py, c2 + 170, py + lh), "")
    maxTechBox = window:createComboBox(Rect(c2 + 180, py, c2 + 350, py + lh), "")
    minTechBox:addEntry("Min: 1"%_t)
    maxTechBox:addEntry("Max: 52"%_t)
    for i = 1, 52 do
        minTechBox:addEntry("Min: " .. i)
        maxTechBox:addEntry("Max: " .. i)
    end
    py = py + dy

    window:createFrame(Rect(c1, py, 492, py + 2))
    py = py + 10

    -- Filter presets
    window:createLabel(vec2(c1, py), "Filter Presets"%_t, 15)
    py = py + dy
    for i = 1, NUM_PRESETS do
        window:createButton(Rect(c2,      py, c2+90,  py+28), "Save #"..i, "onSavePreset"..i).maxTextSize = 13
        window:createButton(Rect(c2+98,   py, c2+188, py+28), "Load #"..i, "onLoadPreset"..i).maxTextSize = 13
        presetLabels[i] = window:createLabel(vec2(c2+200, py+6), "- empty -", 13)
        presetLabels[i].color = ColorRGB(0.45, 0.45, 0.45)
        py = py + dy + 5
    end

    invokeServerFunction("onRequestInitialData")
end

local function canTrashByFilters(sItem, systemRarity, turretRarities, minTech, maxTech, types)
    if not sItem or not sItem.item then return false end
    local item = sItem.item

    if item.itemType == InventoryItemType.VanillaItem then return false end

    local rarity = sItem.rarity and sItem.rarity.value
    if rarity == nil then return false end

    local tech = sItem.tech
    if minTech and tech and tech < minTech then return false end
    if maxTech and tech and tech > maxTech then return false end

    if item.itemType == InventoryItemType.SystemUpgrade then
        if types and not types.systems then return false end
        return rarity <= (systemRarity or -1)
    end

    if item.itemType == InventoryItemType.TurretTemplate then
        if types and not types.templates then return false end
        if sItem.material ~= nil then
            local maxRarity = turretRarities and turretRarities[sItem.material.value]
            if maxRarity == nil then return false end
            return rarity <= maxRarity
        end
        return false
    end

    if sItem.material ~= nil then
        if types and not types.turrets then return false end
        local maxRarity = turretRarities and turretRarities[sItem.material.value]
        if maxRarity == nil then return false end
        return rarity <= maxRarity
    end

    return false
end

local function processTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech, types, applyChanges)
    local counts = { turrets = 0, systems = 0, templates = 0, total = 0 }
    if not inv then return counts end

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem and not iitem.trash and not iitem.favorite then
            local sItem = SellableInventoryItem(iitem, index, buyer)
            if canTrashByFilters(sItem, systemRarity, turretRarities, minTech, maxTech, types) then
                local amount = inv:amount(index)
                counts.total = counts.total + amount

                if iitem.itemType == InventoryItemType.SystemUpgrade then
                    counts.systems = counts.systems + amount
                elseif iitem.itemType == InventoryItemType.TurretTemplate then
                    counts.templates = counts.templates + amount
                else
                    counts.turrets = counts.turrets + amount
                end

                if applyChanges then
                    iitem.trash = true
                    inv:removeAll(index)
                    inv:addAt(iitem, index, amount)
                end
            end
        end
    end

    return counts
end

local function processUnmarkFilteredInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech, types)
    local count = 0
    if not inv then return count end

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem and iitem.trash then
            local sItem = SellableInventoryItem(iitem, index, buyer)
            if canTrashByFilters(sItem, systemRarity, turretRarities, minTech, maxTech, types) then
                local amount = inv:amount(index)
                iitem.trash = false
                inv:removeAll(index)
                inv:addAt(iitem, index, amount)
                count = count + amount
            end
        end
    end

    return count
end

local function getInventoryStats(inv)
    local total, trash, favorites = 0, 0, 0
    if not inv then return total, trash, favorites end

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem then
            local amount = inv:amount(index)
            total     = total     + amount
            if iitem.trash    then trash     = trash     + amount end
            if iitem.favorite then favorites = favorites + amount end
        end
    end

    return total, trash, favorites
end

local function presetKey(slot)
    return PRESET_KEY_PREFIX .. tostring(slot)
end

local function savePlayerPreset(player, slot, data)
    local ok = pcall(function() player:setValue(presetKey(slot), data) end)
    return ok
end

local function loadPlayerPreset(player, slot)
    local ok, val = pcall(function() return player:getValue(presetKey(slot)) end)
    if ok then return val end
    return nil
end

-- private-start
function TrashMan.onMarkTrashPressedServer1(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local inv    = player:getInventory()
    local counts = processTrashInInventory(inv, player, systemRarity, turretRarities, minTech, maxTech, types, true)

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d items marked as trash (private): %d turret(s), %d system(s), %d template(s).",
        counts.total, counts.turrets, counts.systems, counts.templates))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onMarkTrashPressedServer1")

function TrashMan.onUnmarkAllPressedServer1()
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local inv      = player:getInventory()
    local cleared  = 0
    local total_i  = 0

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem then
            local amount = inv:amount(index)
            total_i = total_i + amount
            if iitem.trash then
                iitem.trash = false
                inv:removeAll(index)
                inv:addAt(iitem, index, amount)
                cleared = cleared + amount
            end
        end
    end

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d of %d items untrashed (private).", cleared, total_i))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onUnmarkAllPressedServer1")

function TrashMan.onUnmarkFilteredPressedServer1(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local inv   = player:getInventory()
    local count = processUnmarkFilteredInInventory(inv, player, systemRarity, turretRarities, minTech, maxTech, types)

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d item(s) untrashed by active filter (private).", count))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onUnmarkFilteredPressedServer1")

function TrashMan.onPreviewTrashPressedServer1(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local inv    = player:getInventory()
    local counts = processTrashInInventory(inv, player, systemRarity, turretRarities, minTech, maxTech, types, false)

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
    invokeClientFunction(player, "onPreviewResultReceived",
        counts.total, counts.systems, counts.turrets, counts.templates, false)
end

callable(TrashMan, "onPreviewTrashPressedServer1")
-- private-end

-- allianz-start
local function resolveAlliance(player)
    if not player.alliance then
        player:sendChatMessage("Server", 1, "[Trash Manager] You are not in an alliance.")
        return nil
    end
    local alliance = Alliance(player.allianceIndex)
    if not alliance then
        player:sendChatMessage("Server", 1, "[Trash Manager] Alliance inventory is not accessible right now.")
        return nil
    end
    return alliance
end

function TrashMan.onMarkTrashPressedServer2(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player   = Player(callingPlayer)
    if not player  then return end
    local alliance = resolveAlliance(player)
    if not alliance then return end

    local inv    = alliance:getInventory()
    local counts = processTrashInInventory(inv, alliance, systemRarity, turretRarities, minTech, maxTech, types, true)

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d items marked as trash (alliance): %d turret(s), %d system(s), %d template(s).",
        counts.total, counts.turrets, counts.systems, counts.templates))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onMarkTrashPressedServer2")

function TrashMan.onUnmarkAllPressedServer2()
    if onClient() then return end
    local player   = Player(callingPlayer)
    if not player  then return end
    local alliance = resolveAlliance(player)
    if not alliance then return end

    local inv      = alliance:getInventory()
    local cleared  = 0
    local total_i  = 0

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem then
            local amount = inv:amount(index)
            total_i = total_i + amount
            if iitem.trash then
                iitem.trash = false
                inv:removeAll(index)
                inv:addAt(iitem, index, amount)
                cleared = cleared + amount
            end
        end
    end

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d of %d items untrashed (alliance).", cleared, total_i))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onUnmarkAllPressedServer2")

function TrashMan.onUnmarkFilteredPressedServer2(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player   = Player(callingPlayer)
    if not player  then return end
    local alliance = resolveAlliance(player)
    if not alliance then return end

    local inv   = alliance:getInventory()
    local count = processUnmarkFilteredInInventory(inv, alliance, systemRarity, turretRarities, minTech, maxTech, types)

    player:sendChatMessage("Server", 0, string.format(
        "[Trash Manager] %d item(s) untrashed by active filter (alliance).", count))

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onUnmarkFilteredPressedServer2")

function TrashMan.onPreviewTrashPressedServer2(systemRarity, turretRarities, minTech, maxTech, types)
    if onClient() then return end
    local player   = Player(callingPlayer)
    if not player  then return end
    local alliance = resolveAlliance(player)

    if not alliance then
        invokeClientFunction(player, "onPreviewResultReceived", 0, 0, 0, 0, true)
        return
    end

    local inv    = alliance:getInventory()
    local counts = processTrashInInventory(inv, alliance, systemRarity, turretRarities, minTech, maxTech, types, false)

    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
    invokeClientFunction(player, "onPreviewResultReceived",
        counts.total, counts.systems, counts.turrets, counts.templates, true)
end

callable(TrashMan, "onPreviewTrashPressedServer2")
-- allianz-end

function TrashMan.onRequestInitialData()
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local inv = player:getInventory()
    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)

    local s1 = loadPlayerPreset(player, 1)
    local s2 = loadPlayerPreset(player, 2)
    local s3 = loadPlayerPreset(player, 3)
    invokeClientFunction(player, "onPresetsStatusReceived",
        s1 ~= nil and s1 ~= "",
        s2 ~= nil and s2 ~= "",
        s3 ~= nil and s3 ~= "")
end

callable(TrashMan, "onRequestInitialData")

function TrashMan.onSavePresetServer(slot, data)
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    if type(slot) ~= "number" or slot < 1 or slot > NUM_PRESETS then return end
    if type(data) ~= "string" or data == "" then return end

    local ok = savePlayerPreset(player, slot, data)
    if ok then
        invokeClientFunction(player, "onPresetSaved", slot)
        player:sendChatMessage("Server", 0, "[Trash Manager] Filter preset #" .. slot .. " saved.")
    else
        player:sendChatMessage("Server", 1, "[Trash Manager] Could not save preset #" .. slot .. " (storage unavailable).")
    end
end

callable(TrashMan, "onSavePresetServer")

function TrashMan.onLoadPresetServer(slot)
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    if type(slot) ~= "number" or slot < 1 or slot > NUM_PRESETS then return end

    local data = loadPlayerPreset(player, slot)
    if data and data ~= "" then
        invokeClientFunction(player, "onPresetLoaded", slot, data)
        player:sendChatMessage("Server", 0, "[Trash Manager] Filter preset #" .. slot .. " loaded.")
    else
        player:sendChatMessage("Server", 1, "[Trash Manager] Preset #" .. slot .. " is empty.")
    end
end

callable(TrashMan, "onLoadPresetServer")

-- consolidate-start
function TrashMan.onConsolidateServer()
    if onClient() then return end
    local player = Player(callingPlayer)
    if not player then return end

    local alliance = resolveAlliance(player)
    if not alliance then return end

    local inv        = player:getInventory()
    local allianceInv = alliance:getInventory()
    local moved      = 0
    local dropped    = 0

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem ~= nil and not iitem.favorite then
            local itype = iitem.itemType
            if itype == InventoryItemType.Turret
                or itype == InventoryItemType.TurretTemplate
                or itype == InventoryItemType.SystemUpgrade then

                local amount = inv:amount(index)
                inv:removeAll(index)

                for _ = 1, amount do
                    -- addOrDrop: safely adds to alliance inventory;
                    -- drops the item in space near the ship if the vault is completely full.
                    local added = allianceInv:addOrDrop(iitem)
                    if added then
                        moved = moved + 1
                    else
                        dropped = dropped + 1
                    end
                end
            end
        end
    end

    local msg = string.format("[Trash Manager] %d item(s) consolidated to Alliance Vault.", moved)
    if dropped > 0 then
        msg = msg .. string.format(" %d item(s) dropped in space (vault full).", dropped)
    end
    player:sendChatMessage("Server", 0, msg)

    -- Refresh the private inventory stats on the client.
    local total, trash, favorites = getInventoryStats(inv)
    invokeClientFunction(player, "onInventoryStatsReceived", total, trash, favorites)
end

callable(TrashMan, "onConsolidateServer")
-- consolidate-end

local function buildFilterRequest()
    local turretRarities = {}
    for mat = MaterialType.Iron, MaterialType.Avorion do
        if checkBoxes[mat] and checkBoxes[mat].checked then
            turretRarities[mat] = listBoxes[mat].selectedIndex
        end
    end

    local minTech = nil
    local maxTech = nil
    if minTechBox and minTechBox.selectedIndex > 0 then
        minTech = minTechBox.selectedIndex
    end
    if maxTechBox and maxTechBox.selectedIndex > 0 then
        maxTech = maxTechBox.selectedIndex
    end

    local types = {
        turrets   = checkBoxTurrets   and checkBoxTurrets.checked   or false,
        systems   = checkBoxSystems   and checkBoxSystems.checked   or false,
        templates = checkBoxTemplates and checkBoxTemplates.checked or false,
    }

    -- selectedIndex 0 = "None" -> -1 (no systems).
    -- selectedIndex 1 = Petty (value 0) -> rarity <= 0 marks Petty.
    local sysRarity = systemsBox.selectedIndex - 1

    return sysRarity, turretRarities, minTech, maxTech, types
end

local function serializeUIState()
    local parts = {}
    parts[#parts+1] = tostring(systemsBox.selectedIndex)
    parts[#parts+1] = (checkBoxAllianz[0] and checkBoxAllianz[0].checked) and "1" or "0"
    parts[#parts+1] = (checkBoxTurrets   and checkBoxTurrets.checked)     and "1" or "0"
    parts[#parts+1] = (checkBoxSystems   and checkBoxSystems.checked)     and "1" or "0"
    parts[#parts+1] = (checkBoxTemplates and checkBoxTemplates.checked)   and "1" or "0"
    parts[#parts+1] = tostring(minTechBox and minTechBox.selectedIndex or 0)
    parts[#parts+1] = tostring(maxTechBox and maxTechBox.selectedIndex or 0)
    for mat = MaterialType.Iron, MaterialType.Avorion do
        local cb = checkBoxes[mat]
        local lb = listBoxes[mat]
        parts[#parts+1] = ((cb and cb.checked) and "1" or "0") .. "|" .. tostring(lb and lb.selectedIndex or 0)
    end
    return table.concat(parts, ",")
end

local function applyUIState(data)
    if not data or data == "" then return end
    local parts = {}
    for v in data:gmatch("[^,]+") do parts[#parts+1] = v end
    local i = 0
    local function nextVal() i = i + 1; return parts[i] end

    if systemsBox then systemsBox.selectedIndex = tonumber(nextVal()) or 0 else nextVal() end
    if checkBoxAllianz[0] then checkBoxAllianz[0].checked = nextVal() == "1" else nextVal() end
    if checkBoxTurrets    then checkBoxTurrets.checked    = nextVal() == "1" else nextVal() end
    if checkBoxSystems    then checkBoxSystems.checked    = nextVal() == "1" else nextVal() end
    if checkBoxTemplates  then checkBoxTemplates.checked  = nextVal() == "1" else nextVal() end
    if minTechBox then minTechBox.selectedIndex = tonumber(nextVal()) or 0 else nextVal() end
    if maxTechBox then maxTechBox.selectedIndex = tonumber(nextVal()) or 0 else nextVal() end
    for mat = MaterialType.Iron, MaterialType.Avorion do
        local token = nextVal() or "0|0"
        local cbVal, lbVal = token:match("([^|]+)|([^|]+)")
        if checkBoxes[mat] then checkBoxes[mat].checked = cbVal == "1" end
        if listBoxes[mat]  then listBoxes[mat].selectedIndex = tonumber(lbVal) or 0 end
    end
end

function TrashMan.onInventoryStatsReceived(total, trash, favorites)
    if not statsLabel then return end
    statsLabel.caption = string.format(
        "Inventory: %d items   |   %d trash   |   %d favorites",
        total or 0, trash or 0, favorites or 0)
end

function TrashMan.onPreviewResultReceived(total, countSystems, countTurrets, countTemplates, allianceMode)
    if not previewLabel then return end
    local scope = allianceMode and "alliance" or "private"
    if (total or 0) == 0 then
        previewLabel.caption = string.format("Preview (%s): nothing would be marked.", scope)
        previewLabel.color   = ColorRGB(0.7, 0.7, 0.7)
    else
        previewLabel.caption = string.format(
            "Preview (%s): %d items -> %d turrets, %d systems, %d templates",
            scope, total, countTurrets or 0, countSystems or 0, countTemplates or 0)
        previewLabel.color = ColorRGB(1.0, 0.85, 0.4)
    end
end

function TrashMan.onPresetsStatusReceived(s1, s2, s3)
    local status = { s1, s2, s3 }
    for i = 1, NUM_PRESETS do
        if presetLabels[i] then
            if status[i] then
                presetLabels[i].caption = "* Saved"
                presetLabels[i].color   = ColorRGB(0.35, 1.0, 0.45)
            else
                presetLabels[i].caption = "- empty -"
                presetLabels[i].color   = ColorRGB(0.45, 0.45, 0.45)
            end
        end
    end
end

function TrashMan.onPresetSaved(slot)
    if presetLabels[slot] then
        presetLabels[slot].caption = "* Saved"
        presetLabels[slot].color   = ColorRGB(0.35, 1.0, 0.45)
    end
end

function TrashMan.onPresetLoaded(slot, data)
    applyUIState(data)
    if previewLabel then
        previewLabel.caption = "Preset #" .. tostring(slot) .. " loaded - run Preview to confirm."
        previewLabel.color   = ColorRGB(0.6, 0.8, 1.0)
    end
end

function TrashMan.onConsolidatePressed()
    -- Consolidate is always a one-way transfer: private inventory -> alliance vault.
    -- It is not affected by the Alliance mode toggle (which controls trash marking scope).
    invokeServerFunction("onConsolidateServer")
end

function TrashMan.onMarkTrashPressed()
    local sr, tr, mn, mx, ty = buildFilterRequest()
    if checkBoxAllianz[0] and checkBoxAllianz[0].checked then
        invokeServerFunction("onMarkTrashPressedServer2", sr, tr, mn, mx, ty)
    else
        invokeServerFunction("onMarkTrashPressedServer1", sr, tr, mn, mx, ty)
    end
end

function TrashMan.onUnmarkAllPressed()
    if checkBoxAllianz[0] and checkBoxAllianz[0].checked then
        invokeServerFunction("onUnmarkAllPressedServer2")
    else
        invokeServerFunction("onUnmarkAllPressedServer1")
    end
end

function TrashMan.onUnmarkFilteredPressed()
    local sr, tr, mn, mx, ty = buildFilterRequest()
    if checkBoxAllianz[0] and checkBoxAllianz[0].checked then
        invokeServerFunction("onUnmarkFilteredPressedServer2", sr, tr, mn, mx, ty)
    else
        invokeServerFunction("onUnmarkFilteredPressedServer1", sr, tr, mn, mx, ty)
    end
end

function TrashMan.onPreviewTrashPressed()
    local sr, tr, mn, mx, ty = buildFilterRequest()
    if checkBoxAllianz[0] and checkBoxAllianz[0].checked then
        invokeServerFunction("onPreviewTrashPressedServer2", sr, tr, mn, mx, ty)
    else
        invokeServerFunction("onPreviewTrashPressedServer1", sr, tr, mn, mx, ty)
    end
end

function TrashMan.onSavePreset1() invokeServerFunction("onSavePresetServer", 1, serializeUIState()) end
function TrashMan.onSavePreset2() invokeServerFunction("onSavePresetServer", 2, serializeUIState()) end
function TrashMan.onSavePreset3() invokeServerFunction("onSavePresetServer", 3, serializeUIState()) end
function TrashMan.onLoadPreset1() invokeServerFunction("onLoadPresetServer", 1) end
function TrashMan.onLoadPreset2() invokeServerFunction("onLoadPresetServer", 2) end
function TrashMan.onLoadPreset3() invokeServerFunction("onLoadPresetServer", 3) end
