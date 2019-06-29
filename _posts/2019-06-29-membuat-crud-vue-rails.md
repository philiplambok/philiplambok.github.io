---
layout: post
title: "Membuat Aplikasi CRUD dengan Rails dan Vue.js"
date: 2019-06-29 09:57:00 +0700
categories: rails-vue
comments: true
published: true
---

Tulisan ini sebenernya bisa dibilang versi tulisan dari persentasi (_powerpoint_) yang saya bawakan saat _internal talks_ di Kantor saya yang berjudul "_Modern Frontend in Rails_".

Anda bisa download file powerpointnya [disini](http://localhost:4000/talks/).

Sesuai judulnya pada tulisan ini saya akan berbagi tentang bagaimana kita membuat sebuah fitur CRUD(Create, Read, Update, Delete) menggunakan Vue.js dan gem webpacker. Artinya kita tidak menggunakan cara tradisional namun akan banyak menggunakan _costum-tag_ atau sering disebut juga sebagai _web component_.

Saat tulisan ini ditulis Rails baru saja merilis Rails 6.0, walaupun belum versi _stable_ tapi versi ini sudah jalan di produksi basecamp, github dan shopify.

Pada Rails 6 banyak fitur-fitur baru yang disediakan seperti Action Mailbox, multi-db suppport, parallel testing, webpacker-by-default dan lain-lain. Pada webpacker-by-default artinya Rails akan menggunakan gem webpacker untuk menggantikan sprocets sebagai javascript compilernya.

Dengan menggunakan webpacker ini juga mengakibatkan struktur folder Rails kita menajdi berubah, yang sebelumnya berada di dalam folder asssets `/app/assets/javascript` sekarang menjadi berada tepat dibahwah model sejajar dengan model, controller, dll `app/javascripts`.
