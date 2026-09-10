local tabletEntity = nil

function StartTabletAnimation()
    if not Config.Animation.Enable then return end
    local ped = PlayerPedId()

    -- Načtení animace
    lib.requestAnimDict(Config.Animation.Dict)
    lib.requestModel(Config.Animation.Prop)

    -- Vytvoření propu tabletu
    local coords = GetEntityCoords(ped)
    tabletEntity = CreateObject(GetHashKey(Config.Animation.Prop), coords.x, coords.y, coords.z, true, true, false)
    
    local bone = GetPedBoneIndex(ped, Config.Animation.Bone)
    local pos = Config.Animation.Pos
    local rot = Config.Animation.Rot

    AttachEntityToEntity(
        tabletEntity, 
        ped, 
        bone, 
        pos.x, pos.y, pos.z, 
        rot.x, rot.y, rot.z, 
        true, true, false, true, 1, true
    )

    TaskPlayAnim(ped, Config.Animation.Dict, Config.Animation.Anim, 3.0, 3.0, -1, 49, 0, false, false, false)
end

function StopTabletAnimation()
    local ped = PlayerPedId()
    if tabletEntity and DoesEntityExist(tabletEntity) then
        DeleteEntity(tabletEntity)
        tabletEntity = nil
    end

    if Config.Animation.Enable then
        StopAnimTask(ped, Config.Animation.Dict, Config.Animation.Anim, 2.0)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        StopTabletAnimation()
    end
end)
