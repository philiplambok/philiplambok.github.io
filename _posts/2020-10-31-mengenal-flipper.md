---
layout: post
title:  "Mengenal feature toggle di Rails"
date:   2020-10-31 10:10:00 +0700
categories: toggle-feature, rails
comments: true
published: true
---

Pada tulisan kali ini gw mau ngobrolin tentang [Flipper](https://github.com/jnunemaker/flipper). 

Sebuah paket di lingkungan Ruby, untuk membantu developing aplikasi *feature toggle*.

Apa itu *feature toggle* yang kalo dibahasa indonesia-in mungkin jadi saklar fitur (?)

Dengan fitur ini kita bisa menganti sifat dari aplikasi tanpa harus ada perubahan dari kodenya. Mamfaatnya juga ada banyak, bisa untuk prototyping, atau bisa digunakan sebagai strategi deployment atau switcher untuk fitur yang relatif besar, dan juga bisa untuk backward compatibility dengan lebih cepat dibandingnya revert deployment.

----

Seperti pada biasanya gw akan mencontohnya penggunaaan Flipper dengan studi kasus. 

Misalnya kita dapat task untuk mendevelop dashboard baru. Dashboard ini misalnya ada 20 halaman, dan kita tidak ingin melakukan 1 deployment untuk mengganti 20 halaman ini, namun misalnya dengan 1 halaman 1 deployment. 

Artinya kita ingin akan ada spesific user di production yang menggunakan fitur new dashboard dari deployment pertama. Dan user lain tetap menggunakan dashboard lama, hingga semua halaman terdevelop dengan benar.

Oke, kira-kira begitu kasusnya, mari mulai develop.

Silahkan bikin projek rails baru, dan generate simple controller

```
$> bundle exec rails g controller dashboards index
```

Pada `routes.rb`, bisa diupdate jadi gini:

```rb
Rails.application.routes.draw do
  root 'dashboards#index'
end
```

Edit viewnya dan akses urlnya, maka responsenya akan begini:

```
GET /

Dashboards#index
Welcome to dashboards
```

Oke, sekarang kita install flippernya, dengan tambah gem ini:

```rb
gem 'flipper'
gem 'flipper-ui'
gem 'flipper-active_record'
```

Jalankan `bundle install`.

Dengan buat file initializernya `config/initializers/flipper.rb`

```rb
require 'flipper'

Flipper.configure do |config|
  config.default do
    # use active records as the flipper adapter.
    adapter = Flipper::Adapters::ActiveRecord.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end
```

Kita akan menggunakan database (active record) instead memory untuk alasan kesehatan mental :)

Sekarang tambahkan routes UI-nya, di `routes.rb`:

```rb
Rails.application.routes.draw do
  mount Flipper::UI.app(Flipper) => '/flipper'

  root 'dashboards#index'
end
```

Oke, sekarang kita bisa akses halaman `/flipper` dan akan muncul UI dari Flipper. Flipper gem yang cukup terkenal, jadi ada kemungkinan ada orang yang bisa akses ke UInya. Untuk alasan keamanan anda bisa wrap halaman ini dengan otentikasi, atau bisa sembuyikan UI-nya dengan random url, untuk ini saya udah pernah tulis caranya di tulisan [Menyembunyikan spesifik routes di Rails](https://philiplambok.github.io/security,/rails/2020/10/24/menyembunyikan-routes-di-rails.html).

Sekarang pada halaman `/flipper`, klik button `add feature` lalu masukkan `new_dashboard` dan tekan `add feature` kembali.

Maka kita akan dibawa ke halaman managemen fiturnya. Pada halaman ini anda bisa tambahkan aktor baru dan masukkan string `123`. Ini kita anggap user idnya. Jadi dengan ini kita akan anggap user new dashboard akan hanya bisa dipakai oleh user 123, selain id ini akan menggunakan user lama.

Kita bikin servicenya, `app/services/new_dashboard_feature.rb`:

```rb
class NewDashboardFeature
  def self.enabled?(user_id)
    new.enabled?(user_id)
  end

  def enabled?(user_id)
    return true if Flipper.enabled?(:new_dashboard)
    return false if user_id.blank?

    actors = Flipper::Adapters::ActiveRecord::Gate.where(
      feature_key: 'new_dashboard',
      key: 'actors'
    )
    return false if actors.blank?

    user_ids = actors.pluck(:value)
    return false unless user_ids.include?(user_id)

    true
  end
end
```


Sekarang pada viewsnya kita update jadi seperti ini:

```erb
<h1>Dashboards#index</h1>
<% if  NewDashboardFeature.enabled?(params[:user_id]) %>
  <p>Welcome to new dashboards</p>
<% else %>
  <p>Welcome to dashboards</p>
<% end %>
```

Sekarang kembali akses halaman `localhost:3000/`

```
Dashboards#index
Welcome to dashboards
```

Masih menggunakan dashboard lama, sekarang kita masukkan user_id 123 `localhost:3000?user_id=123`

```
Dashboards#index
Welcome to new dashboards
```

Dan jika yang akses user id lain, misalnya `localhost:3000?user_id=1234`:

```
Dashboards#index
Welcome to dashboards
```

Dan jika anda butuh user lain, tinggal tambahkan idnya di aktor pada halaman fitur `new_dashboard`. Dan jika sudah aman, dan ingin fitur new dashboard ini digunakan di semua user tinggal klik tombol "Fully enable" di halaman managemen fitur `new_dashboard` di Flipper UI-nya.

Maka semua user termasuk user id 123 `localhost:3000?user_id=123` akan menggunakan dashboard baru:

```
Dashboards#index
Welcome to new dashboards
```

Dan jika ternyata ada issue, ingin melakukan revert, bisa klik tombol "Disable" di index page Flipper UI. Maka semua user akan menggunakan dashboard lama, termasuk user_id 123 `localhost:3000?user_id=123`:

```
Dashboards#index
Welcome to dashboards
```

----

Mungkin itu saja tulisan kali ini, jika tertarik dengan kode sumbernya bisa ditemukan disini: [https://github.com/sugar-for-pirate-king/play-with-flipper](https://github.com/sugar-for-pirate-king/play-with-flipper).

Happy hacking~~
