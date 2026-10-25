# Database / Veritabanı

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

`zodi4c-storage` üç tablo ve üç yardımcı view kullanır. Şema `sql/zodi4c-storage.sql`
dosyasındadır ve tekrar çalıştırılabilir (`IF NOT EXISTS` / `CREATE OR REPLACE`).

### Tablolar

#### `zodi4c_storages`

Her depo için bir satır.

| Sütun | Tip | Varsayılan | Açıklama |
| --- | --- | --- | --- |
| `id` | `INT` | AUTO_INCREMENT | Birincil anahtar |
| `owner` | `VARCHAR(50)` | — | Sahibin `citizenid` değeri |
| `name` | `VARCHAR(100)` | — | Depo adı |
| `image` | `LONGTEXT` | `NULL` | Görsel URL veya `data:` URI |
| `slots` | `INT` | `50` | Slot kapasitesi |
| `weight` | `INT` | `100000` | Ağırlık kapasitesi (gram) |
| `password` | `VARCHAR(255)` | `NULL` | İsteğe bağlı, küçük harfe normalize şifre |
| `created_at` | `TIMESTAMP` | `CURRENT_TIMESTAMP` | Oluşturulma zamanı |
| `updated_at` | `TIMESTAMP` | otomatik | Güncellenme zamanı |

**İndeksler**

- `PRIMARY KEY (id)`
- `idx_owner (owner)`
- `idx_created_at (created_at)`

#### `zodi4c_storage_members`

Depoya erişimi olan oyuncular. Sahip bu tabloda **yer almaz**.

| Sütun | Tip | Açıklama |
| --- | --- | --- |
| `storage_id` | `INT` | `zodi4c_storages.id` referansı |
| `citizenid` | `VARCHAR(50)` | Üyenin `citizenid` değeri |
| `name` | `VARCHAR(100)` | Önbelleğe alınmış karakter adı |
| `joined_at` | `TIMESTAMP` | Katılma zamanı |

**Anahtarlar**

- `PRIMARY KEY (storage_id, citizenid)` — aynı oyuncu aynı depoya iki kez eklenemez.
- `idx_member_citizen (citizenid)`
- `FOREIGN KEY (storage_id) REFERENCES zodi4c_storages(id) ON DELETE CASCADE`

#### `zodi4c_storage_logs`

Eşya hareketleri ve depo erişimleri.

| Sütun | Tip | Açıklama |
| --- | --- | --- |
| `id` | `INT` | Birincil anahtar |
| `storage_id` | `INT` | Depo referansı |
| `citizenid` | `VARCHAR(50)` | İşlemi yapan oyuncu |
| `name` | `VARCHAR(100)` | İşlemi yapan karakter adı |
| `action` | `VARCHAR(50)` | `take`, `put` veya `access` |
| `details` | `TEXT` | Eşya adı/miktarı veya `storage_open` |
| `created_at` | `TIMESTAMP` | İşlem zamanı |

**İndeksler**

- `PRIMARY KEY (id)`
- `idx_storage_log (storage_id)`
- `idx_log_time (created_at)`
- `FOREIGN KEY (storage_id) REFERENCES zodi4c_storages(id) ON DELETE CASCADE`

`action` değerleri:

| Değer | Anlamı | Arayüzde (TR / EN) |
| --- | --- | --- |
| `take` | Eşya depodan alındı | ALDI / TAKEN |
| `put` | Eşya depoya kondu | KOYDU / STORED |
| `access` | Depo açıldı | GİRİŞ / ACCESS |

### View'lar

#### `zodi4c_storage_overview`

Tüm depoları sahip ve şifre durumuyla listeler.

```sql
SELECT * FROM zodi4c_storage_overview;
```

| Sütun | Açıklama |
| --- | --- |
| `id`, `storage_name`, `owner_citizenid` | Temel bilgiler |
| `slots` | Slot sayısı |
| `weight_kg` | Ağırlık (kg, ondalıklı) |
| `has_password` | Şifre var mı (`0`/`1`) |

#### `zodi4c_storage_memberships`

Sahipler ve üyeler dahil tüm ilişkiler.

```sql
SELECT * FROM zodi4c_storage_memberships WHERE citizenid = 'abc123';
```

| Sütun | Açıklama |
| --- | --- |
| `storage_id`, `storage_name` | Depo |
| `citizenid` | Oyuncu |
| `role` | `owner` veya `member` |
| `joined_at` | Sahipse depo oluşturma, üyeyse katılma zamanı |

#### `zodi4c_storage_inventory_details`

`ox_inventory` tablosuyla birleşerek hangi depoda hangi eşyanın olduğunu gösterir.

```sql
SELECT * FROM zodi4c_storage_inventory_details WHERE storage_id = 12;
```

