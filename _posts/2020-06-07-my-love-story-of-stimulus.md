---
layout: post
title:  "My love story of stimulus.js"
date:   2020-06-07 10:10:00 +0700
categories: jquery20, railsjs
comments: true
published: true
---

> Vue, React and another fan of web component javascript framework is over-engineering.

Konsep web component memang bagus, namun implementasi mereka di dunia monolith akan mengambil alih kode views dari server side. 

Contohnya jika pada legacy project, kita ingin membuat fitur penambahan komentar baru agar tidak merender ulang semua halaman ketika komentar baru ditambahkan. 

Di Vue.js kita bisa membuat komponen `<Comments>` lalu menulis ulang dari semua kode view dari server side contohnya: `_comments.html.erb` dalam versi `.vue`. Kita juga perlu menyiapkan data jsonnnya, dan api untuk interaksinya. 

Bahkan mungkin kita bisa menulis ulang satu halaman penuh (tidak hanya partial) pada kasus tertentu *ini yang paling saya sering lakukan. 

Stimulus dapat mengatasi hal ini, karena kita bisa menggunakan kode-kode javascript tanpa harus membuat web component, namun cukup dengan server code saja. 

Seperti biasa, gw akan membuat projek kecil-kecilan.

Di projek ini nantinya gw akan membuat sebuah data atau halaman post ada title dan body. Pada data post itu, kita akan membuat fitur: 

- Menambah jumlah likes
- Menambah komentar
- Menghapus komentar
- Mengedit komentar secara inline

Pada fitur-fitur tersebut, browser tidak boleh merefresh halamannya.

Mari kita mulai:

Dimulai dari instalasi:

```
$> rails new stimulus-experiment --webpack=stimulus --database=mysql -T
```

Setelah instalasi silahkan membuat buat data post baru dengan minimal attribute seperti *title* dan *body*. 

Pada viewnya kita-kira menjadi seperti ini:

```erb
<h1><%= @post.title %></h1>

<div>
  <%= sanitize(Kramdown::Document.new(@post.body).to_html) %>
</div>
```

Sekarang fitur pertama kita akan membuat fitur likes:

Tambakan kode viewnya menjadi seperti ini:

```erb
<h1><%= @post.title %></h1>

<div>
  <%= sanitize(Kramdown::Document.new(@post.body).to_html) %>
</div>

<div>
  <div id="likes">
    <%= render 'likes', post: @post %>
  </div>
  <%= button_to 'Like', likes_path(@post), remote: true %>
</div>
```

Pada `_likes.html.erb`-nya simple saja:

```erb
<div><%= post.likes %> likes</div>
```

Sekarang tambahkan routesnya:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  resources :posts do
    scope module: :posts do
      member do
        resources :likes, only: %i[create]
      end
    end
  end
end
```

Dan pada controllernya seperti ini:

```rb
# frozen_string_literal: true

module Posts
  # Like Post
  class LikesController < ApplicationController
    def create
      @post = Post.find_by(id: params[:id])
      @post.update(likes: @post.likes + 1)
      respond_to do |format|
        format.js
        format.json { render json: @post, status: :ok }
      end
    end
  end
end
```

Ketika kita menambahkan kode `format.js` pada controller, secara default pada kasus ini kita akan merender `create.js.erb`. 

Silahkan tambahkan kode ini pada file tersebut:

```js
document.querySelector('#likes').innerHTML = `<%= render 'posts/likes', post: @post %>`
```

Pada kode ini intinya kita akan mereplace, html yang lama dangan render yang baru, atau bisa dibilang kita merender ulang partial `_likes.html.erb`nya.

Hasilnya menjadi seperti ini:

![post like](/assets/likes.gif)

Pada kasus ini kita belum menggunakan stimulus, kita masih menggunakan `js.erb` yang ada di dalam ActionView dan memamfaatkan penggunaan remote. 

Sekarang saatnya ke fitur selanjutnya:

Yaitu menambahkan fitur penambahan komentar, dengan ketentuan browser tidak boleh melakukan *rendering page*.

Pada halaman post kita tambahkan kode ini:

```erb
<hr>

