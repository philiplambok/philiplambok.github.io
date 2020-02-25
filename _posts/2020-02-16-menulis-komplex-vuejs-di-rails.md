---
layout: post
title: "Bekerja dengan kompleks Vue.js di Rails"
date: 2020-02-16 11:00:00 +0700
categories: design-system, rails-webpacker, vue.js 
comments: true
published: false
---

Weekend di minggu dua minggu terakhir ini, mencoba belajar bagaimana menulis kode *large-scaleable* components di frontend teknologi. 

Dimulai membaca buku [Atomic Design by Brad frost](https://bradfrost.com/blog/post/atomic-web-design/) dan mendapatkan pelajaran baru yang menarik, dimana menggambil konsep atau terminologi dari kimia seperti atom, molekul, organisme dan sejenisnya. 

Buku yang menarik!

Brad mengkategorikan komponen menjadi 5 bagian, yaitu Atom, Molekul, Organisme, Template dan Halaman.
- Atom, layaknya kita kenal pada kimia adalah unit terkencil. Pada dunia frontend `<Button>`, `<Label>`, `<Span>` adalah atom-atom. 
- Molekul, satuan kecil yang menandung arti tertentu yang terdiri dari atom-atom. Brad bilang `<FormSearch>` adalah sebuah molekul, karena ia satuan kecil yang mengandung arti yang juga hanya mengandung 3 buah atom: `<Label>`, `<FieldText>` dan `<Button>`. 
- Organisme, sebuah satuan yang dapat terdiri dari beberapa molekul atau juga atom. Brad mengambil contoh sebuah `<Navbar>` adalah sebuah organisme. Karena ia bisa terdiri dari `<FormSearch>`, `<NavbarMenu>` dan `<Logo>`.
- Template, adalah sebuah *instance* dari page.
- Page, adalah halaman. Jadi, pada atomic design satu halaman hanya dimiliki oleh satu komponen page.  

Setelah membaca buku itu, saya mencoba mengimplementasikan di lingkungan Rails. 

Pada artikel ini kita akan membuat sebuah fitur yang implementasinya di frontendnya cukup komplex. Kita akan membuat fitur instalasi atau regitrasi yang mungkin bisa dilihat dari mockup seperti ini: 

1. Halaman register langkah pertama 

   ![Registration step one](/assets/step1.png)

2. Halaman register langkah kedua

   ![Registration step two](/assets/step2.png)

3. Halaman register langkah ketiga

   ![Registration step three](/assets/step3.png)

Kita tidak akan membahas tentang terminologi - terminologi yang ada di Atomic design, tapi lebih ke pengimplementasiannya yang saya dapat dari prinsip tersebut untuk membuat sebuah fitur yang cukup kompleks.

Mari kita mulai. 

Silahkan buat projek baru yang sudah terinstal vue-webpacker dan boostrap. 

Pertama, kita akan membuat fitur registrasi yang pertama.

Silahkan buat routesnya untuk step1: 

```rb
Rails.application.routes.draw do
  scope :web, module: :web do
    resources :users, only: %i[new]
  end
end
```

Lalu buat controllernya
