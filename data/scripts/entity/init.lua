if onServer() then
    local entity = Entity()
    if not entity then
        return
    end

    -- Stormbox: Add TrashMan.lua to all ships, stations, and drones you pilot (including Alliance)
    if not entity.aiOwned and (entity.isShip or entity.isStation or entity.isDrone) and (entity.playerOwned or entity.allianceOwned) then
        entity:addScriptOnce("data/scripts/entity/TrashMan.lua")
    end
end