| Sütun | Açıklama |
| --- | --- |
| `storage_id`, `storage_name`, `owner_citizenid` | Depo |
| `ox_inventory_name` | `zodi4c_storage_<id>` |
| `items_json` | ox_inventory'nin sakladığı veri |

> `items_json` ox_inventory'nin iç formatındadır ve sürümler arasında değişebilir. Salt okunur
> inceleme için kullanın, üzerine yazmayın.

### ox_inventory stash adlandırması

Her depo için stash adı:

```text
zodi4c_storage_<storage_id>
```

Örnek: `id = 42` olan depo → `zodi4c_storage_42`.

Eşyalar `ox_inventory` tablosunda bu isimle saklanır. Depo silinirken:

1. Stash içinde eşya olup olmadığı kontrol edilir.
2. Eşya varsa silme reddedilir.
3. Boşsa `ox_inventory` ve `zodi4c_storages` kayıtları silinir.

### Faydalı sorgular

#### Bir oyuncunun tüm depoları

```sql
SELECT s.id, s.name, s.slots, ROUND(s.weight / 1000, 1) AS weight_kg
FROM zodi4c_storages s
WHERE s.owner = 'CITIZENID';
```

#### Depo üyeleri

```sql
SELECT m.citizenid, m.name, m.joined_at
FROM zodi4c_storage_members m
WHERE m.storage_id = 42;
```

#### Son 50 hareket

```sql
SELECT l.created_at, l.name, l.action, l.details
FROM zodi4c_storage_logs l
WHERE l.storage_id = 42
ORDER BY l.created_at DESC
LIMIT 50;
```

#### Depo başına eşya sayısı

```sql
SELECT s.id, s.name, COUNT(i.id) AS item_rows
FROM zodi4c_storages s
LEFT JOIN ox_inventory i ON i.name = CONCAT('zodi4c_storage_', s.id)
GROUP BY s.id, s.name
ORDER BY item_rows DESC;
```

#### Eski logları temizleme

```sql
DELETE FROM zodi4c_storage_logs
WHERE created_at < NOW() - INTERVAL 90 DAY;
```

> Loglar sınırsız büyür. Yoğun sunucularda periyodik temizlik veya arşivleme önerilir.

### Yedekleme

```bash
mysqldump -u KULLANICI -p VERITABANI \
  zodi4c_storages \
  zodi4c_storage_members \
  zodi4c_storage_logs \
  > zodi4c-storage-backup.sql
```

Eşyalar da yedeklenecekse `ox_inventory` tablosunu dahil edin:

```bash
mysqldump -u KULLANICI -p VERITABANI zodi4c_storages zodi4c_storage_members \
  zodi4c_storage_logs ox_inventory > full-backup.sql
```

### Sık karşılaşılan şema sorunları

| Belirti | Olası neden |
| --- | --- |
| `Table 'zodi4c_storages' doesn't exist` | SQL betiği çalıştırılmamış |
| `Cannot add or update a child row` | Üye eklenirken geçersiz `storage_id` |
| Türkçe karakterler bozuk | Tablo/bağlantı `utf8mb4` değil |
| Eşyalar görünmüyor | Stash adı `zodi4c_storage_<id>` biçiminde değil |

---

## English

`zodi4c-storage` uses three tables and three helper views. The schema lives in
`sql/zodi4c-storage.sql` and is safe to re-run (`IF NOT EXISTS` / `CREATE OR REPLACE`).

### Tables

#### `zodi4c_storages`

One row per storage.

| Column | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `INT` | AUTO_INCREMENT | Primary key |
| `owner` | `VARCHAR(50)` | — | Owner `citizenid` |
| `name` | `VARCHAR(100)` | — | Storage name |
| `image` | `LONGTEXT` | `NULL` | Image URL or `data:` URI |
| `slots` | `INT` | `50` | Slot capacity |
| `weight` | `INT` | `100000` | Weight capacity in grams |
| `password` | `VARCHAR(255)` | `NULL` | Optional lowercased password |
| `created_at` | `TIMESTAMP` | `CURRENT_TIMESTAMP` | Creation time |
| `updated_at` | `TIMESTAMP` | automatic | Last update time |

**Indexes**

- `PRIMARY KEY (id)`
- `idx_owner (owner)`
- `idx_created_at (created_at)`

#### `zodi4c_storage_members`

Players with access to a storage. The owner is **not** stored here.

| Column | Type | Description |
| --- | --- | --- |
| `storage_id` | `INT` | References `zodi4c_storages.id` |
| `citizenid` | `VARCHAR(50)` | Member `citizenid` |
| `name` | `VARCHAR(100)` | Cached character name |
| `joined_at` | `TIMESTAMP` | Join time |

**Keys**

- `PRIMARY KEY (storage_id, citizenid)` — a player can join a storage only once.
- `idx_member_citizen (citizenid)`
- `FOREIGN KEY (storage_id) REFERENCES zodi4c_storages(id) ON DELETE CASCADE`

#### `zodi4c_storage_logs`

