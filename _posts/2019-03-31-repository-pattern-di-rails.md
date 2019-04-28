---
layout: post
comments: true
title:  "Repository Pattern di Rails"
date:   2019-03-31 14:26:24 +0700
categories: rails
comments:   true
published: false
---

Repository Pattern, salah satu pattern untuk meringankan beban model Anda.

Di konsep Domain-Driven Design, Repository pattern dikenal sebagai objek yang paling dekat dengan database, sedangkan Model yang kita kenal di Rails harusnya menjadi entity. Sebuah _Plain Ruby Object_ saja, contohnya:

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

Mungkin hampir mustahil mengimplementasi hal tersebut di Model khususnya jika anda menggunakan _Active Record_, alternatifnya jika anda ingin benar-benar ingin mengimplementasikan-nya anda bisa menggunakan `dry-rb` sebagai _replacement_ dari _Active Record_.

Panduan untuk hal tersebut anda bisa membaca buku [_Exploding Rails_](https://leanpub.com/explodingrails) karya _Ryan Bates_. Ide dari buku itu sangat menarik, bagaimana _dry-rb_ benar-benar memisahkan _Responsibility_ dari validasi, callback sampai masalah query. Setiap aktifitas tersebut anda dituntut untuk membuat masing-masing kelas atau objectnya.

_Apakah itu over engineering?_

Saya rasa tidak, setiap objectnya memilki tujuannya masing-masing dan menurut saya masih masuk akal. Namun, anda perlu banyak konfigurasi lagi, contohnya pada form, anda harus bisa membuat model anda _compatible_ dengan _form_helpers_ dari Rails.

Tapi Implementasi Repository yang ingin saya tunjukkan disini berbeda seperti yang anda kenal, contohnya seperti pada kode yang diatas.

Lagi-lagi, Mas _Ivan Nemytchenko_ membuat saya terkesima dengan caranya mengimplementasikan Repository Pattern, yang benar-benar tidak mengilangkan _Rails way_-nya.

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

Kita mempunyai beberapa scope seperti diatas, lalu mari kita _refactor_ dengan menggunakan _repository pattern_ ala Mas Ivan.

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

Direktorinya kira-kira:

```
.
├── app
│   └── models
|       └── user.rb
|   └── repositories
|        └── user_repository.rb
```

Kode diatas masih memiliki arti yang sama, yaitu anda tetap dapat menggunakan perintah seperti `User.actives`, `User.pendings`, `User.admins`, dll.

### Kesimpulan

Repository pattern yang baru saja anda lihat mungkin terlihat sederhana, namun jika table di model anda sudah banyak kolomnya dan scope yang dimiliki sudah puluhan bahkan ratusan, repository pattern akan sangat terasa, membuat model anda menjadi lebih ringan untuk dilihat :)

Terima kasih telah membaca, semoga tulisan ini dapat bermamfaat bagi pembaca skalian.
