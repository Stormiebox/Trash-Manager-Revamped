package.path = package.path .. ";data/scripts/lib/?.lua"

include ("stringutility")
include ("utility")
include ("callable")
local SellableInventoryItem = include ("sellableinventoryitem")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TrashMan
TrashMan = {}

local systemsBox
local minTechBox
local maxTechBox
local checkBoxes = {}
local checkBoxAllianz = {}
local listBoxes = {}
local previewLabel
local grey = ColorRGB(.3,.3,.3)

local function addLine(matType, px, py, tooltip)
    local material = Material(matType)
    checkBoxes[matType] = window:createCheckBox(Rect(px, py, px + 20, py + 20), "", "")
    local label = window:createLabel(vec2(px + 25, py),  material.name, 15)
    label.color = material.color

    listBoxes[matType] = window:createComboBox(Rect(px + 150, py, px + 300, py + 20), "")
    for rType = RarityType.Petty, RarityType.Legendary do
        local rarity = Rarity(rType)
        listBoxes[matType]:addEntry(rarity.name)
    end
end

function TrashMan.getIcon()
    return "data/textures/icons/trash-can.png"
end

function TrashMan.interactionPossible(playerIndex, option)
    local self = Entity()
    local player = Player(playerIndex)

    local craft = player.craft
    if craft == nil then return false end

    -- Trash Man is accessible only when player is in the entity
    if craft.index == self.index then
        return true
    end

    return false
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function TrashMan.initUI()
    local res = getResolution();
    local size = vec2(460, 540)
    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Trash Man"%_t);

    window.caption = "Trash Man"%_t
    window.showCloseButton = 1
    window.moveable = 1
    window.clickThrough = 0

    local hsplit = UIHorizontalSplitter(Rect(vec2(), size), 10, 10, 0.5)
    hsplit.bottomSize = 30
    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)

    local column1 = 10
    local column2 = 30
    local py = 10
    local lineHeight = 20
    local pyDelta = 30

    -- Systems To Trash
    window:createLabel(vec2(column1, py),  "Systems to trash"%_t, 15)
    py = py + pyDelta
    systemsBox = window:createComboBox(Rect(column2, py, column2 + 300, py + lineHeight), "")
    systemsBox:addEntry("None"%_t)
    for rType = RarityType.Petty, RarityType.Legendary do
        local rarity = Rarity(rType)
        systemsBox:addEntry(rarity.name)
    end
    py = py + pyDelta

    -- Turrets to Trash
    window:createLabel(vec2(column1, py),  "Turrets to trash"%_t, 15)
    py = py + pyDelta

    for materialNumber = MaterialType.Iron, MaterialType.Avorion do
        addLine(materialNumber, column2, py)
        py = py + pyDelta
    end

    -- private // alliance
    checkBoxAllianz[0] = window:createCheckBox(Rect(column2, py, column2 + 20, py + 20), "", "")
    window:createLabel(vec2(column2 + 25, py), "Alliance", 15)
    py = py + pyDelta

    local qFrame = window:createFrame(Rect(380, 10, 400, 30))
    local qLabel = window:createLabel(vec2(380, 10), " ?", 15)

    qLabel.tooltip = "Select which types of inventory items to mark as trash. These items will not be destroyed or immediately sold. Instead, the next time you visit the appropriate merchant they can be sold with the merchant's 'Sell Trash' button.\nItems that are marked as favorites will not get marked for trash!"%_t

    local button1Rect = Rect(column2, py, column2 + 120, py + 32)
    local button2Rect = Rect(column2 + 130, py, column2 + 250, py + 32)
    local button3Rect = Rect(column2 + 260, py, column2 + 380, py + 32)

    local button1 = window:createButton(button1Rect, "Mark"%_t, "onMarkTrashPressed")
    local button2 = window:createButton(button2Rect, "Unmark"%_t, "onUnmarkAllPressed")
    local button3 = window:createButton(button3Rect, "Preview"%_t, "onPreviewTrashPressed")
    button1.maxTextSize = 15
    button2.maxTextSize = 15
    button3.maxTextSize = 15
    py = py + pyDelta + 8

    previewLabel = window:createLabel(vec2(column2, py), "Preview: not run yet"%_t, 15)
    previewLabel.color = ColorRGB(1, 1, 1)
    py = py + pyDelta + 8

    window:createLabel(vec2(column1, py), "Tech level filter (optional)"%_t, 15)
    py = py + pyDelta
    minTechBox = window:createComboBox(Rect(column2, py, column2 + 170, py + lineHeight), "")
    maxTechBox = window:createComboBox(Rect(column2 + 180, py, column2 + 350, py + lineHeight), "")
    minTechBox:addEntry("Min: 1"%_t)
    maxTechBox:addEntry("Max: 52"%_t)
    for i = 1, 52 do
        minTechBox:addEntry("Min: " .. i)
        maxTechBox:addEntry("Max: " .. i)
    end
