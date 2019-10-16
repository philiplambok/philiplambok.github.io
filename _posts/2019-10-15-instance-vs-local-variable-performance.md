---
layout: post
title: "Instance vs Local Variable Performance"
date: 2019-10-15 12:00:00 +0700
categories: ruby-benchmarking
comments: true
published: true
---

Karna tulisan ini ditulis di *weekday*, jadi tulisan ini mungkin akan sangat singkat :)

Jika anda sudah membaca tulisan saya sebelumnya yang berjudul [Tips saat menulis private method](https://philiplambok.github.io/clean-code/2019/07/06/tips-menulis-private-methods.html) mungkin anda sudah tahu kalo saya sangat-sangat menyarankan menggunakan local variable dibanding instance variable pada program anda tulis.

Disana saya menyarankan anda membuat fitur dengan membaginya menjadi *function-function* kecil dan bukan prosedur-prosedur. Prosedur disini maksud saya *function* yang tidak membalikan data, sedangkan "function" adalah *function* yang membalikan data.

Pada buku [Code Complete](https://www.amazon.com/Code-Complete-Practical-Handbook-Construction/dp/0735619670) juga menyarankan ini:

> Keep Variables “Live” for as Short a Time as Possible

Jika anda menyelesaikan masalah dengan menggunakan instance variable otomatis variable tersebut akan terus hidup sampai *main function* anda selesai dipanggil.

Tapi untuk tulisan kali ini saya ingin ngobrol tentang performancenya bukan dari sisi desainnya. Mungkin dari sisi design bisa saya buat lagi di tulisan yang lain :)

Terinspirasi dari tulisan yang udah lumayan lama dipublish oleh Aaron yang berjudul [Instance Variable Performance](https://tenderlovemaking.com/2019/06/26/instance-variable-performance.html) saya jadi melakukan *benchmarking* kecil-kecilan juga tentang perbedaan penggunakan instance vs local variable.

Kira-kira *benchmarking*-nya sebagai berikut:

```sh
$> cat bench.rb
require 'benchmark'

class Instance
  def initialize
    @satu = 'satu'
    @dua = 'dua'
    @tiga = 'tiga'
    @empat = 'empat'
    @lima = 'lima'
  end
end

class Local
  def initialize
    satu = 'satu'
    dua = 'dua'
    tiga = 'tiga'
    empat = 'empat'
    lima = 'lima'
  end
end

n = 5_000_000

Benchmark.bm do |x|
  x.report { n.times { Instance.new } }
  x.report { n.times { Local.new } }
end

$> ruby bench.rb
       user     system      total        real
   2.535891   0.000405   2.536296 (  2.536660)
   1.428839   0.000010   1.428849 (  1.429049)
```

Dapat dilihat dari hasil diatas bahwa secara performa kelas yang menggunakan local variable lebih cepat (**1.429049**) dibandingkan kelas yang menggunakan instance variable (**2.536660**).

Saya tidak melarang anda untuk menggunakan instance variable, tapi sebaiknya coba dipikirkan dahulu untuk menggunakan local variable dengan membuat *function* yang mempunyai kembalian.

Karna menggunakan local variable selain membuat design suatu kelas menjadi mudah untuk dipelihara dan juga dapat meningkatkan performa.

```rb
# bad
def call
  crete_user
  create_organization
  create_log_reports
end

# good
def call
  user = create_user(@user_param)
  organization = create_organization(user, @organization_params)
  create_log_reports(user, organization)
end
```

Terima kasih telah membaca tulisan sederhana ini, semoga tulisan dapat bermamfaat bagi pembaca skalian.

*Have a good day~*