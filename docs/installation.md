# Installation / Kurulum

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Bu döküman `zodi4c-storage` kaynağının sıfırdan kurulumunu anlatır.

### 1. Gereksinimler

| Bileşen | Zorunlu | Not |
| --- | --- | --- |
| FiveM sunucu artefaktı | Evet | `cerulean` uyumlu güncel artefakt |
| `qb-core` | Evet | Oyuncu, para ve karakter verisi (Qbox'ta `qbx_core`) |
| `qbx_core` | Alternatif | Qbox / QBX çekirdeği — `qb-core` köprüsü ile |
| `ox_inventory` | Evet | Stash ve `registerHook` desteği |
| `oxmysql` | Evet | Veritabanı bağlantısı |
| MySQL / MariaDB | Evet | InnoDB, `utf8mb4` |

#### Qbox (QBX) kullanıyorsanız

- Çekirdek kaynak `qbx_core`'dur. `qb-core` klasörünü kurmayın; iki çekirdek aynı anda
  yüklüyse script yanlış çekirdeğe bağlanır.
- `qbx_core`, `fxmanifest.lua`'sında `provide 'qb-core'` bildirir. Bu sayede
  `exports['qb-core']:GetCoreObject()` çağrısı Qbox'un köprüsüne gider ve `dependencies`
  kontrolü de geçer. Ek bir uyumluluk kaynağı gerekmez.
- Köprü varsayılan olarak açıktır. Sunucunuzda `setr qbx:enablebridge false` varsa menü
  açılmaz; bu satırı kaldırın.
- `ox_inventory` Qbox'un varsayılan envanteri olduğu için stash, hook ve para işlemleri yerel
  olarak çalışır.
- Veritabanı şeması QBCore ile aynıdır; script `players` tablosundaki `citizenid` ve
  `charinfo` alanlarını kullanır.

#### Sürüm kontrolü

- `ox_inventory` sürümünüzün `RegisterStash` ve `registerHook` fonksiyonlarını desteklediğinden
  emin olun. Çok eski sürümlerde stash'ler açılmaz.
- `oxmysql` kaynağının `server_scripts` içinde `@oxmysql/lib/MySQL.lua` sağladığını doğrulayın.

### 2. Dosyaları yerleştirme

Klasörü sunucunuzun `resources` dizinine kopyalayın:

```text
resources/
└── [zodi4c]/
    └── zodi4c-storage/
        ├── fxmanifest.lua
        ├── config.lua
        ├── client/
        ├── server/
        ├── shared/
        ├── locales/
        ├── html/
        ├── sql/
        └── docs/
```

> Klasör adı **tam olarak** `zodi4c-storage` olmalıdır. ox_inventory stash adları ve NUI
> `GetParentResourceName()` çağrıları kaynak adını kullanır.

### 3. Veritabanı

#### Seçenek A — Komut satırı

```bash
mysql -u KULLANICI -p VERITABANI_ADI < sql/zodi4c-storage.sql
```

#### Seçenek B — HeidiSQL / phpMyAdmin / DBeaver

1. Veritabanınıza bağlanın.
2. `sql/zodi4c-storage.sql` dosyasını açın.
3. Betiği çalıştırın.

Betik şu nesneleri oluşturur:

- `zodi4c_storages`
- `zodi4c_storage_members`
- `zodi4c_storage_logs`
- `zodi4c_storage_overview`, `zodi4c_storage_memberships`,
  `zodi4c_storage_inventory_details` view'ları

Şema ayrıntıları: [database.md](database.md).

### 4. Sunucu yapılandırması

`server.cfg` dosyanıza aşağıdaki satırları ekleyin. Kaynak, bağımlılıklardan **sonra**
başlatılmalıdır:

```cfg
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure zodi4c-storage
```

`qb-core` genellikle `[qb]` kategorisinde, `ox_inventory` ve `oxmysql` ise `[ox]`
kategorisinde bulunur. Sunucunuzun mevcut sırasına göre düzenleyin.

> Qbox / QBX kullanıyorsanız `ensure qb-core` satırını `ensure qbx_core` ile değiştirin.
> `qb-core` satırı Qbox'ta hata verir, çünkü böyle bir kaynak yoktur.

### 5. İlk yapılandırma

`config.lua` dosyasını açın ve en az şu değerleri kontrol edin:

```lua
Config.Locale = 'tr' -- veya 'en'

Config.NPC = {
    model = `s_m_m_movspace_01`,
    coords = vector4(-68.1458, -1208.8668, 28.1284, 313.9380),
}

Config.Pricing = {
    bank = 10000,
    cash = 10000,
}
```

- **NPC konumu**: Oyuncuların depo menüsüne erişeceği nokta. `vector4` içindeki son değer
  (`w`) NPC'nin baktığı yöndür.
- **Fiyatlar**: Depo oluşturma ücreti. `bank` ve `cash` ayrı ayrı ayarlanabilir; `0` yaparsanız
  ücretsiz olur.
- **Dil**: `tr` veya `en`. Yeni dil eklemek için [configuration.md](configuration.md)
  dosyasındaki "Dil ekleme" bölümüne bakın.

Tüm ayarlar: [configuration.md](configuration.md).

### 6. Kaynağı başlatma

```text
restart zodi4c-storage
```

Konsolda şu satırı görmelisiniz (yalnızca `Config.Debug = true` iken):

```text
[zodi4c-storage] loaded (locale: tr)
```

Ardından oyunda:

1. NPC'nin yanına gidin.
2. `E` tuşuna basın.
3. **Yeni Depo** butonuyla bir depo oluşturun.
4. Depoyu açıp eşya koyun, çıkarın.
5. Başka bir karakterle depoyu açarak üyelik/şifre akışını doğrulayın.

### 7. Yükseltme

1. Sunucuyu durdurun veya kaynağı `stop zodi4c-storage` ile kapatın.
2. Eski klasörü yedekleyin.
3. Yeni dosyaları kopyalayın; `config.lua` dosyanızı koruyun.
4. `CHANGELOG.md` içindeki ilgili sürüm notlarını okuyun.
5. Veritabanı değişikliği varsa `sql/` altındaki güncel şemayı uygulayın.
6. Kaynağı yeniden başlatın.

### 8. Kaldırma

1. `server.cfg` içinden `ensure zodi4c-storage` satırını kaldırın.
2. Kaynağı durdurun ve klasörü silin.
3. Verileri de silmek istiyorsanız:

```sql
DROP VIEW IF EXISTS `zodi4c_storage_inventory_details`;
DROP VIEW IF EXISTS `zodi4c_storage_memberships`;
DROP VIEW IF EXISTS `zodi4c_storage_overview`;
DROP TABLE IF EXISTS `zodi4c_storage_logs`;
DROP TABLE IF EXISTS `zodi4c_storage_members`;
DROP TABLE IF EXISTS `zodi4c_storages`;

DELETE FROM `ox_inventory` WHERE `name` LIKE 'zodi4c\_storage\_%';
```

> Bu işlem geri alınamaz. Önce yedek alın.

---

## English

This document walks through a clean installation of the `zodi4c-storage` resource.

### 1. Requirements

| Component | Required | Note |
| --- | --- | --- |
| FiveM server artifact | Yes | Current `cerulean`-compatible artifact |
| `qb-core` | Yes | Player, money and character data (`qbx_core` on Qbox) |
| `qbx_core` | Alternative | Qbox / QBX core — via the `qb-core` bridge |
| `ox_inventory` | Yes | Stash and `registerHook` support |
| `oxmysql` | Yes | Database layer |
| MySQL / MariaDB | Yes | InnoDB, `utf8mb4` |

#### Using Qbox (QBX)

- Your core resource is `qbx_core`. Do not install `qb-core`; with both present the script
  binds to the wrong core.
- `qbx_core` declares `provide 'qb-core'` in its manifest, so
  `exports['qb-core']:GetCoreObject()` resolves to the Qbox bridge and the `dependencies`
  check passes. No extra compatibility resource is needed.
- The bridge is enabled by default. If your server sets `setr qbx:enablebridge false`, the
  menu will not open — remove that line.
- `ox_inventory` is Qbox's default inventory, so stash, hook and money operations run
  natively.
- The database schema is identical to QBCore; the script reads `citizenid` and `charinfo`
  from the `players` table.

#### Version checks

- Make sure your `ox_inventory` version supports `RegisterStash` and `registerHook`.
  Very old versions will not open stashes.
- Verify that `oxmysql` provides `@oxmysql/lib/MySQL.lua` in `server_scripts`.

### 2. Placing the files

Copy the folder into your server's `resources` directory:

```text
resources/
└── [zodi4c]/
    └── zodi4c-storage/
        ├── fxmanifest.lua
        ├── config.lua
        ├── client/
        ├── server/
        ├── shared/
        ├── locales/
        ├── html/
        ├── sql/
        └── docs/
```

> The folder name must be **exactly** `zodi4c-storage`. ox_inventory stash names and NUI
> `GetParentResourceName()` calls rely on the resource name.

### 3. Database

#### Option A — Command line

```bash
mysql -u USERNAME -p DATABASE_NAME < sql/zodi4c-storage.sql
```

#### Option B — HeidiSQL / phpMyAdmin / DBeaver

1. Connect to your database.
2. Open `sql/zodi4c-storage.sql`.
3. Run the script.

The script creates:

- `zodi4c_storages`
- `zodi4c_storage_members`
- `zodi4c_storage_logs`
- the `zodi4c_storage_overview`, `zodi4c_storage_memberships` and
  `zodi4c_storage_inventory_details` views

Schema reference: [database.md](database.md).

### 4. Server configuration

Add these lines to your `server.cfg`. The resource must start **after** its dependencies:

```cfg
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure zodi4c-storage
```

`qb-core` usually lives under `[qb]`, while `ox_inventory` and `oxmysql` live under `[ox]`.
Adjust the order to match your existing setup.

> On Qbox / QBX, replace `ensure qb-core` with `ensure qbx_core`. The `qb-core` line fails on
> Qbox because no such resource exists.

### 5. First configuration

Open `config.lua` and check at least the following values:

```lua
Config.Locale = 'tr' -- or 'en'

Config.NPC = {
    model = `s_m_m_movspace_01`,
    coords = vector4(-68.1458, -1208.8668, 28.1284, 313.9380),
}

Config.Pricing = {
    bank = 10000,
    cash = 10000,
}
```

- **NPC position**: where players open the storage menu. The last value (`w`) in `vector4`
  is the heading the ped faces.
- **Prices**: one-time creation fee. `bank` and `cash` are configured separately; set them to
  `0` for free storages.
- **Language**: `tr` or `en`. To add another language, see the "Adding a language" section in
  [configuration.md](configuration.md).

All settings: [configuration.md](configuration.md).

### 6. Starting the resource

```text
restart zodi4c-storage
```

With `Config.Debug = true` the console should print:

```text
[zodi4c-storage] loaded (locale: tr)
```

Then, in game:

1. Walk to the NPC.
2. Press `E`.
3. Create a storage with the **New Storage** button.
4. Open it and store/take an item.
5. Test the membership/password flow with a second character.

### 7. Upgrading

1. Stop the server or run `stop zodi4c-storage`.
2. Back up the old folder.
3. Copy the new files; keep your `config.lua`.
4. Read the relevant version notes in `CHANGELOG.md`.
5. If the database changed, apply the current schema from `sql/`.
6. Restart the resource.

### 8. Uninstalling

1. Remove `ensure zodi4c-storage` from `server.cfg`.
2. Stop the resource and delete the folder.
3. To remove the data as well:

```sql
DROP VIEW IF EXISTS `zodi4c_storage_inventory_details`;
DROP VIEW IF EXISTS `zodi4c_storage_memberships`;
DROP VIEW IF EXISTS `zodi4c_storage_overview`;
DROP TABLE IF EXISTS `zodi4c_storage_logs`;
DROP TABLE IF EXISTS `zodi4c_storage_members`;
DROP TABLE IF EXISTS `zodi4c_storages`;

DELETE FROM `ox_inventory` WHERE `name` LIKE 'zodi4c\_storage\_%';
```

> This cannot be undone. Back up first.
