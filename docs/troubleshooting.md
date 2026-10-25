# Troubleshooting / Sorun Giderme

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

### Kaynak başlamıyor

#### Konsolda `Failed to load script` veya `attempt to index a nil value`

**Neden:** Bağımlılık sırası yanlış veya eksik dosya.

**Çözüm:**

1. `server.cfg` sırasını kontrol edin:

```cfg
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure zodi4c-storage
```

2. `fxmanifest.lua` içindeki dosya yollarının mevcut olduğunu doğrulayın:

```lua
shared_scripts { 'config.lua', 'locales/tr.lua', 'locales/en.lua', 'shared/locale.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
```

3. Klasör adının `zodi4c-storage` olduğundan emin olun.

#### `No such export GetCoreObject in resource qb-core`

`qb-core` başlamamış veya yeniden başlatılmış. Sırayı düzeltin ve sunucuyu tamamen yeniden
başlatın (`restart` her zaman yeterli olmaz).

Qbox / QBX kullanıyorsanız `qb-core` diye bir kaynak yoktur: `server.cfg` içinde
`ensure qbx_core` bulunmalıdır. Köprü kapatılmışsa (`setr qbx:enablebridge false`)
`GetCoreObject` yine bulunamaz; bu satırı kaldırın.

### Menü açılmıyor

#### NPC görünmüyor

- `Config.NPC.coords` değerinin geçerli bir konum olduğundan emin olun.
- Konumun zemine yakın olduğunu kontrol edin. NPC `z - 1.0` ile oluşturulur.
- Başka bir kaynak aynı modeli veya konumu kullanıyor olabilir.
- `Config.Debug = true` yapıp konsolu izleyin.

#### `E` tuşu çalışmıyor

- `Config.MenuOpenKey` değeri başka bir kaynak tarafından kullanılıyor olabilir. Varsayılan
  `38` (E) tuşudur.
- Oyuncu ölüyse menü açılmaz; bu davranış bilinçlidir.
- NUI odağı takılı kalmış olabilir. Menüyü kapatıp tekrar deneyin.

#### Arayüz açılıyor ama boş

Tarayıcı konsolunu açın (F8 → `nui_devtools`). Olası nedenler:

- `locales` tablosu NUI'ya ulaşmıyor.
- `html/index.html` içinde bir JavaScript hatası var.
- Lucide CDN'e erişim yok (ikonlar görünmez, işlevler çalışır).

### Veritabanı hataları

#### `Table 'zodi4c_storages' doesn't exist`

SQL betiği çalıştırılmamış:

```bash
mysql -u KULLANICI -p VERITABANI < sql/zodi4c-storage.sql
```

#### `ER_NO_REFERENCED_ROW_2`

Üye eklenirken `storage_id` mevcut değil. Depo silinmiş olabilir; sayfayı yenileyin.

#### Türkçe karakterler bozuk

Veritabanı, tablo ve bağlantı `utf8mb4` olmalı:

