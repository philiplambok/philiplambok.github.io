---
layout: post
title:  "Menyembunyikan spesifik routes di Rails"
date:   2020-10-24 10:10:00 +0700
categories: security, rails
comments: true
published: true
---

Setelah lama gk nulis, akhirnya ada kesempatan lagi ~

Pada kali ini mau coba ngobrolin terkait security atau keamanan.

Tulisan ini terinspirasi dari salah satu website [https://1password.com/](https://1password.com/). Website ini adalah aplikasi untuk manajemen password. 

Jadi jika lu suka mengganti-ganti password alasan keamanan, dan lumayan capek inget-inget passwordnya, website ini bisa jadi pilihan.

Bermula dari pertama kali gw coba login dan masuk ke dashboardnya, url yang ditampilkannya kira-kira gini:

```
https://my.1password.com/vaults/TavH07LQEUCDlwdgIsEqQ8nZyGTcSMe7w/allitems/aXdjKycQqK3Z8mlFwAvRFAJJop8CdSjfp
```

Tenang, untuk random stringnya di urlnya gw generate sendiri kok :)

Akhirnya coba-coba lihat network-nya, dan ternyata data-data yang dikirim lewat api-nya juga ikut di encrypt. Cukup menarik. 

---

Dari kasus ini, tertarik coba implementasi konsep ini di Rails. Konsep ini bisa di implementasi untuk halaman-halaman atau endpoint-endpoint api
yang bersifat rahasia. Atau halaman yang hanya dipakai oleh tim internal, contohnya umumnya seperti halaman Admin. 

Biasanya admin hanya diakses oleh tim internal, kita tidak ingin ada user atau guess yang bisa akses admin. Jadi mari kita coba implementasi saja.

Tujuannya adalah kita ingin tetap bisa menggunakan module `admin` di kode Ruby-nya. Karna lucu jika kita punya module dengan nama `aXdjKycQqK3Z8mlFw`. Jadi intinya bagaimana
kita menggubah ulrnya tanpa merubah codebase yang udah ada (jika dengan di kode turunan).

Kalo lu pake administrate atau develop admin sendiri, kira-kira routesnya begini:

```rb
namespace :admin do
  resources :dashboards, only: %i[index]
end
```

```
$> rails routes | grep admin_dashboard
   admin_dashboards GET    /admin/dashboards(.:format)      admin/dashboards#index
```

Sekarang coba kita hide route adminnya dengan menggantinya dengan random string. Random stringnya bisa digenerate pake module `SecureRandom`.

```rb
$> irb
irb(main):001:0> require 'securerandom'
=> true
irb(main):002:0> SecureRandom.urlsafe_base64
=> "2J-PxHMzm0CiggrRZIcreg"
```

Sekarang ganti routesnya jadi gini:

```rb
scope module: :admin, path: '2J-PxHMzm0CiggrRZIcreg', as: :admin do
  resources :dashboards, only: %i[index]
end
```

Maka hasilnya akan begini:
```
$> rails routes | grep admin_dashboard
   admin_dashboards GET    /2J-PxHMzm0CiggrRZIcreg/dashboards(.:format)     admin/dashboards#index
```

Goalsnya tercapai. urlnya berubah, namun nama modul dan nama pathnya masih sama. 

Maka kita bisa pastikan kita tidak perlu ganti kode-kode yang lain, fiturnya yang di dalam module `admin` masih bisa dipakai dengan semestinya.

Sekarang usernya tidak bisa akses /admin. Karna akan mendapat error 404. 

Jika lu pake active admin, kasusnya beda dikit, karna routesnya begini:

```rb
ActiveAdmin.routes(self)
```

Untuk kasus ini bisa diubah dengan tambahin prefixnya aja:

```rb
scope path: '2J-PxHMzm0CiggrRZIcreg' do
  ActiveAdmin.routes(self)
end
```

Jadinya adminnya gk bisa diakses begini: /admin, tapi harus begini: /2J-PxHMzm0CiggrRZIcreg/admin.

Maka, kasus ini juga tujuannya tercapai kode-kode yang relatif ke active admin tidak perlu ada changes lagi, fitur akan tetep bisa dipakai dengan semestinya.

---

Sebelum mengakhiri tulisan, buat temen-temen yang belum terlalu kenal dengan kode `scope` mari kita ngobrol dikit.

Jadi `scope` adalah salah satu helper yang bisa dipake di `routes.rb`. Dibandingkan dengan `namespace`, scope lebih flexible. 

Jadi kalo di namespace kita dapet gini:

```rb
namespace :admin do
  resources :dashboards, only: %i[index]
end
```

```
$> rails routes | grep admin_dashboard
   admin_dashboards GET    /admin/dashboards(.:format)      admin/dashboards#index
```

Kalo di scope kita bisa bikin jadi gini untuk mendapatkan hasil yang sama:

```rb
scope module: :admin, path: :admin, as: :admin do
  resources :dashboards, only: %i[index]
end
```

```
$> rails routes | grep admin_dashboard
   admin_dashboards GET    /admin/dashboards(.:format)      admin/dashboards#index
```

Didalam scope ini kita mengenal tiga key `module:`, `path:`, dan `as:`. `module:` untuk define modulenya, `path:` untuk define url pathnya (prefix) dan `as:` untuk mendefine helpernya (prefix).

Tapi dalam kasus ini `path:` dan `as:`-nya sama, rails punya versi ringkasnya:

```rb
scope :admin, module: :admin, as: :admin do
  resources :dashboards, only: %i[index]
end
```

Kode ini akan tetap menghasilkan routes yang sama. Untuk lebih jelas dan detailnya bisa ke dokumentasinya langsung [disini](https://api.rubyonrails.org/v5.1/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-scope).


---

Sekian saja tulisan kali ini, terima kasih telah membaca yaa

Happy hacking~~