# Events & API / Olaylar ve API

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Bu döküman kaynağın dışarıya açtığı event, callback ve NUI mesajlarını listeler. Sunucu
event'lerini **yalnızca kendi kaynaklarınızdan** çağırın; sunucu her isteği yeniden doğrular.

### Sunucu event'leri

#### `zodi4c-storage:server:createStorage`

Yeni depo oluşturur.

```lua
TriggerServerEvent('zodi4c-storage:server:createStorage', {
    name = 'Ev Deposu',
    image = 'https://example.com/storage.png',
    slots = 50,
    weight = 100000, -- gram
    password = '1234', -- isteğe bağlı
    paymentType = 'bank', -- 'bank' | 'cash'
})
```

| Alan | Tip | Zorunlu | Not |
| --- | --- | --- | --- |
| `name` | `string` | Evet | `Config.Limits.minNameLength` kadar uzun olmalı |
| `image` | `string` | Hayır | Boşsa `Config.DefaultImage` |
| `slots` | `number` | Evet | `1..Config.Limits.maxSlots` |
| `weight` | `number` | Evet | Gram, `1000..Config.Limits.maxWeight` |
| `password` | `string` | Hayır | Uzunluk `Config.Security` ile sınırlı |
| `paymentType` | `string` | Hayır | Geçersizse `cash` |

Ek kontroller:

- Oyuncunun depo sayısı `maxStoragesPerPlayer` altında mı?
- Yeterli para var mı?
- `requireUniqueNames` açıksa isim kullanılmış mı?

Başarılı olursa `zodi4c-storage:client:refreshStorages` tetiklenir.

#### `zodi4c-storage:server:openStorage`

Depoyu açar ve ox_inventory stash'ini yükler.

```lua
TriggerServerEvent('zodi4c-storage:server:openStorage', storageId, password)
```

| Parametre | Tip | Not |
| --- | --- | --- |
| `storageId` | `number` | Depo ID |
| `password` | `string\|nil` | Yalnızca şifre gerekiyorsa |

Akış:

1. Depo sahibi doğrudan açar.
2. Kayıtlı üye doğrudan açar.
3. Diğer oyuncular için şifre doğrulanır (varsa).
4. Hatalı denemeler sayılır; limit aşılırsa geçici kilit uygulanır.
5. Başarılıysa `zodi4c-storage:client:openStash` gönderilir.

#### `zodi4c-storage:server:kickMember`

Depo sahibinin bir üyeyi çıkarmasını sağlar.

```lua
TriggerServerEvent('zodi4c-storage:server:kickMember', storageId, citizenid)
```

Yalnızca depo sahibi çağırabilir. Sahip kendini çıkaramaz (listede zaten yer almaz).

#### `zodi4c-storage:server:leaveStorage`

Bir üyenin depodan ayrılmasını sağlar.

```lua
TriggerServerEvent('zodi4c-storage:server:leaveStorage', storageId)
```

- Sahip ayrılamaz; `owner_cannot_leave` bildirimi döner.
- `Config.Features.allowLeaveStorage` kapalıysa reddedilir.

#### `zodi4c-storage:server:deleteStorage`

Depoyu ve boş stash'ini siler.

```lua
TriggerServerEvent('zodi4c-storage:server:deleteStorage', storageId)
```

Stash içinde eşya varsa silme reddedilir ve oyuncuya bildirim gönderilir.

#### `zodi4c-storage:server:updateStorage`

Depo adını ve görselini günceller.

```lua
TriggerServerEvent('zodi4c-storage:server:updateStorage', {
    id = 42,
    name = 'Yeni İsim',
    image = 'https://example.com/new.png',
})
```

Yalnızca sahip çağırabilir. `requireUniqueNames` açıksa yeni isim kontrol edilir.

#### `zodi4c-storage:server:changePassword`

Şifreyi değiştirir.

```lua
TriggerServerEvent('zodi4c-storage:server:changePassword', {
    id = 42,
    oldPass = 'eski', -- mevcut şifre varsa zorunlu
    newPass = 'yeni',
})
```

Mevcut şifre varsa `oldPass` doğrulanır. Yeni şifre `Config.Security` limitlerine uymalıdır.

#### `zodi4c-storage:server:removePassword`

Şifreyi kaldırır.

```lua
TriggerServerEvent('zodi4c-storage:server:removePassword', storageId)
```

`Config.Features.allowPasswordRemoval` kapalıysa reddedilir.

#### `zodi4c-storage:server:updateStorageCapacity`

Slot ve ağırlık kapasitesini günceller.

```lua
TriggerServerEvent('zodi4c-storage:server:updateStorageCapacity', {
    id = 42,
    slots = 80,
    weight = 250000, -- gram
})
```

