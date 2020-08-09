---
layout: post
title:  "Menjalankan test secara paralel di Rails"
date:   2020-08-09 10:10:00 +0700
categories: parallel_test, rspec, rails
comments: true
published: true
---

Tulisan ini akan singkat, gw cuman mau share hasil eksperimen di *weekend* ini terkait testing.

Eksperimennya itu adalah oprek paket [parallel_test](https://github.com/grosser/parallel_tests).

Paket ini dibuat untuk membuat test (spec) di Ruby (Rails) bisa dijalankan secara parallel. Goalsnya adalah dapat membuat test jalannya jadi jauh lebih cepat. 

Untuk instalasinya sangat-sangatlah simple: 

Pertama tambahkan gem `parallel_tests` di `Gemfile`.

```rb
gem 'parallel_tests', group: [:development, :test]
```

Lalu edit `database.yml`, dengan memasukan `ENV['TEST_ENV_NUMBER']`. 

ENV ini nantinya digunakan sebagai jumlah thread atau proses yang ingin dibuat. Pada paket ini setiap proses akan dijalankan di database yang berbeda, maka jika anda define `ENV` dengan 8, maka database test anda nantinya juga ada 8. Logic ini dibuat sebagai solusi atas issue deadlock pada software database.

```yml
test:
  database: yourproject_test<%= ENV['TEST_ENV_NUMBER'] %>
```

Sekarang silahkan buat databasenya

```sh
RAILS_ENV=test bundle exec rake parallel:create
```

Lalu jalankan migrasinya:

```sh
RAILS_ENV=test bundle exec rake parallel:migrate
```

Lalu seedsnya, (jika di test anda membutuhkan seeds):

```sh
RAILS_ENV=test bundle exec rake parallel:seed
```

Jika database sudah *complete*, maka sekarang tinggal jalankan testnya (di RSpec):

```sh
RAILS_ENV=test bundle exec rake parallel:spec
```

-----

Dapat dilihat, dengan parallel_test *test runtime* jadi jauh lebih cepat. Pada projek eksperimen kira-kira hasilnya seperti ini:

```
$> time bundle exec rspec
196.55s user 24.45s system 35% cpu 10:30.98 total
$> time RAILS_ENV=test bundle exec rake parallel:spec
302.62s user 56.55s system 144% cpu 4:08.47 total
```

Dengan 8 thread proses yang jalan dengan paralel, running time test dari 10 menitan jadi 4 menitan, 

Untuk paralel test ini sendiri sebenernya sudah ada di default Rails 6. Jika projek anda menggunakan mini-test dan Rails 6, bisa coba paralel test bawaan rails disini: https://edgeguides.rubyonrails.org/testing.html#parallel-testing. 

Namun sayangnya saat tulisan ini ditulis RSpec masih belum implementasi fitur tersebut, jadi jika anda menggunakan RSpec, mungkin bisa menggunakan gem `parallel_test`. 

Sekian saja tulisan kali ini, happy hacking~.