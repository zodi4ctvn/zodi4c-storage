local QBCore = exports['qb-core']:GetCoreObject()

local STASH_PREFIX = 'zodi4c_storage_'
local loginAttempts = {}

local function DebugPrint(...)
    if Config.Debug then
        print('[zodi4c-storage]', ...)
    end
end

local function Notify(src, key, notifyType, ...)
    TriggerClientEvent('zodi4c-storage:client:sendNotify', src, L(key, ...), notifyType or 'info')
end

local function GetCharacterName(player)
    local charinfo = player.PlayerData.charinfo or {}
    local firstname = charinfo.firstname or ''
    local lastname = charinfo.lastname or ''
    local name = ('%s %s'):format(firstname, lastname):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then
        return L('unknown_member')
    end
    return name
end

local function NormalizeName(name)
    local value = tostring(name or '')
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    return value:sub(1, 100)
end

-- Passwords are stored case-insensitively. This keeps passwords easy to type on
-- the in-game prompt and remains compatible with existing installations.
local function NormalizePassword(password)
    if not password then return nil end
    local value = tostring(password)
    if value == '' then return nil end
    return string.lower(value)
end

local function VerifyPassword(stored, provided)
    if not stored or stored == '' then return true end
    if not provided then return false end
    return string.lower(tostring(provided)) == stored
end

local function ValidatePassword(password)
    if not password or password == '' then return true end

    local minLength = tonumber(Config.Security.minPasswordLength) or 4
    local maxLength = tonumber(Config.Security.maxPasswordLength) or 50

    if #password < minLength then
        return false, 'password_too_short', minLength
    end
    if #password > maxLength then
        return false, 'password_too_long', maxLength
    end

    return true
end

local function GetLoginState(citizenid)
    local state = loginAttempts[citizenid]
    if state and state.lockedUntil and state.lockedUntil <= os.time() then
        loginAttempts[citizenid] = nil
        return nil
    end
    return state
end

local function RegisterFailedAttempt(citizenid)
    local maxAttempts = math.max(1, tonumber(Config.Security.maxLoginAttempts) or 3)
    local lockoutDuration = math.max(1, tonumber(Config.Security.lockoutDuration) or 300)
    local state = GetLoginState(citizenid) or { count = 0 }

    state.count = state.count + 1
    if state.count >= maxAttempts then
        state.lockedUntil = os.time() + lockoutDuration
    end

    loginAttempts[citizenid] = state
    return state
end

local function LogAction(storageId, citizenid, name, action, details)
    MySQL.insert(
        'INSERT INTO zodi4c_storage_logs (storage_id, citizenid, name, action, details) VALUES (?, ?, ?, ?, ?)',
        { storageId, citizenid, name, action, details }
    )
end

-- Log item movement in and out of a storage stash.
exports.ox_inventory:registerHook('swapItems', function(payload)
    local src = payload.source
    if not src then return true end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then return true end

    local fromInventory = tostring(payload.fromInventory or '')
    local toInventory = tostring(payload.toInventory or '')
    local storageId, action

    if fromInventory:find(STASH_PREFIX, 1, true) then
        storageId = tonumber(fromInventory:match(STASH_PREFIX .. '(%d+)'))
        action = 'take'
    elseif toInventory:find(STASH_PREFIX, 1, true) then
        storageId = tonumber(toInventory:match(STASH_PREFIX .. '(%d+)'))
        action = 'put'
    end

    if storageId and payload.fromSlot then
        local count = payload.fromSlot.count or 0
        local label = payload.fromSlot.label or payload.fromSlot.name or '?'
        local details = ('%sx %s'):format(count, label)

        LogAction(storageId, player.PlayerData.citizenid, GetCharacterName(player), action, details)
    end

    return true
end, {
    inventoryFilter = {
        '^' .. STASH_PREFIX .. '%d+'
    }
})

