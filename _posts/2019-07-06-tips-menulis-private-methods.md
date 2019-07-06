---
layout: post
title: "Tips saat menulis private method"
date: 2019-07-06 11:35:00 +0700
categories: clean-code
comments: true
published: true
---

Sebenarnya saya sudah cukup lama ingin menulis tentang hal ini tapi entah kenapa selalu kena _pending_.

Tapi, karena baru saja kemarin di projek saya, saya menemukan _bug_ dan saya pun kesulitan untuk _debuggingnya_ karena ada kesalahan dalam menulis _private method_ ini
maka akhirnya saya kesampaian juga untuk menulisnya disini.

Sebenernya saya juga bingung untuk memberikan judulnya karena mungkin kita tidak hanya berbicara tentang _private method_, namun juga akan berbicara tentang penggunaan _instance variable_ dan bahkan _public method_.

Tapi karena _private method_ lebih banyak berperan di tulisan ini, maka saya ambil itu sebagai judul, saja.

Sebelum mulai berbicara tentang _private method_ saya ingin berbicara tentang _dependency_ (kebergantungan).

Saya rasa anda pasti sudah pernah dengan bahkan mengetahui apa itu _dependency_. Singkatnya _dependency_ sendiri ada jenis-jenis yang berbeda, antara lain:

- _Dependency_ level paket. Contohnya jika kita menggunakan Rails, Rails akan menggunakan paket _activerecord_. Ketika kita menggunakan _activerecord_, paket tersebut menggunakan paket _activesupport_. Maka, ketika kode di activerecord ada yang berubah maka implementasi dari kode Rails kita juga akan berubah.

  ![Paket dependency](/assets/paket-dependency.png)

- _Dependency_ level kelas. Contohnya pada kelas _controller_ kita sering memanggil kelas _model_ artinya kelas controller kita dependency terhadap model. Maka ketika kita membuat perubahan di model, maka akan berpengaruh pada kelas controller kita.

  ![Class dependent](/assets/class-depen.png)

- _Depedency_ level method. Contohnya ketika kita memanggil sebuah _method_ dari _method_ lain. Contohnya:

  ```rb
  def show
    @user = find_user(params[:id])
  end

  private

  def find_user(id)
    User.find_by(id: id)
  end
  ```

  Pada kode diatas, method `show` _dependent_ terhadap method `find_user(id)`, artinya jika mengubah kode di method `find_user(id)` maka akan berpengaruh pada _method_ `show`.

  ![Function dependent](/assets/user-depend.png)

Kode yang memiliki banyak _dependency_ adalah kode yang buruk. Misalnya anda memiliki satu kelas yang didalamnya memiliki dependent secara bertingkat hingga empat tingkat. Misalnya kelas `A` memanggil kelas `B` dan kelas `B` memanggil kelas `C`. Lalu kelas `C` memanggil kelas `D`.

![Bad class depedency](/assets/class-bad.png)

Maka perubahan yang dilakukan di kelas `D` akan mengakibatkan perubahan di ketiga kelas diatasnya (A/B/C). Jika ada bug di fitur tersebut mungkin anda sudah bisa membayangkan bagaimana sulitnya kita mencari bug tersebut.

Jika kode yang memiliki depedency seperti itu, apakah anda yakin jika mengubah kode di dalam kelas D tidak akan menghancurkan ketiga kelas yang depedent terhadapnya?

