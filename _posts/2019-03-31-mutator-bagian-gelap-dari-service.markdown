---
layout: post
comments: true
title:  "Pengenalan Mutator, bagian gelap dari service object."
date:   2019-03-31 12:20:24 +0700
categories: rails
comments:   true
---
Hello, akhirnya setelah sekian lama, saya nulis lagi. Minggu ini saya menemukan sesuatu menarik yaitu pola desain Mutator.

Kata-kata *Ruby is dead* mungkin sudah sering saya dengar jadi tidak ada masalah dengan hal tersebut, namun belakangan ini saya juga sudah sering dengar *Rails is DEAD*. Jika anda salah satu orang yang menyuarakan hal tersebut dan juga pengguna aktif Hanami di *Production*, mungkin tulisan ini bukan buat anda.

Secara pribadi saya suka Rails, tapi mungkin saya sudah menemukan bahwa *Vanilla Rails* mungkin sudah tidak cocok lagi pada program yang sudah mulai besar. Pattern MVC yang diadopsi oleh Rails membuat model saya menjadi sangat besar dan sudah sulit untuk dipelihara. Service object datang sebagai salah satu solusi untuk meringankan beban dari model. Saya pun setuju dengan hal tersebut.

Namun, Mas *Ivan Nemytchenko* secara revolusioner mengenalkan saya tentang Mutator, konsep yang cukup *extreme* namun saya sangat sependapat dengannya. Kenapa *extreme*? di akhir tulisan ini akan saya jawab.

Biar *updol* dalam membahas Mutator, mari kita membuat studi kasus yang akan kita selesaikan menggunakan service object terlebih dahulu, lalu selanjutnya bary kita improve dengan menggunakan Mutator.

Ok, begini alur programnya:

Kita diminta membuatkan sebuah program kecil-kecilan untuk sebuah program internal di PT MRT, sebuah industri perkeretaan. Disana, kita disuruh membuat sebuah program terkait antrian kereta, berikut detail-nya.
```
Input:
Masukkan Kereta nama anda: [....]

----
Antrian:
[1] PX-223
[2] IO-123
[3] OO-251
[4] IW-211
```
Setiap input yang disimpan harus ada lognya: `Kereta dengan tipe IW-211 masuk ke antrian 4`, selain itu sistem ini juga harus dapat menghapus antrian tertentu, misalnya kita akan menghapus antrian kedua (`IO-123`), maka hasil akhir antrian menjadi.
```
Antrian:
[1] PX-223
[2] OO-251
[3] IW-211
```
Antrian kereta sebelumnya menjadi naik, dan ada lognya juga `Kereta dengan tipe IO-123 terhapus dari antrian 2`. Dan fitur terakhir adalah, mengapus unit keretanya, contohnya saya ingin menghapus unit `PX-223`, maka Antriannya juga terhapus, namun log yang tertulis adalah `Kereta PX-223 Terhapus dari daftar Kereta` dan tidak ada log untuk penghapusan antrian, namun realitasnya sistem tetap menampilkan daftar antrian menjadi 2 Buah saja :
```
Antrian:
[1] OO-251
[2] IW-211
```

Oke, mungkin sudah cukup jelas, sekarang mari kita buat programmya.

Saya hanya menampilkan klip-klip kode yang pentingnya saja agar kita bisa terfokus pada masalah *Mutator* dan *Service*.

### Feature Pertama: Menambahkan Fitur Antrian.
```ruby
# Controller
def create
  # ...
  add_queue = TrainQueueService::Create.new(train).perform
  # ..
end

# Service
module TrainQueueService
  class Create
    def initialize(train)
      @train = train
    end
    def perform
      number = Train::Queue.find_last_number
      current_number = number + 1
      Train::Queue.create!(number: current_number, train: @train)
      log_desc = "Kereta dengan tipe #{@train.name} masuk ke antrian #{current_number}"
      Log.create!(description: log_desc)
    end
  end
end
```

Oke, kode diatas sepertinya sudah cukup, sekarang lanjut ke penghapusan antrian.

### Feature Kedua: Menghapus Antrian.
```ruby
# Controller
def destroy
  # ...
  remove_queue = TrainQueueService::Destroy.new(train).perform
  # ...
end

module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
       name_of_train = @train.name
       queue = TrainQueue.find_by(train: @train)
       behind_the_queue = TrainQueue.find_behind_queue_of(queue)
       queue.destroy!
       behid_the_queue.each(&:increase_number!)
       log_desc = "Kereta dengan tipe #{name_of_train} terhapus dari antrian #{current_number}"
       Log.create!(description: log_desc)
    end
  end
end
```

Oke, kode diatas sudah cukup kompleks, seharusnya anda bisa memisahnya jadi beberapa method.

Sekarang fitur yang terakhir, yaitu menghapus keretanya, namun ingat kita juga perlu menghapus dari antrian keretanya yaa.

### Feature Ketiga: Menghapus Kereta
```ruby
# Controller
def destroy
  # ...
  delete_train = TrainService::Destroy.new(train).perform
  # ...
end

module TrainService
  class Destroy
    def new(train)
      @train = train
    end

    def perform
      name_of_train = @train.name
      TrainQueueService::Destroy.new(@train).perform
      @train.destroy
      log_desc = "kereta #{name_of_train} terhapus dari daftar kereta"
      Log.create(description: log_desc)
    end
  end
end
```

Oke, sepertinya sudah selesai.

