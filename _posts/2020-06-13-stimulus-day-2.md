---
layout: post
title:  "Real-time search with stimulus.js"
date:   2020-06-13 10:10:00 +0700
categories: railsjs, stimulus
comments: true
published: true
---

Pada tulisan ini sebelumnya [My love story with stimulus](https://philiplambok.github.io/jquery20,/railsjs/2020/06/07/my-love-story-with-stimulus.html) gw sudah mengenalkan cara penggunaan dan mamfaat menggunakan stimulus.

Namun, problem yang gw contohnya di tulisan sebelumnya masih menggunakan trigger-trigger standard yang dihandle pada file html pada umumnya, seperti ketika klik something atau tekan enter atau submit form.

Pada tulisan ini kita akan menggunakan trigger yang tidak dihandle pada file html. Kita akan membuat sebuah fitur realtime searching pada aplikasi yang sudah kita buat sebelumnya.

Kasusnya:

Misalnya kita punya 10 posts yang tampil semuanya pada sebuah halaman. Pada halaman tersebut kita memiliki sebuah field text dengan placeholder "Type something", ketika kita menginput kata "Sample" tanpa menekan enter secara otomatis posts yang tadinya 10, menjadi 2.

Kita akan menggunakan event trigger *keyup* pada kasus ini.

Mari kita mulai.

Kita masih menggunakan project yang sama dengan tulisan: [sebelumnya](https://philiplambok.github.io/jquery20,/railsjs/2020/06/07/my-love-story-with-stimulus.html).

Silahkan buat halaman `posts/index.html.erb`:

```erb
<div data-controller="search">
  <%= form_with(url: posts_path, method: :get, data: { target: 'search.form' }, remote: true) do |form| %>
    <%= form.text_field :query, 
                        value: params[:query], 
                        placeholder: 'Type something',
                        class: 'form-control', 
                        data: { action: 'keyup->search#call' } %>
  <% end %>
</div>

<br>

<div id="posts">
  <%= render 'posts', posts: @posts %>
</div>
```

Pada partial view `posts/_posts.html.erb` kita buat begini:

```erb
<% if @posts.any? %>
  <table class="table">
    <tr>
      <th>#</th>
      <th>Title</th>
    </tr>

    <% posts.each.with_index(1) do |post, index| %>
      <tr>
        <td><%= index %></td>
        <td><%= post.title %></td>
      </tr>
    <% end %>
  </table>
<% else %>
  <p>No posts provided.</p>
<% end %>
```

Pada views kita kira-kira menjadi seperti ini:

![Post index view](/assets/posts_index.png)

Sekarang kita buat file stimulus controllernya:

```rb
import Rails from '@rails/ujs';
import { Controller } from 'stimulus'

export default class SearchController extends Controller {
  static targets = ["form"]

  call(){
    Rails.fire(this.formTarget, 'submit')
  }
}
```

Yups, cukup ini aja. 

Stimulus controller kita hanya memiliki satu public method `call`, method ini dipanggil ketika event `keyup` ter-trigger. Dan isi method `call` kita akan mentrigger related *remote form* dari field kita.

Dan pada controllernya kita buat seperti ini:

```rb
# frozen_string_literal: true

class PostsController < ApplicationController
  def index
    @posts = Post.all
    @posts = @posts.where('title LIKE ?', "%#{params[:query]}%") if params[:query].present?
    respond_to do |format|
      format.html { render :index }
      format.js
    end
  end

  # ...
end
```

Kita akan filter `@posts`-nya ketika params di kirim oleh remote form.

Dan pada partial `posts/index.js.erb`-nya, kita buat gini:

```erb
document.getElementById('posts').innerHTML = `<%= render 'posts/posts', posts: @posts  %>`
```

Sekarang hasilnya akan menjadi begini:

![Realtime search](/assets/realtime-search.gif)

----

Dengan stimulus javascript kita menjadi sangat milimalis sekali. Stimulus controllernya juga lebih general dan dapat digunakan di form atau halaman-halaman lain.

Untuk kodenya bisa diakses di project yang sama: [https://github.com/sugar-for-pirate-king/stimulus-experiment](https://github.com/sugar-for-pirate-king/stimulus-experiment)

Segini saja dulu untuk tulisan ini yaa

Thank you and happy hacking!