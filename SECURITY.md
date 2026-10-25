# Security Policy / Güvenlik Politikası

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

### Desteklenen sürümler

| Sürüm | Destek |
| --- | --- |
| 1.0.x | Evet |

### Açık bildirimi

Güvenlik sorunları için lütfen **herkese açık issue açmayın**.

Bunun yerine bakımcıya özel olarak şunları iletin:

- Sorunun tanımı ve etkisi
- Hatayı yeniden üretme adımları
- Etkilenen sürüm ve yapılandırma
- Varsa kavram kanıtı kod veya loglar (oyuncu verilerini sansürleyin)

Bakımcıya GitHub profili üzerinden ulaşabilirsiniz:
[`zodi4ctvn`](https://github.com/zodi4ctvn).

72 saat içinde geri dönüş yapılması hedeflenir. Lütfen kamuya açıklamadan önce düzeltme
için makul süre tanıyın.

### Kapsam

Kapsam içinde:

- Depolara veya eşyalara yetkisiz erişim
- Yetki yükseltme (örneğin bir üyenin sahip gibi davranması)
- SQL enjeksiyonu veya güvensiz veritabanı işlemleri
- NUI'da XSS veya HTML enjeksiyonu
- Kaynağın neden olduğu eşya çoğaltma veya kaybı
- Şifre kilidinin atlatılması

Kapsam dışında:

- `qb-core` (Qbox'ta `qbx_core`), `ox_inventory`, `oxmysql` veya FiveM'in kendi sorunları
  (ilgili projelere bildirin)
- Sunucu yapılandırma hataları (zayıf veritabanı şifresi, açık portlar)
- Sosyal mühendislik
- Meşru yönetici işlemleriyle yapılan hizmet engelleme

### Bilinen sınırlamalar

#### Şifre saklama

Depo şifreleri veritabanında **küçük harfe normalize edilerek** saklanır, hash'lenmez.
Bu, README'de açıklanan bilinçli bir uyumluluk tercihidir. Veritabanı erişimi olan herkes bu
şifreleri okuyabilir. bcrypt/argon2 tabanlı bir yapıya geçiş planlanmaktadır.

#### Depo keşfi

`getStorages` sunucudaki tüm depoları döndürür; oyuncular böylece yeni depoları keşfedebilir.
Bu nedenle depo adları ve görselleri her oyuncu tarafından görülebilir. Depo adlarında
hassas bilgi kullanmayın.

Şifresi olmayan bir depo, depo listesini gören **her oyuncuya açıktır**. Özel depolar için
her zaman şifre belirleyin.

#### İstemci tarafı doğrulama

NUI, form girdisini kullanıcı deneyimi için doğrular; ancak sunucu her değeri yeniden
doğrular. Kaynağı değiştirirken yalnızca istemci kontrollerine güvenmeyin.

---

## English

### Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | Yes |

### Reporting a vulnerability

Please **do not** open a public issue for security problems.

Instead, contact the maintainer privately with:

- A description of the issue and its impact
- Steps to reproduce
- Affected version and configuration
- Any proof-of-concept code or logs (redact player data)

You can reach the maintainer through the GitHub profile
[`zodi4ctvn`](https://github.com/zodi4ctvn).

You should receive an acknowledgement within 72 hours. Please allow reasonable time for a fix
before public disclosure.

### Scope

In scope:

- Unauthorized access to storages or items
- Privilege escalation (for example, a member acting as an owner)
- SQL injection or unsafe database handling
- XSS or HTML injection in the NUI
- Item duplication or loss caused by the resource
- Bypassing the password lockout

Out of scope:

- Issues in `qb-core` (`qbx_core` on Qbox), `ox_inventory`, `oxmysql` or FiveM itself
  (report them upstream)
- Server misconfiguration (weak database credentials, exposed endpoints)
- Social engineering
- Denial of service through legitimate administrative actions

### Known limitations

#### Password storage

Storage passwords are stored in the database **lowercased and normalized**, not hashed.
This is a deliberate compatibility trade-off documented in the README. Anyone with database
access can read them. An upgrade to bcrypt/argon2 hashing is planned.

#### Storage discovery

`getStorages` returns all storages on the server so players can discover and join them.
Storage names and images are therefore visible to every player. Do not use storage names for
sensitive information.

A storage **without a password is open to every player** who can see the storage list.
Always set a password for private storages.

#### Client-side validation

The NUI validates form input for a better user experience, but the server re-validates every
value. Never rely on the client checks alone when modifying the resource.