<h4>Komentar</h4>
<%= form_with(model: @post.comments.build) do |form| %>
  <div>
    <%= form.text_field :body, placeholder: 'tambahkan komentar' %>
    <%= form.submit 'Tambahkan' %>
  </div>
<% end %>

<div id="comments">
  <%= render 'comments', post: @post %>
</div>
```

Pada partial `_comments.html.erb`:

```erb
<p>
  <% if post.recent_comments.count.zero? %>
    <p>Tidak ada komentar</p>
  <% else %>
    <% post.recent_comments.each do |comment| %>
      <%= render 'posts/comment', comment: comment %>
      <hr>
    <% end %>
  <% end %>
</p>
```

Pada partial `_comment.html.erb`:

```erb
<div>
  <p><%= comment.body %></p>
  <p>at <%= comment.updated_at %> </p>
  <p>
    <%= link_to 'Edit', '#' %>
    <%= link_to 'Destroy', '# %>
  </p>
</div>
```

Lalu tambahakan routesnya menjadi:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  resources :posts do
    scope module: :posts do
      member do
        resources :likes, only: %i[create]
        resources :comments, only: %i[create]
      end
    end
  end
end
```

Pada controllernya kita buat seperti ini:

```rb
# frozen_string_literal: true

module Posts
  class CommentsController < ApplicationController
    def create
      @post = Post.find_by(id: params[:id])
      comment = @post.comments.build
      comment.update(comment_params)
      @post.reload
      respond_to do |format|
        format.js
        format.json { render json: comment, status: :created }
      end
    end

    private

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
```

Dan pada file `posts/comments/_create.js.erb` kita buat begini:

```js
document.querySelector('#comments').innerHTML = `<%= render 'posts/comments', post: @post %>`
document.querySelector('#comment_body').value = ''
```

Gw juga menambahkan method agar render menjadi terurut dari `updated_at`-nya:

```rb
# frozen_string_literal: true

class Post < ApplicationRecord
  has_many :comments

  def recent_comments
    comments.order(updated_at: :desc)
  end
end
```

Kita merender ulang partial `posts/comments` dan menghapus input pada komentar.

Hasilnya menjadi seperti ini:

![Comments](/assets/comments.gif)

Setelah itu kita akan menambakan fitur hapus komentar. Fitur ini implementasinya sama kayak fitur likes, kita akan menggunakan link dengan remote.

```erb
<div>
  <p><%= comment.body %></p>
  <p>at <%=comment.updated_at%> </p>
  <p>
    <%= link_to 'Edit', '#', data: { action: 'click->comment#edit' } %>
    <%= link_to 'Destroy', comment_path(comment.id), method: :delete, remote: true %>
  </p>
</div>
```

Silahkan tambahakan routesnya menjadi seperti ini:

```rb
Rails.application.routes.draw do
  resources :posts do
    scope module: :posts do
      member do
        resources :likes, only: %i[create]
        resources :comments, only: %i[create]
      end
    end
  end

  resources :comments, only: %i[destroy]
end
```

Lalu pada controllernya kita buat seperti ini:

```rb
# frozen_string_literal: true

class CommentsController < ApplicationController
  def destroy
    comment = Comment.find_by(id: params[:id])
    @post = Post.find_by(id: comment.post_id)
    comment.destroy
    respond_to do |format|
      format.js
      format.json { render json: comment, status: :ok }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
```

Pada file `comments/_destroy.js.erb`nya:

```rb
document.querySelector('#comments').innerHTML = `<%= render 'posts/comments', post: @post %>`
```

Kita hanya perlu reload partial comments-nya lagi.

Hasilnya menjadi seperti ini:

