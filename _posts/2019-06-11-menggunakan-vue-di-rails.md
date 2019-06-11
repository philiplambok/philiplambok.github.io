---
layout: post
comments: true
title:  "Menggunakan Vue di Rails"
date:   2019-06-11 13:10:00 +0700
categories: vue-rails
comments:   true
published: true
---

Kebetulan hari ini saya baru saja melakukan migrasi teknologi javascript pada proyek saya yang menggunakan vue.js.

Sebelumnya saya menggunakan gem [vuejs-rails](https://github.com/adambutler/vuejs-rails) dan terdapat kendala pada testnya, yaitu ketika saya menggunakan fitur _component_ pada vue.js, kode test saya tidak bisa membaca isi dalam dari _component_ yang bersangkutan.

Maka daripada itu saya melakukan migrasi untuk menggunakan gem [webpacker](https://github.com/rails/webpacker), webpacker adalah teknologi baru di rails untuk bekerja pada moderen javascript. Webpacker ini juga rencananya akan dimuat secara default menggantikan asset pipeline pada Rails 6 yang akan di rilis 30 April nanti.

Maka sekarang mungkin waktu yang tepat untuk menggunakan ini legacy sistem anda.

Tulisan ini akan membahas langkah-langkah bagaimana menggunakan webpacker(vue) pada legacy sistem, namun bisa juga pada sistem yang baru.

#### Langkah Pertama: Menghapus Turbolinks

Langkah pertama adalah menghapus penggunaan _turbolinks_.

Turbolink adalah sebuah paket yang dibuat oleh Basecamp yang memfasilitasi teknologi PWA pada website anda. Namun, nyatanya paket ini dapat membuat kompleks kode anda dan pengalaman saya banyak error-error yang terjadi yang mungkin sulit untuk ditangani, karena masalah low-level dari paket ini.

Bagi saya javascript ini sudah cukup kompleks, dan penggunaan turbolinks dapat membuat kodenya menjadi makin kompleks lagi, sehingga menurut saya penggunaan turbolinks ini tidak terlalu relevan.

Cara menghapus turbolink, langkah-langkahnya adalah:

1. Menghapus gem `turbolinks` pada `Gemfile` anda:

   ```Gemfile
   # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
   gem 'turbolinks', '~> 5'
   # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
   gem 'jbuilder', '~> 2.5'
   # Use Redis adapter to run Action Cable in production
   # gem 'redis', '~> 4.0'
   ```

   Jika anda menggunakan masih menggunakan `coffee-rails` sebaiknya juga dihapus saja, lebih baik gunakan `es6`.

2. Jalankan perintah `$> bundle`
3. Lalu hapus `require turbolinks` pada `application.js` anda.

   ```js
   //= require rails-ujs
   //= require activestorage
   //= require turbolinks
   //= require_tree .
   ```

4. Setelah itu pada file `application.html.erb` hilangkan turbolinks pada `javscript`

   ```erb
   <!-- Ganti -->
   <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload'%>

   <!-- Menjadi -->
   <%= javascript_include_tag 'application' %>
   ```

5. Lalu restart server anda, dan selesai.

#### Langkah Kedua: Install webpacker

Setelah turbolinksnya dihapus maka anda sekarang mulai menginstall gem Webpacker-nya, langkah-langkahnya:

1. Tambahkan kode ini pada file `Gemfile` anda.

   ```Gemfile
   gem 'webpacker', '~> 4.x
   ```

   Lalu, jalankan perintah (secara berurutan):

   ```
   $> bundle
   $> bundle exec rails webpacker:install
   $> yarn upgrade
   ```

2. Setelah webpacker telah terinstall, langkah selanjutnya anda bisa melakukan installasi vue-nya, dengan menjalankan perintah:

   ```
   $> bundle exec rails webpacker:install:vue
   ```

   Selesai.

   Lebih lanjut mengenai installasi ini anda bisa lihat di [https://github.com/rails/webpacker](https://github.com/rails/webpacker)

Setelah instalasi anda akan dibuatkan folder yang berisi file-file di `app/javascript`. Dimana sekarang kode development kita sudah berada di folder ini, bukan di `app/assets/javascript` lagi.

Development frontend tanpa assets javascript ini sebenernya sudah memungkinkan, namun jika anda berada pada proyek _legacy_ saya tidak menganjurkan untuk menghapusnya.

#### Langkah Terakhir: Setup Vue Component

Ok, sekarang kita sudah berada di tahap terakhir.

Sebelumnya mari kita melihat kode di dalam `app/javascript/packs/hello_vue.js` yang berisi kode untuk menampilkan component `App`(dari file `app.vue`) pada akhir element dari `body` tag. Sekarang kita mencoba untuk menjalankan file ini di rails kita untuk melihat apakah vue sudah berjalan seperti yang kita ekspektasikan.

Untuk menjalankannya anda hanya tinggal menambahkan kode ini di dalam `<head>` tag.

```erb
<head>
    <title>RailsVueWebpackerExample</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload'
    <!-- Tambahkan baris kode dibawah ini -->
    <%= javascript_pack_tag 'hello_vue' %>
  </head>
```

Silahkan buat satu file controller untuk melihat hasilnya:

```
$> rails g controller home index
```

Silahkan buka halaman `/home/index` dan anda akan melihat hasilnya disana.

Namun pada produksi kita tidak menggunakan file ini, melainkan kita akan menggunakan `application.js`.

Untuk mengakhiri tulisan ini kita akan membuat dua buah component di dua halaman yang berbeda, yaitu `home/index` dan `dashboard/index`.

Jika sebelumnya `home/index` sudah dibuat, sekarang kita membuat `dashboard/index`.

```
$> rails g controller dashboard/index
```

Dan pada viewsnya masing-masing kita menulis tagnya seperti ini:

```erb
<!-- app/views/dashboard/index.html.erb  -->
<h1>Dashboard#index</h1>
<app-dashboard></app-dashboard>
```

```erb
<!-- app/views/home/index.html.erb -->
<h1>Home#index</h1>
<app-home></app-home>
```

Kita akan membuat dua component yaitu: `app-home` dan `app-dashboard`.

Maka buatlah file baru: `app/javascript/app-home.vue` dan tulis kode seperti dibawah ini:

```vue
<template>
  <div id="app-home">
    <p>{{ message }}</p>
  </div>
</template>

<script>
export default {
  data: function() {
    return {
      message: "Pesan dari app-home"
    };
  }
};
</script>

<style>
p {
  color: deeppink;
}
</style>
```

Lalu, buatlah file baru juga: `app/javascript/app-dashboard.vue` dan tulis kode sama seperti dibawah ini:

```vue
<template>
  <div id="app-dashboard">
    <p>{{ message }}</p>
  </div>
</template>

<script>
export default {
  data: function() {
    return {
      message: "Pesan dari app-dashboard"
    };
  }
};
</script>

<style>
p {
  color: darkblue;
}
</style>
```

Lalu terakhir, daftarkan kedua file(_component_) diatas pada file `app/javascripts/packs/application.js`, seperti kode dibawah ini:

```js
import Vue from "vue/dist/vue.esm";
import AppHome from "../app-home.vue";
import AppDashboard from "../app-dashboard.vue";

document.addEventListener("DOMContentLoaded", () => {
  const app = new Vue({
    el: "#app",
    data: {},
    components: { AppHome, AppDashboard }
  });
});
```

Jika kita liat kode diatas, kedua komponent itu didaftarkan ke dalam salah satu id tertentu, pada kode diatas yaitu `#app`. Maka pada file `app/views/application.html.erb` kita ubah kodenya menjadi seperti ini:

```html
<body>
  <div id="app">
    <%= yield %>
  </div>
</body>
```

Kita apit `<%= yield %>`-nya di dalam `div#app`.

Dan jangan lupa untuk memodifikasi file `config/initializers/content_security_policy.rb` yang sebelumnya sudah dibuat ketika kita install webpackernya menjadi:

```rb
Rails.application.config.content_security_policy do |policy|
  if Rails.env.development?
    policy.script_src :self, :https, :unsafe_eval, :unsafe_inline
  else
    policy.script_src :self, :https
  end
end
```

Lalu restart ulang rails servernya dan tambahkan terminalnya untuk menjalankan webpack-server dengan perintah `$> bin/webpack-dev-server`.

Ketika bekerja dengan webpack, kita membutuhkan dua port server, jika anda ingin flexibilitas, anda bisa gunakan [foreman](https://github.com/ddollar/foreman). Penggunakan _forman_ diluar scope tulisan ini, anda bisa baca dokumentasi pada link yang bersangkutan.

Setelah kedua port tersebut jalan, maka anda bisa melihat pesannya tampil di kedua halaman tersebut.

Begitu juga dengan test-nya. Anda bisa menggunan `system-spec` untuk melakukan pengujian pada kedua halaman tersebut dengan mudah:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home index', type: :system, js: true do
  it 'returns expected message' do
    visit home_index_path
    expect(page).to have_content 'Pesan dari app-home'
  end
end

RSpec.describe 'Dashboard index', type: :system, js: true do
  it 'returns expected message' do
    visit dashboard_index_path
    expect(page).to have_content 'Pesan dari app-dashboard'
  end
end
```

Untuk setting configuration pada `system-spec` ini anda bisa ikuti [panduan ini](https://medium.com/table-xi/a-quick-guide-to-rails-system-tests-in-rspec-b6e9e8a8b5f6)

Sekiranya sampai sini saja tulisan ini, untuk lebih kompleks mengenai vue.js mungkin akan saya tulis di tulisan yang lain,

Sampai bertemu lagi.
