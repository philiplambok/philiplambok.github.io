---
layout: post
title:  "Infinite scroll di Rails"
date:   2020-06-13 13:10:00 +0700
categories: railsjs, infinite-scroll
comments: true
published: true
---

Oke, terkait dengan dua tulisan sebelumnya. 

Sekarang gw mau nulis tentang cara bikin "Infinite scroll" di Rails.

Infinite scroll disini initinya sama kayak pagination seperti biasa, namun data yang sebelumnya tidak hilang, tapi tetep ada dihalaman yang sama. 

Kita akan punya sebuah link 'Load more', gitu. Setiap kita klik link tersebut maka akan muncul data baru dibawahnya.

Kita akan menggunakan paket buatan [Basecamp](https://basecamp.com/) yaitu [geared_pagination](https://github.com/basecamp/geared_pagination). 

Kenapa menggunakan paket ini?

Dengan paket ini kita diberikan flexibilitas yang sangat cocok dengan kebutuhan infinite scroll. Berbeda dengan kebanyakan pake lain, records yang diberikan fixed, misalnya ada 100 data, dengan default per_page di set 10. Maka setiap halaman akan hanya ada 10 data saja. 

Namun, dengan paket ini, pagination kita menjadi page 1 (10 items), page 2 (20 items), page 3 (30 items) dan seterusnya.

Sangat cocok dengan infinite scroll.

Kalo gitu, mari kita mulai.

Karna projeknya masih sama seperti sebelumnya, update controllernya menjadi seperti ini:

```rb
def index
  @posts = Post.all
  if params[:query].present?
    @posts = @posts.where('title LIKE ?', "%#{params[:query]}%")
  end
  set_page_and_extract_portion_from @posts
  @records = @page.last? ? @page.recordset.records : @page.records
  respond_to do |format|
    format.html { render :index }
    format.js
  end
end
```

Kode yang ditambahkan ini:

```rb
set_page_and_extract_portion_from @posts
@records = @page.last? ? @page.recordset.records : @page.records
```

- Kode ini `set_page_and_extract_portion_from @posts` akan membuat instance `@page` 
- Kode ini `@records = @page.last? ? @page.recordset.records : @page.records` akan mengeset `@records` dengan semua data jika kita sedang berada dihalaman akhir. 

Sekarang kita ke viewsnya `posts/_posts.html.erb`, update menjadi seperti ini:

```erb
<div id="posts">
  <%= render 'posts', posts: @records %>
</div>

<div id="load-more-data">
  <%= render 'load_more_data_link', page: @page, remote: true %>
</div>
```

Di `posts/_load_more_data_link.html.erb`-nya dibuat gini:

```erb
<%= link_to "Load more data", posts_path(page: page.next_param), remote: true unless page.last? %>
```

Dan pada `posts/index.js.erb`nya diupdate jadi gini:

```rb
# ...
document.getElementById('load-more-data').innerHTML = `<%= render 'load_more_data_link', page: @page %>`
```

Maka hasilnya akan menjadi seperti ini:

![Infinite scroll](/assets/infinite-scroll.gif)

----

Yups thats works!

Here’s how to write an “infinite scroll” feature in rails way.

Jika anda perhatikan kita hanya menggunakan single javascript code saja `document.innerHTML` saja dalam membuat fitur ini.

Sampai ketemu di tulisan yang lain!

Happy hacking!