local function OpenStash(src, storageId, storage)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local charName = GetCharacterName(player)

    if storage.owner ~= citizenid then
        MySQL.query(
            'INSERT IGNORE INTO zodi4c_storage_members (storage_id, citizenid, name) VALUES (?, ?, ?)',
            { storageId, citizenid, charName }
        )
    end

    local stashName = STASH_PREFIX .. storage.id
    exports.ox_inventory:RegisterStash(stashName, storage.name, storage.slots, storage.weight, false)
    TriggerClientEvent('zodi4c-storage:client:openStash', src, stashName)

    LogAction(storageId, citizenid, charName, 'access', 'storage_open')
end

-- Returns every storage so players can discover and join new ones.
QBCore.Functions.CreateCallback('zodi4c-storage:server:getStorages', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return cb({}) end

    local citizenid = player.PlayerData.citizenid
    local query = [[
        SELECT
            s.id,
            s.owner,
            s.name,
            s.image,
            s.slots,
            s.weight,
            s.created_at,
            s.updated_at,
            CASE WHEN s.password IS NOT NULL AND s.password <> '' THEN 1 ELSE 0 END AS password,
            CASE WHEN s.owner = ? THEN 1 ELSE 0 END AS isOwner,
            CASE WHEN m.citizenid IS NOT NULL THEN 1 ELSE 0 END AS isMember
        FROM zodi4c_storages s
        LEFT JOIN zodi4c_storage_members m
            ON s.id = m.storage_id
            AND m.citizenid COLLATE utf8mb4_general_ci = ?
    ]]

    MySQL.query(query, { citizenid, citizenid }, function(results)
        results = results or {}

        for _, storage in ipairs(results) do
            storage.password = storage.password == 1
            storage.isOwner = storage.isOwner == 1
            storage.isMember = storage.isMember == 1
        end

        cb(results)
    end)
end)