end

local function getItemTechLevel(sItem)
    if not sItem or not sItem.item then return nil end
    local item = sItem.item

    if (item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate) and item.averageTech then
        return round(item.averageTech, 1)
    end

    if item.getValue and item:getValue("tech") then
        return item:getValue("tech")
    end

    return nil
end

local function canTrashByFilters(sItem, systemRarity, turretRarities, minTech, maxTech)
    if not sItem or not sItem.item then return false end
    local item = sItem.item

    if item.itemType == InventoryItemType.VanillaItem then
        return false
    end

    local rarity = sItem.rarity and sItem.rarity.value or nil
    if rarity == nil then return false end

    local tech = getItemTechLevel(sItem)
    if minTech and tech and tech < minTech then return false end
    if maxTech and tech and tech > maxTech then return false end

    if item.itemType == InventoryItemType.SystemUpgrade then
        return rarity <= (systemRarity or -1)
    end

    if sItem.material ~= nil then
        local material = sItem.material.value
        local selectedMaxRarity = turretRarities and turretRarities[material]
        if selectedMaxRarity == nil then return false end
        return rarity <= selectedMaxRarity
    end

    return false
end

local function processTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech, applyChanges)
    local itemsMatched = 0
    if not inv then return itemsMatched end

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if (iitem ~= nil) and (not iitem.trash) and (not iitem.favorite) then
            local sItem = SellableInventoryItem(iitem, index, buyer)
            if canTrashByFilters(sItem, systemRarity, turretRarities, minTech, maxTech) then
                local amount = inv:amount(index)
                itemsMatched = itemsMatched + amount

                if applyChanges then
                    iitem.trash = true
                    inv:removeAll(index)
                    inv:addAt(iitem, index, amount)
                end
            end
        end
    end

    return itemsMatched
end

local function markTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech)
    return processTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech, true)
end

local function previewTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech)
    return processTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech, false)
end

-- private-start
function TrashMan.onMarkTrashPressedServer1(systemRarity, turretRarities, minTech, maxTech)
    if onClient() then return end

    local player = Player(callingPlayer)
    if not player then return end

    local inv = player:getInventory()
    local itemsMarked = markTrashInInventory(inv, player, systemRarity, turretRarities, minTech, maxTech)

    player:sendChatMessage("Server", 0, itemsMarked .. " items have been marked as trash (private).")
end
callable(TrashMan, "onMarkTrashPressedServer1")

function TrashMan.onUnmarkAllPressedServer1()
    if onClient() then return end

    local player = Player(callingPlayer)
    if not player then return end

    local itemsMarked = 0
    local inv = player:getInventory()
    local totalItems = 0

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem ~= nil then
            local amount = inv:amount(index)
            totalItems = totalItems + amount

            if iitem.trash then
                iitem.trash = false
                inv:removeAll(index)
                inv:addAt(iitem, index, amount)
                itemsMarked = itemsMarked + amount
            end
        end
    end

    player:sendChatMessage("Server", 0, itemsMarked .. " of " .. totalItems .. " items are no longer marked for trash (private).")
end
callable(TrashMan, "onUnmarkAllPressedServer1")
-- private-end

