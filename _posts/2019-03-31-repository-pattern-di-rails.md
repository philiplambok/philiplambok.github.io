---
layout: post
comments: true
title:  "Repository Pattern di Rails"
date:   2019-03-31 14:26:24 +0700
categories: rails
comments:   true
---

Repository Pattern, salah satu pattern untuk meringankan beban model Anda.

Di konsep Domain-Driven Design, Repository pattern dikenal sebagai objek yang paling dekat dengan database, sedangkan Model yang kita kenal di Rails harusnya menjadi entity. Sebuah *Plain Ruby Object* saja, contohnya:
```rb
# Repository Pattern
class UserRepository
  def all
    # Selecting all users from database
  end

  def create(user)
    # sql query to create users
  end
end


# Model -- PORO
class User
end

# Controller
def index
  @users = UserRepository.all
end


def create
  @user = UserRepository.create(User.new(user_params))
  # ...
end
```

Mungkin hampir mustahil mengimplementasi hal tersebut di Model khususnya jika anda menggunakan *Active Record*, alternatifnya jika anda ingin benar-benar ingin mengimplementasikan-nya anda bisa menggunakan `dry-rb` sebagai *replacement* dari *Active Record*.

Panduan untuk hal tersebut anda bisa membaca buku [*Exploding Rails*](https://leanpub.com/explodingrails) karya *Ryan Bates*. Ide dari buku itu sangat menarik, bagaimana *dry-rb* benar-benar memisahkan *Responsibility* dari validasi, callback sampai masalah query. Setiap aktifitas tersebut anda dituntut untuk membuat masing-masing kelas atau objectnya.

*Apakah itu over engineering?*

Saya rasa tidak, setiap objectnya memilki tujuannya masing-masing dan menurut saya masih masuk akal. Namun, anda perlu banyak konfigurasi lagi, contohnya pada form, anda harus bisa membuat model anda *compatible* dengan *form_helpers* dari Rails.

Tapi Implementasi Repository yang ingin saya tunjukkan disini berbeda seperti yang anda kenal, contohnya seperti pada kode yang diatas.

Lagi-lagi, Mas *Ivan Nemytchenko* membuat saya terkesima dengan caranya mengimplementasikan Repository Pattern, yang benar-benar tidak mengilangkan *Rails way*-nya.

Kita langsung saya melihat contohnya, andaikan kita memiliki table users seperti ini
```rb
# app/models/user.rb
# SCHEMA:
# id            : integer
# username:     : string
# admin         : boolean
# status        : integer
# created_at    : datetime
# updated_at    : datetime
class User
  scope :actives,
        -> { where(status: :active) }
  scope :pendings,
        -> { where(status: :pending) }
  scope :inactives,
        -> { where(status: :inactives) }
  scope :admins,
        -> { where(admin: true) }

  enum status: %i[active pending inactive]

  validates :username,
             presence: true,
             uniqueness: { case_sesitive: false }
end
```

Kita mempunyai beberapa scope seperti diatas, lalu mari kita *refactor* dengan menggunakan *repository pattern* ala Mas Ivan.

```rb
# app/repositories/user_repository.rb
module UserRepository
  extend ActiveSupport::Concern

  included do
    scope :actives,
          -> { where(status: :active) }
    scope :pendings,
          -> { where(status: :pending) }
    scope :inactives,
          -> { where(status: :inactives) }
    scope :admins,
          -> { where(admin: true) }
  end
end

# Sedangkan, untuk modelnya menjadi
# app/models/user.rb
# SCHEMA:
# id            : integer
# username:     : string
# admin         : boolean
# status        : integer
# created_at    : datetime
# updated_at    : datetime
class User
  include UserRepository

  enum status: %i[active pending inactive]

  validates :username,
             presence: true,
             uniqueness: { case_sesitive: false }
end
```

Kode diatas masih memiliki arti yang sama, yaitu anda tetap dapat menggunakan perintah seperti `User.actives`, `User.pendings`, `User.admins`, dll.

### Kesimpulan
Repository pattern yang baru saja anda lihat mungkin terlihat sederhana, namun jika table di model anda sudah banyak kolomnya dan scope yang dimiliki sudah puluhan bahkan ratusan, repository pattern akan sangat terasa, membuat model anda menjadi lebih ringan untuk dilihat :)

Terima kasih telah membaca, semoga tulisan ini dapat bermamfaat bagi pembaca skalian.
