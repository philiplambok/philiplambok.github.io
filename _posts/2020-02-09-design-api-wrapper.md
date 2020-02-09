---
layout: post
title: "Bereksperimen dalam mendesain API Wrapper"
date: 2020-02-09 11:00:00 +0700
categories: api-wrapper, design-systemd
comments: true
published: true
---

Karna ada pekerjaan yang berelasi dengan topik ini, jadi coba-coba design api wrapper. Karena sebelumnya di kantor menggunakan arsitektur [ini](https://github.com/moneyforward/mf_cloud-invoice-ruby). Jadi, desain yang saya buat juga banyak terinspirasi dari sana. 

Sebelumnya mungkin untuk anda yang belum tahu apa itu API Wrapper. API Wrapper adalah sebuah design pattern yang mungkin dikenal dengan nama [Adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern). 

Mudahnya kita membuat sebuah *class interface* terhadap sebuah third party yang kita gunakan pada sistem. Misalnya pada Ruby, jika kita ingin mengambil daftar artikel dari sebuah eksternal aplikasi daripada kita melakukannya dengan cara seperti ini: 

```rb
response = Faraday.get 'http://wrapper.com/articles'
articles = response.body 
articles #> [{ id: 1, title: 'The title' }]
```

Lebih baik kita membuat interface pada *wrapper.com* dan mengambil artikelnya seperti ini: 

```rb
client = Wrapper::Client.new()
articles = client.articles.all
articles #> [{ id: 1, title: 'The title' }]
```

Pada tulisan ini saya akan fokus bagaimana mendesain api wrapper yang punya konsistensi yang baik dan mudah dimengerti. Goalsnya adalah:
- Mengimplementasikan CRUD (create, read, update, delete).
- Bekerja dengan nested resources.

Mari kita mulai dengan CRUD sebuah posts.


#### Mendapatkan daftar postingan

```rb
client = Wrapper::Client.new
posts = client.posts.all
posts.to_json #> [{ id: 1, title: 'The title' }]
```


#### Membuat postingan baru

```rb
client = Wrapper::Client.new
post = client.posts.create(title: 'The second post')
post.to_json #> { id: 2, title: 'The second post' }
```

#### Melihat postingan dari spesific id

```rb
client = Wrapper::Client.new
post = client.posts.find(2)
post.to_json #> { id: 2, title: 'The second post' }
```

#### Mengpdate postingan dari spesific id

```rb
client = Wrapper::Client.new
post = client.posts.find(2)
post.update({title: 'The updated title'}) #> 
post.to_json #> { id: 2, title: 'The updated title' }
```

#### Menghapus postingan dari spesific  id

```rb
client = Wrapper::Client.new
post = client.posts.find(2)
post.destroy #> { id: 2, title: 'The updated title' }
```

Dan untuk *nested resources*-nya bisa dibuat seperti ini, misalnya kita mengambil daftar komentar dari spesific postingan

```rb
client = Wrapper::Client.new
post = client.posts.find(2)
comments = post.comments 
comments.to_json #> [{id: '1', user_id: 2, body: 'this is sample comment' }]
```

Dan jika kita ingin menggambil comment dari spesific idnya kita bisa melakukannya dengan cara ini: 

```rb
client = Wrapper::Client.new
comment = client.comments.find(1)
comment.to_json #> {id: '1', user_id: 2, body: 'this is sample comment' }
```

Dengan memamfaatkan konsep dari *chaining method* saya kira kita dapat meningkatkan *readability*.

Untuk arsitekturnya kira-kira saya mendesainya seperti ini: 

![Api Wrapper](/assets/api_wrapper.png)

Maaf untuk kualitas gambarnya, entah kenapa balsamiq belum support export by svg -_-

Sebagai catatan, kotak yang berwarna pink adalah kelas, sedangkan yang berwarna biru adalah modul.

----
Sekian saja untuk tulisan ini, jika ingin melihat kodenya bisa ditemukan [disini](https://github.com/philiplambok/jsonplaceholder_api).

Happy hacking ~