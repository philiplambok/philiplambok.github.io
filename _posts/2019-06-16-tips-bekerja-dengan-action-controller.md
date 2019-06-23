---
layout: post
title: "Tips saat bekerja dengan Action Controller"
date: 2019-06-16 12:00:00 +0700
categories: rails-tips
comments: true
published: false
---

<!--
- Hindari penggunaan before_action
- Hindari penggunaan instance variable pada controller
- Namespacing Controller
- Buat standard routes
- Buat standard controller
- Keep it simple.
- Gunakan static analyzer
- Kesimpulan
 -->

Tulisan ini serupa dengan tulisan sebelumnya yang berjudul [Tips saat bekerja dengan Active Record](https://philiplambok.github.io/rails-tips/2019/06/14/tips-dalam-bekerja-active-record.html).

Jika pada tulisannya sebelumnya saya berfokus pada _model layer_, pada tulisan ini saya akan berfokus pada _controller layer_.

Pada pola MVC, controller memiliki tanggung jawab untuk meneruskan request yang diberikan oleh pengguna aplikasi dan mengirim responsenya ke _views template_.

Tidak se-ekstrim ActionRecord. ApplicationRecord biasanya cukup bekerja dengan baik.

Atau mungkin hanya terlihat baik? Hmnn

Pada tulisan ini saya mencoba mengeluarkan opini-opini saya berdasarkan pengalaman pribadi, bagaimana kita semestinya menulis kode di layer ini dengan baik.

#### Pertama: Hindari penggunaan before_action

`before_action` atau saya lebih suka menyebutnya _the magic function dependency creator_.

Walaupun judulnya `before_action`, namun anda juga harus menghindari teman-temannya juga seperti `after_action`, `around_action` dan lain-lain. `before_action` saya pilih karena callback inilah yang paling banyak digunakan.

`before_action` akan membuat sebuah fungsi terdependensi dengan secara magic, yang jika kita debug memerlukan usaha yang lumayan pusing. Tidak hanya kelas saja yang dapat memiliki _dependency_ tapi _function_ juga bisa.

![function dependent](/../assets/function_dependent.png)

Gambar diatas adalah contoh bagaimana `function_a` bergantung(_dependent_) pada `function_b`.

Jika kita contohkan pada kode, kira-kira seperti ini

```rb
class UsersController < ApplicationController
  def function_a
    user = User.new(user_params)
    function_b()
  end

  private

  def function_b
  end
```

Pada kode diatas, `function_a` memanggil `function_b` artinya `function_a` _dependent_ dengan `function_b`. Ketika ada perubahan di `function_b` maka `function_a` juga ikut berubah.

Sebenernya hal tersebut tidaklah buruk. Memecahkan kode yang banyak dan kompleks menjadi bagian-bagian kecil _function_ adalah hal yang baik.

Yang buruk adalah jika anda menggunakan _function dependency_ menggunakan `before_action`, seperti kode dibawah ini:

```rb
class UsersController < ApplicationController
  before_action :function_b, only: %i[function_a]

  def function_a
    user = User.new(user_params)
  end

  private

  def function_b
  end
end
```

Bayangkan jika `before_action` ada banyak karena proses bisnis kita yang kompleks. Misalnya kita memiliki 5 atau 10 `before_action`, maka kita akan sangat sulit mengetahui _function-function_ apa saja yang dipanggil di `function_a` atau ter*depedency* dengan `function_a`.

```rb
class ArticlesController < ApplicationController
  def show
    @article = find_article(params[:id])
  end

  def edit
    @article = find_article(params[:id])
  end

  def update
    article = find_article(params[:id])
    if article.update(article_params)
      # ...
  end

  def destroy
    article = find_article(params[:id])
    if article.destroy
      # ...
  end

  private

  def find_article(id)
    Article.find_by(id: id)
  end
end
```

Saya lebih prefer kode diatas dibandingkan dengan menggunakan `before_action`.

Mungkin anda berfikir, kenapa harus ditulis seperti itu? Bukannya itu duplikasi?

Duplikasi? Menurut saya itu tidak duplikasi. Apakah jika kita memanggil sebuah function yang sama di beberapa tempat yang berbeda dinamakan duplikasi?

Saya rasa tidak. Kode saya tidak duplikasi, namun _reuseable_. Saya memiliki function yang bisa digunakan kembali lagi dan lagi. Dan itu hal yang baik bagi saya.

Namun `before_action` masih tetap saya gunakan untuk hal-hal seperti otentikasi atau otorisasi, seperti kode dibawah ini.

```rb
class AdminsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index; end
end
```

Selain kedua hal tersebut, sebisa mungkin hindari.

#### Kedua: Hindari penggunaan instance variable

Tips kedua adalah hindari atau jangan gunakan _instance variable_ pada _controller_ anda. Tips ini bisa dilakukan jika anda sudah menerapkan tips yang pertama.

Tidak jarang saya menemukan kode yang seharusnya simple, namun menjadi kompleks dikarenakan penggunakan `instance_variable` yang berlebihan. Penggunaan `instance variable` membuat scope dari variable tersebut menjadi sangat luas dan sulit dipelihara.

Mungkin biar kelihatan lebih jelas, mari kita masuk ke contoh kode. Pertama kita menulis menggunakan `instance_variable` lalu kita refactor kodenya agar tidak menggunakan `instance_variable`.

Studi kasus mudah yaitu perhitungan sederhana saja.

Kode yang menggunakan `instance_variable`:

```rb
def main
  @result = params[:result]
  calculate_result
  render json: @result
end

private

def calculate_result
  result_plus_two
  result_plus_three
  result_plus_four
end

def result_plus_two
  @result += 2
end

def result_plus_three
  @result += 3
end

def result_plus_four
  @result += 4
end
```

Kode yang tidak menggunakan `instance_variable`, atau hanya menggunakan `local_variable` saja

```rb
def main
  result = calculate(params[:result])
  render json: result
end

private

def calculate(result)
  result = add_two(result)
  result = add_three(result)
  add_four(result)
end

def add_two(number)
  number + 2
end

def add_three(number)
  number + 3
end

def add_four(number)
  number + 4
end
```

Mungkin jika dilihat dari teori _function dependency_ keduanya memiliki garis yang sama. Namun untuk kemudahan debug atau modifikasi maupun penambahan fitur, kode yang menggunakan `local_variable` jelas lebih mudah dibandingkan dengan kode yang ditulis dengan `instance_variable`.

#### Ketiga: Namespacing Controller

Sama seperti pada layer model, tidak ada aturannya controller harus berada pada 1 level directory.

Dapat dilihat [disini](https://github.com/philiplambok/kaon/blob/develop/config/routes.rb)

#### Keempat: Buat standard untuk Controller

#### Kelima: Keep it simple

#### Terakhir: Gunakan Static Analyzer

#### Kesimpulan
