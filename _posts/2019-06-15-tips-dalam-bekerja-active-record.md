---
layout: post
title: "Tips saat bekerja dengan Active Record"
date: 2019-06-15 0:0:00 +0700
categories: rails-tips
comments: true
published: true
---

<!-- Apa yang ini ingin disampaiikan?

- Masalah pada active record.
- Perlunya sebuah standard.
- Masukkan rule domain model dari buku painless rails.
- pengenalan repository pattern.
- pengenalan konsep mutator.
- gunanya namespacing.
- pentingnya kode uji
- kesimpulan.
-
-->

Jika anda mengingat kembali hari-hari awal kita menulis kode Active Record mungkin sangat menyenangkan.

Namun seiringnya waktu, kode yang ditulis oleh active record menjadi sangat besar dan sulit dipelihara. Saya sudah pernah mengulas tentang hal ini ditulisan sebelumnya, mungkin anda bisa cek [disini](https://philiplambok.github.io/rails/2019/04/28/mutator-bagian-gelap-dari-service.html).

Pada tulisan ini saya ingin fokus memberikan beberapa tips yang mungkin dapat membuat kode anda lebih mudah dipelihara khusunya pada model anda.

#### Pertama: Jangan gunakan Active::Record callbacks seperti `before_create`, `after_create` dan sejenisnya.

Untuk list lengkap dari action-actionnya ada di [dokumentasi ini](https://guides.rubyonrails.org/active_record_callbacks.html).

Callback adalah kode proses bisnis yang sangat cepat untuk berubah-ubah(dinamis). Bagi saya model yang baik itu adalah model yang jarang untuk berubah.
Selain itu, kode bisnis juga sangat bisa menjadi kompleks.

Contohnya ketika sebuah data dihapus, sistem bisa saja melakukan banyak sekali hal-hal yang berakhir dengan seratus baris untuk sebuah callback `after_destroy` saja, belum termasuk `before_destroy` atau `after_create` jika mungkin nanti ada.

Alternativenya anda bisa menggunakan konsep Mutator.

Saya sudah pernah bahas konsep ini di [tulisan yang sebelumnya](https://philiplambok.github.io/rails/2019/04/28/mutator-bagian-gelap-dari-service.html).

#### Kedua: Model tidak diperbolehkan untuk memiki _dependency_.

Singkatnya, anda hanya boleh memangil _method-method_ yang ada di dalam kelas yang bersangkutan saja dan tidak boleh memanggil kelas lain.

Contohnya seperti ini:

```rb
class User < ApplicationRecord
  def add_log
    Log.add_user_log("User log created")
  end
end
```

Pada kode diatas anda memangil kelas `Log` pada kelas `User`, artinya kelas `User` memiliki _dependency_ pada kelas `Log`. Artinya ketika model `Log` anda ubah, maka model `User` juga akan ikut berubah.

Rails menganut pola MVC pada developmentnya, dimana pada pola itu model adalah core kelas atau objek yang bisa dipanggil dibanyak tempat seperti controller, view atau service dan sebagainya.

Maka saya tidak ingin model memiliki _dependency_ pada model lain atau kelas lain.

Jika pada suatu model terdapat _dependency_ maka rantaian _dependency_ pada sebuah proses tersebut akan menjadi sangat besar sehingga kode sulit untuk dipelihara.

Hal ini bisa terealisasi jika anda tidak menggunakan `callback`, tips yang sebelumnya.

#### Ketiga: Perlunya sebuah _standard_

Berdasarkan tips-tips sebelumnya, maka anda butuh sebuah _standard_ atau _rule_ dalam menulis kode model.

Active Record sangat-sangat ideal sekali dalam menampilkan data, namun cukup buruk untuk menulis atau memberharui data pada database.

Maka anda perlu _rule_ yang cukup ketat untuk membatasi domain pada model ini, _rule_ ini saya ambil dari sebuah buku yang ditulis oleh [Ivan Nemytchenko](https://github.com/inem).

Model hanya dibolehkan memiliki 3 hal ini:

1. Asosiasi. `belongs_to`, `has_many` dan sejenisnya dibolehkan.
2. _Attribute_. `enum status: { :active, :inactive }`, `attr_reader`, `attributes`, `delegate :local, :user` dan sejenisnya dibolehkan.
3. Aturan bisnis terkait model yang bersangkutan. Contohnya seperti validasi: `validates :username, presence: true` atau mempertanyakan tentang field dari model `def admin?; end`

Model tidak boleh memiliki:

- Aplikasi logic seperti:

  ```rb
  class User
   has_many :items

   def add_item(item)
     items.create(item.attributes)
   end
  ```

- Jangan melakukan otorisasi seperti `User.can_edit_post(post)`, lebih baik gunakan _policy object_.
- Penggunaan `scope` sebaiknya juga dihindari, lebih baik gunakan _repository pattern_, contohnya seperti kode ini:

  ```rb
  # app/repositories/user_repository.rb
  module UserRepository
    extend ActiveSupport::Concern

    included do
      scope :admins,
            -> { where(admin: true) }
    end
  end

  # app/model/user.rb
  class User < ApplicationRecord
    include UserRepository
  end

  # anda bisa memanggilnya seperti ini
  User.admins
  ```

Maka, saya melihat sebuah objek model itu lebih mempresentasikan sebuah _record_ dibandingkan sebuah _table_.

![rule model](/../assets/rule_model.png)

#### Keempat: Gunakan Static Analyzer

Salah satunya adalah [Rubocop](https://github.com/rubocop-hq/rubocop) anda bisa set di file `rubocop.yml`

```yml
Rails:
  Enabled: true
```

Dengan static analyzer anda bisa mengunakan method-method yang sesuai standard yang direkomendasikan oleh komunitas Rails.

#### Kelima: Gunakan fitur namespacing

Jangan menaruh sebuah model pada level yang sama, misalnya

```
/models
  -- user.rb
  -- article.rb
  -- article_comment.rb
```

Tapi coba berikan `namespace` pada model anda sehingga arsitektur folder anda bisa menceritakan sistem aplikasi apa yang anda buat. Anda bisa lakukan refactor menjadi seperti ini.

```
/models
  -- user.rb
  -- article.rb
  /article
    - comment.rb
```

Artinya model comment anda simpan di dalam modul article:

```rb
module Article
  class Comment < ApplicationRecord
  end
end
```

#### Keenam: Gunakan _annotate_models_

_Annotate_models_ adalah sebuah gem yang memberikan komentar daftar field-field apa saja yang ada pada sebuah model. Anda bisa cek dokumentasinya [disini](https://github.com/ctran/annotate_models).

#### Terakhir: Jangan lupa untuk uji model anda.

Sebenernya tips ini lebih penting dari semuanya, namun saya taruh di paling terakhir karena saya anggap anda sudah paham pentingnya kode test ini.

Jika anda ingin mengimplementasikan tips-tips diatas pada kode _legacy_ sebaiknya gunakan metode _cover and modify_ yaitu tulis kode testnya dulu baru kemudian ubah kode produksinya.

#### Kesimpulan

Mari kita buatkan list dari tips-tips sebelumnya dibagian ini:

- Jangan gunakan Active::Record callbacks seperti `before_create`, `after_create` dan sejenisnya.
- Model tidak diperbolehkan untuk memiki _dependency_
- Perlunya Sebuah Standard
- Gunakan Static Analyzer
- Gunakan fitur namespacing (module)
- Gunakan annotate_models
- Jangan lupa untuk uji model anda.

Tips ini tidak bersifat mutlak, mungkin ada beberapa yang belum tercover. Jika nanti saya menemukan hal yang baru, saya akan update lagi.

Jika anda memiliki _preference_ atau opini yang berbeda dengan saya, anda bisa berikan kritik dan saran kepada saya. Sekian saja untuk tulisan ini, terima kasih.