![Destroy comment](/assets/destroy_comment.gif)

Fitur terakhir yaitu fitur inline editing. Pada fitur ini kita akan menggunakan stimulus.js

Silahkan update partial `_comment.html.erb` menjadi seperti ini:

```erb
<div data-controller="comment">
  <%= form_with(model: comment, url_path: comment_path(comment), method: :put, data: { target: 'comment.form' }, class: 'd-none') do |form| %>
    <%= form.text_field :body %>
    <%= form.submit 'Update comment' %>
  <% end %>

  <div data-target="comment.content">
    <p><%= comment.body %></p>
    <p>at <%=comment.updated_at%> </p>
    <p>
      <%= link_to 'Edit', '#', data: { action: 'click->comment#edit' } %>
      <%= link_to 'Destroy', comment_path(comment.id), method: :delete, remote: true %>
    </p>
  </div>
</div>
```

Pada stimulus kita melakukan connect dom, dengan menggunakan attribute `data-controller` yang akan menjadi sebuah kelas controller pada stimulus. `data-target` akan menjadi model, dan `data-action` akan menjadi event bindingnya.

Kita bisa menambakan file stimulus controllernya disini: `app/javascripts/controllers/comment_controlller.js`

```js
import { Controller } from 'stimulus'

export default class CommentController extends Controller {
  static targets = ["form", "content"]

  edit(event){
    event.preventDefault()
    this.formTarget.classList.remove('d-none')
    this.contentTarget.classList.add("d-none")
  }
}
```

Pada stimulus, kita hanya perlu melakukan toogle classnya saja.

Tambahkan kelas `d-none` ini pada `application.css`-nya:

```css
.d-none {
  display: none;
}
```

Untuk submitnya masih sama, kita menggunakan form remote bawaan rails:

```rb
# frozen_string_literal: true

class CommentsController < ApplicationController
  def update
    comment = Comment.find_by(id: params[:id])
    comment.update(comment_params)
    @post = comment.post
    respond_to do |format|
      format.js
      format.json { render json: comment, status: :ok }
    end
  end

  # ...
end
```

Pada file `comments/update.js.erb`-nya kita render ulang lagi partial commentsnya:

```erb
document.querySelector('#comments').innerHTML = `<%= render 'posts/comments', post: @post %>`
```

Hasilnya menjadi seperti ini:

![Update comment](/assets/update_comment.gif)

----

Bagimana?

Untuk fitur-fitur tersebut, jika kita implement menggunakan vue, kita akan banyak menulis ulang kode server code view ke client view. Pada server juga kita perlu membuat API hingga harus membuat dan mengirim json ke client.

Dengan stimulus dan rails-ujs kode kita menjadi lebih rapih dan jauh lebih simple.

Lalu, apakah Stimulus menjadi replacement dari Vue dan React dan another web component yang lain?

Hmn, jawabannya bisa iya, bisa enggak. 

Jika fitur-fitur yang akan dibuat sama seperti diatas:
- Input form dan updating sesuatu element dengan browser tanpa harus melakukan render halaman
- Fitur like dengan counter yang berubah terus
- Validation input form realtime, seperti uniqueness dari username.
- Toogle sebuah element
- Dan fitur-fitur yang simple lain

Stimulus akan sangat *perfect* disana. 

Namun jika anda membutuhkan sebuah komponen yang sangat *complex* dan *user interactive* sekali, mungkin anda bisa menggunakan Vue.js, saja.

Jadi gunakan sesusai kebutuhkan, saja. 

Menggunakan Vue dan Stimulus di satu project tidak akan jadi masalah.

Untuk full source of codenya bisa di lihat disini: [https://github.com/sugar-for-pirate-king/stimulus-experiment](https://github.com/sugar-for-pirate-king/stimulus-experiment)

Semoga tulisan ini dapat bermafaat bagi pembaca skalian.

Thank you.