`Config.Features.allowCapacityUpdate` kapalıysa reddedilir.

### Sunucu callback'leri

QBCore callback'leri `QBCore.Functions.TriggerCallback` ile çağrılır. Qbox / QBX
sunucularında bu çağrı `qbx_core` içindeki `qb-core` köprüsü tarafından karşılanır; kodunuzu
değiştirmeniz gerekmez.

#### `zodi4c-storage:server:getStorages`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
    -- storages: table
end)
```

Dönen her kayıt:

| Alan | Tip | Açıklama |
| --- | --- | --- |
| `id` | `number` | Depo ID |
| `owner` | `string` | Sahip citizenid |
| `name` | `string` | Depo adı |
| `image` | `string` | Görsel |
| `slots` | `number` | Slot sayısı |
| `weight` | `number` | Ağırlık (gram) |
| `password` | `boolean` | Şifre var mı |
| `isOwner` | `boolean` | İstek sahibi sahip mi |
| `isMember` | `boolean` | İstek sahibi üye mi |
| `created_at`, `updated_at` | `string` | Zaman damgaları |

> Tüm depolar döner; bu, oyuncuların yeni depoları keşfetmesini sağlar. Gizlilik gerekiyorsa
> sorguyu özelleştirin.

#### `zodi4c-storage:server:getMembers`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getMembers', function(members)
    -- members: table
end, storageId)
```

Yalnızca depo sahibi gerçek üye listesini alır; diğerleri boş tablo alır.

| Alan | Tip | Açıklama |
| --- | --- | --- |
| `citizenid` | `string` | Oyuncu |
| `name` | `string` | Karakter adı |
| `isOwner` | `boolean` | Sahip mi |

Sahip her zaman listenin ilk elemanıdır.

#### `zodi4c-storage:server:getLogs`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getLogs', function(logs)
    -- logs: table
end, storageId)
```

Son 150 kaydı döner (en yeni önce). Yalnızca sahip erişebilir.

| Alan | Açıklama |
| --- | --- |
| `name` | İşlemi yapan |
| `action` | `take`, `put`, `access` |
| `details` | Eşya veya `storage_open` |
| `date` | `DD/MM/YYYY HH:MM` biçiminde |
| `created_at` | Ham zaman damgası |

### İstemci event'leri

Bu event'ler sunucu tarafından tetiklenir; normalde doğrudan çağırmayın.

| Event | Parametreler | Açıklama |
| --- | --- | --- |
| `zodi4c-storage:client:sendNotify` | `text`, `type` | Menü açıksa NUI toast, değilse QBCore bildirimi |
| `zodi4c-storage:client:refreshStorages` | — | Depo listesini yeniler |
| `zodi4c-storage:client:openStash` | `stashName` | ox_inventory stash'ini açar |

`type` değerleri: `success`, `error`, `info`, `warning`.

### NUI mesajları

İstemci → NUI (`SendNUIMessage`):

| `action` | Alanlar | Açıklama |
| --- | --- | --- |
| `showInteraction` | `text`, `key` | NPC yanında etkileşim kutusu |
| `hideInteraction` | — | Etkileşim kutusunu gizler |
| `updateInteractionPos` | `x`, `y` | Kutunun ekran konumu (yüzde) |
| `openMenu` | `storages`, `pricing`, `blurLevel`, `limits`, `security`, `defaultImage`, `locales`, `locale` | Ana menüyü açar |
| `updateStorages` | `storages` | Listeyi günceller |
| `notify` | `text`, `type` | Toast gösterir |

### NUI callback'leri

NUI → istemci (`RegisterNUICallback`):

| Callback | Gönderilen veri | Açıklama |
| --- | --- | --- |
| `closeMenu` | `{}` | NUI odağını bırakır |
| `createStorage` | `name`, `image`, `slots`, `weight`, `password`, `paymentType` | Sunucuya iletir |
| `openStorage` | `storageId`, `password`, `passwordRequired` | Sunucuya iletir |
| `getMembers` | `{ id }` | Üyeleri döner |
| `kickMember` | `{ storageId, citizenid }` | Üye çıkarır |
| `leaveStorage` | `{ storageId }` | Depodan ayrılır |
| `deleteStorage` | `{ id }` | Depoyu siler |
| `notify` | `{ text, type }` | Yerel bildirim gösterir |
| `updateStorage` | `{ id, name, image }` | Depoyu düzenler |
| `changePassword` | `{ id, oldPass, newPass }` | Şifre değiştirir |
| `removePassword` | `{ id }` | Şifreyi kaldırır |
| `updateStorageCapacity` | `{ id, slots, weight }` | Kapasite günceller |
| `getLogs` | `{ storageId }` | Logları döner |

### Entegrasyon örnekleri

#### Depo oluşturulduğunda başka bir kaynağa haber verme

```lua
-- server/main.lua içindeki createStorage akışına eklenebilir
TriggerEvent('my-log-resource:storageCreated', id, citizenid)
```

#### Kendi komutunuzla depo listesini çekme

```lua
RegisterCommand('mystorages', function(source)
    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
        for _, storage in ipairs(storages) do
            if storage.isOwner then
                print(storage.id, storage.name)
            end
        end
    end)
