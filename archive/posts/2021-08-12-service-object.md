---
layout: post
title:  "Service Object"
date:   2021-08-12 20:13:00 +0700
categories: service-object, rails
comments: true
published: true
---

Hello!

Sebenernya ditulisan sebelumnya saya udah mau *commit* buat mau mulai nulis pake bahasa inggris di blog ini, tapi baru sadar, kalo blog ini udah saya submit di pulo.dev, yang dimana ekpektasi konten-konten disana itu berbahasa indonesia.

Ditambah gk ada alasan tertentu tulisan-tulisan saya harus berbahasa inggris karna kebanyakan terinspirasi dari tulisan-tulisan luar (inggris) 🙂, jadi saya balik lagi buat nulis pakai bahasa indo saja ya.

Oke, mari kita mulai saja.

Tulisan ini saya buat scopenya saja, agar batasannya bisa lebih jelas dan bisa membantu saya agar tidak lari kemana-mana 😂

- Apa itu Service Object (SO), dan masalah apa yang ingin dicoba untuk diselesaikan?
- Design yang seperti apa yang bagus untuk di implement?
- Apakah ada solusi alternative?

## Apa itu Service Object, dan masalah apa yang ingin dicoba untuk diselesaikan?

Pertama kali saya menulis kode Service Object (SO) mungkin di akhir tahun 2018, ketika saya baru pertama kali menulis kode dengan dibayar oleh uang, yups it's my first job.

