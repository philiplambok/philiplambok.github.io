---
layout: post
title:  "Mengenal Rails engine"
date:   2020-12-26 14:10:00 +0700
categories: rails, engine
comments: true
published: true
---

Tulisan ini hanyalah pengatar atau mengenalkan tentang "Apa itu rails engine" ke pembaca. Jika anda sudah tau atau mengenal bahkan menulis rails engine mungkin anda tidak akan mendapat sesuatu baru dari tulisan ini :)

Ok, langsung mulai saja.

Jadi, apa itu Rails engine? Kalo kita baca dokumentasi Railsnya ditulis begini:

> Engines can be considered miniature applications that provide functionality to their host applications.

Kira-kira kalo diartikan Rails engine itu adalah aplikasi rails "mini" yang menyediakan fitur untuk aplikasi hostnya atau aplikasi *root* atau pemanggilnya.

Mungkin agak membingungkan, biar lebih jelas mari kita coba lihat cara implementasinya.

Misalnya kita membuat sebuah aplikasi kasir, dan kita ingin membuat fitur blog. Karena aplikasi blog ini nantinya tidak akan menyentuh fitur-fitur yang ada di core sistem, dan juga akan punya tim khusus untuk menghandle aplikasi blog ini kita bisa pisahkan aplikasi rails antara core sistem dengan aplikasi blog dengan konsep rails engine ini.

Mari buat aplikasi Railsnya terlebih dahulu:

```sh
$> rails new rails-engine -T --database=mysql
```

Setelah terbuat, kita generate enginenya dengan perintah ini:

```sh
$> rails plugin new blog --mountable
```

Setelah proses selesai, rails akan membuat mini rails di `/blog` kita bisa rapihkan foldernya sesuai docsnya jadi gini:

```
$> mkdir engines
$> mv blog engines/blog
```

Setelah rapih, sekarang include engine ini ke main appnya (host) dengan:

```rb
# config/routes.rb
Rails.application.routes.draw do
  root 'home#index'
  mount Blog::Engine => '/blogs'
end
```

Lalu mappingin juga routes di dalam enginenya:
```rb
# engines/blog/config/routes.rb
Blog::Engine.routes.draw do
  root 'home#index'
end
```

Sekarang hit halaman `/blogs`nya dari url, maka akan merenspon dari view `home#index` yang di dalam engine blognya.

Dengan rails engine, maka aplikasi rails menjadi terisolasi dan tidak menggangu core sistem. Untuk *people*-nya juga bisa menjadi lebih produktif karena proses onboarding dan scope aplikasi menjadi jelas.

Pola ini juga ada yang menyebutnya sebagai *Component-Based Rails Application*, jika anda tertarik lebih lanjut anda bisa membaca bukunya disini: [https://cbra.info/](https://cbra.info/). Buku itu menjelaskan bagaimana kita membuat dan merancang desain komponen hingga *technical things*-nya seperti bagaimana proses migrasi database dan strategi deploymentnya.

---

Sepertinya cukup sampai sini aja tulisan kali ini,

Makasih sudah membaca yaa :)

