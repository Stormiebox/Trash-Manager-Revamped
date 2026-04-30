if onServer() then
    local entity = Entity()
    if not entity then return end

    -- Attach TrashMan only to player-owned ships & stations.
    -- This avoids broad attachment to unrelated entities and reduces script index mismatch noise.
    if not entity.aiOwned and (entity.isShip or entity.isStation) and entity.playerOwned then
        entity:addScriptOnce("data/scripts/entity/TrashMan.lua")
    end
end