```sql
ALTER DATABASE `VERITABANI` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

`oxmysql` bağlantı dizesinde `charset=utf8mb4` kullanın.

### Depo ve eşya sorunları

#### Depo açılıyor ama eşyalar görünmüyor

1. Stash adını kontrol edin:

```sql
SELECT `name` FROM `ox_inventory` WHERE `name` LIKE '%storage%';
```

2. Depo stash'inin adı `zodi4c_storage_<id>` biçiminde olmalı.
3. `ox_inventory` sürümünüzün `RegisterStash` desteklediğinden emin olun.

#### "Depoyu silmek için önce boşaltmalısınız" hatası

Depo stash'inde eşya var. Depoyu açıp tüm eşyaları boşaltın. Eşyalar başka bir oyuncunun
envanterinde kalmışsa önce onları geri getirin.

#### Eşya kayboldu

- Logları kontrol edin: `zodi4c_storage_logs`.
- `ox_inventory` stash kaydını inceleyin:

```sql
SELECT * FROM `ox_inventory` WHERE `name` = 'zodi4c_storage_42';
```

- Sunucu çökmesi sırasında açık stash varsa ox_inventory verisi yazılmamış olabilir.
  ox_inventory'nin kendi yedekleme mekanizmasını kontrol edin.

#### Üye depoyu açamıyor

- Üyeliğin kaydedildiğini doğrulayın:

```sql
SELECT * FROM `zodi4c_storage_members` WHERE `storage_id` = 42;
```

- Oyuncunun `citizenid` değeri karakter değiştirdiğinde değişir. Üyeliği yeniden ekletin.
- `Config.Features.allowLeaveStorage` kapalı olsa bile mevcut üyeler depoyu açabilir.

### Şifre ve kilit sorunları

#### Doğru şifre reddediliyor

- Şifreler küçük harfe çevrilerek saklanır; büyük/küçük harf farkı olmamalı.
- Veritabanındaki değeri kontrol edin:

```sql
SELECT `id`, `password` FROM `zodi4c_storages` WHERE `id` = 42;
```

- Şifre `NULL` veya boşsa depo şifresizdir.

#### Oyuncu kilitli kaldı

Kilit süresi `Config.Security.lockoutDuration` kadar (varsayılan 300 saniye). Sunucu yeniden
başlatılırsa sayaç sıfırlanır. Acil durumda kaynağı yeniden başlatın.

#### Şifre değiştirilemiyor

- Mevcut şifre varsa `Eski Şifre` alanı zorunludur.
- Yeni şifre `minPasswordLength` ve `maxPasswordLength` aralığında olmalı.
- `Config.Features.allowPasswordRemoval` yalnızca **kaldırma** işlemini etkiler, değiştirmeyi
  engellemez.

### Arayüz ve görsel sorunlar

#### İkonlar görünmüyor

Lucide CDN erişilemiyor olabilir. `html/index.html` içindeki şu satırı kontrol edin:

```html
<script src="https://unpkg.com/lucide@latest"></script>
```

Sunucunuz dış internete kapalıysa ikonları yerel olarak barındırın.

#### Yazı tipi farklı görünüyor

Google Fonts erişilemiyor. Alternatif olarak `Outfit` yazı tipini yerel dosya olarak ekleyin.

#### Toast bildirimleri görünmüyor

- `html/style.css` içinde `#zodi4c-toast-container` tanımlı mı?
- NUI konsolunda JavaScript hatası var mı?
- Menü kapalıyken bildirimler QBCore tarafından gösterilir, NUI toast değil.

#### Görsel önizlemesi çalışmıyor

Yalnızca `http://`, `https://` ve `data:` ile başlayan URL'ler önizlenir. Diğer değerler
varsayılan görsele düşer.

### Performans

#### Menü açılırken FPS düşüyor

- `Config.BlurLevel = 0` yapın.
- Çok büyük `Config.DefaultImage` data URI'lerini küçültün.
- Sayfalama zaten 6 kartla sınırlıdır; çok sayıda depo kartı performansı etkilemez.

#### Etkileşim gecikmeli

Yakınlık döngüsü mesafeye göre uyur (en fazla 2 saniye). `Config.InteractionDistance` çok
küçükse oyuncular menüyü açmakta zorlanabilir; 2.0–2.5 arası önerilir.

### Hâlâ çözülmedi mi?

Bir hata bildirimi açarken şunları ekleyin:

- FiveM artefakt sürümü
- `qb-core`, `ox_inventory`, `oxmysql` sürümleri
- `config.lua` (şifre gibi hassas değerleri sansürleyin)
- Sunucu ve istemci konsol çıktısı
- Hatayı yeniden üretme adımları

Şablon: [.github/ISSUE_TEMPLATE/bug_report.yml](../.github/ISSUE_TEMPLATE/bug_report.yml)

---

## English

### The resource will not start

#### `Failed to load script` or `attempt to index a nil value` in the console

**Cause:** wrong dependency order or a missing file.

**Fix:**

1. Check the `server.cfg` order:

```cfg
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure zodi4c-storage
```

2. Verify that the paths in `fxmanifest.lua` exist:

```lua
shared_scripts { 'config.lua', 'locales/tr.lua', 'locales/en.lua', 'shared/locale.lua' }
client_scripts { 'client/main.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
```

3. Make sure the folder is named `zodi4c-storage`.

#### `No such export GetCoreObject in resource qb-core`

`qb-core` has not started or was restarted. Fix the order and restart the whole server
(`restart` alone is not always enough).

On Qbox / QBX there is no `qb-core` resource at all: `server.cfg` must contain
`ensure qbx_core`. If the bridge is disabled (`setr qbx:enablebridge false`),
`GetCoreObject` also cannot be resolved — remove that line.

### The menu does not open

#### The NPC is not visible

- Make sure `Config.NPC.coords` is a valid position.
- Confirm the position is close to the ground. The ped is created with `z - 1.0`.
- Another resource may use the same model or position.
- Set `Config.Debug = true` and watch the console.

