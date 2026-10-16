---
layout: post
title: "Rails template made easy"
date: 2019-10-19 12:00:00 +0700
categories: personal-project
comments: true
published: true
---

Di tulisan ini saya hanya ingin kasih tau kalo saya baru saja membuat *rails template* sendiri.

Jika anda seperti saya, orang yang belajar sesuatu atau mencoba sesuatu biasanya dengan implementasi projek baru (aplikasi Rails yang baru), mungkin anda lelah untuk melakukan setup instalasi *testing framework*, *bootstrap*, *javascript framework* dan sejenisnya setiap ingin memulai ber-eksperiment.

Mungkin projek ini cocok untuk anda: [rails-app-template](https://github.com/sugar-for-pirate-king/rails-app-template)

Karna projek ini, projek kemarin sore, jadi mungkin masih belum banyak yang anda dapat dari sini, tapi menurut saya ini sudah cukup untuk eksperimen projek.

Saat tulisan ini ditulis, anda akan mendapatkan:
- Setup testing framework secara penuh (system test, unit test & factory_bot)
- Vue.js (Javascript framework)
- Bootstrap (CSS Framework)
- Pry-rails (Dubugger)
- `rubocop.yml` (Static analizer)
- Costum architecture.

Namun, sebelum anda mau pakai anda harus edit file `template.rb` sesuai *local* anda, contohnya pada konstanta `BASE_PATH`.Silahkan sesuaikan dengan path template repo ini diclone.

Begitu juga dengan driver testingnya, saya pake *chrome* jadi anda harus sesuakan drivernya dengan sistem operasi anda. Linux adalah default drivernya. Dan jangan lupa juga anda harus sudah punya chrome yang terinstal di *local* anda :).

Begitu saja tulisan ini, jika anda tertarik mengembangkan projek ini agar lebih *stable* silahkan lempar pull-request-nya ke saya :)

Sekian dan terima kasih.

