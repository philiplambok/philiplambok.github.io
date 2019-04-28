---
layout: post
comments: true
title:  "Pengenalan Mutator, bagian gelap dari service object."
date:   2019-03-31 12:20:24 +0700
categories: rails
comments:   true
---

Dalam menulis kode Rails kita biasanya memiliki satu mantra yakni

> Skinny Controller, Fat Model

Perbincangan di kalangan rails developer mungkin yang sering kita temui.

Q: Apa kode ini bisa saya taro di views?<br>
A: Jangan.<br>
Q: Hmnn, lalu apakah boleh saya taru di controller?<br>
A: Hmn, jangan juga deh<br>
Q: Hmnn, berarti model dong ya?<br>
A: Ok Sipp.

Hingga akhirnya model benar-benar besar, beberapa contohnya bisa kita lihat dari projek *open source* yang ada di luar seperti Discourse. Projek ini memiliki 1551 baris di model [topic.rb](https://github.com/discourse/discourse/blob/master/app/models/topic.rb) begitu juga dengan model [user.rb](https://github.com/discourse/discourse/blob/master/app/models/user.rb) yang memiliki 1490 baris (*diakses 22 April 2019*).

Saya rasa untuk satu kelas yang memilki banyak kode/baris seperti ini sangat sulit dipeliharanya. Bisa dilihat dari banyak kode ini, kelas ini sudah memiliki banyak tanggung jawab yang diberikan kepadanya. Untuk mengatasi masalah ini komunitas Rails sudah mengenalkan pola *Service Object*.

*Service Object* mungkin saya bisa bilang adalah sebuah layer yang berdiri diantara *controller* dan model. Layer ini bertujuan untuk mengurangi tanggung jawab model sehingga hasil akhir yang diharapkan kode di dalam model bisa lebih sedikit.

Pola ini berhasil di pasar komunitas Rails, banyak yang memamfaatkannya karena ternyata bisa mengurangi kode model yang cukup signifikan. Namun, ternyata realitas tidak seindah itu dirasakan.

Mantra mulai beralih menjadi :

> Skinny Controller, Fat Model, Fat Service

Dari awal Rails memang tidak memiliki peraturan yang ketat pada layer-layer ini, begitu juga dengan *service layer*. Tidak jelas kode apa yang harus ditulis di *controller*, di model dan juga di *service*. Seperti yang dikatakan sebelumnya, *Service layer* hanyalah sebagai tempat pembuangan diantara *controller* dan model agar kedua objek yang lain itu lebih bersih saja.

Hingga akhirnya ada beberapa skenario seperti kode-kode yang di dalam callback `before_action`, `after_action` dan teman-temannya muncul. Pada kode awal, kode-kode yang didalam blok ini di ekstrak keluar ke *service object* agar model terhindar dari *aplikasi logic*. Namun kode-kode ini sangat terikat dengan model, sedangkan *service objek* tidak. Service objek hanyalah berdiri diantara 1 controller dan 1 model.

Hingga akhirnya kita kembali menulis `before_action` dan `after_action` di dalam model karena memang tidak relevan di *service object*. Maka, model kita kembali memiliki *aplikasi logic* yang jika aplikasi terus berkembang, mau tidak mau model kita akan terus bertambah gemuk.

Pada tulisan ini saya ingin mengenalkan *Mutator Layer*. Sebuah layer baru yang mencoba mengatasi masalah yang baru saja dibahas. Pada pengenalan ini saya akan mengajak pembaca untuk mengerjakan studi kasus terkait hal diatas agar kita bisa lebih paham, lalu mencoba memberikan solusinya.

**Studi kasus**

PT MRT Jakarta (sebuah perusahaan perkeretaan) mengontrak kita untuk menambahkan 3 fitur di dalam sistemnya.

1. **Penambahan antrian kereta**

   Di halaman tambahan antrian, admin memilih kereta yang akan ditambahkan ke antrian, setelah ditambahkan kereta otomatis masuk ke antrian (paling terakhir) lalu sistem mengirim log untuk penambahan keretanya (Lognya: Kereta TIPE-X masuk antrian urutan ke 3).
2. **Penghapusan antrian kereta**

   Di halaman list antrian, admin dapat menghapus kereta tertentu dan ketika kereta dihapus di antrian, maka kereta-kereta yang antriannya dibawah kereta yang bersangkutan akan naik ke atas. Setelah itu sistem memberikan log juga ke sistem. (Lognya: Kereta dengan TIPE-X terhapus dari antrian ke 3).
3. **Penghapusan kereta**

   Di halaman daftar kereta, admin dapat memilih dan menghapus kereta yang dipilih. Setelah dipilih sistem menghapus kereta dan juga antrian dari kereta yang bersangkutan. Lalu sistem juga menulis log ke sistem. (Lognya: Kereta TIPE-X terhapus dari daftar kereta).

Analogi soalnya kira-kira bisa kita gambarkan seperti ini:

![Analogi Soal](/assets/anologi-soal.png)

Awalnya, mari kita rancang sistem basis datanya terdahulu.

kira-kira akan seperti ini:

![Struktur data](/assets/mutator-example-erd.png)

Lalu kita menulis kode untuk fitur pertama, yaitu kode untuk penambahan antrian ke dalam sistem.

Kode untuk controllernya

```rb
# / app/controllers/trains/queue_controller.rb
class Trains::QueueController < ApplicationController
  def create
    TrainQueueController::Create.new(train).perform
  end
end

# / app/services/train_queue_service/create.rb
module TrainQueueService
  class Create
    def initialize(train)
      @train = train
    end

    def perform
      # get last number in trains queue.
      last_number = Train::Queue.last_number
      # set current train number with last number plus one.
      current_number = last_number + 1
      # save train in train queue
      Train.queue.create(number: current_number, train: @train)
      # last, we create log for this feature.
      log_message = "Kereta #{@train.name} masuk antrian urutan ke-#{@train.number}"
      Log.create(description: log_message)
    end
  end
end
```

Pada kode diatas secara singkat kita hanya memanggil objek *service*  di *controller* dan berikan dia bertanggung jawab atas penambahan fitur antrian kereta.

Maka fitur pertama kita sudah selesai, sekarang kita lanjut ke fitur selanjutnya, fitur kedua yaitu fitur penghapusan kereta.

```rb
#/ app/controllers/trains/queue_controller.rb
class Trains::QueueController < ApplicationController
  # ...
  def destroy
    TrainQueueService::Destroy.new(train).perform
  end
end

# / app/services/train_queue_service/destroy.rb
module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    # Logic:
    # 1. Kita menaikan antrian dari semua kereta
    # yang antriannya dibawah kereta yang ingin dihapus
    # 2. Lalu, baru kita menghapus kereta yang bersangkutan
    # 3. Terakhir, kita membuatkan lognya.
    def perform
      queue = Train::Queue.find_by(train: @train)
      queues = Train::Queue.where('number < ?', queue.number)
      queues.each(&:decrease_number!)
      _queue = queue
      queue.destroy
      log_message = "Kereta dengan tipe #{@train.name} terhapus dari antrian ke #{_queue.number}"
      Log.create(description: log_message)
    end
  end
end
```

Kode diatas sudah lumayan panjang. Intinya seperti yang di komentar yaitu menghapus kereta yang dipilih dari antrian lalu mengurangi number dari semua kereta yang antriannya sesudah dari kereta yang dihapus. Lalu yang terakhir yaitu membuatkan lognya.

Fitur pertama dan kedua telah selesai, sekarang kita lanjut ke fitur yang ketiga (terakhir). Kita membuat sebuah fitur penghapusan kereta. Dimana ketika kereta dihapus, sistem akan menyimpan log *"Kereta TIPE-X terhapus dari daftar kereta"*. Kereta yang dihapus juga, akan menghapus antrian yang mungkin sebelumnya sudah terdafatar.

Lalu kita mungkin berfikir kalo dikode ini kita bisa memanggil service penghapusan antrian yang sebelumnya kita sudah buat:

```rb
#/ app/controllers/trains/queue_controller.rb
class TrainsController < ApplicationController
  # ...
  def destroy
    TrainService::Destroy.new(train).perform
  end
end

#/ app/services/trains_service/destroy.rb
class TrainsService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
      # Sebelum menghapus keretanya, kita menghapus antriannya terlebih dahulu
      TrainQueueService::Destroy.new(@train)
      _train = @train
      @train.destroy
      Log.create(description: "Kereta #{_train.name} terhapus dari daftar kereta"
    end
  end
end
```

Kode diatas singkatnya menghapus antrian kereta, lalu baru menghapusnya. Namun sayangnya kode diatas tidak mengikuti permintaan user. Karena di service `TrainsQueueService` membuatkan log untuk penghapusan antrian diakhir prosesnya, sedangkan user tidak menginginkan hal tersebut.

Mau tidak mau, kita harus rombak kode service yang sebelumnya sudah dibuat, dan memindahkan penghapusan antrian pindah ke model.

```rb
# / app/models/train/queue.rb
class Train::Queue < ApplicationModel
  before_destroy do
    trains = where('number < ?', number)
    trains.each(&:decrease_number!)
  end

  def decrease_number!; end
end

# / app/services/train_queue_service/destroy.rb
module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
      queue = Train::Queue.find_by(train: @train)
      _queue = queue
      queue.destroy
      log_message = "Kereta dengan tipe #{@train.name} terhapus dari antrian ke #{_queue.number}"
      Log.create(description: log_message)
    end
  end
end
```

Kode diatas kita memindahkan *logic* dari *service* ke model, karena kode-kode ini akan selalu dipanggil ketika kita menginginkan penghapusan model. Maka dengan kode ini fitur menjadi sesuai yang diinginkan klien kita.

Namun kita jadi mengenalkan *application logic* pada model kita. Dimana ketika dikemudian hari aplikasi terus berkembang, maka model kita akan menjadi makin gemuk.

Sekarang waktunya saya mengenalkan anda pola mutator. Dimana kelas ini sebagai kelas yang menggantikan *callback* yang ada di dalam model seperti `before_action`, `after_action`, `before_update`, `before_destroy` dan teman-temannya.

Mari kita implementasikan dengan kodenya

```rb
#/ app/models/train/queue.rb
class Train::Queue < ApplicationModel
  def decrease_number; end
end

#/ app/mutators/queue_mutator.rb
class QueueMutator
  def self.destroy(queue)
    queues = Train::Queue.where('number < ?', queue.number)
    queues.each(&:decrease_number!)
    queue.destroy
  end
end

#/ app/services/train_queue_service/destroy.rb
module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
      queue = Train::Queue.find_by(train: @train)
      QueueMutator.destroy(queue)
      log_message = "Kereta dengan tipe #{@train.name} terhapus dari antrian ke #{_queue.number}"
      Log.create(description: log_message)
    end
  end
end

#/ app/services/trains_service/destroy.rb
class TrainsService
  class Destroy
    def initialize(train)
      @train = train
    end

    def perform
      # Sebelum menghapus keretanya, kita menghapus antriannya terlebih dahulu
      queue = Train::Queue.find_by(train: @train)
      QueueMutator.destroy(queue)
      _train = @train
      @train.destroy
      Log.create(description: "Kereta #{_train.name} terhapus dari daftar kereta"
    end
  end
end
```

Kita membuat mutator, dimana kodenya diambil dari `before_destroy` yang sebelumnya ada di model `Train::Queue`. Lalu mutator itu kita penggil di *service* `TrainQueueService` dan `TrainsService` menggantikan `queue.destroy` menjadi `QueueMutator.destroy(queue)`.

Dengan mengimplementasikan mutator, model kita menjadi bersih terhindar dari *aplication logic*. Memang model menurut saya harusnya hanya mempresentasikan *record* dari satu tabel database saja. Penjelasan lanjut dengan domain model mungkin akan dibahas di tulisan yang lain.

> Always implement things when you actually need them, never when you just foresee that you need them. (YAGNI -- You aren't gonna need it yet).

Sebuah prinsip yang menganjurkan bahwa programmer seharusnya tidak menambah fungsional jika memang tidak diperlukan. Artinya mutator digunakan hanyalah ketika memang perintah lebih dari satu yang terlihat adanya `before_action` pada model.

Jika `before_action` tidak ada di model, maka jangan gunakan mutator karena anda tidak memerlukannya, cukup gunakan *magic_rails*-nya saja seperti `user.create`, `user.destroy`, dll dan bukan `UserMutator.create(user)`,dll.

| Action  | Trivial      | Complex                   |
| ------- | ------------ | ------------------------- |
| Create  | User.create  | UserMutator.create(user)  |
| Destroy | User.destroy | UserMutator.destroy(user) |
| Save    | User.save    | UserMutator.save(user)    |
| Update  | User.update  | UserMutator.update(user)  |

Atau secara alur bisa digambarkan seperti gambar dibawah.

![Flow Mutator](/assets/flow-mutator.png)

**Kesimpulan**

Mutator adalah sebuah solusi dari bagian gelap (tidak terlihat) dari service object yang semakin besar. Semakin besar sebuah kelas, maka semakin banyak tanggung jawab dari kelas tersebut. Ada sebuah prinsip juga yang mengatakan setiap kelas harusnya hanya punya satu tanggung jawab saja (*Single Responsibility Principal/SPR*).

Ada prinsip atau rules lain yang menyebutkan bahwa setiap kelas maksimal harusnya hanya boleh memiliki 100 baris saja, jika anda mengikuti peraturan default pada Rubocop. Semakin kecil kelas juga kelas lebih mudah digunakan kembali (*reuseable*) sehingga kode juga lebih mudah untuk dipelihara.

Semoga tulisan ini dapat bermamfaat bagi pembaca sekalian.
