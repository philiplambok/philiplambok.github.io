---
layout: post
title:  "Sidekiq untuk non-parallel job"
date:   2021-02-12 10:10:00 +0700
categories: rails, sidekiq
comments: true
published: true
---

Tulisan pertama di tahun 2021 :)

Setelah sekian lama ada plan akhirnya ada kesempatan buat nulis juga hehe

Pada tulisan ini gw mau ngobrolin tentang Sidekiq.

Untuk anda yang belum tau apa itu Sidekiq, Sidekiq adalah sebuah paket di Ruby yang bisa anda gunakan jika ingin melakukan sesuatu terkait backgroud job. 

Jika anda mendevelop web yang cukup kompleks saya yakin anda pasti menggunakan backgroud job. Background job biasanya digunakan jika anda membuat fitur terkait *async*, walaupun beberapa orang mulai menyarankan background job untuk digunakan juga di *sync* dengan bantuan websocket, seperti kata om Nate

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Web transactions that take longer than ~1 second are a bad thing because they tie up capacity that could otherwise be doing useful work. If you&#39;ve got long-running web transactions, move to background jobs + longpolling/websocket update. Much more scalable.</p>&mdash; Nate Berkopec (@nateberkopec) <a href="https://twitter.com/nateberkopec/status/1359186810082123778?ref_src=twsrc%5Etfw">February 9, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Namun di tulisan ini gw gk ngobrolin cara implementasi background job dengan kasus sync, tapi lebih ke kasus parallel-job.

Sidekiq secara defaultnya adalah parallel, walaupun kita memiliki konsep antrian namun tidak berarti 1 antrian hanya boleh mengerjakan 1 worker pada 1 waktu.

Asumsikan kita punya kode ini di projek:

```rb
# config/routes.rb
require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  root 'home#index'
end

# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @workers = Worker.all
    SampleWorker.perform_async
  end
end

# app/workers/sample_worker.rb
class SampleWorker
  include Sidekiq::Worker

  def perform
    Worker.create
    sleep 5.seconds
  end
end
```

Di viewsnya begini: `app/views/home/index.html.erb`

```html
<%= link_to 'Trigger job', root_path %>
<br><br><br>
<table>
  <tr>
    <th>#id</th>
    <th>created_at</th>
  </tr>
  <% @workers.each do |worker| %>
    <tr>
      <td><%= worker.id %></td>
      <td><%= worker.created_at %></td>
    </tr>
  <% end %>
</table>
```

Lalu gw coba klik triggernya berkali dengan cepat, dan hasilnya gini:

```
#id	created_at
2	2021-02-12 04:17:02 UTC
3	2021-02-12 04:17:02 UTC
4	2021-02-12 04:17:02 UTC
5	2021-02-12 04:17:02 UTC
6	2021-02-12 04:17:02 UTC
7	2021-02-12 04:17:07 UTC
8	2021-02-12 04:17:07 UTC
9	2021-02-12 04:17:07 UTC
10	2021-02-12 04:17:07 UTC
11	2021-02-12 04:17:07 UTC
12	2021-02-12 04:17:12 UTC
13	2021-02-12 04:17:12 UTC
14	2021-02-12 04:17:12 UTC
15	2021-02-12 04:17:12 UTC
16	2021-02-12 04:17:12 UTC
```

Dengan hasil gini, kita asumsikan 1 antrian maksimal mengerjakan 5 job. Namun ada saatnya kita ingin 1 antrian hanya ingin mengerjakan 1 job pada 1 waktu. 

Untuk melakukan ini kita perlu menggunakan paket tambahan yaitu: [sidekiq-limit_fetch](https://github.com/brainopia/sidekiq-limit_fetch). Caranya cukup mudah, tinggal tambahkan 

```rb
# Gemfile
gem 'sidekiq-limit_fetch'
```

```rb
# config/initializers/sidekiq.rb
Sidekiq::Queue['default'].limit = 1
```

Lalu restart servernya, dan coba trigger ulang, maka hasilnya akan begini:

```
#id	created_at
171	2021-02-12 04:36:09 UTC
172	2021-02-12 04:36:14 UTC
173	2021-02-12 04:36:19 UTC
174	2021-02-12 04:36:24 UTC
175	2021-02-12 04:36:29 UTC
176	2021-02-12 04:36:34 UTC
177	2021-02-12 04:36:39 UTC
178	2021-02-12 04:36:44 UTC
179	2021-02-12 04:36:49 UTC
180	2021-02-12 04:36:54 UTC
181	2021-02-12 04:36:59 UTC
182	2021-02-12 04:37:04 UTC
```

Maka, kita bisa pastikan antriannya hanya menjalankan 1 job pada 1 waktu.

-----

Jika anda tertarik lebih lanjut dengan fitur-fitur lainnya, bisa langsung ke Githubnya aja ya. Untuk source code sample projek ini bisa ditemukan disini: [sidekiq-parallel](https://github.com/sugar-for-pirate-king/sidekiq-parallel).

Itu saja tulisan kali ini, terima kasih telah membaca, happy hacking~