Uncle Bob menyebut kode ini dengan [rigidity](https://notherdev.blogspot.com/2013/07/code-smells-rigidity.html). Kode menjadi sulit untuk dimodifikasi karena pergantian kecil saja dapat menghancurkan kelas-kelas yang lain.

Kode yang baik adalah kode yang mudah untuk dimodifikasi, maka semakin kecil depedency dari sebuah kode, kode tersebut semakin baik.

Menghindari penggunaan depedency dalam pembuatan software sangatlah sulit dan sebenernya penggunaan dependency dengan benar dapat membuat kode menjadi bersih. Khususnya untuk level kelas, ada yang namanya konsep _dependency injection_.

Namun, pada tulisan ini kita tidak sedang membahas dependency level kelas, melainkan level _method_.

Seperti yang sudah saya sebutkan sebelumnya, dependency juga bisa terjadi pada level _method_. Kita akan membahas buruknya hal tersebut, dan bagaimana cara saya untuk mengatasinya.

Kode yang buruk:

```rb
# frozen_string_literal: true

module AuthService
  # Class that handling creating token when employee sign in
  class CreateToken
    attr_reader :jwt_token, :login_url, :default_password

    def initialize(auth_params)
      @auth_params = auth_params

      raise 'Invalid auth params' if auth_params_empty?

      @username_or_email = auth_params[:username_or_email]
      @password = auth_params[:password]
    end

    def run
      checking_credentials
      load_default_password
      create_jwt_token
      create_moodle_token
    end

    private

    def auth_params_empty?
      return true if @auth_params[:username_or_email].nil? || @auth_params[:password].nil?
    end

    def create_jwt_token
      @jwt_token = TokenService.new(payload: { employee_id: @employee.id }).encoded
    end

    def checking_credentials
      load_employee

      return true if @employee&.authenticate(@password)

      raise 'Credentials is invalid'
    end

    def load_employee
      load_moodle_user

      @employee = @user.employee
    end

    def load_default_password
      @default_password = @employee.default_password
    end

    def create_moodle_token
      moodle = MoodleService::SignIn.new(
        username: @user.username,
        email: @user.email
      )

      # => Requesting token to moodle website
      moodle.run

      @login_url = moodle.login_url # => grap the moodle token
    end

    def load_moodle_user
      @user = Moodle::User.find_by(
        'username = :username_or_email OR email = :username_or_email',
        username_or_email: @username_or_email
      )
      raise 'Moodle user not found' if @user.nil?
    end
  end
end
```

Kelas diatas sebenarnya memiliki tanggung jawab yang sangatlah simple, yaitu mengembalikan token ke _controller_ jika username dan password benar.

Untuk garis _dependency_-nya :

![Bad Dependency Arrow](/assets/bad-arrow-d.png)

But wait....

Bagaimana jika saya menghapus saya mengubah nilai dari instance variable `@auth_params[:username_or_email]`
dari _method_ `auth_params_empty?` menjadi:

```rb
def auth_params_empty?
  return true if @auth_params[:username_or_email].nil? || @auth_params[:password].nil?
  @auth_params[:username_or_email] = "Changed!"
end
```

Maka method yang menggunakan instance variable tersebut akan juga ikut berubah dalam hal ini adalah method `load_moodle_user`.
Jika method tersebut berubah keempat method yang dependent pada dirinya juga ikut berubah.

Oh...

Pada method `create_moodle_token` dan `create_jwt_token` juga menggunakan instance variable yang dibuat di kedua method `load_employee` `load_moodle_user`, maka artinya `create_moodle_token` dan `create_jwt_token` juga ikut berubah.

Dan dapat dibilang karena perubahan kecil di method tersebut, hampir semua `method` di kelas ini juga ikut berubah.

How a bad code :(

**Maka dalam menulis kode di _private method_ saya memiliki aturan untuk:**

1. _private method_ **tidak boleh menggunakan instance variable**. Gunakan _local variable_ yang dilempar melalui parameter.
2. _private method_ **tidak boleh dependent atau memanggil method yang lain**. private method harus terisolasi atau berdiri sendiri.
3. _public method_ menjadi _main method_ yang **bertanggung jawab terhadap flow algoritma dan perpindahan data antara satu private method dan private method lain**. Jangan pisahkan proses flow-nya seperti yang kita lakukan sebelumnya

Maka, berdasarkan aturan tersebut, saya menulis ulang kelas tersebut menjadi:

```rb
# frozen_string_literal: true

module AuthService
  # Class that handling creating token when employee sign in
  class CreateToken
    attr_reader :jwt_token, :login_url, :default_password

    def initialize(username_or_email, password)
      raise 'Invalid auth params' if username_or_email.blank? && password.blank?

      @username_or_email = username_or_email
      @password = password
    end

    def run
      moodle_user = find_moodle_user(@username_or_email)
      raise 'Moodle user not found' if moodle_user.blank?

      employee = moodle_user.employee
      raise 'Credentials is invalid' unless employee&.authenticate(@password)

      @jwt_token = create_jwt_token(employee)
      @login_url = create_moodle_token(moodle_user)
      @default_password = employee.default_password
    end

    private

    def find_moodle_user(username_or_email)
      Moodle::User.find_by(
        'username = :username_or_email OR email = :username_or_email',
        username_or_email: username_or_email
      )
    end

    def create_jwt_token(employee)
      TokenService.new(payload: { employee_id: employee.id }).encoded
    end

    def create_moodle_token(moodle_user)
      moodle = MoodleService::SignIn.new(
        username: moodle_user.username,
        email: moodle_user.email
      )
      moodle.run
      moodle.login_url
    end
  end
end
```

Apakah anda merasakan perbedaannya?

Untuk garis _dependency_-nya kira-kira menjadi seperti ini:

![Good Arrow Dependency](/assets/good-arrow-d.png)

Pada kode diatas private method kita tidak memanggil private method yang lain, namun memangil kelas yang lain, yang menurut saya masih cukup baik.
Selain itu saya juga menghilangkan penggunaan _passing parameter by hash_ namun menggantinya dengan _passing parameter by values_ yang membuat kodenya semakin simple.

Karena bagi saya _passing by hash_ hanya membuat kodenya menjadi semakin kompleks dan lebih sulit dibaca.
Anda bisa coba bandingkan kode dibawah ini:

```rb
# Passing by options(hash)
CreateToken.new(
  username_or_email: auth_attributes[:username_or_email],
  password: auth_attributes[:password]
)

# Passing by values
CreateToken.new(
  auth_attributes[:username_or_email],
  auth_attributes[:password]
)

# Definition (options)
def initialize(auth_attributes)

# Definition (value)
def initialize(username_or_email, password)
```

Kode kita menjadi lebih simple dan lebih _reliable_.

Memang setau saya tidak ada aturan resmi mengenai ini. Namun jika anda lebih memilih parameter passing by _hash_,
saya menyarankan untuk menggunakan _passing by keywords_, maka anda perlu mengubah kode definisinya menjadi:

```rb
# Before
def initialize(auth_attributes = {})

# After
def initialize(username_or_email:, password:)
```

Sekiranya segitu saja untuk tulisan kali ini, ikuti tips ini sebisa mungkin maka kode anda akan menjadi lebih bersih dan mudah untuk diubah.

Rule ini tidak bersifat mutlak, mungkin saja ada masalah-masalah yang memang tidak cocok dengan rule ini.

Terima kasih,

_Happy Hacking!_
