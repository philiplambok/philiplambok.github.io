---
layout: post
title: "Bereksperimen menggunakan mock test"
date: 2019-07-14 16:58:00 +0700
categories: tdd
comments: true
published: true
---

Saat tulisan ini ditulis sebenernya saya masih bingung dengan perbedaan antara _stub_, _mock_ dan _fake_.

Namun untuk terminologi-terminologi ini saya ambil simple saja.

Saya menyebut itu _stub_ ketika anda mendeklarasikan output. Misalnya pada [webmock](https://github.com/bblimke/webmock) anda mendefinisikan output pada _enpoint_ tertentu dan output yang anda definisikan adalah apa yang di test.

Saya ambil konsep ini dari [webmock](https://github.com/bblimke/webmock). Kenapa pemrogram melakukan ini? mereka melakukan ini agar test mereka tetap _independent_. Tanpa koneksi online test akan tetap jalan sempurna.

Lalu dengan _mock_. Saya menyebut itu sebagai _mock_ ketika anda ingin melakukan _break dependencies_ dengan kelas atau objek. Pada pemrograman berorientasi kelas jarang sekali berdiri sendiri, biasanya untuk memproses sesuatu kelas akan berelasi satu dengan lainnya.

Namun terkadang, kita ingin mengetes suatu kelas secara terisolasi. Karena akan mendatangkan banyak mamfaatnya, seperti kode uji semakin cepat dan mungkin yang paling sering adalah: mengadakan semua dependensi yang dibutuhkan kelas yang ingin kita uji tak _seelok_ yang dibayangkan.

Pada tulisan ini saya ingin berbagi bagaimana saya menggunakan _mock test_ ketika membuat fitur seperti _import_ data dari file _excel_.

Fitur _import_ excel adalah fitur yang hampir ada disetiap projek yang saya kerjakan, baik untuk projek untuk perusahaan yang baru, atau untuk perusahaan yang sudah jalan. Karena fitur input lewat form untuk data yang banyak dapat membuat tangan admin menjadi lelah.

Fitur _import_ yang ingin kita bahas disini sangatlah simple, yaitu fitur _import_ untuk membuat data user yang kolomnya hanyalah dua yaitu: _username_, _age_.

Baik, mari kita mulai.

#### Langkah pertama: install dependencies

Pada projek eksperimen ini saya menggunakan `rspec-rails` sebagai _test framework_ dan [_roo_](https://github.com/roo-rb/roo) sebagai library pengimportnya.

Silahkan tambahkan kode ini di `Gemfile`:

```rb
gem 'roo', '~> 2.8.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara'
  gem 'pry-rails'
  gem 'rspec-rails'
end
```

Lalu install rspec dengan perintah `bundle exec rails rspec:install`.

#### Langkah kedua: membuat system test-nya.

Karena kita akan menggunakan paradigma _test-driven development_, maka kita menulis kode testnya terlebih dahulu sebelum kode produksi.

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import Users Spec', type: :system do
  before do
    driven_by :rack_test
  end

  context 'with valid params' do
    it 'returns success message' do
      visit new_employees_import_path
      file = Rails.root.join('spec', 'fixtures', 'files', 'users-all-valid.xlsx')
      attach_file :employee_import_form_file, file
      click_on 'Submit'
      expect(page).to have_content '3 employees has been created'
    end
  end
end
```

Kode test error sesuai ekspektasi kita, `new_empoyees_import_path` dibaca sebagai `undefined variable`.

#### Langkah ketiga: membuat kode produksi untuk membuat kode testnya sukses

Sekarang, mari kita membuat kode produksinya untuk membuat kode testnya _success_.

Pertama, register routes-nya terlebih dahulu:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  scope :employees, module: :employees, as: :employees do
    resources :imports
  end
end
```

Kedua, buat file controller-nya:

```rb
module Employees
  class ImportsController < ApplicationController
    def new
      @form = EmployeeImportForm.new
    end

     def create
      form = EmployeeImportForm.new(form_params)
      form.save
      flash[:success] = form.success_message
      redirect_to new_employees_import_path
    end

     private

     def form_params
      params.require(:employee_import_form).permit(:file)
    end
  end
end
```

Kita akan menggunakan _form object_ untuk fitur seperti ini. Kenapa _form object_? saya biasanya menggunakan _form object_ bukan untuk form yang terdiri dari dua model atau lebih saja, namun untuk form yang tidak memiliki table-nya.

Maka, ketiga kita buat _form object_-nya:

```rb
# frozen_string_literal: true

class EmployeeImportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :success_message

  attribute :file, default: nil

  def save
    @success_message = '3 employees has been created'
  end
end
```

Saya juga menggunakan `ActiveModel::Attributes` untuk membuat variable input yang bisa memiliki fitur _default value_, _setting type_ dan sebagainya.

Pada object ini saya awalnya tidak pusing untuk bagaimana bekerja dengan import-nya dulu, tapi saya buat _fake implementation_ untuk melihat kode test kita sukses.

Lalu jalankan testnya kembali.

Dan testnya sukses.

Setelah _fake implementation_, sekarang kita sudah cukup bisa berkreasi untuk _real implementationnya_.

Untuk kodenya kira-kira bisa kita buat menjadi seperti ini:

```rb
# frozen_string_literal: true

class EmployeeImportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :success_message

  attribute :file, default: nil

  def save
    total_created = 0
    xlsx = Roo::Spreadsheet.open(file)
    xlsx.parse(headers: true).each_with_index do |row, index|
      next if index.eql?(0)

      User.create(username: row['username'], age: row['age'])
      total_created += 1
    end
    @success_message = "#{total_created} employees has been created"
  end
end
```

Lalu testnya kita jalankan kembali.

Dan testnya masih sukses.

#### Langkah terakhir: improve kode testnya

Saat ini kita masih mengetest pesan errornya saja, namun untuk apakah recordnya sudah tersimpan di database atau malah tidak tersimpan kita masih belum yakin.

Oke, untuk itu kita coba improve kode test kita yang sebelumnya untuk mengecek database.

Kira-kira menjadi seperti ini:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import Users Spec', type: :system do
  before do
    driven_by :rack_test
  end

  context 'with valid params' do
    it 'returns success message' do
      visit new_employees_import_path
      file = Rails.root.join('spec', 'fixtures', 'files', 'users-all-valid.xlsx')
      attach_file :employee_import_form_file, file
      click_on 'Submit'
      expect(page).to have_content '3 employees has been created'
      expect(User.all.pluck(:username, :age)).to include(
        ['pquest', 23], ['larapel', 44], ['kimono', 31]
      )
    end
  end
end
```

Oke, dan testnya masih sukses.

Namun, bagaimana menurut anda kode test yang diatas?

Saya biasanya tidak melakukan hal tersebut.

_System spec_ biasanya saya buat hanya untuk menguji user interfacenya saja seperti bagaimana pengguna menginput data melalui form dan bagaimana _flash message_ yang ditampikan ke user sebagai outputnya.

Sedangkan untuk _low level_ seperti _query_ database saya tidak uji di _system spec_, melainkan saya mengujinya di _unit spec_, seperti model spec, controller spec, forms spec, service spec, dll.

Pada kasus ini, yaitu form spec: `employee_import_form_spec.rb`.

Sekarang mari kita biarkan system spec seperti yang awal kita buat, dan membuat form spec baru: `employee_import_form_spec`.

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmployeeImportForm do
  context 'with valid params' do
    it 'returns success message' do
      file_path = Rails.root.join(
        'spec', 'fixtures', 'files', 'users-all-valid.xlsx'
      )
      form = EmployeeImportForm.new(file: file_path)
      form.save
      expect(form.success_message).to eq '3 employees has been created'
      expect(User.all.pluck(:username, :age)).to include(
        ['pquest', 23], ['larapel', 44], ['kimono', 31]
      )
    end
  end
end
```

Kode testnya menghasilkan pesan error:

```bash
 1) EmployeeImportForm with valid params returns success mes
sage
     Failure/Error: xlsx = Roo::Spreadsheet.open(file)

     NoMethodError:
       undefined method `=~' for #<Pathname:0x00005588a608e420>
     # ./app/forms/employee_import_form.rb:13:in `save'
     # ./spec/forms/employee_import_form_spec.rb:13:in `block (3 levels) in <top (required)>'

Finished in 1.44 seconds (files took 1.13 seconds to load)
3 examples, 1 failure, 1 pending

Failed examples:

rspec ./spec/forms/employee_import_form_spec.rb:7 # EmployeeImportForm with valid params returns success message
```

Ufff...

Oke, sekarang waktunya kita mengimplementasikan mock object.

Sebelum kita mengimplementasikan mock object, kita lihat dulu kode implementasi dari kode `Roo::Spreadsheet.open(file)`.

Saya buka source-code-nya dan hasilnya:

```rb
require 'uri'

module Roo
  class Spreadsheet
    class << self
      def open(path, options = {})
        path      = path.respond_to?(:path) ? path.path : path
        extension = extension_for(path, options)

        begin
          Roo::CLASS_FOR_EXTENSION.fetch(extension).new(path, options)
        rescue KeyError
          raise ArgumentError,
                "Can't detect the type of #{path} - please use the :extension option to declare its type."
        end
      end

      def extension_for(path, options)
    end
  end
end
```

Hmnn, sepertinya _class method_ dari `open` mengekpektasikan objek yang mereka terima memiliki sebuah method `path`.

Oke, waktunya oprek kode test kita kembali dan saya membuatnya menjadi seperti ini:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmployeeImportForm do
  context 'with valid params' do
    it 'returns success message' do
      file_path = Rails.root.join(
        'spec', 'fixtures', 'files', 'users-all-valid.xlsx'
      )
      mock_excel = MockExcelFile.new(file_path)
      form = EmployeeImportForm.new(file: mock_excel)
      form.save
      expect(form.success_message).to eq '3 employees has been created'
      expect(User.all.pluck(:username, :age)).to include(
        ['pquest', 23], ['larapel', 44], ['kimono', 31]
      )
    end
  end

  private

  class MockExcelFile
    def initialize(path)
      @path = path
    end

    def path
      @path.to_s
    end
  end
end
```

Dan kode test-nya menjadi _success_.

:)

Sekarang ketika _business code_ dari import menjadi kompleks kita bisa bebankan untuk cek query-query database-nya di form spec dan bukan di fitur system spec.

Untuk tulisan kali ini saya kira sudah cukup, semoga dapat membantu para pembaca skalian.

Terima kasih.