#### The `E` key does nothing

- `Config.MenuOpenKey` may be used by another resource. The default is `38` (E).
- The menu does not open while the player is dead; this is intentional.
- NUI focus may be stuck. Close the menu and try again.

#### The UI opens but is empty

Open the browser console (F8 → `nui_devtools`). Likely causes:

- The `locales` table is not reaching the NUI.
- There is a JavaScript error in `html/index.html`.
- The Lucide CDN is unreachable (icons disappear, functions still work).

### Database errors

#### `Table 'zodi4c_storages' doesn't exist`

The SQL script has not been imported:

```bash
mysql -u USERNAME -p DATABASE < sql/zodi4c-storage.sql
```

#### `ER_NO_REFERENCED_ROW_2`

`storage_id` does not exist while adding a member. The storage may have been deleted; refresh
the page.

#### Turkish characters look broken

The database, table and connection must use `utf8mb4`:

```sql
ALTER DATABASE `DATABASE` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Use `charset=utf8mb4` in your `oxmysql` connection string.

### Storage and item issues

#### The storage opens but items are missing

1. Check the stash names:

```sql
SELECT `name` FROM `ox_inventory` WHERE `name` LIKE '%storage%';
```

2. The stash name must be `zodi4c_storage_<id>`.
3. Make sure your `ox_inventory` version supports `RegisterStash`.

#### "Empty the storage before deleting it"

The stash still contains items. Open the storage and take everything out. If items are stuck
in another player's inventory, bring them back first.

#### An item disappeared

- Check the logs: `zodi4c_storage_logs`.
- Inspect the ox_inventory stash row:

```sql
SELECT * FROM `ox_inventory` WHERE `name` = 'zodi4c_storage_42';
```

- If the server crashed while a stash was open, ox_inventory may not have written the data.
  Check ox_inventory's own backup behavior.

#### A member cannot open the storage

- Confirm the membership exists:

```sql
SELECT * FROM `zodi4c_storage_members` WHERE `storage_id` = 42;
```

- A player's `citizenid` changes when they switch characters. Add the membership again.
- Existing members can still open a storage when `Config.Features.allowLeaveStorage` is off.

### Password and lockout issues

#### The correct password is rejected

- Passwords are stored lowercased; case should not matter.
- Check the stored value:

```sql
SELECT `id`, `password` FROM `zodi4c_storages` WHERE `id` = 42;
```

- If the password is `NULL` or empty, the storage has no password.

#### A player is locked out

The lockout lasts `Config.Security.lockoutDuration` seconds (default 300). Restarting the
server resets the counter. In an emergency, restart the resource.

#### The password cannot be changed

- When a password exists, the "Old Password" field is required.
- The new password must be between `minPasswordLength` and `maxPasswordLength`.
- `Config.Features.allowPasswordRemoval` only affects **removal**, not changing.

### UI and visual issues

#### Icons are missing

The Lucide CDN may be unreachable. Check this line in `html/index.html`:

```html
<script src="https://unpkg.com/lucide@latest"></script>
```

If your server has no internet access, host the icons locally.

#### The font looks different

Google Fonts is unreachable. Add the `Outfit` font as a local file instead.

#### Toast notifications do not appear

- Is `#zodi4c-toast-container` defined in `html/style.css`?
- Is there a JavaScript error in the NUI console?
- While the menu is closed, notifications are shown by QBCore, not the NUI toast.

#### Image preview does not work

Only URLs starting with `http://`, `https://` and `data:` are previewed. Other values fall
back to the default image.

### Performance

#### FPS drops when the menu opens

- Set `Config.BlurLevel = 0`.
- Shrink very large `Config.DefaultImage` data URIs.
- Pagination already limits the list to 6 cards, so the number of storages is not the cause.

#### Interaction feels delayed

The proximity loop sleeps based on distance (up to 2 seconds). If
`Config.InteractionDistance` is very small, players may struggle to open the menu; 2.0–2.5 is
recommended.

### Still stuck?

When opening a bug report, include:

- FiveM artifact version
- `qb-core`, `ox_inventory`, `oxmysql` versions
- `config.lua` (redact sensitive values such as passwords)
- Server and client console output
- Steps to reproduce

Template: [.github/ISSUE_TEMPLATE/bug_report.yml](../.github/ISSUE_TEMPLATE/bug_report.yml)