Eh, namun nyatanya tidak, implementasi log yang terjadi pada kode diatas adalah.
```
Log: Kereta dengan tipe #{name_of_train} terhapus dari antrian #{current_number}
Log: kereta #{name_of_train} terhapus dari daftar kereta
```
Sesuatu yang kita tidak inginkan :(

Kita tidak seharusnya membuat log pada penghapusan antrian, ketika kita menghapus kereta.

Jadi bagaimana solusinya?

Oke, mungkin saat ini kita akan memisahkan service pada penghapusan antrian(database) dengan lognya, contohnya akan jadi seperti ini.
```ruby
module TrainQueueService
  class Remove
    def initialize(train)
      @train = train
    end

    def perform
      name_of_train = @train.name
      TrainQueueService::Destroy.new(name_of_train).perform
      log_desc = "Kereta dengan tipe #{name_of_train} terhapus dari antrian #{current_number}"
      Log.create!(description: log_desc)
    end
  end
end

module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
       name_of_train = @train.name
       queue = TrainQueue.find_by(train: @train)
       behind_the_queue = TrainQueue.find_behind_queue_of(queue)
       queue.destroy!
       behid_the_queue.each(&:increase_number!)
    end
  end
end

# Controller sebelumnya juga jadi berubah!
def destroy
  # ...
  remove_queue = TrainQueueService::Remove.new(train).perform
  # ...
end
```
Oke, sekarang lognya menjadi satu :
```
Log: kereta #{name_of_train} terhapus dari daftar kereta
```

Namun, kita mulai merasakan konsistensi service kita mulai aneh. Kita mulai merasakan adanya `Gap`. Solusi atas masalah ini adalah `Mutator`, yaitu sesuatu yang ada di `before_**` atau `after_*` seharusnya di handle oleh `Mutator` bukan `Service` class. Penambahan layer ini membuat arsitektur kita mulai berubah dari:
![Model-Service](/assets/trivial-model-service.png)

Menjadi:

![Mutator-Relation](/assets/mutator-relation.svg)

Mari kita langsung ke refactoring kode kita sebelumnya.
### Refactoring Fitur Pertama: Penambahan Kereta.
```ruby
# Controller
def create
  # ...
  add_queue = TrainQueueService::Create.new(train).perform
  # ..
end

# Mutator
class TrainQueueMutator
  def self.create(train)
    number = Train::Queue.find_last_number
    current_number = number + 1
    Train::Queue.create!(number: current_number, train: train)
  end
end

# Service
module TrainQueueService
  class Create
    def initialize(train)
      @train = train
    end
    def perform
      TrainQueueMutator.create(train)
      log_desc = "Kereta dengan tipe #{@train.name} masuk ke antrian #{current_number}"
      Log.create!(description: log_desc)
    end
  end
end
```

Oke, sekarang kita sudah pisahkan sesuatu yang bisnis role, dan sesuatu yang sebenernya lumayan *low-level/model-level*.

### Refactoring Fitur Kedua: Penghapusan antrian kereta.
```ruby
module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
      name_of_train = @train.name
      TrainQueueMutator.destroy(name_of_train)
      log_desc = "Kereta dengan tipe #{name_of_train} terhapus dari antrian #{current_number}"
      Log.create!(description: log_desc)
    end
  end
end

module TrainQueueMutator
  def self.create(train)
    # ...
  end

  def self.destroy(train)
    name_of_train = @train.name
    queue = TrainQueue.find_by(train: @train)
    behind_the_queue = TrainQueue.find_behind_queue_of(queue)
    queue.destroy!
    behid_the_queue.each(&:increase_number!)
  end
end

# Controller kita pakai yang pertama!
def destroy
  # ...
  remove_queue = TrainQueueService::Destroy.new(train).perform
  # ...
end
```

Oke, sekarang lebih mantap bukan?

### Refactoring Fitur Ketiga: menghapus kereta.
```ruby
# Controller
def destroy
  # ...
  delete_train = TrainService::Destroy.new(train).perform
  # ...
end

module TrainService
  class Destroy
    def new(train)
      @train = train
    end

    def perform
      name_of_train = @train.name
      TrainQueueMutator.destroy(@train)
      @train.destroy
      log_desc = "kereta #{name_of_train} terhapus dari daftar kereta"
      Log.create(description: log_desc)
    end
  end
end
```

Lumayan gokil?

### Kesimpulan.
Walapun agak ekstrim, seperti yang saya sebelumnya bilang, karena memang saya mencoba mencari pattern ini di google belum ada yang pernah membahasnya. Kita anda familiar dengan DDD, mungkin anda bilang kenapa tidak menggunakan *Repository Pattern*?

*Create*, *Destroy*, *Update* memang cocok untuk di repository pattern, namun jika anda mendalami lebih lanjut dari repository pattern, pada konsep tersebut, anda tidak dibolehkan untuk:
```rb
# Tidak boleh
@user.update(user_params)
# Tapi, harus
UserRepository.destroy(@user)
```
Dengan mutator, anda tetap dibolehkan menggunakan magic rails:
```ruby
# Magic, tapi tetap cantik!
@user.update(user_params)
# Namun, jika update yang dilakukan tidak lagi trivial,
# maka baiknya menggunakan mutator.
UserMutator.update(@user)
```

Semoga dengan artikel ini bermamfaat untuk anda, dan mungkin bisa menunda untuk migrasi ke Hanami ^^

Sampai ketemu di lain tulisan, Sayonara~