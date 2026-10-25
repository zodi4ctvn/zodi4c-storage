# Changelog / Sürüm Geçmişi

Biçim [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) temellidir ve proje
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) kullanır.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

### [1.0.0] - 2026-10-25

İlk genel sürüm.

#### Eklenen

- ox_inventory stash'leri üzerinde depo oluşturma, açma, paylaşma ve silme.
- Şifre korumalı erişim; şifre uzunluğu, hatalı deneme limiti ve geçici kilit.
- Üye yönetimi: üye atma, "Depodan Ayrıl" ve sunucu tarafında sahiplik kontrolü.
- Yönetim paneli: depo düzenleme, kapasite güncelleme, şifre değiştirme ve detaylı hareket
  logları (son 150 kayıt).
- Ana menüde arama, favoriler, sayfalama ve görsel önizleme.
- Depo oluşturmada birden fazla ödeme yöntemi ve oluşturma başarısız olursa otomatik iade.
- Türkçe (`tr`) ve İngilizce (`en`) dil dosyaları, paylaşılan `L()` yardımcısı ve İngilizce
  yedek.
- `Config.Locale`, `Config.Security` ve `Config.Features` ayarları.
- NUI'da depo adı, üye adı ve log detayları için HTML kaçırma (XSS koruması).
- Qbox (QBX) desteği: `qbx_core` içindeki `provide 'qb-core'` köprüsü sayesinde ek uyumluluk
  kaynağı gerekmez.
- Türkçe + İngilizce README, kurulum, yapılandırma, veritabanı, olaylar ve sorun giderme
  dokümanları.

#### Notlar

- Log hareketleri görünen metinler yerine sabit değerler kullanır: `take`, `put`, `access`.
- Depo güncelleme, şifre değiştirme ve kapasite güncelleme işlemleri `affectedRows` yerine
  sahiplik ön kontrolü kullanır; değişiklik olmasa da hatalı uyarı çıkmaz.
- Mevcut şifre varken şifre değiştirmek için eski şifre zorunludur.

---

## English

### [1.0.0] - 2026-10-25

First public release.

#### Added

- Create, open, share and delete storages backed by ox_inventory stashes.
- Password-protected access with length limits, a failed-attempt counter and a temporary
  lockout.
- Member management: kick, "Leave storage" and server-side ownership checks.
- Management panel: storage editing, capacity updates, password changes and detailed
  activity logs (latest 150 entries).
- Search, favorites, pagination and image preview in the main menu.
- Multiple payment methods for storage creation, with an automatic refund when creation
  fails.
- Turkish (`tr`) and English (`en`) locale files, a shared `L()` helper and an English
  fallback.
- `Config.Locale`, `Config.Security` and `Config.Features` options.
- HTML escaping in the NUI for storage names, member names and log details (XSS protection).
- Qbox (QBX) support: the `provide 'qb-core'` bridge inside `qbx_core` means no extra
  compatibility resource is required.
- Turkish + English documentation for installation, configuration, database, events and
  troubleshooting.

#### Notes

- Log actions use canonical values instead of display strings: `take`, `put`, `access`.
- Storage updates, password changes and capacity updates pre-check ownership instead of
  relying on `affectedRows`, so no false failure message appears when nothing changed.
- Changing a password requires the current password when one is already set.