-- allianz-start
function TrashMan.onMarkTrashPressedServer2(systemRarity, turretRarities, minTech, maxTech)
    if onClient() then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems)
    if not buyer then
        Player(callingPlayer):sendChatMessage("Server", 1, "Missing alliance permissions to modify alliance trash items.")
        return
    end

    local inv = buyer:getInventory()
    local itemsMarked = markTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech)

    Player(callingPlayer):sendChatMessage("Server", 0, itemsMarked .. " items have been marked as trash (alliance).")
end
callable(TrashMan, "onMarkTrashPressedServer2")

function TrashMan.onPreviewTrashPressedServer1(systemRarity, turretRarities, minTech, maxTech)
    if onClient() then return end

    local player = Player(callingPlayer)
    if not player then return end

    local inv = player:getInventory()
    local itemsMatched = previewTrashInInventory(inv, player, systemRarity, turretRarities, minTech, maxTech)

    invokeClientFunction(player, "onPreviewResultReceived", itemsMatched, false)
end
callable(TrashMan, "onPreviewTrashPressedServer1")

function TrashMan.onPreviewTrashPressedServer2(systemRarity, turretRarities, minTech, maxTech)
    if onClient() then return end

    local player = Player(callingPlayer)
    if not player then return end

    local buyer, ship, _ = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems)
    if not buyer then
        player:sendChatMessage("Server", 1, "Missing alliance permissions to preview alliance trash items.")
        invokeClientFunction(player, "onPreviewResultReceived", 0, true)
        return
    end

    local inv = buyer:getInventory()
    local itemsMatched = previewTrashInInventory(inv, buyer, systemRarity, turretRarities, minTech, maxTech)

    invokeClientFunction(player, "onPreviewResultReceived", itemsMatched, true)
end
callable(TrashMan, "onPreviewTrashPressedServer2")

function TrashMan.onUnmarkAllPressedServer2()
    if onClient() then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendItems)
    if not buyer then return end

    local itemsMarked = 0
    local inv = buyer:getInventory()
    local totalItems = 0

    for index, slotItem in pairs(inv:getItems()) do
        local iitem = slotItem.item
        if iitem ~= nil then
            local amount = inv:amount(index)
            totalItems = totalItems + amount

            if iitem.trash then
                iitem.trash = false
                inv:removeAll(index)
                inv:addAt(iitem, index, amount)
                itemsMarked = itemsMarked + amount
            end
        end
    end

    Player(callingPlayer):sendChatMessage("Server", 0, itemsMarked .. " of " .. totalItems .. " items are no longer marked for trash (alliance).")
end
callable(TrashMan, "onUnmarkAllPressedServer2")
-- allianz-end

local function buildFilterRequest()
    local turretRarities = {}

    for mat = MaterialType.Iron, MaterialType.Avorion do
        if checkBoxes[mat].checked then
            turretRarities[mat] = listBoxes[mat].selectedIndex - 1
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

    return (systemsBox.selectedIndex - 2), turretRarities, minTech, maxTech
end

function TrashMan.onPreviewResultReceived(itemsMatched, allianceMode)
    if not previewLabel then return end
    local scope = allianceMode and "alliance" or "private"
    previewLabel.caption = string.format("Preview: %d items would be marked (%s)", itemsMatched or 0, scope)
end

function TrashMan.onPreviewTrashPressed()
    local systemRarity, turretRarities, minTech, maxTech = buildFilterRequest()
    if checkBoxAllianz[0].checked then
        invokeServerFunction("onPreviewTrashPressedServer2", systemRarity, turretRarities, minTech, maxTech)
    else
        invokeServerFunction("onPreviewTrashPressedServer1", systemRarity, turretRarities, minTech, maxTech)
    end
end

function TrashMan.onMarkTrashPressed()
    local systemRarity, turretRarities, minTech, maxTech = buildFilterRequest()

    if checkBoxAllianz[0].checked then
        invokeServerFunction("onMarkTrashPressedServer2", systemRarity, turretRarities, minTech, maxTech)
    else
        invokeServerFunction("onMarkTrashPressedServer1", systemRarity, turretRarities, minTech, maxTech)
    end
end

function TrashMan.onUnmarkAllPressed()
    if checkBoxAllianz[0].checked then
        invokeServerFunction("onUnmarkAllPressedServer2")
    else
        invokeServerFunction("onUnmarkAllPressedServer1")
    end
end