Item movements and storage access.

| Column | Type | Description |
| --- | --- | --- |
| `id` | `INT` | Primary key |
| `storage_id` | `INT` | Storage reference |
| `citizenid` | `VARCHAR(50)` | Player who performed the action |
| `name` | `VARCHAR(100)` | Character name |
| `action` | `VARCHAR(50)` | `take`, `put` or `access` |
| `details` | `TEXT` | Item name/amount or `storage_open` |
| `created_at` | `TIMESTAMP` | Action time |

**Indexes**

- `PRIMARY KEY (id)`
- `idx_storage_log (storage_id)`
- `idx_log_time (created_at)`
- `FOREIGN KEY (storage_id) REFERENCES zodi4c_storages(id) ON DELETE CASCADE`

`action` values:

| Value | Meaning | UI (TR / EN) |
| --- | --- | --- |
| `take` | Item taken from the storage | ALDI / TAKEN |
| `put` | Item stored | KOYDU / STORED |
| `access` | Storage opened | GİRİŞ / ACCESS |

### Views

#### `zodi4c_storage_overview`

Lists every storage with its owner and password state.

```sql
SELECT * FROM zodi4c_storage_overview;
```

| Column | Description |
| --- | --- |
| `id`, `storage_name`, `owner_citizenid` | Basic information |
| `slots` | Slot count |
| `weight_kg` | Weight in kg (decimal) |
| `has_password` | Whether a password is set (`0`/`1`) |

#### `zodi4c_storage_memberships`

All relationships, including owners and members.

```sql
SELECT * FROM zodi4c_storage_memberships WHERE citizenid = 'abc123';
```

| Column | Description |
| --- | --- |
| `storage_id`, `storage_name` | Storage |
| `citizenid` | Player |
| `role` | `owner` or `member` |
| `joined_at` | Creation time for owners, join time for members |

#### `zodi4c_storage_inventory_details`

Joins `ox_inventory` to show which items are in which storage.

```sql
SELECT * FROM zodi4c_storage_inventory_details WHERE storage_id = 12;
```

| Column | Description |
| --- | --- |
| `storage_id`, `storage_name`, `owner_citizenid` | Storage |
| `ox_inventory_name` | `zodi4c_storage_<id>` |
| `items_json` | Raw ox_inventory data |

> `items_json` uses ox_inventory's internal format and may change between versions. Use it
> for read-only inspection; do not write to it.

### ox_inventory stash naming

Each storage uses the following stash name:

```text
zodi4c_storage_<storage_id>
```

Example: a storage with `id = 42` uses `zodi4c_storage_42`.

Items are stored in the `ox_inventory` table under that name. When a storage is deleted:

1. The stash is checked for items.
2. Deletion is refused if any item is present.
3. Otherwise the `ox_inventory` and `zodi4c_storages` rows are removed.

### Useful queries

#### All storages owned by a player

```sql
SELECT s.id, s.name, s.slots, ROUND(s.weight / 1000, 1) AS weight_kg
FROM zodi4c_storages s
WHERE s.owner = 'CITIZENID';
```

#### Storage members

```sql
SELECT m.citizenid, m.name, m.joined_at
FROM zodi4c_storage_members m
WHERE m.storage_id = 42;
```

#### Latest 50 actions

```sql
SELECT l.created_at, l.name, l.action, l.details
FROM zodi4c_storage_logs l
WHERE l.storage_id = 42
ORDER BY l.created_at DESC
LIMIT 50;
```

#### Item rows per storage

```sql
SELECT s.id, s.name, COUNT(i.id) AS item_rows
FROM zodi4c_storages s
LEFT JOIN ox_inventory i ON i.name = CONCAT('zodi4c_storage_', s.id)
GROUP BY s.id, s.name
ORDER BY item_rows DESC;
```

#### Cleaning old logs

```sql
DELETE FROM zodi4c_storage_logs
WHERE created_at < NOW() - INTERVAL 90 DAY;
```

> Logs grow without limit. Periodic cleanup or archiving is recommended on busy servers.

### Backup

```bash
mysqldump -u USERNAME -p DATABASE \
  zodi4c_storages \
  zodi4c_storage_members \
  zodi4c_storage_logs \
  > zodi4c-storage-backup.sql
```

To include the stored items, add the `ox_inventory` table:

```bash
mysqldump -u USERNAME -p DATABASE zodi4c_storages zodi4c_storage_members \
  zodi4c_storage_logs ox_inventory > full-backup.sql
```

### Common schema issues

| Symptom | Likely cause |
| --- | --- |
| `Table 'zodi4c_storages' doesn't exist` | SQL script not imported |
| `Cannot add or update a child row` | Invalid `storage_id` when adding a member |
| Turkish characters look broken | Database/table/connection is not `utf8mb4` |
| Stored items are missing | Stash name is not in the `zodi4c_storage_<id>` format |