Waktu itu saya menganggap Service Object adalah layer baru di dalam Rails, terinspirasi dari [buku ini](https://painlessrails.com/), dimana dia berada diantara Model dan Controller. 

Kode-kode SO adalah *plain ruby object* yang digunakan untuk menghandle logic bisnis pada aplikasi, sedangkan Model digunakan oleh service untuk membuat versi SQL dari hasil logic yang dihasilkan, dan Controller untuk mem-*forward* hasil logic (SO) ke user.

Kita bisa contohkan penggunaannya dengan seperti ini, misalkan kita berada di perusahaan online shop, dan kita diminta untuk membuat fitur order invoice.

```ruby
# app/services/create_order_invoice.rb
class CreateOrderInvoice
  def initialize(params); end

  def perform
    tax = calculate_tax
    total_invoice = calculate_total_invoice(tax)
    order_invoice = OrderInvoice.create(create_order_invoice)
    send_email_order_invoice(order_invoice)
  end
end

# app/controllers/order_invoice_controller.rb
class OrderInvoiceController < ApplicationController
  def create
    CreateOrderInvoice.new(params).perform
    redirect_to invoice_path, notice: 'Your order has been successfully added'
  end
end

# app/models/order_invoice.rb
class OrderInvoice < ApplicationRecord; end
```

Daripada kita membuat kode perhitungan pajak, total amount dari invoice, membuat record order invoice, dan mengirim email order invoice pada controller atau model, lebih baik kita membuat object atau kelas khusus untuk menghandle hal tersebut yang membuat controller dan model kita tetep kurus. 

Benefit lain, kode jadi lebih mudah dibaca dan dipelihara, ketika model dan controller mulai berkembang, kode SO jadi lebih mudah diubah, karna perhintungan kalkulasinya hanya bisa diakses oleh SO, tidak bisa diakses di Model dan Controller sehingga kita tidak perlu khawatir dengan backward compatibility dan breaking changes, asal public methodnya `#perfom` tetap perform sesuai ekspektasi.

## Design yang seperti apa yang bagus untuk di implement?

Ok, saya harap anda sudah paham benefit apa yang dapat dihasilkan dengan mengimplement SO. Sekarang mari lanjut untuk membahas bagaimana cara mendesain interfacenya, karna menurut pengalaman saya belum ada standard yang jelas tentang interfacenya.

Khususnya pada memberikan nama public methodnya. Pertama kali saya menulis kode SO yaitu dengan memberi nama `#perform` mengukuti codebase yang sudah ada pada saat itu. 

Mungkin make *sense* memberi nama `#perform` yang mungkin menurut saya mereka mengikuti standard yang diberikan Sidekiq, karna secara implementasi SO mirip seperti worker, karena pada sidekiq, sebuah kelas worker hanya boleh memiliki satu tujuan saja, kita tidak bisa dimungkinkan untuk memiliki sebuah kelas worker yang bisa memiliki dua tanggung jawab. 

Tapi secara implementasi SO berbeda dengan worker, SO (*in most cases)* juga tidak akan jalan di background job, mereka memberikan hasil yang hasilnya akan diperlukan oleh client pemanggilnya, berbeda dengan worker dimana pemanggilnya tidak memerlukan hasil atau return dari worker yang ia panggil.

Interface lain yang salah lihat adalah `#execute`, *make sense* juga, mereka mengikuti *naming* dari [Command pattern](https://refactoring.guru/design-patterns/command), yang sudah populer, dimana yang mungkin saya yakini service object terinspirasi dari design pattern tersebut. 

*But, let me tell you a secret, most of the time SO not working with commands things.* 

Berbeda dengan command pattern `CopyCommand`, `CutCommand` dimana antara satu object dan object lainnya sangat dimungkinkan dipanggil oleh satu client yang sama, pada SO biasanya objectnya langsung dipanggil oleh client, dalam arti lain, sangat jarang ada SO yang saling berkaitan sehingga dipanggil oleh client yang sama.

Pada SO kita bisa saja memiliki kelas dengan nama `CreateOrderInvoice` dan `UpdateUserRole` dimana keduanya sama sekali berbeda. 

Interface lainnya adalah `#call`. Ruby juga implement ini di core mereka yang memungkinkan term *Object as Function.* Salah satu term yang sangat cocok bagi service object menurut saya dibandingkan Command pattern.

Seperti definisi yang sebelumnya kita sudah bahas, bahwa SO adalah tempat dimana *business logic* pada aplikasi berada, kita bisa menamainya dengan nama tiket Jira yang di assign ke kita seperti `GeneratePayrollReport` , `ChargeInvoice`, `SendEmailToCustomer`, dll. 

Dan secara implementasi object-object tersebut sangat mirip dengan function, kita tidak memiliki *property,* ataupun *behavior* layaknya pada object pada umumnya, karena SO hanya boleh memiliki satu *instance method* saja yaitu `#call`.

*Object as Function* di Ruby seperti ini:

```ruby
class Hello
  def call(name)
    puts "Hello, #{name}"
  end
end

Hello.new.('kotori') #> "Hello, kotori"
```

 Sekarang kelas `Hello` diakses layaknya function di Ruby, seperti yang kita inginkan.

### API Design

Setelah membahas background tentang belum adanya standard yang jelas tentang API design, khususnya pada penamaan public API. Sekarang waktunya untuk membuat standard versi kita.

Seperti yang sudah dibahas sebelumnya, SO hanya boleh memiliki satu public method saja, karena kita akan mengadopsi philosophy Object as Function, untuk kontraknya seperti ini:

```ruby
# app/services/charge_payment.rb
class ChargePayment < ApplicationService
  Error = Class.new(StandardError)

  def initialize(invoice); end
  # Public: Handle charge payment to the Invoice
  # Returns Invoice
  def call
    # charge invoice logic goes in here
  end
end

# app/services/application_service.rb
class ApplicationService
  def call(...)
    new(...).call
  end
end

# how the service object was called
ChargePayment.call(invoice)
```

Setiap SO inherit ke `ApplicationService` dimana kelas tersebut berfungsi untuk mendelegasikan `.call` menjadi `#call` . Jadi kita bisa memanggilnya dengan lebih mudah

```ruby
# instead of 
ChargePayment.new.call(invoice)
# or 
ChargePayment.new.(invoice)

# we could call like this
ChargePayment.call(invoice)
```

Setiap SO boleh mengembalikan object apapun tanpa batasan, bahkan objectnya sendiri walaupun saya belum pernah mendapat case yang seperti ini. Namun satu hal yang tidak boleh adalah memiliki method lain selain `#call`, maupun property baik itu dibuat oleh generator seperti `attr_reader` maupun `attr_accessor`.

Jika anda ingin mengembalikan object atau value yang lebih dari satu, saya prefer untuk menggunakan Hash, atau OpenStruct, misalnya seperti ini:

```ruby
class GeneratePayrollReport
  def call
    OpenStruct.new(account_number: account_number, total_transfer: total_transfer)
  end
end

# or 
class GeneratePayrollReport
  def call
    { account_number; account_number, total_transfer: total_transfer }
  end
end
```

Ketika aplikasi semakin besar (fiturnya makin banyak), maka kelas service pun jadi makin banyak juga, karna setiap Jira issue yang dibuat adalah kandidat yang bagus untuk menjadi SO.

Alangkah lebih bagus kelas-kelas ini kita organisir lagi berdasarkan scope atau domainnya agar lebih rapih, kita bisa organisir menjadi seperti ini:

```ruby
PayrollServices::GeneratePdfReport
PayrollServices::TransferTheMoney
InvoiceServices::MakeItExpired
InoviceServices::GeneratePdfReport
```

Dibandingkan keempat kelas itu flat (tanpa module) lebih baik kita organisir agar lebih rapih, benefit lain, penamaan kelas juga jadi tidak bentrok untuk kelas-kelas yang memiliki tujuan yang mirip, seperti `GeneratePdfReport`, Karena kita menempati mereka di module yang berbeda.

Untuk *naming convention*-nya anda bisa buat DomainNameServices, untuk DomainName diusahakan singular jadi dibuat seperti ini: `PayrollServices` bukan `PayrollsService` atau `PayrollsServices`. 

## **Error handling**

Kita tidak bisa memastikan semua SO akan berjalan mulus tanpa ada hambatan atau rintangan, contohnya pada `PayrollServices::TransferTheMoney` mungkin saja bisa gagal perform karena ada network error pada bank API, atau nomor rekening karwayannya salah, begitu juga dengan `InvoiceServices::MakeItExpired` bisa saja ada gagal ketika melakukan SQL query update ke database, dan sebagainya.

Pada handle error di SO saya merekomendasikan untuk menggunakan filosofi *fail-closed design by default*. Pada filosofi ini kita akan melakukan raise `Exception` kelas ketika kita mendapatkan bahwa kelas tidak perform dengan benar dan kita memberhentikan processnya dengan paksa. 

Contohnya seperti ini:

```ruby
class ChargePayment
  Error = Class.new(StandardError)

  def call
    raise Error, 'Failed to charge please try again',  if something_wrong?
  end
end

class PaymentsController < ApplicationController
  def create
    ChargePayment.call 
    redirect_to report_path, notice: "Charge payment was successfully"
  rescue ChargePayment::Error => e
    redirect_to report_path, notice: e.message
  end
end
```

Jadi ketika kita gagal melakukan, melakukan charge stack process akan berhenti di SO dan customer akan ditampilkan pesan error "Failed to charge please try again". 

Benefit menggunakan prinsip ini kita tidak akan memberikan miss informasi ke user, contohnya jika kita lupa melakukan rescue terhadap errornya:

```ruby
class PaymentsController < ApplicationController
  def create
    ChargePayment.call 
    redirect_to report_path, notice: "Charge payment was successfully"
  end
end
```

Aplikasi kita tidak akan akan menampilkan 'Charge payment was successfully' namun internal server error, dan error monitoring akan memberitahukan bahwa ada `Exception` yang belum di handle pada aplikasi.

Dibandingkan dengan menggunakan *fail-open design* yang menggunakan flag pada handle errornya:

```ruby
class ChargePayment
  Error = Class.new(StandardError)

  def call
    return false if something_wrong?
  end
end

class PaymentsController < ApplicationController
  def create
    charge_payment = ChargePayment.call
    if charge_payment.false?
      redirect_to report_path, notice: 'Failed to charge please try again'
    else
      redirect_to report_path, notice: 'Charge payment was successfully'
    end
  end
end
```

Kode diatas menggunakan fail-open design yang memungkinkan kita dapat memberikan informasi yang salah kepada user, contohnya jika kita lupa mengecek return atau flag yang diberikan oleh SO:

```ruby
class PaymentsController < ApplicationController
  def create
    ChargePayment.call
    redirect_to report_path, notice: 'Failed to charge please try again' 
  end
end
```

Hal ini bisa saja terjadi, mungkin anda mengerjakan task ini sedang pada deadline, atau ada programmer baru yang belum familiar dengan domain aplikasinya.

Denga kode yang seperti ini user akan mendapat informasi yang salah, dan hal tersebut tidak ada error atau tidak terditeksi, sehingga ketika user menggunakan aplikasi ini untuk menjual produknya, akan ada kemungkinan banyak produknya yang sudah terdistribusi ke customer atau clientnya tanpa adanya balance masuk ke akun user, *this is so sad to the user*. 

Maka daripada itu lebih baik user melihat pesan aplikasi error daripada informasi yang salah.

## How to do validation things

SO bisa saja menggunakan input dari JSON request body, atau dari form input yang keduanya bisa diinput oleh user. Dan kita tidak boleh mempercaya input yang diinput oleh user begitu saja, karna user bisa saja menginput sesuatu yang salah secara tidak sengaja maupun sengaja. 

Maka SO perlu adanya logic untuk memvalidasi bahwa input yang dinput sudah benar atau belum. Jika belum kita bisa memberikan pesan error untuk user membenarkannya, namun jika benar kita bisa memproses input itu lebih lanjut.

Mungkin logicnya bisa seperti ini:

```ruby
def call?
  unless valid?(params)
    raise Error, "The input was invalid!"
  end
  # the actual process goes here.
end

private

def valid?(params)
```

Hal ini bagus, dan cukup *common*, beberapa komunitas yang saya respect seperti dry.rb juga menggunakan implementasi yang [serupa](https://dry-rb.org/gems/dry-transaction/0.13/basic-usage/). 

Tapi issue yang terjadi pada hal ini adalah validation `#valid?` menjadi *private method* dan tidak *reuseable,* ketika ada params yang serupa ingin dipakai ditempat lain, anda perlu melakukan ekstraksi logic validasinya terlebih dahulu ke kelas atau object baru, atau bahkan anda melakukan duplikasi kode implementasinya.

Solusi atas masalah ini adalah *"Parse, don't validate",* tulisan yang sangat menarik ditulis oleh [Alexis King](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

Dengan solusi ini kita bisa mengubah kode kita menjadi seperti ini:

```ruby
# app/services/charge_payment.rb
class ChargePayment
  Error = Class.new(StandardError)

  def initialize(charge_params)
    charge_params = charge_params
  end

  def call
    # do the actual process in here
  end
end

# app/controllers/charge_controller.rb
class ChargeController < ApplicationService
  def create
    ChargePayment.call(charge_params)
    redirect_to report_path, notice: 'Charge payment was successfully'
  rescue ChargePayment::Error, ChargeParams::ParserError => e
    redirect_to report_path, notice: e.message
  end
  
  private
  
  def charge_params
    ChargeParams.parse(form_params)
  end
end

# app/models/charge_params.rb
class ChargeParams
  ParserError = Class.new(StandardError)

  def initialize(params); end

  # Public: Parse and validate the params
  # Returns ChargeParams or ParserError
  def self.parse(); end
  def to_hash; end
end
```

Kita membuat sebuah object atau *intelegent data structure* yang bernama `ChargeParams`  setidaknya pada object ini memiliki dua tanggung jawab:

1) Melakukan validasi, jika diinput misalnya user memasukan email, dan email tersebut tidak sesuai format pake object ini akan melakukan raise `ChargeParams::ParserError` dengan pesan "email is invalid format"

2) Melakukan transformasi *data structure*, dari *unstructured* menjadi *structured.* Yaitu yang menjadi tujuan atau definisi dari sebuah `#parse` . Karna terkadang input yang diinput sama user yang bisa melalui API dan form di web tidak sama dengan input yang diperlukan oleh SO. Contohnya kita ingin membuat fitur input buku baru ke koleksi spesific user, dari API input yang diberikan client structurenya seperti ini:

```ruby
{ user_name: "pquest", book_name: "Hello World", status: "read" }
```

Mungkin di service kita ingin structurenya seperti ini, karna yang kita perlu adalah `id` user dan id book. 

```ruby
{ user_id: 125, book_id: 125, status: "read" }
```

Jika kita implementasi dengan `#valid?` maka kita perlu membuatnya seperti ini:

```ruby
class AddUserBookCollection
  def initialize(params); end

  def call
    raise Error unless valid?

    user_collection_params = build_user_collection_params
    UserCollection.create!(user_collection_params)
  end
end

AddUserBookCollection.call(params)
```

Namun jika menggunakan `#parse` kita membuatnya seperti ini:

```ruby
class AddUserBookCollection
  def initialize(user_collection_params); end
  def call
    UserCollection.create!(user_collection_params.to_hash)
  end
end

class UserCollectionParams
  ## 
end

user_collection_params = UserColectionParams.parse(params)
AddUserBookCollection.call(user_collection_params)
```

Membuat kode SO menjadi lebih ringan, kita hanya care dengan data structure yang sudah kita define sebelumnya. Membuat SO menjadi mudah untuk dipakai ditempat yang lain, ketika ada structure input baru, kita hanya perlu update object parser kita untuk support hal tersebut, kode SO masih tetap sama. 

Validation juga menjadi sebuah public yang dapat mudah untuk digunakan ditempat lain, plus parser dan validation juga menjadi kesatuan dimana tidak ada kata lupa melakukan validasi saat melakukan parser dimana hal ini mungkin terjadi jika kita menggunakan `valid?` .

Salah satu kalimat yang menarik yang ditulis terkait hal ini oleh [Alexis King](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) adalah:

> Let your datatypes inform your code, don’t let your code control your datatypes.

Hal ini juga lebih baik lagi jika di implement pada *type programming language,* karna pada Ruby hal ini masih memungkinkan client tidak melakukan parser terlebih dahulu ketika menggunakan SO-nya. 

Kita bisa solve masalah ini dengan menggunakan hal ini:

```ruby
 def call
   raise ArgumentError unless user_collection_params.is_a?(UserCollectionParams)

   UserCollection.create!(user_collection_params)
 end
```

But this is too ashamed, I'm kinda against with this approach.

But, hey do you know `ActiveRecord::Validations`?

Ya, saya tau hal tersebut exist, dan saya masih menggunakannya saat ini, jika anda possible untuk menggunakan hal tersebut silahkan gunakan itu, ParserObject digunakan hanya ketika anda membuat pure validation pada SO anda, bukan pada ActiveRecordValidations.

Jadi pada contoh diatas jika ada kebutuhan baru, yaitu untuk menambah validasi user dimana user tidak boleh menambahkan koleksi lebih dari 3 buku. Anda bisa menulisnya seperti ini:

```ruby
class AddUserBookCollection
  Error = Class.new(StandardError)

  def initialize(user_collection_params); end

  def call
    UserCollection.create!(user_collection_params.to_hash)
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  end
end

class UserCollection < ApplicationRecord
  validate :user_collections_maximum_three_books
end
```

Validasi Parser hanya sebatas *the presence of input params,* sedangkan tambahan validasi bisa ditaro di dalam modelnya.

Bahkan tidak perlu parser lagi jika memang input juga sudah sesuai structure atau validasi bisa ditaro di dalam model. 

*But i hope you got the point, the parser just needed when you write pure validation in SO, if you don't write the validation method in SO, you probably don't need the parser object, it means just use the Active Record Validations.* 

Mungkin contoh yang lebih make sense untuk penggunaan Parser adalah seperti input untuk bulk import, dimana model validation tidak dapat digunakan untuk case yang seperti ini, dan structure yang di input sama user berbeda dengan structure yang diekspektasikan oleh SO.

## Apakah ada solusi alternative?

Mungkin hal yang menarik lainnya terkait pattern ini adalah banyak programmer-programmer handal yang tidak suka dengan *approach* ini. Seperti [Avdi Grimm](https://avdi.codes/service-objects/), [Xavier Noria](https://twitter.com/fxn/status/1416289485264932869), even [DHH](https://twitter.com/dhh/status/1245431067563012096) was in this position 😂

Orang-orang tersebut memiliki alasan yang sama, yaitu tidak suka dengan API yang dihasilkan oleh service object. Daripada membuat API seperti ini: `InvoiceServices::Charge.call(params)` lebih baik `invoice.charge(params)` begitu juga daripada membuat `PayrollServices::GenerateReport.call` lebih baik `payroll.report.generate_pdf` dalam hal ini `invoice` dan `payroll` adalah instance yang dibuat oleh Model. 

Mereka percaya bahwa *fat models* sebuah *term* yang kita anggap sebuah masalah pada codebase, bagi mereka itu bukanlah sebuah masalah. Khususnya pada bahasa Ruby, dimana kita bisa dilihat di standard library yang ditulis oleh *Ruby core team*, kelas-kelasnya memiliki banyak sekali methods, *even* kelas-kelas primitive seperti String, Array, dan Hash juga memiliki banyak sekali methods.

Begitu juga dengan Rails, ActiveRecord::Base, ActionController::Base dan kelas-kelas lain memiliki banyak sekali methods, dan kita tidak anggap itu sebuah kekurangan, malah bisa dibilang itu sebuah kelebihan karena dengan API tersebut kita bisa menulis kode dengan lebih sedikit dan lebih menyenangkan.

Berbeda mungkin dengan Java dimana untuk membuat sebuah program console anda harus bekerja dengan beberapa kelas berbeda contohnya seperti Scanner, System.out, System.in atau Buffer, dll, yang dimana pada Ruby mungkin anda hanya perlu satu kelas dan semua method sudah tersedia disana. 

Kode yang dihasilkanpun akan berbeda yang dimana kode di Ruby menjadi lebih sedikit dibandingkan dengan kode yang ditulis menggunakan Java in *most cases*. Tapi bukan berarti Ruby lebih baik dari Java atau sebaliknya, namun kembali lagi ke filosofi atau tujuan dari bahasa pemrograman masing-masing, di Java mungkin mereka lebih peduli ke performance yang dimana mereka ingin setiap object memiliki method yang sedikit agar lebih ringan ketika di load, sedangkan Ruby lebih peduli ke programmer yang mereka ingin programmer lebih mudah menulis kodenya.  

Namun secara pribadi saya tidak berangapan bahwa SO sepenuhkan salah atau bahkan Anti Pattern, karena untuk menulis kode atau mendesain API pada Model memerlukan pemahaman dengan Design Object baik secara teknikal maupun secara teori, jadi sangat-sangat memungkinkan untuk programmer dengan menulis API yang tidak ciamik.

Maka, SO come to the rescue yang saya yakini sangat sulit untuk menulis kode yang salah karena ada standard dan API yang sangat sedikit karna hanya boleh memiliki satu public method saja, sehingga kita bisa make sure bahwa kode lebih mudah dipelihara karena object juga relative kecil-kecil.

Walaupun memiliki kekurangan yaitu pada design API, sehingga kurang enak untuk dipakai, dan juga membuat programmer kurang creative, karna hal yang ia bisa design hanyalah nama kelas SO-nya saja, tidak ada yang lain.

Namun mungkin terkait hal ini (*alternative solution*) yang membuat SO menjadi Model bisa saya bikin postingan baru agar bisa diobrolin lebih detail.

---

Terima kasih, saya rasa itu sudah cukup untuk membahas tentang mendesain Service Object. Desain ini bukanlah sebuah *Best Practice,* namun hanyalah preferensi saja, masih banyak kekurangan dan hal-hal yang mungkin belum dicover.

So, happy hacking!