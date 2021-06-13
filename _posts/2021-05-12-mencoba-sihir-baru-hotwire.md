---
layout: post
title:  "Mencoba sihir baru: Hotwire"
date:   2021-04-22 10:10:00 +0700
categories: rails, hotwire
comments: true
published: true
---

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Hotwire aka NEW MAGIC is finally here: An alternative approach to building modern web applications without using much JavaScript by sending HTML instead of JSON over the wire. This includes our brand-new Turbo framework and pairs with Stimulus 2.0 😍🎉🥂 <a href="https://t.co/Pa4EG8Av5E">https://t.co/Pa4EG8Av5E</a></p>&mdash; DHH (@dhh) <a href="https://twitter.com/dhh/status/1341420143239450624?ref_src=twsrc%5Etfw">December 22, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Setelah pertama kali spoiler *the new magic* di juni 2020, dan pertama kali rilis di desember 2020, akhirnya baru bisa coba di juni 2021

<div class="tenor-gif-embed" data-postid="17231623" data-share-method="host" data-width="40%" data-aspect-ratio="1.0"><a href="https://tenor.com/view/sad-cute-anime-pillow-hugs-gif-17231623">Sad Cute GIF</a> from <a href="https://tenor.com/search/sad-gifs">Sad GIFs</a></div><script type="text/javascript" async src="https://tenor.com/embed.js"></script>

---

*Anyways*,

