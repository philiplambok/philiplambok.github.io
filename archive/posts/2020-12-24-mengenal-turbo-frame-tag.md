---
layout: post
title:  "Mengenal turbo_frame_tag di Hotwire"
date:   2020-12-24 14:10:00 +0700
categories: rails, new-magic
comments: true
published: false
---

Oke, the "New Magic" yang ditunggu-tunggu akhirnya muncul juga ke darat.

Mumpung lagi libur, jadi coba nulis lagi aja.

Pada tulisan ini gw cuman mau bahas salah satu fitur aja dari paket ini yaitu `turbo_frame_tag`. 

Hotwire sendiri fiturnya ada banyak bukan ini aja, tapi emang di tulisan ini gw cuman mau bahas ini aja, untuk yang lainnya bakal ditulisan ditulisan yang lain.

`turbo_frame_tag` ini konsepnya sangat simple, banyakan aja seperti tag `iframe`. Html yang dibungkus di dalem tag ini akan berubah-berubah secara partial atau terisolasi dengan html yang diluar tag ini, persis seperti `iframe`. 

Kita coba praktekan aja. Sekarang bikin aplikasi baru:

```
$> rails new turbo_frame_tag --database=mysql -T --webpacker=stimulus 
```

Sebenernya enggak perlu stimulus juga gapapa sih, gw pake ini untuk skalian kasih tau gimana install di legacy projek yang udah keinstall webpackernya.

Oke, setelah selesai dibuat, sekarang tambahkan gem ini:

```rb
gem 'hotwire-rails'
```

Sekarang jalankan 
```
$> bundle install
```

lalu selanjutnya jalankan ini:

```
$> hotwire:install
```

Setelah selesai, rails akan membuat beberapa file. Lalu di ubah file `application.js`-nya jadi begini:

```js
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import * as ActiveStorage from "@rails/activestorage"
import "channels"
import { Turbo, cable } from "@hotwired/turbo-rails"
ActiveStorage.start()
import "controllers"
```

Hapus `Turbolinks` dan `rails-ujs`nya dan tambahkan `import { Turbo, cable } from "@hotwired/turbo-rails"`. Cara installasi ini didapat dari dokumentasinya, silahkan lihat disini untuk referensinya: [https://github.com/hotwired/hotwire-rails](https://github.com/hotwired/hotwire-rails)
