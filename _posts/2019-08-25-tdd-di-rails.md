---
layout: post
title: "Test-driven development di Rails"
date: 2019-08-25 12:00:00 +0700
categories: tdd, rails6, vue.js
comments: true
published: false
---

Pada tulisan ini saya ingin berbagi bagaimana saya menulis kode test-driven development pada Rails. Saya akan meng-*cover* system test, model test dan request test. Kita juga akan menggunakan Rails 6 dan Vue.js pada teknologinya.

Saya yakin anda sudah mengetahui apa itu test-driven development. Test-driven development adalah sebuah metodologi yang mengharuskan kode test ditulis terlebih dahulu sebelum kode produksinya. Dengan metodologi ini kita dapat meyakini semua kode produksi ditulis dari case yang gagal terlebih dahulu.

Test-driven development juga memberikan kita keberanian dalam melakukan refactoring kode dan ketika deployment.

Namun realitas tidak sesederhana itu, karena pada realitas kode test terbagi menjadi beberapa tipe, seperti yang saya sebutkan diawal, yaitu system test, model test dan request test.

Sebelumnya mari kita definisikan kategori test-test tersebut:
- System test, adalah test sistem dengan black box atau menggunakan browser layaknya user atau pengguna yang menggunakan aplikasinya. Jika kita membuat aplikasi website, maka sistem spec adalah robot yang menjalankan browser yang melakukan input-input secara otomatis.
- Model test, adalah unit test. Kita mengetest setiap objek-objek yang ada di dalam program.
- Request test, adalah api test. Kita mengetest api yang ada di dalam sistem.

Seperti biasanya kita akan membahas ini sambil mengerjakan projek sebagai studi kasusnya. Fitur-fitur yang ingin kita buat antara lain:
- Halaman welcome
- Registrasi user
- Login user
- List of notes
- Create new note

Kita akan membuat aplikasi penyimpanan catatan-catatan.