Kalo liat di dokumentasi Hotwire disini: [https://hotwire.dev/](https://hotwire.dev/), hotwire terdiri dari tiga paket yaitu Turbo, Stimulus, dan Strada. 

Turbo adalah sebuah kumpulan teknik yang dapat digunakan untuk mempercepat pergantian halaman, dan *submission form*, memecahkan halaman yang kompleks menjadi komponen, dan *stream* update halaman partial lewat websocket. 

Stimulus adalah sebuah framework javascript yang memiliki pedoman pada HTML-centric, saya udah pernah nulis terkait paket ini sebelumnya, bisa di cek disini: [Real-time search with stimulus.js](https://philiplambok.github.io/railsjs,/stimulus/2020/06/13/stimulus-day-2.html), [My love story with stimulus.js](https://philiplambok.github.io/jquery20,/railsjs/2020/06/07/my-love-story-with-stimulus.html)

Terakhir adalah strada, sebuah paket untuk membantu development pada native app, seperti mobile. Paket ini masih belum rilis saat tulisan ini dipublikasi.

Jadi, tulisan ini akan banyak ngobrolin tentang turbo.

Seperti biasa, kita akan mencoba membuat aplikasi menggunakan teknologi ini, aplikasi yang akan dibuat sederhana saja, kita akan membuat aplikasi chat, user bisa submit chat baru, edit dan hapus, itu saja.

Sample apikasinya bisa dilihat dari gambar ini:

![example app](/assets/hotwire-one.gif)

Saya memakai *marquee* (tulisan berjalan) untuk menandakan tidak ada reload halaman secara keseluruhan, tapi pergantian halaman dilakukan hanya pada sepesifik DOM element aja.

## Instalasi

Seperti biasa, hal yang pertama kali dilakukan silahkan init railsnya dulu:

```sh
$ rails new hotwire-chat-example -T --database=mysql
```

Setelah di-init silahkan install hotwirenya, dengan cara ini:

```sh
$ bundle add hotwire-rails
$ bundle install
$ rails hotwire:install
```

Bisa lihat disini untuk lebih detailnya: [https://github.com/hotwired/hotwire-rails](https://github.com/hotwired/hotwire-rails)

## Membuat fitur create chat

Seperti yang dibilang sebelumnya, pada tulisan ini saya cuman bakal bahas teknologi Turbo aja. Jadi kalo liat di [docsnya](https://turbo.hotwire.dev/handbook/introduction). Ada 3 paket di Turbo ini:

- Turbo drive, dari tagline docsnya paket ini adalah evolusi dari paket Turbolinks yang udah ada di rails saat ini.
- Turbo frame, sebuah paket yang digunakan untuk membuat sebuah komponen frame yang dinamis. Secara konsep mirip seperti html iframe tag.
- Turbo stream, sebuah paket yang dapat digunakan sebagai abstraksi komunikasi websocket yang nantinya digunakan untuk mengupdate halaman frontend-nya.

Ok, sekarang mari kita develop fitur create chatnya. Pada fitur create chat ini yang perlu kita lakukan adalah membuat sebuah form text field untuk submit input pesannya, dan menampikan pesannya dihalaman yang sama.

Dimulai dari `routes.rb`.

```rb
# config/routes.rb
Rails.application.routes.draw do
  resources :chats
  root 'home#index'
end
```

Gk ada yang aneh, kita bikin `HomeController` sebagai routesnya, dan bikin `resources :chats` sebagai controller untuk membuat record chat-nya. 

Pada controllernya ditulis gini: 

```rb
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @chats = Chat.all
    @new_chat = Chat.new
  end
end

# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  def create
    Chat.create!(chat_params)
    respond_to do |format|
      format.html do
        redirect_to root_path
      end
    end
  end

  private

  def chat_params
    params.require(:chat).permit(:message)
  end
end
```

Pada modelnya gini:

```rb
# app/views/chat.rb
class Chat < ApplicationRecord
  after_create { broadcast_append_to "chats" }
end
```

Pada controllernya tidak ada yang baru, yang baru hanya pada model `Chat`nya. Yaitu penggunakan callback `broadcast_append_to`, callback ini digunakan untuk untuk melakukan broadcast untuk perubahan DOM element dengan `append` yaitu penambahan element, secara default element yang dikirim adalah partial `chats/_chat.html` dalam Channel `chats`.

Broadcast ini menggunakan teknologi `ActionCable`, saya harap anda sudah familiar dengan paket itu terlebih dahulu. 

Pada viewsnya tulis begini:

```html
<!-- #app/views/home/index.html.erb -->
<%= turbo_stream_from "chats" %>

<div class="container mt-4">
  <div class="row">
    <div class="col-md-6 m-auto">
      <h4>Chat example app</h4>

      <marquee>Time: <%= DateTime.now %></marquee>
      
      <%= render 'chats/chats', chats: @chats %>

      <hr>
      
      <%= turbo_frame_tag "chat_form" do %>
        <%= render 'chats/form', chat: @new_chat %>
      <% end %>
    </div>
  </div>
</div>
```

Pada partial viewnya:

```html
<!-- #app/views/chats/_chats_.html.erb -->
<ul id="chats" class="list-group list-group-flush my-4">
  <% chats.each do |chat| %>
    <%= render chat %>
  <% end %>
</ul>
```

```html
<!-- #app/views/chats/_chat_.html.erb -->
<li class="list-group-item d-flex justify-content-between">
  <%= chat.message %>
  <div>
    <%= link_to 'Edit', '#' %>
    <%= link_to 'Remove', '#' %>
  </div>
</li>
```

Hasilnya akan gini:

![hotwire-two](/assets/hotwire-two.gif)

Pada partialnya ada helper yang baru yaitu `<%= turbo_stream_from "chats" %>` dan `<%= turbo_frame_tag "chat_form" do %>`. 

`turbo_stream_from "chats"` digunakan untuk *listen* websocket changes pada channel `chats`. Dimana pada kasus ini kita melakukan trigger changes dom yang dilakukan pada modelnya `broadcast_append_to`, dan pada log juga kita bisa lihat:

```sh
Started POST "/chats" for ::1 at 2021-06-13 09:47:27 +0700
Processing by ChatsController#create as TURBO_STREAM
 ...
[ActionCable] Broadcasting to chats: "<turbo-stream action=\"append\" target=\"chats\"><template><turbo-frame id=\"chat_124\">\n  <li class=\"list-group-item d-flex justify-content-between\">\n    Empat\n    <div>\n      <a href=\"/chats/124/edit?time=1623552448\">Edit</a>\n      <a rel=\"nofollow\" data-method=\"delete\" href=\"/chats/124\">Remove</a>\n    </div>\n  </li>\n</turbo-frame></template></turbo-stream>"
Turbo::StreamsChannel transmitting "<turbo-stream action=\"append\" target=\"chats\"><template><turbo-frame id=\"chat_124\">\n  <li class=\"list-group-item d-flex justify-content-between\">\n    Empat\n    <div>\n      <a href=\"/chats/124/edit?time=1623552448\">Edit</a>\n      <a rel=\"nofollow\" data-method=\"delete\" href=\"/ch... (via streamed from chats)
  TRANSACTION (1.2ms)  COMMIT
  ↳ app/controllers/chats_controller.rb:3:in `create'
Redirected to http://localhost:3000/
Completed 302 Found in 14ms (ActiveRecord: 8.0ms | Allocations: 3850)
```

Actionya adalah `append` yaitu akan menambahkan data baru dari element paling bawah, layaknya konsep `push` pada `Stack`. Dan target elementnya adalah `#chats` jadi pastikan anda sudah membuat targetnya dulu, sedangkan *changes element* yang dikirim adalah view yang diambil dari partial default dari modelnya yaitu `chats/_chat.html.erb`. 

Konsep kedua yang baru yaitu `turbo_frame_tag "chat_form"`, seperti yang sudah dibilang sebelumnya turbo frame ini layaknya konsep iframe, padahal di controllernya saya balikin `redirect_to`, tapi yang ganti cukup element yang didalem tag `turbo_frame_tag`nya aja gk semuanya. Cukup simple bukan? 

## Membuat fitur edit

Fitur selanjutnya adalah fitur edit, pada fitur ini kita akan menggunakan konsep Turbo frame saja. Dimulai dari partial viewnya:

```html
<!-- app/views/chats/_chat.html.erb -->
<%= turbo_frame_tag dom_id(chat) do %>
  <li class="list-group-item d-flex justify-content-between">
    <%= chat.message %>
    <div>
      <%= link_to 'Edit', edit_chat_path(chat) %>
      <%= link_to 'Remove', "#" %>
    </div>
  </li>
<% end %>
```

Kita update link editnya untuk redirect ke controller edit.

Pada controllernya kita update jadi seperti ini:

```rb
# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  # ...
  def edit
    @chat = Chat.find params[:id]
  end

  def update
    chat = Chat.find params[:id]
    chat.update!(chat_params)
    respond_to do |format|
      format.html do
        redirect_to chat_path
      end
    end
  end
```

Dan pada views `edit.html.erb`nya dibuat gini:

```html
<!-- app/views/chats/edit.html.erb -->
<%= turbo_frame_tag dom_id(@chat) do %>
  <li class="list-group-item">
    <%= form_with(model: @chat, url: chat_path(@chat), method: :put, class: 'd-flex justify-content-between') do |form| %>
      <div class="col-auto">
        <%= form.text_field :message, class: 'form-control' %> 
      </div>
      <%= form.submit 'Update', class: 'ml-auto btn btn-primary' %>
    </div>
    <% end %>
  </li>
<% end %>
```

And done. It's work!

![hotwire-three](/assets/hotwire-three.gif)

Mungkin anda bertanya, kenapa perlu tag `turbo_frame_tag dom_id(@chat)` di file partial `edit.html.erb`-nya? Yups benar, kita perlu itu karna rails tidak serta-merta langsung mengganti elementnya dengan semua file responsenya, namun ia perlu melakukan matching terlebih dahulu sama framenya. Karta pada source viewnya kita taro frame dengan nama `dom_id(chat)` maka, ia akan mengganti frame itu dari response dengan frame yang sama yaitu `dom_id(chat)`, jadi kalo misalnya edit.html.erbnya kita update jadi gini:

```html
<!-- app/views/chats/edit.html.erb -->
<h1> Ini tidak ditampilkan karna diluar frame</h1>

<%= turbo_frame_tag dom_id(@chat) do %>
  <li class="list-group-item">
    <%= form_with(model: @chat, url: chat_path(@chat), method: :put, class: 'd-flex justify-content-between') do |form| %>
      <div class="col-auto">
        <%= form.text_field :message, class: 'form-control' %> 
      </div>
      <%= form.submit 'Update', class: 'ml-auto btn btn-primary' %>
    </div>
    <% end %>
  </li>
<% end %>
```

Hasil masih akan tetap sama.

## Membuat fitur delete

Fitur selanjutnya adalah fitur delete. Kita mulai dari update viewnya:

```html
<!-- app/views/chats/_chat.html.erb -->
<%= turbo_frame_tag dom_id(chat) do %>
  <li class="list-group-item d-flex justify-content-between">
    <%= chat.message %>
    <div>
      <%= link_to 'Edit', edit_chat_path(chat) %>
      <%= link_to 'Remove', chat_path(chat), method: :delete %>
    </div>
  </li>
<% end %>
```

Untuk fitur ini kita perlu menggunakan konsep Turbo stream, untuk mengirim stream action remove ke target dom `#chats`. Pada controllernya kita bikin gini:

```rb
# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  # ...
  def destroy
    chat = Chat.find params[:id]
    chat.destroy!
    respond_to do |format|
      format.html do
        head :no_content
      end
    end
  end
end
```

Kita tidak perlu merender apa2 pada controllernya, karna cukup mengirim stream action remove dom lewat websocketnya, yang ditrigger lewat model:

```rb
class Chat < ApplicationRecord
  # ...
  after_destroy_commit { broadcast_remove_to 'chats' }
end
```

Done, and it's works!

![hotwire-four](/assets/hotwire-four.gif)

Secara konsep mirip saat `create`, perbedannya hanya di action turbo streamnya saja, kalo pada `create` kita pake `append` kalo pada `destroy` kita pake `remove`. 

## Improvement

Kalo liat pada demo aplikasi yang pertama kali mungkin anda sadar kita ada fitur untuk memberikan pesan "No Chats", bisa liat lagi:

![example app](/assets/hotwire-one.gif)

Untuk fitur ini belum disupport dengan kode yang ada. Kode yang ada saat ini tidak akan menampilan data chat pertama kali.

```html
<!-- app/views/chats/_chats.html.erb -->
<ul id="chats" class="list-group list-group-flush my-4">
  <% if chats.blank? %>
    <p class="text-center my-4">No chats</p>
  <% else %>
      <% chats.each do |chat| %>
        <%= render chat %>
      <% end %>
  <% end %>
</ul>
```

Untuk mensupport itu kita perlu update modelnya menjadi seperti ini:

```rb
class Chat < ApplicationRecord
  after_create :append_chat_dom
  after_destroy_commit :remove_chat_dom

  private

  def append_chat_dom
    if Chat.all.size.eql?(1)
      broadcast_replace_to 'chats', target: 'chats',
                                    partial: 'chats/chats',
                                    locals: { chats: Chat.all }
    else
      broadcast_append_to 'chats'
    end
  end

  def remove_chat_dom
    if Chat.all.blank?
      broadcast_replace_to 'chats', target: 'chats',
                                    partial: 'chats/chats',
                                    locals: { chats: Chat.all }
    else
      broadcast_remove_to 'chats'
    end
  end
end
```

Kita perlu melakukan perbedaan pada chat ketika data kosong. Yaitu contohnya pada `create` ketika itu adalah chat yang pertama kali, kita akan melakukan render replace pada view `chats/chats` rather than melalukan `append`. Begitu juga dengan `destroy`-nya kita akan melakukan replace pada view `chats/chats` daripada hanya melakukan remove domnya.

----

Saya rasa itu saja cukup pada tulisan ini, mudah2an tulisan ini dapat membantu anda dalam mengenal teknologi hotwire ini (yang pasalnya akan menjadi default paket pada Rails 7 mendatang). Jika anda tertarik melihat sample codenya bisa ditemukan disini ya: [hotwire-chat-example](https://github.com/philiplambok/hotwire-chat-example). Happy hacking~ 