end, false)
```

> Callback'ler oyuncuya bağlıdır; komutun `source` değeri ile aynı oyuncudan çağrılmalıdır.

#### Log tablosunu dışa aktarma

```lua
MySQL.query('SELECT * FROM zodi4c_storage_logs WHERE created_at > ?', { since }, function(rows)
    -- rows
end)
```

---

## English

This document lists the events, callbacks and NUI messages exposed by the resource. Only call
server events from resources you control; the server re-validates every request.

### Server events

#### `zodi4c-storage:server:createStorage`

Creates a new storage.

```lua
TriggerServerEvent('zodi4c-storage:server:createStorage', {
    name = 'Home Storage',
    image = 'https://example.com/storage.png',
    slots = 50,
    weight = 100000, -- grams
    password = '1234', -- optional
    paymentType = 'bank', -- 'bank' | 'cash'
})
```

| Field | Type | Required | Note |
| --- | --- | --- | --- |
| `name` | `string` | Yes | At least `Config.Limits.minNameLength` characters |
| `image` | `string` | No | Falls back to `Config.DefaultImage` |
| `slots` | `number` | Yes | `1..Config.Limits.maxSlots` |
| `weight` | `number` | Yes | Grams, `1000..Config.Limits.maxWeight` |
| `password` | `string` | No | Length limited by `Config.Security` |
| `paymentType` | `string` | No | Invalid values fall back to `cash` |

Additional checks:

- Is the player below `maxStoragesPerPlayer`?
- Does the player have enough money?
- If `requireUniqueNames` is enabled, is the name already taken?

On success, `zodi4c-storage:client:refreshStorages` is triggered.

#### `zodi4c-storage:server:openStorage`

Opens a storage and loads its ox_inventory stash.

```lua
TriggerServerEvent('zodi4c-storage:server:openStorage', storageId, password)
```

| Parameter | Type | Note |
| --- | --- | --- |
| `storageId` | `number` | Storage ID |
| `password` | `string\|nil` | Only when a password is required |

Flow:

1. The owner opens directly.
2. A registered member opens directly.
3. Other players are validated against the password (if set).
4. Failed attempts are counted; exceeding the limit applies a temporary lockout.
5. On success, `zodi4c-storage:client:openStash` is sent.

#### `zodi4c-storage:server:kickMember`

Lets the owner remove a member.

```lua
TriggerServerEvent('zodi4c-storage:server:kickMember', storageId, citizenid)
```

Owner only. The owner cannot kick themselves (they are not in the member list).

#### `zodi4c-storage:server:leaveStorage`

Lets a member leave a storage.

```lua
TriggerServerEvent('zodi4c-storage:server:leaveStorage', storageId)
```

- The owner cannot leave; `owner_cannot_leave` is returned.
- Rejected when `Config.Features.allowLeaveStorage` is disabled.

#### `zodi4c-storage:server:deleteStorage`

Deletes a storage and its empty stash.

```lua
TriggerServerEvent('zodi4c-storage:server:deleteStorage', storageId)
```

If the stash still contains items, deletion is refused and the player is notified.

#### `zodi4c-storage:server:updateStorage`

Updates the storage name and image.

```lua
TriggerServerEvent('zodi4c-storage:server:updateStorage', {
    id = 42,
    name = 'New Name',
    image = 'https://example.com/new.png',
})
```

Owner only. With `requireUniqueNames` enabled the new name is checked.

#### `zodi4c-storage:server:changePassword`

Changes the storage password.

```lua
TriggerServerEvent('zodi4c-storage:server:changePassword', {
    id = 42,
    oldPass = 'old', -- required when a password exists
    newPass = 'new',
})
```

When a password already exists, `oldPass` is validated. The new password must satisfy
`Config.Security`.

#### `zodi4c-storage:server:removePassword`

Removes the storage password.

```lua
TriggerServerEvent('zodi4c-storage:server:removePassword', storageId)
```

Rejected when `Config.Features.allowPasswordRemoval` is disabled.

#### `zodi4c-storage:server:updateStorageCapacity`

Updates slot and weight capacity.

```lua
TriggerServerEvent('zodi4c-storage:server:updateStorageCapacity', {
    id = 42,
    slots = 80,
    weight = 250000, -- grams
})
```

Rejected when `Config.Features.allowCapacityUpdate` is disabled.

### Server callbacks

QBCore callbacks are invoked with `QBCore.Functions.TriggerCallback`. On Qbox / QBX servers
the same call is served by the `qb-core` bridge inside `qbx_core`, so no code changes are
required.

#### `zodi4c-storage:server:getStorages`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
    -- storages: table
end)
```

