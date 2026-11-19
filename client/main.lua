do
    local resName = GetCurrentResourceName()
    local author = tostring(GetResourceMetadata(resName, 'author', 0) or '')
    if resName ~= 'zodi4c-storage' or not string.find(string.lower(author), 'zodi4c', 1, true) then
        print('^1======================================================================^7')
        print('^1[zodi4c-storage] [TR] HATA: Kaynak adi veya yazar bilgisi degistirilmis!^7')
        print('^1[zodi4c-storage] [TR] Lutfen kaynak adini "zodi4c-storage" olarak geri adlandirin^7')
        print('^1[zodi4c-storage] [TR] ve fxmanifest.lua icindeki author bilgisini geri yukleyin.^7')
        print('^1[zodi4c-storage] [EN] ERROR: Resource name or author metadata was modified!^7')
        print('^1[zodi4c-storage] [EN] Please rename this resource back to "zodi4c-storage"^7')
        print('^1[zodi4c-storage] [EN] and restore the original Zodi4c author metadata.^7')
        print('^1[zodi4c-storage] Official source: https://github.com/zodi4ctvn^7')
        print('^1======================================================================^7')
        return
    end
end

local QBCore = exports['qb-core']:GetCoreObject()

local npcEntity = nil
local uiActive = false
local menuOpen = false

CreateThread(function()
    local model = Config.NPC.model
    if not IsModelInCdimage(model) then return end

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    npcEntity = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityHeading(npcEntity, Config.NPC.coords.w)
    FreezeEntityPosition(npcEntity, true)
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    SetModelAsNoLongerNeeded(model)
end)

CreateThread(function()
    while true do
        local sleep = 1500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local npcCoords = vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
        local distance = #(playerCoords - npcCoords)

        if distance < 10.0 then
            if not menuOpen and not IsNuiFocused() then
                if distance < Config.InteractionDistance then
                    sleep = 0

                    if not uiActive then
                        SendNUIMessage({
                            action = 'showInteraction',
                            text = L('interaction_text'),
                            key = L('press_e')
                        })
                        uiActive = true
                    end

                    if IsControlJustPressed(0, Config.MenuOpenKey) then
                        local playerData = QBCore.Functions.GetPlayerData()
                        local metadata = playerData.metadata or {}

                        if metadata.isdead or metadata.inlaststand then
                            TriggerEvent('zodi4c-storage:client:sendNotify', L('dead_cannot_access'), 'error')
                        else
                            OpenStorageMenu()
                        end
                    end
                else
                    sleep = 500

                    if uiActive then
                        SendNUIMessage({ action = 'hideInteraction' })
                        uiActive = false
                    end
                end
            else
                sleep = 1000

                if uiActive then
                    SendNUIMessage({ action = 'hideInteraction' })
                    uiActive = false
                end
            end
        else
            sleep = 2000

            if uiActive then
                SendNUIMessage({ action = 'hideInteraction' })
                uiActive = false
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if uiActive and not menuOpen and npcEntity then
            Wait(50)

            local npcCoords = GetEntityCoords(npcEntity)
            local onScreen, x, y = GetScreenCoordFromWorldCoord(npcCoords.x, npcCoords.y, npcCoords.z + 1.0)

            if onScreen then
                SendNUIMessage({
                    action = 'updateInteractionPos',
                    x = x * 100,
                    y = y * 100
                })
            end
        else
            Wait(500)
        end
    end
end)

function OpenStorageMenu()
    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
        if not storages then
            QBCore.Functions.Notify(L('storage_load_error'), 'error')
            return
        end

        if Config.BlurLevel > 0 then
            TriggerScreenblurFadeIn(500)
        end

        menuOpen = true
        SetNuiFocus(true, true)

        SendNUIMessage({
            action = 'openMenu',
            storages = storages,
            pricing = Config.Pricing,
            blurLevel = Config.BlurLevel,
            limits = Config.Limits,
            security = Config.Security,
            defaultImage = Config.DefaultImage,
            locales = Config.Locales,
            locale = Config.Locale
        })
    end)
