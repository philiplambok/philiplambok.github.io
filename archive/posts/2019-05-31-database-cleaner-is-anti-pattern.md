---
layout: post
comments: true
title:  "database_cleaner is anti-pattern"
date:   2019-05-31 13:10:00 +0700
categories: rails-test
comments:   true
published: true
---

Tulisan ini hanyalah sedikit ulasan tentang hal yang terjadi pada hari ini.

Hari ini saya mendapat kesempatan untuk mempercepat _running time_ dari kode test pada projek saya. Sedikit informasi saja, projek saya ini dibuat menggunakan Ruby 2.5.0 dan Rails 5.2.2.

Pada projek ini saya memiliki test sebanyak 638 _case_ dengan tingkat _coverage_ sekitar 95%. Setiap menjalankan full-spec-nya akan memakan waktu sekitar 21 menit sudah termasuk booting-nya.

```
$> time rspec
638 examples, 0 failures
Coverage report generated for RSpec (95.33%) covered.
bundle exec rspec 488,63s user 20,80s system 39% cpu 21:22,95 total
```

Sebelumnya saya sudah mendengar dari beberapa artikel atau video conference tentang _database_cleaner_ yang melambatkan _running time_ dari kode test. Maka langkah pertama saya adalah menghapus gem _database_cleaner_ ini.

Namun, setelah saya jalankan kode testnya banyak yang failure, karena memang _database_cleaner_ pada feature spec sangat dibutuhkan. Maka, saya mencoba mengganti feature spec menjadi system spec. Feature spec nyatanya sama dengan system spec, feature spec dibuat oleh team capybara sebelum munculnya system spec sehingga dalam setup data testnya perlu bantuan dari gem yang lain (_database_cleaner_ sebagai contohnya).

Sedangkan system spec adalah tipe spec yang ada dalam Rails secara default, artinya kita tidak perlu bantuan paket/gem dari luar untuk melakukan setup data testnya. Setelah saya mengganti semua fitur test menjadi sistem test dengan bantuan artikel [ini](https://medium.com/table-xi/a-quick-guide-to-rails-system-tests-in-rspec-b6e9e8a8b5f6) atau [ini](https://stackoverflow.com/a/49248170), akhirnya saya selesai melakukan migrasi dan untuk testnya saya juga berhasil (_passed_) ketika dijalankan kembali.

Yang mengejutkan adalah _running time_ test saya turun drastis menjadi hanya sekitar 1 detik:

```
$> time rspec
bundle exec rspec 42,90s user 2,37s system 69% cpu 1:05,15 total
```

Waktu testnya totalnya berkurang hingga 20 menitan, bahkan waktu loadnya juga hanya 2 detik saja dibandingkan yang sebelumnya sekitar 20 detik. Angka yang cukup epik.

Tapi saya tidak berhenti sampai disitu saja, saya juga mencoba mematikan rails untuk menulis kode log di lingkungan testing dengan menulis kode berikut di file `config/environtment/test.rb` :

```ruby
Rails.application.configure do
  config.logger = Logger.new(nil)
  config.log_level = :fatal
  # ....
end
```

Lalu saya mencoba menjalankan kode testnya lagi :

```
$> time rspec
bundle exec rspec 35,86s user 1,30s system 87% cpu 42,272 total
```

Waktunya menjadi sekitar 42 detik saja, tidak sampai 1 menit, lagi-lagi sangat epik bagaimana hanya 2 baris saja bisa mempercepat kode test yang lumayan besar.

Jika pada projek anda memiliki _database_cleaner_, dan kode test anda juga berjalan lambat mungkin anda bisa memikirkan untuk upgrade Rails anda ke versi 5.1 atau lebih. Karena system spec memang diperkenalkan pada versi tersebut. Namun, jika versi Rails anda 5.1 atau diatasnya maka tidak ada alasan anda menggunakan _database_cleaner_.

Pada software development saat ini, test menjadi intinya. Test yang berjalan cepat maka feedback yang anda dapat juga menjadi lebih cepat. Feedback yang cepat akan menaikan produktif anda dalam menulis kode.

Sebenernya pada projek ini juga masih banyak menggunakan query-query ke database karena memang masih belum menggunakan _factory_bot_. Sehingga sebenernya testnya masih dapat di-_improve_ lagi, pengenalan _factory_bot_ pada projek ini akan dilakukan di lain waktu, karena memang membutuhkan waktu yang tidak singkat.

Btw, sebenernya _database_cleaner_ itu bukan sebuah _pattern_ sih, lebih tepatnya dia itu paket atau _library_, tapi _yaudahlah_ kata _Anti-pattern_ sudah terlanjur kental dengan sesuatu hal yang tidak baik atau larangan terhadap sesuatu, jadinya pake kata itu aja :D

Oke cukup sekian tulisan kali ini, semoga dapat bermamfaat bagi pembaca skalian.

Terima kasih.