RegisterNetEvent('zodi4c-storage:server:createStorage', function(data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(data) ~= 'table' or not data.name or not data.slots or not data.weight then
        Notify(src, 'missing_data', 'error')
        return
    end

    local citizenid = player.PlayerData.citizenid
    local name = NormalizeName(data.name)
    local slots = tonumber(data.slots)
    local weight = tonumber(data.weight)
    local image = tostring(data.image or '')
    local paymentType = (data.paymentType == 'bank' or data.paymentType == 'cash') and data.paymentType or 'cash'
    local price = tonumber(Config.Pricing[paymentType]) or 0
    local rawPassword = data.password and tostring(data.password) or ''

    if image == '' then
        image = Config.DefaultImage
    end
    image = image:sub(1, 4096)

    if not slots or slots < 1 or slots > (Config.Limits.maxSlots or 100) then
        Notify(src, 'invalid_slots', 'error')
        return
    end

    if not weight or weight < 1000 or weight > (Config.Limits.maxWeight or 500000) then
        Notify(src, 'invalid_weight', 'error')
        return
    end

    if #name < (Config.Limits.minNameLength or 3) then
        Notify(src, 'name_too_short', 'error', Config.Limits.minNameLength or 3)
        return
    end

    local passwordValid, passwordKey, passwordLimit = ValidatePassword(rawPassword)
    if not passwordValid then
        Notify(src, passwordKey, 'error', passwordLimit)
        return
    end

    local password = NormalizePassword(rawPassword)

    local function CreateStorage()
        MySQL.scalar('SELECT COUNT(*) FROM zodi4c_storages WHERE owner = ?', { citizenid }, function(count)
            if (count or 0) >= (Config.Limits.maxStoragesPerPlayer or 10) then
                Notify(src, 'max_storages_reached', 'error', Config.Limits.maxStoragesPerPlayer or 10)
                return
            end

            if player.Functions.GetMoney(paymentType) < price then
                Notify(src, 'not_enough_money', 'error')
                return
            end

            player.Functions.RemoveMoney(paymentType, price, 'storage-creation')

            MySQL.insert(
                'INSERT INTO zodi4c_storages (owner, name, image, slots, weight, password) VALUES (?, ?, ?, ?, ?, ?)',
                { citizenid, name, image, slots, weight, password },
                function(id)
                    if not id then
                        player.Functions.AddMoney(paymentType, price, 'storage-creation-refund')
                        Notify(src, 'storage_create_failed', 'error')
                        return
                    end

                    Notify(src, 'storage_created', 'success')
                    TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
                end
            )
        end)
    end

    if Config.Features.requireUniqueNames then
        MySQL.scalar('SELECT COUNT(*) FROM zodi4c_storages WHERE name = ?', { name }, function(count)
            if count and count > 0 then
                Notify(src, 'storage_name_taken', 'error')
                return
            end

            CreateStorage()
        end)
    else
        CreateStorage()
    end
end)

RegisterNetEvent('zodi4c-storage:server:openStorage', function(storageId, password)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    storageId = tonumber(storageId)
    if not storageId then return end

    local citizenid = player.PlayerData.citizenid

    MySQL.single('SELECT * FROM zodi4c_storages WHERE id = ?', { storageId }, function(storage)
        if not storage then
            Notify(src, 'storage_not_found', 'error')
            return
        end

        if storage.owner == citizenid then
            OpenStash(src, storageId, storage)
            return
        end

        MySQL.scalar(
            'SELECT COUNT(*) FROM zodi4c_storage_members WHERE storage_id = ? AND citizenid = ?',
            { storageId, citizenid },
            function(memberCount)
                if memberCount and memberCount > 0 then
                    OpenStash(src, storageId, storage)
                    return
                end

                if storage.password and storage.password ~= '' then
                    local loginState = GetLoginState(citizenid)
                    if loginState and loginState.lockedUntil then
                        Notify(src, 'too_many_attempts', 'error', loginState.lockedUntil - os.time())
                        return
                    end

                    if not VerifyPassword(storage.password, password) then
                        local failedState = RegisterFailedAttempt(citizenid)
                        if failedState.lockedUntil then
                            Notify(src, 'locked_out', 'error', Config.Security.lockoutDuration or 300)
                        else
                            Notify(src, 'wrong_password', 'error')
                        end
                        return
                    end

                    loginAttempts[citizenid] = nil
                end

                OpenStash(src, storageId, storage)
            end
        )
    end)
end)

QBCore.Functions.CreateCallback('zodi4c-storage:server:getMembers', function(source, cb, storageId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return cb({}) end

    storageId = tonumber(storageId)
    if not storageId then return cb({}) end

    MySQL.single([[
        SELECT s.owner, p.charinfo
        FROM zodi4c_storages s
        LEFT JOIN players p
            ON s.owner COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
        WHERE s.id = ?
    ]], { storageId }, function(storage)
        if not storage or storage.owner ~= player.PlayerData.citizenid then
            return cb({})
        end

        local ownerName = L('unknown_owner')
        if storage.charinfo then
            local charinfo = storage.charinfo
            if type(charinfo) == 'string' then
                local ok, decoded = pcall(json.decode, charinfo)
                charinfo = ok and decoded or nil
            end
            if type(charinfo) == 'table' and charinfo.firstname then
                ownerName = ('%s %s'):format(charinfo.firstname, charinfo.lastname or '')
            end
        end

        MySQL.query([[
            SELECT m.citizenid, m.name AS cached_name, p.charinfo
            FROM zodi4c_storage_members m
            LEFT JOIN players p
                ON m.citizenid COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
            WHERE m.storage_id = ?
        ]], { storageId }, function(memberResults)
            local members = {
                {
                    citizenid = storage.owner,
                    name = ownerName,
                    isOwner = true
                }
            }

            for _, member in ipairs(memberResults or {}) do
                if member.citizenid ~= storage.owner then
                    local name = member.cached_name or L('unknown_member')

                    if member.charinfo then
                        local charinfo = member.charinfo
                        if type(charinfo) == 'string' then
                            local ok, decoded = pcall(json.decode, charinfo)
                            charinfo = ok and decoded or nil
                        end
                        if type(charinfo) == 'table' and charinfo.firstname then
                            name = ('%s %s'):format(charinfo.firstname, charinfo.lastname or '')
                        end
                    end

                    members[#members + 1] = {
                        citizenid = member.citizenid,
                        name = name,
                        isOwner = false
                    }
                end
            end

            cb(members)
        end)
    end)
end)

RegisterNetEvent('zodi4c-storage:server:kickMember', function(storageId, citizenid)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    storageId = tonumber(storageId)
    citizenid = citizenid and tostring(citizenid) or nil

    if not storageId or not citizenid then return end

    MySQL.single('SELECT owner FROM zodi4c_storages WHERE id = ?', { storageId }, function(storage)
        if not storage or storage.owner ~= player.PlayerData.citizenid then
            Notify(src, 'no_permission', 'error')
            return
        end

        MySQL.query(
            'DELETE FROM zodi4c_storage_members WHERE storage_id = ? AND citizenid = ?',
            { storageId, citizenid },
            function()
                Notify(src, 'member_kicked', 'success')
                TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
            end
        )
    end)
end)

RegisterNetEvent('zodi4c-storage:server:leaveStorage', function(storageId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if not Config.Features.allowLeaveStorage then
        Notify(src, 'feature_disabled_leave', 'error')
        return
    end

    storageId = tonumber(storageId)
    if not storageId then return end

    local citizenid = player.PlayerData.citizenid

    MySQL.single('SELECT owner FROM zodi4c_storages WHERE id = ?', { storageId }, function(storage)
        if not storage then return end

        if storage.owner == citizenid then
            Notify(src, 'owner_cannot_leave', 'error')
            return
        end

        MySQL.query(
            'DELETE FROM zodi4c_storage_members WHERE storage_id = ? AND citizenid = ?',
            { storageId, citizenid },
            function()
                Notify(src, 'left_storage', 'success')
                TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
            end
        )
    end)
end)

RegisterNetEvent('zodi4c-storage:server:deleteStorage', function(storageId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    storageId = tonumber(storageId)
    if not storageId then return end

    MySQL.single('SELECT owner FROM zodi4c_storages WHERE id = ?', { storageId }, function(storage)
        if not storage or storage.owner ~= player.PlayerData.citizenid then
            Notify(src, 'no_permission', 'error')
            return
        end

        local stashName = STASH_PREFIX .. storageId
        local inventory = exports.ox_inventory:GetInventory(stashName)

        if inventory and inventory.items then
            for _, item in pairs(inventory.items) do
                if item and (item.count or 0) > 0 then
                    Notify(src, 'storage_has_items', 'error')
                    return
                end
            end
        end

        MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { stashName })
        MySQL.query('DELETE FROM zodi4c_storages WHERE id = ?', { storageId }, function()
            Notify(src, 'storage_deleted', 'success')
            TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
        end)
    end)
end)

RegisterNetEvent('zodi4c-storage:server:updateStorage', function(data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(data) ~= 'table' or not data.id or not data.name then
        Notify(src, 'missing_data', 'error')
        return
    end

    local id = tonumber(data.id)
    if not id then return end

    local name = NormalizeName(data.name)
    local image = tostring(data.image or '')

    if image == '' then
        image = Config.DefaultImage
    end
    image = image:sub(1, 4096)

    if #name < (Config.Limits.minNameLength or 3) then
        Notify(src, 'name_too_short', 'error', Config.Limits.minNameLength or 3)
        return
    end

    local function UpdateStorage()
        MySQL.single(
            'SELECT id FROM zodi4c_storages WHERE id = ? AND owner = ?',
            { id, player.PlayerData.citizenid },
            function(storage)
                if not storage then
                    Notify(src, 'no_permission', 'error')
                    return
                end

                MySQL.update(
                    'UPDATE zodi4c_storages SET name = ?, image = ? WHERE id = ? AND owner = ?',
                    { name, image, id, player.PlayerData.citizenid },
                    function()
                        Notify(src, 'storage_updated', 'success')
                        TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
                    end
                )
            end
        )
    end

    if Config.Features.requireUniqueNames then
        MySQL.scalar(
            'SELECT COUNT(*) FROM zodi4c_storages WHERE name = ? AND id <> ?',
            { name, id },
            function(count)
                if count and count > 0 then
                    Notify(src, 'storage_name_taken', 'error')
                    return
                end

                UpdateStorage()
            end
        )
    else
        UpdateStorage()
    end
end)

RegisterNetEvent('zodi4c-storage:server:changePassword', function(data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(data) ~= 'table' or not data.id or not data.newPass then
        Notify(src, 'missing_data', 'error')
        return
    end

    local id = tonumber(data.id)
    if not id then return end

    local newPassword = tostring(data.newPass)
    local oldPassword = data.oldPass and tostring(data.oldPass) or ''

    local passwordValid, passwordKey, passwordLimit = ValidatePassword(newPassword)
    if not passwordValid then
        Notify(src, passwordKey, 'error', passwordLimit)
        return
    end

    MySQL.single(
        'SELECT password FROM zodi4c_storages WHERE id = ? AND owner = ?',
        { id, player.PlayerData.citizenid },
        function(storage)
            if not storage then
                Notify(src, 'storage_not_found', 'error')
                return
            end

            if storage.password and storage.password ~= '' and not VerifyPassword(storage.password, oldPassword) then
                Notify(src, 'old_password_wrong', 'error')
                return
            end

            MySQL.update(
                'UPDATE zodi4c_storages SET password = ? WHERE id = ?',
                { NormalizePassword(newPassword), id },
                function()
                    Notify(src, 'password_updated', 'success')
                end
            )
        end
    )
end)

RegisterNetEvent('zodi4c-storage:server:removePassword', function(storageId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if not Config.Features.allowPasswordRemoval then
        Notify(src, 'feature_disabled_password_removal', 'error')
        return
    end

    storageId = tonumber(storageId)
    if not storageId then return end

    MySQL.single(
        'SELECT password FROM zodi4c_storages WHERE id = ? AND owner = ?',
        { storageId, player.PlayerData.citizenid },
        function(storage)
            if not storage then return end

            if not storage.password or storage.password == '' then
                Notify(src, 'password_already_none', 'error')
                return
            end

            MySQL.update(
                'UPDATE zodi4c_storages SET password = NULL WHERE id = ? AND owner = ?',
                { storageId, player.PlayerData.citizenid },
                function()
                    Notify(src, 'password_removed', 'success')
                end
            )
        end
    )
end)

RegisterNetEvent('zodi4c-storage:server:updateStorageCapacity', function(data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if not Config.Features.allowCapacityUpdate then
        Notify(src, 'feature_disabled_capacity', 'error')
        return
    end

    if type(data) ~= 'table' or not data.id or not data.slots or not data.weight then
        Notify(src, 'missing_data', 'error')
        return
    end

    local id = tonumber(data.id)
    local slots = tonumber(data.slots)
    local weight = tonumber(data.weight)

    if not id then return end

    if not slots or slots < 1 or slots > (Config.Limits.maxSlots or 100) then
        Notify(src, 'invalid_slots', 'error')
        return
    end

    if not weight or weight < 1000 or weight > (Config.Limits.maxWeight or 500000) then
        Notify(src, 'invalid_weight', 'error')
        return
    end

    MySQL.single(
        'SELECT id FROM zodi4c_storages WHERE id = ? AND owner = ?',
        { id, player.PlayerData.citizenid },
        function(storage)
            if not storage then
                Notify(src, 'no_permission', 'error')
                return
            end

            MySQL.update(
                'UPDATE zodi4c_storages SET slots = ?, weight = ? WHERE id = ? AND owner = ?',
                { slots, weight, id, player.PlayerData.citizenid },
                function()
                    Notify(src, 'capacity_updated', 'success')
                    TriggerClientEvent('zodi4c-storage:client:refreshStorages', src)
                end
            )
        end
    )
end)

QBCore.Functions.CreateCallback('zodi4c-storage:server:getLogs', function(source, cb, storageId)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return cb({}) end

    storageId = tonumber(storageId)
    if not storageId then return cb({}) end

    MySQL.single('SELECT owner FROM zodi4c_storages WHERE id = ?', { storageId }, function(storage)
        if not storage or storage.owner ~= player.PlayerData.citizenid then
            return cb({})
        end

        MySQL.query([[
            SELECT *, DATE_FORMAT(created_at, '%d/%m/%Y %H:%i') AS date
            FROM zodi4c_storage_logs
            WHERE storage_id = ?
            ORDER BY created_at DESC
            LIMIT 150
        ]], { storageId }, function(logs)
            cb(logs or {})
        end)
    end)
end)

CreateThread(function()
    Wait(0)
    DebugPrint(('loaded (locale: %s)'):format(Config.Locale))
end)
