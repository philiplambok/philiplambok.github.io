---
layout: post
title:  "Enkripsi Data di Rails"
date:   2020-05-22 10:10:00 +0700
categories: rails, encryption
comments: true
published: true
---

Karna terpicu tentang kejadian kebobolan data yang ramai belakangan ini, saya jadi ingin coba oprek-oprek tentang enkripsi data.

Pada tulisan ini akan berbagi sesuatu yang baru saja saya pelajari. Kita akan membuat sebuah projek kecil-kecilan seperti biasanya.

Kita akan membuat sebuah projek yang bisa menyimpan sebuah data karyawan, dimana ada atribut yang kita enkripsi, yaitu salary (gaji).

Saya akan menggunakan Rails dan library(gem) yang menarik yaitu [lockbox](https://github.com/ankane/lockbox) dan [blind_index](https://github.com/ankane/blind_index).

Saya menggunakan library ini karena interface dan migrasi yang sangat mudah. Mari kita mulai dengan membuat projeknya.

```
$> rails new try-db-encrypt --database=mysql
```

Saya menggunakan mysql, bukan sqlite agar databasenya bisa di akses lewat db client di local saya. 

Lalu buat scaffolding employee-nya, saya akan membuatnya sangat simple saja:

```
$> rails g scaffold employee full_name salary:integer
```

Lalu mari kita buka halaman employees-nya dan tambahkan data. Kita tidak mengimplementasikan enkripsinya terlebih dahulu agar skalian mencontohkan cara migrasi data dari plain data. Karna pada realitas projek yang ada tidak dibuat dengan enkripsi di tempat pertama.

Setelah anda menambahkan beberapa data, saatnya kita mengintall lockbox. Tambahkan gem ini pada file `Gemfile`:

```rb
gem 'lockbox'
```

Lalu jalankan `bundle install`. 

Pertama kita generate dulu random keynya dengan:

```rb
Lockbox.generate_key 
#> '103cc6ebf93fd0d146dfdbc8791218bcf07e1dfa717bf84a018100ff59d51c21'
```

Kita akan menggunakan default rails credensial untuk menyimpannya:

```
$> EDITOR=vim rails credentials:edit
```

```
lockbox_master_key=103cc6ebf93fd0d146dfdbc8791218bcf07e1dfa717bf84a018100ff59d51c21
```

Dan buat file `config/initializers/lockbox.rb`

```
Lockbox.master_key = Rails.application.credentials.lockbox_master_key
```

Setelah itu buat file migrasi pada atribute yang ingin kita enkripsi, pada kasus ini adalah salary:

```
$> rails g migration addSalaryChipertext salary_chipertext:text
```

Lalu jalankan migrationnya: 

```
$> rails db:migrate
```

Dan update model `Employee`-nya:

```rb
# frozen_string_literal: true

# Employee
class Employee < ApplicationRecord
  encrypts :salary, type: :integer, encode: true
end
```

Lalu pergi ke halaman web employeesnya dan tambahkan data baru, maka pada db clientnya data akan dibuat begini:

```yml
id: 4
name: something
salary: 10000000
salary_ciphertext: 3d5Lo+N9DS8Cdbtl4JVSEWCXYjisENn53EqGZ0nRBGc=
```

Artinya enkripsi telah berhasil. Sekarang waktunya untuk migrasi data, karena pada data-data employees sebelumnya tidak memiliki nilai pada field `salary_ciphertext`.

Migrasi dapat dilakukan dengan sangat mudah, kita tinggal jalankan kode ini di console:

```
Lockbox.migrate(Employee)
```

Maka semua field akan memiliki nilai pada field `salary_ciphertext`.

Setelah migrasi selesai waktunya untuk menghapus field salary kita, karna percuma saja kita encrypt tapi nilai aslinya masih ada didatabase.

```
$> rails g migration RemoveSalaryFromEmployees salary:integer
```

Lalu jalankan

```
$> rails db:migrate
```

Maka data pada database kita tinggal:

```yml
id: 4
name: something
salary_ciphertext: 3d5Lo+N9DS8Cdbtl4JVSEWCXYjisENn53EqGZ0nRBGc=
```

Namun, aplikasi web kita tidak ada yang break. Artinya kita telah berhasil melakukan enkripsi pada database kita.

Namun setelah ini kita ada issue baru, yaitu kita tidak bisa mencari salary yang kita inginkan, karena datanya yang ada di database sudah di enkripsi. 

```
Employee.where(salary: 1_000_000)
#> ActiveRecord::StatementInvalid (Mysql2::Error: Unknown column 'employees.salary' in 'where clause')
```

Issue ini bisa di solve dengan menggunakan blind_index.

Install gem ini dari `Gemfile`:

```rb
gem 'blind_index'
```

Lalu jalankan `bundle install`

Lalu update model `Employee` kita: 

```rb
# frozen_string_literal: true

# Employee
class Employee < ApplicationRecord
  encrypts :salary, type: :integer, encode: true
  blind_index :salary
end
```

Dan buat file migrasi baru: 

```
$> rails g migration addSalaryBidxToEmployees salary_bidx:text
```

Lalu jalankan

```
$> rails db:migrate
```

Lalu jalankan kode ini untuk migrasi di level datanya:

```
BlindIndex.backfill(User)
```

Sekarang di database kita menjadi seperti ini:

```yml
id: 4
name: something
salary_ciphertext: 3d5Lo+N9DS8Cdbtl4JVSEWCXYjisENn53EqGZ0nRBGc=
salary_bidx: 3d5Lo+N9DS8Cdbtl4JVSEWCXYjisENn53EqGZ0nRBGc=
```

Sekarang sudah solved:

```rb
$> Employee.where(salary: 1_000_000)
#<ActiveRecord::Relation [#<Employee id: 2, full_name: "Nani what the heels", created_at: "2020-05-22 04:35:17", updated_at: "2020-05-22 05:01:56", salary_bidx: "hjUe8orIAKr6k2XXOCUkVFm9DZ7CYDc2uTc1SdQjrdY=">, #<Employee id: 5, full_name: "This is good employee", created_at: "2020-05-22 04:58:39", updated_at: "2020-05-22 05:01:56", salary_bidx: "hjUe8orIAKr6k2XXOCUkVFm9DZ7CYDc2uTc1SdQjrdY=">]>
```

Jadi ketika database kita dicuri, data salarynya akan aman.

Namun, lain hal jika file log kita juga ikut dicuri.

Jika anda sadar, jika kita lihat file log ketika membuat data employee baru:

```log
Started POST "/employees" for ::1 at 2020-05-22 16:09:15 +0700
Processing by EmployeesController#create as HTML
  Parameters: {"authenticity_token"=>"AXc02QtOmL8OzVUght/J89v8WbPwd2yQossbZnepJrCEMPiZRYvoWHepSnpdC4hFFK5qY8xAEJ5dEk6OvkYBNg==", "employee"=>{"full_name"=>"Plain logger", "salary"=>"1000000"}, "commit"=>"Create Employee"}
   (0.3ms)  BEGIN
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
  Employee Create (0.5ms)  INSERT INTO `employees` (`full_name`, `created_at`, `updated_at`, `salary_ciphertext`, `salary_bidx`) VALUES ('Plain logger', '2020-05-22 09:09:15.687197', '2020-05-22 09:09:15.687197', 'rJgUVQwMvqtjTGAy8iHhWC6GhMSXIdMx5UD3p7h6jMAqux4B', 'hjUe8orIAKr6k2XXOCUkVFm9DZ7CYDc2uTc1SdQjrdY=')
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
   (1.7ms)  COMMIT
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
Redirected to http://localhost:3000/employees/8
Completed 302 Found in 29ms (ActiveRecord: 2.5ms | Allocations: 4208)
```

Anda akan sadar, salary dan full name dari employee tertulis jelas disana.

Untuk mengatasi masalah ini, kita akan melakukan filter pada field salary secara global dengan fitur bawaan Rails. 

Kita bisa update file `config/initializers/filter_parameter_logging.rb` menjadi ini: 

```rb
# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]
Rails.application.config.filter_parameters += [:salary]
```

Awalnya rails hanya melakukan filter pada field password saja, sekarang kita tambahkan field baru yaitu `salary`.

Maka, anda bisa restart servernya lalu coba tambahkan employee baru, kita akan mendapatkan log seperti ini:

```log
Started POST "/employees" for ::1 at 2020-05-22 16:15:36 +0700
Processing by EmployeesController#create as HTML
  Parameters: {"authenticity_token"=>"OmJfyBcAay0myS1nYKyKinCbmiqh0VafUR2c0nJcqvC/JZOIWcUbyl+tMj27eMs8v8mp+p3mKpGuxMk6u7ONdg==", "employee"=>{"full_name"=>"Filtered logs", "salary"=>"[FILTERED]"}, "commit"=>"Create Employee"}
   (0.5ms)  BEGIN
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
  Employee Create (0.7ms)  INSERT INTO `employees` (`full_name`, `created_at`, `updated_at`, `salary_ciphertext`, `salary_bidx`) VALUES ('Filtered logs', '2020-05-22 09:15:36.875876', '2020-05-22 09:15:36.875876', 'bsVU8Vk1iBcacwb2LWMu4okqoVwhtXG4RRYp8h/TJuywQn3B', 'hjUe8orIAKr6k2XXOCUkVFm9DZ7CYDc2uTc1SdQjrdY=')
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
   (1.0ms)  COMMIT
  ↳ app/controllers/employees_controller.rb:30:in `block in create'
Redirected to http://localhost:3000/employees/9
Completed 302 Found in 31ms (ActiveRecord: 2.3ms | Allocations: 4217)
```

Oke, sekarang salarynya tidak ditampilkan pada file log kita.

Sekedar saran jika anda mengimplementasi lockbox pada projek anda pastikan file migrasi penambahan field `salary_chipertext` dan `salary_bidx` dengan penghapusan field `salary` (plain) terjadi pada beda deployment. Karna kita terjadi pada satu deployment data salary yang di current production akan menjadi hilang dan anda tidak bisa melakukan migrasi data. 

Jadi, pastikan migrasi data terjadi dengan lancar, baru lakukan penghapusan field. 

Saya kira cukup sampai disini saja, terima kasih telah membaca tulisan ini :)


