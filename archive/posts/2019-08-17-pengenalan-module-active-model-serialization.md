---
layout: post
title: "Pengenalan modul ActiveModel::Serialization"
date: 2019-08-17 16:58:00 +0700
categories: tdd
comments: true
published: true
---

Akhirnya Rails 6.0.0 sudah rilis secara resmi pada [tanggal 15 Agustus kemarin](https://weblog.rubyonrails.org/2019/8/15/Rails-6-0-final-release/).

Pada versi ini, Rails membawa banyak perubahan-perubahan yang sangat menyenangkan para rails developer seperti *webpacker by default*, *multiple database*, *action text*, *pararel testing* dan lain-lain.

Namun saat ini yang saya ingin bahas disini bukan fitur-fitur tersebut, melainkan sebuah module baru di dalam ActiveModel yaitu [Serialization](https://api.rubyonrails.org/classes/ActiveModel/Serialization.html).

Akhirnya setelah penantian yang cukup panjang, rails dapat memiliki *serializer*-nya sendiri hehehe

Jika kita lihat [dokumentasi yang disediakan](https://api.rubyonrails.org/classes/ActiveModel/Serialization.html) kita bisa membuat kelas *serializer* dengan langsung meng-*include* modulenya seperti ini:

```rb
class Person
  include ActiveModel::Serialization

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

Dan untuk penggunaanya seperti ini:

```rb
person = Person.new
person.serializable_hash   # => {"name"=>nil}
person.name = "Bob"
person.serializable_hash   # => {"name"=>"Bob"}
```

Atau jika anda ingin mengeluarkan langsung sebuah json dari *serializer* anda:

```rb
class Person
  include ActiveModel::Serializers::JSON

  attr_accessor :name

  def attributes
    {'name' => nil}
  end
end
```

Untuk penggunaannya:

```rb
person = Person.new
person.serializable_hash   # => {"name"=>nil}
person.as_json             # => {"name"=>nil}
person.to_json             # => "{\"name\":null}"

person.name = "Bob"
person.serializable_hash   # => {"name"=>"Bob"}
person.as_json             # => {"name"=>"Bob"}
person.to_json             # => "{\"name\":\"Bob\"}"
```

Semenjak kita menggunakan rails yang menyediakan `render json:` seharusnya kita tidak memperlukan *serializer* yang menghasilkan data json langsung karna yang kita butuhkan cukup *hash* saja.

Tapi mungkin *module* ini akan diperlukan untuk anda yang menggunakan ActiveRecord namun tidak menggunakan Rails. Atau anda menggunakan rails namun lebih suka dengan method `as_json()` daripada `serializable_hash()` yang bisa kita lihat kedua method tersebut adalah sama :D.

Beberapa contoh diatas saya ambil dari dokumentasinya langsung, namun pada realitas kita perlu mengubah kelas-kelas ini. Untuk menjelaskan ini mari kita buat contoh kasus dengan menampilkan data json *article* dari *article* tertentu berdasarkan id-nya.

Pada *controller*, kita akan membuatnya seperti ini:

```rb
class ArticleController < ApplicationController
  def show
    article = Article.find_by(params[:id])
    serializer = ArticleSerializer.new(article)
    serializer_hash = serializer.serializable_hash
    render json: { article: serializer_hash }
  end
end
```

Untuk kode *serializer*-nya kita dapat membuatnya seperti ini:

```rb
class ArticleSerializer
  include ActiveModel::Serialization

  attr_reader :title, :body

  def initialize(article)
    @title = article.title
    @body = article.body
  end

  def attributes
    { 'title' => nil, 'body' => nil }
  end
end
```

Maka hasilnya adalah

```json
{
  "article": {
    "title": "Sample article title",
    "body": "Sample content of article"
  }
}
```

Pada kode diatas saya menambahkan method `initialize` agar proses inisialisasi atribut dilakukan di dalam kelas *serializer* sehingga jika atribut-nya banyak, proses tidak dibebankan kepada *controller*.

Saya kira tulisan ini cukup sekian saja,

*Happy hacking ~*