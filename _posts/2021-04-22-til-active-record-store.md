---
layout: post
title:  "TIL: ActiveRecord::Store"
date:   2021-04-22 10:10:00 +0700
categories: rails, active-record
comments: true
published: true
---

Jadi ceritanya ketika gw mau nambahin interface baru di [Realiser](https://github.com/philiplambok/realiser/issues/2), sebuah rails engine yang baru gw buat belakangan ini, interfacenya gw mau buat static method `.store` di model turunan `ActiveRecord::Base`, dapat error conflict, ternyata `.store` udah reserved di kelas `ActiveRecord::Base`. 

Dan, ternyata setelah baca API ini di docsnya, lumayan menarik juga, jadinya skalian aja share dimari.

Kalo di docs definisinya ditulis gini:

> Store gives you a thin wrapper around serialize for the purpose of storing hashes in a single column. It's like a simple key/value store baked into your record when you don't care about being able to query that store outside the context of a single record.

Initinya `store` callback yang bisa bikin model kita punya beberapa attribute yang bisa disimpen di cukup satu kolom aja, dimana kolom tersebut disimpan sebagai *json*, jadinya ketika attribute2 yang disimpen bisa dinamis dan flexible, kita bisa nambahin atau menghapus attribute yang bersangkutan tanpa perlu adanya migrasi database. 

Selain kemudahan migrasi, juga dapat membuat table jadi lebih bersih, karna *grouping*-nya.

Oke, mungkin langsung ke contoh implementasinya:

Kira2 kita pengen bikin model `Invoice` yang ngimpen data customer.

Pertama mari bikin modelnya dulu:

```
$ rails g model Invoice customer:text
```

Terus di modelnya kita define apa aja attribute yang mau disimpen di customer, contohnya gini:

```rb
class Invoice < ApplicationRecord
  store :customer, accessors: %i[name phone], coder: JSON, prefix: true
end
```

Misalnya kita mau simpen data nama customer dan nomor handphonenya, dan aksesnya bisa dibuat gini:

```
Running via Spring preloader in process 19326
Loading development environment (Rails 6.1.3.2)
irb(main):001:0> invoice = Invoice.create!(customer_name: 'Kokomi', customer_phone: '08123123123')
  TRANSACTION (0.2ms)  BEGIN
  Invoice Create (0.5ms)  INSERT INTO `invoices` (`customer`, `created_at`, `updated_at`) VALUES ('{\"name\":\"Kokomi\",\"phone\":\"08123123123\"}', '2021-05-22 05:01:10.126028', '2021-05-22 05:01:10.126028')
  TRANSACTION (0.7ms)  COMMIT
=> 
#<Invoice:0x00007f8879200540
 id: 1,
 customer: {"name"=>"Kokomi", "phone"=>"08123123123"},
 created_at: Sat, 22 May 2021 05:01:10.126028000 UTC +00:00,
 updated_at: Sat, 22 May 2021 05:01:10.126028000 UTC +00:00>
irb(main):002:0> invoice.customer_name
=> "Kokomi"
irb(main):003:0> invoice.customer_phone
=> "08123123123"
irb(main):008:0> invoice.customer
=> {"name"=>"Kokomi", "phone"=>"08123123123"}
irb(main):009:0> invoice.customer[:name]
=> "Kokomi"
irb(main):010:0> invoice.customer[:phone]
=> "08123123123"
```

Data `invoice.customer` di database tetep simpan sebagai string, tapi secara default kita langsung dapat versi hashnya. Which is good.

Kita juga bisa memberikan validasi pada attribute-attribute seperti layanya atribute biasa:

```rb
class Invoice < ApplicationRecord
  validates :customer_name, presence: true

  store :customer, accessors: %i[name phone], coder: JSON, prefix: true
end
```

```
Running via Spring preloader in process 21979
Loading development environment (Rails 6.1.3.2)
irb(main):001:0> Invoice.create!
/usr/local/var/rbenv/versions/3.0.1/lib/ruby/gems/3.0.0/gems/activerecord-6.1.3.2/lib/active_record/validations.rb:80:in `raise_validation_error': Validation failed: Customer name can't be blank (ActiveRecord::RecordInvalid)
irb(main):002:0> Invoice.create(customer_name: "Hello")
  TRANSACTION (0.2ms)  BEGIN
  Invoice Create (5.4ms)  INSERT INTO `invoices` (`customer`, `created_at`, `updated_at`) VALUES ('{\"name\":\"Hello\"}', '2021-05-22 05:08:04.310622', '2021-05-22 05:08:04.310622')
  TRANSACTION (2.5ms)  COMMIT
=> 
#<Invoice:0x00007f88737a3a48
 id: 3,
 customer: {"name"=>"Hello"},
 created_at: Sat, 22 May 2021 05:08:04.310622000 UTC +00:00,
 updated_at: Sat, 22 May 2021 05:08:04.310622000 UTC +00:00>
irb(main):003:0> 
```

Untuk lebih lengkapnya bisa baca documentasi resminya disini ya: [https://api.rubyonrails.org/classes/ActiveRecord/Store.html](https://api.rubyonrails.org/classes/ActiveRecord/Store.html)

----

Itu aja sih yang mau dishare ditulisan ini, happy hacking ya~