end

local function CloseMenu()
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(500)
    menuOpen = false
end

RegisterNUICallback('closeMenu', function(_, cb)
    CloseMenu()
    cb({ success = true })
end)

RegisterNUICallback('createStorage', function(data, cb)
    if type(data) ~= 'table' or not data.name then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:createStorage', data)
    cb({ success = true })
end)

RegisterNUICallback('openStorage', function(data, cb)
    if type(data) ~= 'table' or (not data.storageId and not data.id) then
        cb({ success = false })
        return
    end

    local storageId = data.storageId or data.id

    if data.password and data.password ~= '' then
        TriggerServerEvent('zodi4c-storage:server:openStorage', storageId, data.password)
    else
        TriggerServerEvent('zodi4c-storage:server:openStorage', storageId)
    end

    CloseMenu()
    cb({ success = true })
end)

RegisterNUICallback('getMembers', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb({ success = false, members = {} })
        return
    end

    local resolved = false

    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getMembers', function(members)
        if resolved then return end
        resolved = true
        cb({ success = true, members = members or {} })
    end, data.id)

    SetTimeout(5000, function()
        if resolved then return end
        resolved = true
        cb({ success = false, members = {} })
    end)
end)

RegisterNUICallback('kickMember', function(data, cb)
    if type(data) ~= 'table' or not data.storageId or not data.citizenid then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:kickMember', data.storageId, data.citizenid)
    cb({ success = true })
end)

RegisterNUICallback('leaveStorage', function(data, cb)
    if type(data) ~= 'table' or not data.storageId then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:leaveStorage', data.storageId)
    cb({ success = true })
end)

RegisterNUICallback('deleteStorage', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:deleteStorage', data.id)
    CloseMenu()
    cb({ success = true })
end)

RegisterNUICallback('notify', function(data, cb)
    if type(data) == 'table' and data.text then
        QBCore.Functions.Notify(data.text, data.type or 'info')
    end
    cb({ success = true })
end)

RegisterNetEvent('zodi4c-storage:client:sendNotify', function(text, notifyType)
    if menuOpen then
        SendNUIMessage({
            action = 'notify',
            text = text,
            type = notifyType or 'info'
        })
    else
        QBCore.Functions.Notify(text, notifyType or 'info')
    end
end)

RegisterNetEvent('zodi4c-storage:client:refreshStorages', function()
    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
        SendNUIMessage({
            action = 'updateStorages',
            storages = storages or {}
        })
    end)
end)

RegisterNetEvent('zodi4c-storage:client:openStash', function(stashName)
    if uiActive then
        SendNUIMessage({ action = 'hideInteraction' })
        uiActive = false
    end

    -- The inventory needs focus, so close the NUI before opening the stash.
    Wait(100)
    exports.ox_inventory:openInventory('stash', stashName)
end)

RegisterNUICallback('updateStorage', function(data, cb)
    if type(data) ~= 'table' or not data.id or not data.name then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:updateStorage', data)
    cb({ success = true })
end)

RegisterNUICallback('changePassword', function(data, cb)
    if type(data) ~= 'table' or not data.id or not data.newPass then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:changePassword', data)
    cb({ success = true })
end)

RegisterNUICallback('removePassword', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:removePassword', data.id)
    cb({ success = true })
end)

RegisterNUICallback('updateStorageCapacity', function(data, cb)
    if type(data) ~= 'table' or not data.id or not data.slots or not data.weight then
        cb({ success = false })
        return
    end

    TriggerServerEvent('zodi4c-storage:server:updateStorageCapacity', data)
    cb({ success = true })
end)

RegisterNUICallback('getLogs', function(data, cb)
    if type(data) ~= 'table' or not data.storageId then
        cb({})
        return
    end

    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getLogs', function(logs)
        cb(logs or {})
    end, data.storageId)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if npcEntity and DoesEntityExist(npcEntity) then
        DeleteEntity(npcEntity)
        npcEntity = nil
    end

    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0)
    menuOpen = false
    uiActive = false
end)
