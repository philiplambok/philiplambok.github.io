---
layout: post
title: "Event-driven Development di Rails"
date: 2020-01-26 11:00:00 +0700
categories: rails-event-store, pattern
comments: true
published: true
---

Karena kebetulan di kantor kemarin ada ngerjain projek yang di dalam codebasenya pakai pattern ini, jadi sambil belajar, coba nulis disini juga :)

Event-driven development mungkin lebih terkenal di dunia frontend dibanding di dunia backend. Jika anda pernah menggunakan modern javascript saat ini seperti react dan vue.js mungkin anda akan familiar dengan konsep ini. Event-driven development adalah sebuah pattern yang menggunakan event sebagai flow sistemnya. 

Pada tulisan ini saya mencoba menjelaskan konsep dari event-driven development menggunakan studi kasus. Kita akan membuat sebuah projek sederhana. Pertama kita akan menggunakan cara tradisional, lalu melakukan refactoring dengan mengimplementasikan event-driven. Untuk pattern ini saya akan menggunakan paket [rails_event_store](https://github.com/RailsEventStore/rails_event_store).     


### Desain Aplikasi

Seperti yang sudah anda tau, kita akan membuat aplikasi api pembuat user, kira-kira desainnya seperti ini: 

- Membuat user baru:

  ```
  POST /api/users

  {
    "email": "pquest@gmail.com",
  }
  ```

- Melihat informasi data dari user:

  ```
  GET /api/users/:id

  {
    "email: "pquest@gmail.com",
    "status": "inactive"
  }
  ```

- Membuat user menjadi active:

  ```
  POST /api/users/activation

  {
    "id": 1
  }
  ```


Bisa dilihat dari desain aplikasi diatas, maka kita akan membuat setidaknya tiga fitur, yaitu membuat user baru dengan status yang inactive, lalu membuat sebuah enpoint yang dapat membuat spesifik user bisa menjadi aktif. 

Fitur terakhir kita dapat melihat informasi dari user yang bersangkutan. Pada fitur pertama dan ketiga kita akan membuatkan lognya.


Sekarang, mari kita membuat fiturnya satu-per-satu dari fitur pertama membuat user baru, kode specnya: 

```rb
require 'rails_helper'

RSpec.describe "Create new user", type: :request do
  it 'creates expected user' do
    post '/api/users', params: { user: { email: 'pquest@gmail.com' } }
    expect(json_response['email']).to eq 'pquest@gmail.com'
    user = User.find_by(email: 'pquest@gmail.com')
    expect(user).to be_inactive
    log = Log.last
    expect(log.text).to eq 'User with email pquest@gmail.com has been created'
  end

  private 

  def json_response
    JSON.parse(response.body)
  end
end
```

Jalankan dan lihat kode testnya menghasilkan failed test case. Lalu kita buat kode testnya menjadi passed, dengan menulis kode ini: 

```rb
# app/controllers/api/users_controller.rb
module Api
  class UsersController < ApplicationController
    def create
      user = User.new(user_params)
      user.save
      Log.create(text: "User with email #{user.email} has been created")
      render json: { email: user.email }
    end

    private 

    def user_params
      params.require(:user).permit(:email)
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  enum status: [:inactive]
end
```

Fitur pertama telah berhasil kita buat, sekarang fitur kedua yaitu melihat informasi dari spesific user: 

```rb
require 'rails_helper'

RSpec.describe 'Show user information', type: :request do
  it 'returns expected user' do
    user = create(:user, email: 'pquest@gmail.com')
    get "/api/users/#{user.id}"
    expect(json_response['email']).to eq 'pquest@gmail.com'
    expect(json_response['status']).to eq 'inactive'
  end

  private 

  def json_response
    JSON.parse(response.body)
  end  
end
```

Sekarang buat kodenya menjadi passed dengan kode ini: 

```rb
# app/controllers/api/users_controller.rb
module Api
  class UsersController < ApplicationController
    # ...

    def show
      user = User.find_by(id: params[:id])
      render json: { email: user.email, status: user.status }
    end

    # ...
  end
end
```

Sekarang mari kita buat fitur terakhir yaitu membuat user statusnya menjadi active dari sebelumnya yang inactive.

```rb
require 'rails_helper'

RSpec.describe "User activation", type: :request do
  it 'make user actives' do
    user = create(:user, status: 0)
    expect(user).to be_inactive
    post '/api/users/activations', params: { id: user.id }
    expect(json_response['email']).to eq user.email
    expect(json_response['status']).to eq 'active'
    user.reload
    expect(user).to be_active
    log = Log.last
    expect(log.text).to eq "User with email #{user.email} has been activated"
  end

  private 

  def json_response
    JSON.parse(response.body)
  end
end
```

Untuk kode produksinya: 

```rb
# /api/users/activations_controller.rb
module Api
  module Users
    class ActivationsController < ApplicationController
      def create
        user = User.find_by(id: params[:id])
        user.active!
        Log.create(text: "User with email #{user.email} has been activated")
        render json: { email: user.email, status: user.status }
      end
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  enum status: [:inactive, :active]
end
```

Maka, ketiga fitur sudah berjalan seperti yang di ekspektasi sekarang waktunya untuk melakukan refactoring dengan menggunakan event-driven development.

Kita akan menggunakan rails-event-store, maka sebelumnya silahkan tambahkan gem tersebut di Gemfile: 

```Gemfile
gem "rails_event_store"
```

Lalu jalankan `$> bundle install`. 

Sekarang kita lakukan setup lain yaitu database: 

```rb
$> string stop
$> rails generate rails_event_store_active_record:migration
$> rails db:migrate
```

Setelah database telah berhasil di-isi sekarang kita buat global statenya:

```rb
Rails.configuration.to_prepare do
  Rails.configuration.event_store = $event_store = RailsEventStore::Client.new
  $event_store.subscribe(UserCreatedHandler.new, to: [UserCreated])
end
```

Kita akan merefactor fitur yang pertama, yaitu fitur membuat user baru: 

```rb
# app/controllers/users_controller.rb
module Api
  class UsersController < ApplicationController
    def create
      user = User.new(user_params)
      user.save
      event = UserCreated.new(data: { user: user })
      $event_store.publish(event)
      render json: { email: user.email }
    end

    # ...
  end
end

## app/handlers/user_created_handler.rb
class UserCreatedHandler
  def call(event)
    user = event.data[:user]
    user_email = user.email
    Log.create(text: "User with email #{user_email} has been created")
  end
end

# app/events/user_created.rb
class UserCreated < RailsEventStore::Event; end
```

Sekarang jalankan kode testnya kembali, dan kita masih mendapat pesan sukses, artinya refactoring untuk fitur pertama kita telah berhasil.

Sekarang lanjut ke fitur ketiga (fitur kedua kita lewati karena memang tidak ada handlernya/log):

```rb
# app/controllers/users/activations_controller.rb
module Api
  module Users
    class ActivationsController < ApplicationController
      def create
        user = User.find_by(id: params[:id])
        user.active!
        event = UserActivated.new(data: { user: user })
        $event_store.publish(event)
        render json: { email: user.email, status: user.status }
      end
    end
  end
end

# app/handlers/user_activated_handler.rb
class UserActivatedHandler 
  def call(event)
    user = event.data[:user]
    user_email = user.email
    Log.create(text: "User with email #{user_email} has been activated")
  end 
end

# app/events/user_activated.rb
class UserActivated < RailsEventStore::Event; end
```

Sekarang jalankan kembali testnya dan hasilnya akan kembali sukses. Artinya kita berhasil merefactoring fitur terakhir ini.


### Konklusi
Karna saya baru menggunakan atau belajar pola ini, jadi saya masih belum bisa menyarankan untuk menggunakan pola ini untuk next projek anda atau menggunakan pola ini untuk membersihkan atau refactor projek anda. 

Tapi kelebihan yang mungkin saya rasakan mungkin dengan pola ini kode kita menjadi lebih independent, peran handlernya bisa sangat jelas dibandingkan dengan pola service objek yang mungkin harus lebih hati-hati dalam membuatnya.

Tapi kekuarangnya mungkin kita akan sulit melakukan track flow dari kode kita karena mungkin akan sulit menemukan sumbernya. Jadi mungkin debuggingnya caranya bisa beda dengan tradisional pada umumnya.  

Sekali lagi saya tidak bisa menentukan mana pola yang lebih baik, karena masih baru belajar juga. Jika anda tertarik untuk kode sumbernya bisa di lihat [disini](https://github.com/sugar-for-pirate-king/try-event-store).

Terima kasih telah membaca, semoga tulisan ini dapat bermamfaat bagi pembaca skalian, thank you.

*Happy hacking ~*