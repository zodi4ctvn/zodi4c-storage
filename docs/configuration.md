# Configuration / Yapılandırma

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Tüm ayarlar `config.lua` dosyasındadır. Sunucu ve istemci aynı dosyayı `shared_scripts`
üzerinden okur, bu yüzden bir değişiklikten sonra kaynağı yeniden başlatın:

```text
restart zodi4c-storage
```

### Genel ayarlar

| Anahtar | Tip | Varsayılan | Açıklama |
| --- | --- | --- | --- |
| `Config.Debug` | `boolean` | `false` | Sunucu konsoluna ek tanılama yazar |
| `Config.Locale` | `string` | `'tr'` | Aktif dil: `tr` veya `en` |
| `Config.BlurLevel` | `number` | `0` | Menü açıkken arka plan bulanıklığı (px). `0` kapalı |
| `Config.InteractionDistance` | `number` | `2.0` | NPC ile etkileşim mesafesi (metre) |
| `Config.MenuOpenKey` | `number` | `38` | Menü tuşu (FiveM kontrol ID'si; `38` = E) |
| `Config.DefaultImage` | `string` | SVG data URI | Görsel girilmezse kullanılan resim |

```lua
Config.Debug = false
Config.Locale = 'en'
Config.BlurLevel = 8
Config.InteractionDistance = 2.5
Config.MenuOpenKey = 38 -- E
```

> `Config.BlurLevel` değerini yükseltmek düşük donanımlı oyuncularda FPS düşüşüne yol
> açabilir. Sorun yaşanırsa `0` yapın.

### NPC

```lua
Config.NPC = {
    model = `s_m_m_movspace_01`,
    coords = vector4(-68.1458, -1208.8668, 28.1284, 313.9380),
}
```

| Alan | Açıklama |
| --- | --- |
| `model` | Ped modeli (hash veya string) |
| `coords` | `x, y, z` konumu ve `w` yönü |

NPC oluşturulurken `z - 1.0` kullanılır; bu, pedin zemine oturmasını sağlar. NPC donmuş,
dokunulmaz ve dış etkenlere tepkisizdir.

Yeni konum almak için F8 konsolunda `GetEntityCoords(PlayerPedId())` kullanabilirsiniz.

### Fiyatlandırma

```lua
Config.Pricing = {
    bank = 10000,
    cash = 10000,
}
```

- Depo oluşturma tek seferlik ücretlendirilir.
- Ödeme, seçilen yönteme göre `player.Functions.RemoveMoney` ile alınır.
- Veritabanı kaydı başarısız olursa ücret otomatik iade edilir.
- Ücretsiz depo için `0` kullanın:

```lua
Config.Pricing = { bank = 0, cash = 0 }
```

### Limitler

```lua
Config.Limits = {
    maxSlots = 100,
    maxWeight = 500000, -- gram (500 kg)
    minNameLength = 3,
    maxStoragesPerPlayer = 10,
}
```

| Anahtar | Açıklama |
| --- | --- |
| `maxSlots` | Bir deponun sahip olabileceği en fazla slot |
| `maxWeight` | Gram cinsinden en fazla ağırlık. `500000` = 500 kg |
| `minNameLength` | Depo adı için minimum karakter sayısı |
| `maxStoragesPerPlayer` | Bir oyuncunun sahip olabileceği depo sayısı |

> Arayüzde ağırlık **kg** olarak girilir ve sunucuya **gram** olarak gönderilir.
> `Config.Limits.maxWeight` her zaman gram cinsindendir.

Bu limitler hem NUI'da hem de `server/main.lua` içinde doğrulanır. NUI kontrolü yalnızca
kullanıcı deneyimi içindir; sunucu doğrulaması kaldırılmamalıdır.

### Güvenlik

```lua
Config.Security = {
    minPasswordLength = 4,
    maxPasswordLength = 50,
    maxLoginAttempts = 3,
    lockoutDuration = 300, -- saniye
}
```

| Anahtar | Açıklama |
| --- | --- |
| `minPasswordLength` | Yeni şifreler için minimum uzunluk |
| `maxPasswordLength` | Şifre alanına girilebilecek maksimum uzunluk |
| `maxLoginAttempts` | Kilitlenmeden önceki hatalı deneme sayısı |
| `lockoutDuration` | Kilit süresi (saniye) |

#### Nasıl çalışır?

- Hatalı şifre denemeleri **oyuncu bazında** (`citizenid`) sayılır.
- Limit aşıldığında oyuncu `lockoutDuration` boyunca şifreli depolara giremez.
- Doğru şifre girildiğinde sayaç sıfırlanır.
- Sayaç yalnızca bellekte tutulur; sunucu yeniden başladığında sıfırlanır.
- Sahip ve kayıtlı üyeler şifre sorulmadan depoyu açar.

> Bu koruma kaba kuvvet denemelerini yavaşlatır ancak tamamen engellemez. Depo şifreleri
> hash'lenmediği için veritabanı erişimi olan biri şifreleri okuyabilir. Ayrıntılar:
> [SECURITY.md](../SECURITY.md).

### Özellik anahtarları

```lua
Config.Features = {
    allowLeaveStorage = true,
    allowPasswordRemoval = true,
    allowCapacityUpdate = true,
    requireUniqueNames = true,
}
```

| Anahtar | Kapalıyken davranış |
| --- | --- |
| `allowLeaveStorage` | Üyeler depodan ayrılamaz; sunucu hata bildirir |
| `allowPasswordRemoval` | "Şifreyi Kaldır" isteği reddedilir |
| `allowCapacityUpdate` | Kapasite güncelleme isteği reddedilir |
| `requireUniqueNames` | Aynı isimde birden fazla depo oluşturulabilir |

`requireUniqueNames` açıkken isim kontrolü **tüm sunucuda** yapılır, yalnızca oyuncunun kendi
depoları arasında değil. Bu nedenle genel bir isim seçmek zor olabilir; gerekirse kapatın.

### Dil ekleme

1. `locales/en.lua` dosyasını kopyalayıp `locales/de.lua` gibi yeni bir dosya oluşturun.
2. Dosyanın başındaki tablo adını değiştirin:

```lua
Locales = Locales or {}

Locales.de = {
    menu_title = 'Gemeinsamer Lagerraum',
    -- ...
}
```

3. `fxmanifest.lua` içindeki `shared_scripts` listesine ekleyin:

```lua
shared_scripts {
    'config.lua',
    'locales/tr.lua',
    'locales/en.lua',
    'locales/de.lua',
    'shared/locale.lua'
}
```

4. `config.lua` içinde `Config.Locale = 'de'` yapın.

Eksik anahtarlar otomatik olarak İngilizce dosyadan gelir, bu yüzden yeni dili aşamalı olarak
çevirebilirsiniz.

#### Çeviri anahtarları hakkında

- `%s` yer tutucuları `L('key', value)` veya `t('key', value)` ile doldurulur.
- Arayüzde statik metinler `data-i18n`, `data-i18n-placeholder`, `data-i18n-title`
  öznitelikleriyle işaretlenir.
- JavaScript içinde dinamik metinler `t('key')` ile üretilir.
- Yeni bir anahtar eklerken **hem** `tr.lua` **hem** `en.lua` dosyasına ekleyin.

### Özel görsel

`Config.DefaultImage` bir `data:` URI veya `https://` URL olabilir. Depo oluştururken görsel
alanı boş bırakılırsa bu değer kullanılır.

```lua
Config.DefaultImage = 'https://example.com/storage.png'
```

> Görseller NUI tarafından yüklenir. Çok büyük dosyalar menü açılışını yavaşlatabilir.
> `data:` URI kullanıyorsanız boyutu makul tutun.

---

## English

All settings live in `config.lua`. Both the server and the client read the same file through
`shared_scripts`, so restart the resource after any change:

```text
restart zodi4c-storage
```

### General settings

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `Config.Debug` | `boolean` | `false` | Prints extra diagnostics to the server console |
| `Config.Locale` | `string` | `'tr'` | Active language: `tr` or `en` |
| `Config.BlurLevel` | `number` | `0` | Background blur while the menu is open (px). `0` = off |
| `Config.InteractionDistance` | `number` | `2.0` | Interaction distance to the NPC (metres) |
| `Config.MenuOpenKey` | `number` | `38` | Menu key (FiveM control ID; `38` = E) |
| `Config.DefaultImage` | `string` | SVG data URI | Image used when none is provided |

```lua
Config.Debug = false
Config.Locale = 'en'
Config.BlurLevel = 8
Config.InteractionDistance = 2.5
Config.MenuOpenKey = 38 -- E
```

> Raising `Config.BlurLevel` can cost FPS on low-end machines. Set it to `0` if players
> report stutter.

### NPC

```lua
Config.NPC = {
    model = `s_m_m_movspace_01`,
    coords = vector4(-68.1458, -1208.8668, 28.1284, 313.9380),
}
```

| Field | Description |
| --- | --- |
| `model` | Ped model (hash or string) |
| `coords` | `x, y, z` position and `w` heading |

The ped is created with `z - 1.0` so it sits on the ground. It is frozen, invincible and
ignores non-temporary events.

To get a new position, use `GetEntityCoords(PlayerPedId())` in the F8 console.

### Pricing

```lua
Config.Pricing = {
    bank = 10000,
    cash = 10000,
}
```

- Creating a storage is a one-time charge.
- Payment is taken with `player.Functions.RemoveMoney` using the selected method.
- If the database insert fails, the money is refunded automatically.
- For free storages use `0`:

```lua
Config.Pricing = { bank = 0, cash = 0 }
```

### Limits

```lua
Config.Limits = {
    maxSlots = 100,
    maxWeight = 500000, -- grams (500 kg)
    minNameLength = 3,
    maxStoragesPerPlayer = 10,
}
```

| Key | Description |
| --- | --- |
| `maxSlots` | Maximum slots a storage can have |
| `maxWeight` | Maximum weight in grams. `500000` = 500 kg |
| `minNameLength` | Minimum characters for a storage name |
| `maxStoragesPerPlayer` | Number of storages a player can own |

> The UI accepts weight in **kg** and sends **grams** to the server.
> `Config.Limits.maxWeight` is always in grams.

These limits are validated in the NUI and in `server/main.lua`. The NUI check is only for
user experience; never remove the server-side validation.

### Security

```lua
Config.Security = {
    minPasswordLength = 4,
    maxPasswordLength = 50,
    maxLoginAttempts = 3,
    lockoutDuration = 300, -- seconds
}
```

| Key | Description |
| --- | --- |
| `minPasswordLength` | Minimum length for new passwords |
| `maxPasswordLength` | Maximum length accepted by the password field |
| `maxLoginAttempts` | Failed attempts before a lockout |
| `lockoutDuration` | Lockout duration in seconds |

#### How it works

- Failed attempts are counted **per player** (`citizenid`).
- After the limit, the player cannot open password-protected storages for `lockoutDuration`.
- A correct password resets the counter.
- Counters live in memory only and reset when the server restarts.
- Owners and registered members open a storage without a password prompt.

> This slows brute-force attempts but does not stop them completely. Passwords are not
> hashed, so anyone with database access can read them. Details:
> [SECURITY.md](../SECURITY.md).

### Feature flags

```lua
Config.Features = {
    allowLeaveStorage = true,
    allowPasswordRemoval = true,
    allowCapacityUpdate = true,
    requireUniqueNames = true,
}
```

| Key | Behavior when disabled |
| --- | --- |
| `allowLeaveStorage` | Members cannot leave; the server returns an error |
| `allowPasswordRemoval` | "Remove password" requests are rejected |
| `allowCapacityUpdate` | Capacity update requests are rejected |
| `requireUniqueNames` | Multiple storages may share the same name |

With `requireUniqueNames` enabled, the check is **server-wide**, not limited to the player's
own storages. Generic names may be unavailable; disable it if that is a problem.

### Adding a language

1. Copy `locales/en.lua` to a new file such as `locales/de.lua`.
2. Change the table name at the top:

```lua
Locales = Locales or {}

Locales.de = {
    menu_title = 'Gemeinsamer Lagerraum',
    -- ...
}
```

3. Add it to `shared_scripts` in `fxmanifest.lua`:

```lua
shared_scripts {
    'config.lua',
    'locales/tr.lua',
    'locales/en.lua',
    'locales/de.lua',
    'shared/locale.lua'
}
```

4. Set `Config.Locale = 'de'` in `config.lua`.

Missing keys fall back to English, so a new language can be translated gradually.

#### About translation keys

- `%s` placeholders are filled by `L('key', value)` or `t('key', value)`.
- Static UI text is marked with `data-i18n`, `data-i18n-placeholder` and `data-i18n-title`.
- Dynamic text in JavaScript is produced with `t('key')`.
- When adding a key, add it to **both** `tr.lua` and `en.lua`.

### Custom default image

`Config.DefaultImage` can be a `data:` URI or an `https://` URL. It is used when the image
field is left empty during storage creation.

```lua
Config.DefaultImage = 'https://example.com/storage.png'
```

> Images are loaded by the NUI. Very large files slow down the menu. Keep `data:` URIs
> reasonably small.