Each returned record:

| Field | Type | Description |
| --- | --- | --- |
| `id` | `number` | Storage ID |
| `owner` | `string` | Owner citizenid |
| `name` | `string` | Storage name |
| `image` | `string` | Image |
| `slots` | `number` | Slot count |
| `weight` | `number` | Weight in grams |
| `password` | `boolean` | Whether a password is set |
| `isOwner` | `boolean` | Requester owns it |
| `isMember` | `boolean` | Requester is a member |
| `created_at`, `updated_at` | `string` | Timestamps |

> Every storage is returned so players can discover new ones. Customize the query if you
> need privacy.

#### `zodi4c-storage:server:getMembers`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getMembers', function(members)
    -- members: table
end, storageId)
```

Only the owner receives the real member list; others receive an empty table.

| Field | Type | Description |
| --- | --- | --- |
| `citizenid` | `string` | Player |
| `name` | `string` | Character name |
| `isOwner` | `boolean` | Owner flag |

The owner is always the first entry.

#### `zodi4c-storage:server:getLogs`

```lua
QBCore.Functions.TriggerCallback('zodi4c-storage:server:getLogs', function(logs)
    -- logs: table
end, storageId)
```

Returns the latest 150 entries (newest first). Owner only.

| Field | Description |
| --- | --- |
| `name` | Actor name |
| `action` | `take`, `put`, `access` |
| `details` | Item or `storage_open` |
| `date` | Formatted as `DD/MM/YYYY HH:MM` |
| `created_at` | Raw timestamp |

### Client events

Triggered by the server; do not call these directly in normal use.

| Event | Parameters | Description |
| --- | --- | --- |
| `zodi4c-storage:client:sendNotify` | `text`, `type` | NUI toast when the menu is open, QBCore notification otherwise |
| `zodi4c-storage:client:refreshStorages` | — | Refreshes the storage list |
| `zodi4c-storage:client:openStash` | `stashName` | Opens the ox_inventory stash |

`type` values: `success`, `error`, `info`, `warning`.

### NUI messages

Client → NUI (`SendNUIMessage`):

| `action` | Fields | Description |
| --- | --- | --- |
| `showInteraction` | `text`, `key` | Interaction box next to the NPC |
| `hideInteraction` | — | Hides the interaction box |
| `updateInteractionPos` | `x`, `y` | Screen position (percentage) |
| `openMenu` | `storages`, `pricing`, `blurLevel`, `limits`, `security`, `defaultImage`, `locales`, `locale` | Opens the main menu |
| `updateStorages` | `storages` | Updates the list |
| `notify` | `text`, `type` | Shows a toast |

### NUI callbacks

NUI → client (`RegisterNUICallback`):

| Callback | Payload | Description |
| --- | --- | --- |
| `closeMenu` | `{}` | Releases NUI focus |
| `createStorage` | `name`, `image`, `slots`, `weight`, `password`, `paymentType` | Forwards to the server |
| `openStorage` | `storageId`, `password`, `passwordRequired` | Forwards to the server |
| `getMembers` | `{ id }` | Returns members |
| `kickMember` | `{ storageId, citizenid }` | Removes a member |
| `leaveStorage` | `{ storageId }` | Leaves a storage |
| `deleteStorage` | `{ id }` | Deletes a storage |
| `notify` | `{ text, type }` | Shows a local notification |
| `updateStorage` | `{ id, name, image }` | Edits a storage |
| `changePassword` | `{ id, oldPass, newPass }` | Changes the password |
| `removePassword` | `{ id }` | Removes the password |
| `updateStorageCapacity` | `{ id, slots, weight }` | Updates capacity |
| `getLogs` | `{ storageId }` | Returns logs |

### Integration examples

#### Notify another resource when a storage is created

```lua
-- can be added to the createStorage flow in server/main.lua
TriggerEvent('my-log-resource:storageCreated', id, citizenid)
```

#### Fetch the storage list from your own command

```lua
RegisterCommand('mystorages', function(source)
    QBCore.Functions.TriggerCallback('zodi4c-storage:server:getStorages', function(storages)
        for _, storage in ipairs(storages) do
            if storage.isOwner then
                print(storage.id, storage.name)
            end
        end
    end)
end, false)
```

> Callbacks are bound to the player; call them from the same player as the command `source`.

#### Export the log table

```lua
MySQL.query('SELECT * FROM zodi4c_storage_logs WHERE created_at > ?', { since }, function(rows)
    -- rows
end)
```