Sebelumnya untuk flow TDD, saya biasanya mengikuti aturan yang dibuat oleh Steve Freeman dan Nat Pryce yang mereka tulis di dalam buku [Growing Object-Oriented Software, Guided by Tests](https://www.amazon.com/Growing-Object-Oriented-Software-Guided-Tests/dp/0321503627).

![Flow tdd](/assets/flow_tdd.png)

Aturannya adalah kita mulai dari *acceptance test* atau yang dimaksud adalah system test. Lalu menulis kode request test dan unit testnya.

Baiklah mari kita mulai.


### Langkah pertama: Instalasi
Silahkan siapkan Ruby diatas 2.5 dan Rails 6.0. Lalu jalankan perintah:

```
$> rails new tdd-in-rails -T
```

Pada rails 6 pembuatan projek barunya agak lama dengan versi sebelumnya karena pada versi ini kita menggunkan webpacker.

Setelah rails selesai dibuat, maka install vue.js-nya.

```
$> bundle exec webpacker:install:vue
```

Anda bisa cek dokumentasinya [disini](https://github.com/rails/webpacker) untuk lebih lanjut.

Setelah vue.js terinstall, maka selanjutnya kita menginstal test frameworknya. Pada projek ini saya akan menggunakan `rspec`, `factory_bot`, `capybara` dan `selenium_driver` (selenium adalah chrome driver).

Silahkan tambahkan paket-paket tersebut di Gemfile
```rb
group :development, :test do
  # ...
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
end
```

Lalu jalankan perintah:

```rb
$> bundle exec rspec:install
```

Dan pada `rails_helper.rb`, tambahkan kode:
```rb
  # configuration driver for system spec
  chrome = Selenium::WebDriver::Chrome::Service
  chrome.driver_path = "#{::Rails.root}/spec/web_drivers/chromedriver"

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end

  # include factory_bot
  config.include FactoryBot::Syntax::Methods
```

Untuk chrome driver silahkan download [disini](https://chromedriver.chromium.org/downloads) sesuaikan dengan versi chrome yang terinstal di sistem operasi anda.

Maka, setup aplikasi kita selesai.

### Langkah kedua: Membuat halaman welcome
Halaman welcome seperti landing page pada umumnya, yang menceritakan tentang aplikasi yang kita buat. Kira-kira rancangannya seperti ini:

![root_path](/assets/root_path.png)

Mari buat file baru: `/spec/system/root_spec.rb`
```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Root page spec', type: :system do
  before do
    visit root_path
  end

  it 'returns title of web app' do
    expect(page).to have_content 'Example tdd-in-rails web app'
  end

  it 'returns daftar button' do
    expect(page).to have_link 'Daftar', href: new_user_path
  end

  it 'returns login button' do
    expect(page).to have_link 'Login', href: new_login_path
  end
end
```

Maka akan terjadi error root_path tidak ditemukan. Sekarang kita buat di file `routes.rb`
```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  root 'web/welcome#index'
end
```

Lalu selanjutnya kita membuat `WelcomeController` di dalam module `Web`. Tulis kode ini di file `app/controllers/web/welcome_controller.rb`

```rb
# frozen_string_literal: true

module Web
  class WelcomeController < ApplicationController
    def index; end
  end
end
```

Dan terakhir, kita buat file viewsnya di file `app/views/web/welcome/index.html.erb`

```erb
<h1>Example tdd-in-rails web app</h1>

<%= link_to 'Daftar', new_user_path %>
<%= link_to 'Login', new_login_path %>
```

Pada view kita membuat dua method `new_user_path` dan `new_login_path` yang belum dibuat, maka kita buat dulu di `routes.rb`:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  root 'web/welcome#index'

  scope module: :web do
    resource :login, only: %i[new]
    resources :users, only: %i[new]
  end
end
```

Dengan ini, testnya sudah berhasil dan fitur kita yang pertama halaman welcome sudah selesai.

### Langkah ketiga: Membuat fitur user registration
Fitur ini digunakan user untuk mendaftarkan dirinya agar bisa menggunakan aplikasi. Rancangannnya kira-kira akan seperti ini:

![new_user_path](/assets/new_user_path.png)

Sekarang kita mulai lagi dari kode testnya:
```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  it 'returns success message' do
    visit new_user_path
    fill_in :user_full_name, with: 'Kano minami'
    fill_in :user_email, with: 'kano@minami.com'
    fill_in :user_password, with: 'secret123'
    click_on 'Submit'
    expect(page).to have_content 'Registration has been succeed'
  end
end
```

Maka akan terjadi error viewnya tidak ada. Kita buat di file `app/views/web/users/new.html.erb`

```erb
<h4>User Registration</h4>

<%= form_with model: @user, url: users_path, method: :post, local: true do |form| %>
  <p>
    <%= form.label :full_name %>
    <%= form.text_field :full_name %>
  </p>
  <p>
    <%= form.label :email %>
    <%= form.text_field :email %>
  </p>
  <p>
    <%= form.label :password %>
    <%= form.text_field :password %>
  </p>
  <p>
    <%= form.submit "Submit" %>
  </p>
<% end %>
```

Kode tersebut masih belum sukses karena `@user` adalah `nil`. Sekarang generate model user. dengan perintah:

```sh
$> rails g model user full_name email password_digest
```

Maka rails akan membuatkan file model serta unit test dan factories-nya. Sebelum menggunakan model tersebut mari kita buat kode unit test di model user sesuai dengan system test yang kita tulis sebelumnya.

Di file `spec/models/user_spec` kita tulis kode seperti ini:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is valid with full_name, email and password' do
    user = build(:user,
                 full_name: 'Bill john',
                 email: 'bill.john@gmail.com',
                 password: 'secret123')
    user.valid?
    expect(user.errors).to be_blank
  end
end
```

Kode diatas akan failed karena attribute `password` kita tidak punya. Karena kita akan menggunakan `bycrpt` maka tambahkan itu di Gemfile

```rb
gem 'bcrypt', '~> 3.1.7'
```

Lalu jalankan `bundle` dan tambahkan *callback* ini di model anda:

```rb
# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
end
```

Kodenya unit test kita akan *passed* jika dijalankan kembali, sesuai ekspektasi kita. Sekarang lanjut ke controllernya untuk membuat variable `@user`.

```rb
# frozen_string_literal: true

module Web
  class UsersController < ApplicationController
    def new
      @user = User.new
    end
  end
end
```

Lalu jalankan test, dan kita mendapatkan error method `create` tidak ditemukan di `UsersController`, sekarang kita buat method tersebut:

```rb
# frozen_string_literal: true

module Web
  class UsersController < ApplicationController
    def new
      @user = User.new
    end

    def create
      user = User.new(user_params)
      user.save
      flash[:success_message] = 'Registration has been succeed'
      redirect_to new_user_path
    end

    private

    def user_params
      params.require(:user).permit(:full_name, :email, :password)
    end
  end
end
```

Maka kode test kita *passed*.

Sekarang kita menguji *negative case-nya*, bagaimana jika `full_name` kosong atau `email`-nya kosong.

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  it 'returns success message' do
    # ...
  end

  it 'returns error message' do
    visit new_user_path
    fill_in :user_full_name, with: ''
    fill_in :user_email, with: ''
    fill_in :user_password, with: ''
    click_on 'Submit'
    error_messages = [
      "Full name can't be blank",
      "Email can't be blank",
      "Password can't be blank"
    ]
    error_messages.each do |message|
      expect(page).to have_content message
    end
  end
end
```

Sekarang kode test kita akan *fail* kembali. Sekarang kita kembali kode kode unit test kita untuk menambahkan case-case tersebut:
```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is valid with full_name, email and password' do
    # ...
  end

  it 'is invalid without full_name' do
    user = build(:user, full_name: nil)
    user.valid?
    expect(user.errors[:full_name]).to include "can't be blank"
  end

  it 'is invalid without email' do
    user = build(:user, email: nil)
    user.valid?
    expect(user.errors[:email]).to include "can't be blank"
  end

  it 'is invalid without password' do
    user = build(:user, password: nil)
    user.valid?
    expect(user.errors[:password]).to include "can't be blank"
  end
end
```

Lalu kita tambahkan kode di modelnya menjadi:
```rb
# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :full_name, presence: true
  validates :email, presence: true
end
```

Maka kode test kita semuanya menjadi *passed*.

Fitur kedua kita telah selesai.

### Langkah keempat: Membuat fitur login
Sekarang kita membuat fitur login, karena di sistem kita nantinya akan ada halaman yang diakses perlu adanya otentikasi

Kira-kira rancangannya seperti ini:

![login_path](/assets/login_path.png)


Sekarang mari kita buat kode testnya `spec/system/logins/create_spec.rb`

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User login', type: :system do
  context 'with valid params' do
    it 'redirect to dashboard' do
      create(:user, full_name: 'pquest', email: 'pquest@mail.com', password: 'secret123')
      visit new_login_path
      fill_in :login_form_email, with: 'pquest@mail.com'
      fill_in :login_form_password, with: 'secret123'
      click_on 'Login'
      expect(page).to have_content 'Dashboard'
      expect(page).to have_content 'Hi, pquest'
    end
  end
end
```

Kita akan mendapat pesan error form tidak ditemukan. Mari kita buat di view kita `app/views/web/logins/new.html.erb`

```erb
<%= form_with(model: @form, url: login_path, method: :post, local: true) do |form| %>
  <p>
    <%= form.label :email  %>
    <%= form.text_field :email %>
  </p>
  <p>
    <%= form.label :password %>
    <%= form.password_field :password %>
  </p>
  <p>
    <%= form.submit "Login" %>
  </p>
<% end %>
```

Pada view ini kita memerlukan variable `@form`, mari kita buat variable tersebut

```rb
# frozen_string_literal: true

module Web
  class LoginsController < ApplicationController
    def new
      @form = LoginForm.new
    end
  end
end
```

Bisanya saya jika membuat form yang tidak memiliki table (model)-nya saya akan membuatkannya menjadi form object. Mari kita buat dengan menulis kode testnya terlebih dahulu:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoginForm do
  it 'is valid with email and password' do
    form = LoginForm.new(email: 'pquest@gmail.com', password: 'secret123')
    form.valid?
    expect(form.errors).to be_blank
  end
end
```

Lalu untuk kode form objectnya kita buat di file `/app/forms/login_form.rb`

```rb
# frozen_string_literal: true

class LoginForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
end
```

Maka form sudah tampil, namun masih terjadi error, yaitu method `crete` tidak ditemukan. Sekarang mari kita fix dengan menambahkan kode:
```rb
# frozen_string_literal: true

module Web
  class LoginsController < ApplicationController
    def new
      @form = LoginForm.new
    end

    def create
      user = User.find_by(email: form_params[:email])
      if user&.authenticate(form_params[:password])
        sign_in(user)
        redirect_to notes_path
      end
    end

    private

    def form_params
      params.require(:login_form).permit(:email, :password)
    end
  end
end
```

Pada controller diatas kita menggunakan method `sign_in(user)` sekarang mari kita buat itu di `app/helpers/authentication_helper.rb`

```rb
# frozen_string_literal: true

module AuthenticationHelper
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find_by(id: user_id)
  end

  def sign_in(user)
    session[:user_id] = user.id
  end
end
```

Lalu include helper tersebut di dalam `ApplicationController` kita

```rb
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AuthenticationHelper
end
```

Lalu di controller kita juga mengunakan method `notes_path`, sekarang buat itu di `routes.rb`

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  root 'web/welcome#index'

  scope module: :web do
    resource :login, only: %i[new create]
    resources :users, only: %i[new create]
    resources :notes, only: %i[index]
  end
end
```

Maka kode testnya sudah berhasil semua. Sekarang waktunya untuk menambahkan negative casenya.

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User login', type: :system do
  context 'with valid params' do
    it 'redirect to dashboard' do
      # ...
    end
  end

  context 'with invalid params' do
    it 'returns error message' do
      visit new_login_path
      fill_in :login_form_email, with: 'hacker@mail.com'
      fill_in :login_form_password, with: 'secret123'
      click_on 'Login'
      expect(page).to have_content 'Email or password was invalid'
    end
  end
end
```

Kita edit controllernya menjadi

```rb
# frozen_string_literal: true

module Web
  class LoginsController < ApplicationController
    def new
      @form = LoginForm.new
    end

    def create
      user = User.find_by(email: form_params[:email])
      if user&.authenticate(form_params[:password])
        sign_in(user)
        redirect_to notes_path
      else
        flash.now[:error] = 'Email or password was invalid'
        render :new
      end
    end

    private

    def form_params
      params.require(:login_form).permit(:email, :password)
    end
  end
end
```

Terakhir kita buat file di `notes_path`-nya

```erb
<p>Hi, <%= current_user.full_name %></p>
<h4>Dashboard</h4>
```

Maka kode test tersebut menjadi *passed*.

Sekarang kita buat fitur *logout*.

Kita buat testnya di `spec/system/logins/destroy_spec.rb`

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User logout', type: :system do
  context 'with authentication' do
    it 'redirect to root_path' do
      user = create(:user)
      page.set_rack_session(user_id: user.id)
      visit notes_path
      click_on 'Logout'
      expect(page).to have_current_path root_path
      # Try to access authenticated page
      visit notes_path
      expect(page).to have_current_path new_login_path
    end
  end
end
```

Saya menggunakan `rack_session_access` untuk membuat session lewat kode test. Silahkan tambahkan kode ini di Gemfile

```rb
group :development, :test do
  # ...
  gem 'rack_session_access'
  # ...
end
```

Lalu tambahkan ini di `spec_helper.rb`-nya untuk monkey patch-nya.

```rb
require 'rack_session_access/capybara'
```

Sekarang kode test kita akan error karena link logout belum ada, mari kita buat:

```erb
<p>Hi, <%= current_user.full_name %></p>
<p><%= link_to 'Logout', login_path, method: :delete %></p>
<h4>Dashboard</h4>
```

Lalu tambahkan kode ini di controller kita:

```rb
# frozen_string_literal: true

module Web
  class LoginsController < ApplicationController
    def new
      @form = LoginForm.new
    end

    def create
     #...
    end

    def destroy
      logout
      redirect_to root_path
    end

    private

    def form_params
      params.require(:login_form).permit(:email, :password)
    end
  end
end
```

Lalu tambahkan method `logout` di helper kita:

```rb
module AuthenticationHelper
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find_by(id: user_id)
  end

  def sign_in(user)
    session[:user_id] = user.id
  end

  def logout
    session[:user_id] = nil
  end
end
```

Terakhir kita buat notes_path hanya tersedia untuk user yang sudah login saja.

```rb
# frozen_string_literal: true

module Web
  class NotesController < ApplicationController
    before_action :require_login

    def index; end
  end
end
```

Kita buat method `require_login` di `ApplicationController` kita:

```rb
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AuthenticationHelper

  def require_login
    return true if signed_in?

    redirect_to new_login_path
  end
end
```

Maka fitur logout kita pun selesai.

### Langkah kelima: Membuat fitur list of notes
Pada fitur ini kita menampilkan data notes yang ada di database melalui api. Kita akan menggunakan Vue.js disini.

Sekarang kita mulai lagi dari kode testnya:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notes Index', type: :system, js: true do
  context 'without authentication' do
    it 'redirect to new_login_path' do
      visit notes_path
      expect(page).to have_current_path new_login_path
    end
  end

  context 'with authentication' do
    before do
      create(:note, title: 'Test-driven development di Rails')
      create(:note, title: 'Arsitektur Rails')
      user = create(:user, email: 'pquest@gmail.com')
      page.set_rack_session(user_id: user.id)
      visit notes_path
    end

    it 'returns list of notes' do
      notes = [
        'Test-driven development di Rails',
        'Arsitektur Rails'
      ]
      notes.each do |note_title|
        expect(page).to have_content note_title
      end
    end
  end
end
```

Kode diatas akan error notenya tidak ditemukan di view-nya.

Sekarang mari kita buat tambahkan component `<notes>` di view-nya.

```erb
<p>Hi, <%= current_user.full_name %></p>
<p><%= link_to 'Logout', login_path, method: :delete %></p>
<h4>Dashboard</h4>

<notes></notes>
```

Lalu kita buat file `app/javascript/notes.vue`

```html
<template>
  <div>
    <ul v-for="note of notes" :key="note.id">
      <li>{{ note.title }}</li>
    </ul>
  </div>
</template>

<script>
export default {
  data() {
    return {
      notes: []
    };
  },
  mounted() {
    fetch("/api/v1/notes")
      .then(response => response.json())
      .then(data => {
        this.notes = data;
      });
  }
};
</script>
```

Sekarang pada `application.js`-nya kita buat menjadi:

```js
import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import Notes from '../notes.vue'

Vue.use(TurbolinksAdapter)

document.addEventListener('turbolinks:load', () => {
  const app = new Vue({
    el: '#app',
    components: { App, Notes }
  })
})
```

Komponent kita berhasil di load, namun kita api kita masih belum tersedia, kita buat dengan kode testnya terlebih dahulu:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notes index API', type: :request do
  context 'without authentication' do
    it 'returns not authenticated error message' do
      get '/api/v1/notes'
      expect(response.body).to include "You're not authenticated"
    end
  end
end
```

Lalu kita mulai dari routesnya terlebih dahulu:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  root 'web/welcome#index'

  scope module: :web do
    resource :login, only: %i[new create destroy]
    resources :users, only: %i[new create]
    resources :notes, only: %i[index new]
  end

  namespace :api do
    namespace :v1 do
      resources :notes, only %i[index]
    end
  end
end
```

