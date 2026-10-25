# Contributing / Katkı Rehberi

`zodi4c-storage` projesine zaman ayırdığınız için teşekkürler. Bu rehber hem Türkçe hem
İngilizce hazırlanmıştır.

Thanks for taking the time to improve `zodi4c-storage`. This guide is available in both
Turkish and English.

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

### Başlamadan önce

- Büyük değişiklikler için önce bir issue açın; yaklaşımı birlikte netleştirelim.
- Pull request'leri odaklı tutun. Bir PR'de tek özellik veya tek düzeltme olması incelemeyi
  kolaylaştırır.
- Sunucu verisi, veritabanı dökümü, `node_modules` veya derleme çıktısı commit etmeyin.

### Geliştirme ortamı

1. Depoyu forklayın ve klonlayın:

```bash
git clone https://github.com/zodi4ctvn/zodi4c-storage.git
```

2. Klasörü test sunucunuzda `resources/[zodi4c]/zodi4c-storage` altına yerleştirin.
3. `sql/zodi4c-storage.sql` dosyasını **test** veritabanınıza aktarın.
4. Test sırasında `config.lua` içinde `Config.Debug = true` kullanın.
5. Ayrı bir test karakteri kullanın; yıkıcı işlemleri asla canlı veride denemeyin.

### Kod stili

#### Lua

- 4 boşluk, tab yok.
- Global olması gerekmeyen her şey için `local`.
- İstemciden gelen her değer sunucuda yeniden doğrulanmalı.
- Oyuncuya görünen metinler için `L('anahtar', ...)` kullanın. Yeni anahtarları **hem**
  `locales/tr.lua` **hem** `locales/en.lua` dosyasına ekleyin.
- Yorumlar kısa ve olgusal olsun; *ne* yapıldığını değil *neden* yapıldığını anlatın.
- NUI girdisine asla güvenmeyin: tip ve aralık kontrolünü `server/main.lua` içinde yapın.

#### JavaScript / CSS / HTML

- 4 boşluk, JavaScript'te noktalı virgül.
- Oyuncu tarafından kontrol edilen her değeri HTML'e yazmadan önce kaçırın (`escapeHtml`).
- Statik metinler için `data-i18n`, `data-i18n-placeholder`, `data-i18n-title` kullanın.
- `html/script.js` içindeki dinamik metinler için `t('anahtar', ...)` kullanın.
- Stilleri `html/style.css` içinde tutun; çalışma anında hesaplanmayan büyük satır içi
  stillerden kaçının.

#### SQL

- Tablo ve sütun adları `snake_case`.
- Her foreign key için `ON DELETE` kuralı tanımlayın.
- `sql/zodi4c-storage.sql` dosyasını güncelleyin ve şema değişikliklerini
  `docs/database.md` içinde belirtin.

#### Dokümanlar

- Dokümanlar iki dilli tutulur. Bir bölümü değiştirdiğinizde Türkçe ve İngilizce
  karşılığını da güncelleyin.
- README ve `docs/` dosyalarındaki bağlantıların çalıştığını kontrol edin.

### Test kontrol listesi

Pull request açmadan önce şunları doğrulayın:

- [ ] Kaynak `Config.Debug = true` ile hatasız başlıyor.
- [ ] Depo hem banka hem nakit ödemeyle oluşturulabiliyor.
- [ ] Eşya depoya konup alınabiliyor ve iki hareket de loga yazılıyor.
- [ ] Şifreli depo yanlış şifreyi reddediyor ve limitten sonra kilitleniyor.
- [ ] Üyeler depoyu açabiliyor ve ayrılabiliyor; sahip ayrılamıyor.
- [ ] Dolu depo silinemiyor.
- [ ] `tr` ve `en` dilleri arayüzde ve bildirimlerde doğru görünüyor.

### Commit mesajları

Kısa ve emir kipi konu satırları kullanın:

```text
Add per-storage capacity validation
Fix member list refresh after kick
Document password storage limitations
```

### Hata bildirimi

Hata şablonunu kullanın ve şunları ekleyin:

- FiveM artefakt sürümü
- `ox_inventory`, `oxmysql` ve `qb-core` (Qbox'ta `qbx_core`) sürümleri
- Hatayı yeniden üretme adımları
- Sunucu ve istemci konsol çıktısı
- Görsel sorunlarda ekran görüntüsü veya kısa video

### Güvenlik açıkları

Güvenlik sorunları için **herkese açık issue açmayın**. [SECURITY.md](SECURITY.md)
sürecini izleyin.

---

## English

### Before you start

- Open an issue for larger changes so the approach can be discussed first.
- Keep pull requests focused. One feature or fix per pull request is easier to review.
- Do not commit server data, database dumps, `node_modules`, or generated build output.

### Development setup

1. Fork and clone the repository:

```bash
git clone https://github.com/zodi4ctvn/zodi4c-storage.git
```

2. Place the folder at `resources/[zodi4c]/zodi4c-storage` on a test server.
3. Import `sql/zodi4c-storage.sql` into a **test** database.
4. Set `Config.Debug = true` in `config.lua` while testing.
5. Use a dedicated test character; never test destructive actions on production data.

### Code style

#### Lua

- 4 spaces, no tabs.
- `local` for everything that does not need to be global.
- Server-side validation is mandatory for every value coming from the client.
- Use `L('key', ...)` for player-facing text. Add new keys to **both** `locales/tr.lua`
  and `locales/en.lua`.
- Keep comments factual and short. Explain *why*, not *what*.
- Never trust NUI input: validate types and ranges in `server/main.lua`.

#### JavaScript / CSS / HTML

- 4 spaces, semicolons in JavaScript.
- Escape any player-controlled value before inserting it into HTML (`escapeHtml`).
- Use `data-i18n`, `data-i18n-placeholder` and `data-i18n-title` for static text.
- Use `t('key', ...)` for dynamic text in `html/script.js`.
- Keep NUI styles in `html/style.css`; avoid large inline style blocks unless values are
  computed at runtime.

#### SQL

- Table and column names use `snake_case`.
- Every foreign key needs an `ON DELETE` rule.
- Update `sql/zodi4c-storage.sql` and document schema changes in `docs/database.md`.

#### Documentation

- Documentation is bilingual. When you change a section, update both the Turkish and the
  English version.
- Check that links in README and `docs/` still work.

### Testing checklist

Before opening a pull request, verify:

- [ ] Resource starts without errors (`Config.Debug = true`).
- [ ] A storage can be created with bank and cash payment.
- [ ] Items can be stored, taken and the log records both actions.
- [ ] Password-protected storage rejects wrong passwords and locks after the configured limit.
- [ ] Members can open and leave a storage; the owner cannot leave.
- [ ] Deleting a non-empty storage is blocked.
- [ ] Both `tr` and `en` locales render correctly in the UI and notifications.

### Commit messages

Use short imperative subjects, for example:

```text
Add per-storage capacity validation
Fix member list refresh after kick
Document password storage limitations
```

### Reporting bugs

Use the bug report template and include:

- FiveM artifact version
- `ox_inventory`, `oxmysql` and `qb-core` (or `qbx_core` on Qbox) versions
- Steps to reproduce
- Server and client console output
- Screenshots or a short clip when the issue is visual

### Security issues

Do **not** open a public issue for security problems. Follow [SECURITY.md](SECURITY.md).
