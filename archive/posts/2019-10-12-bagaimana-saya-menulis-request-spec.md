---
layout: post
title: "Ngobrol tentang request spec"
date: 2019-10-12 12:00:00 +0700
categories: rails, request-spec, tdd
comments: true
published: true
---

Rails 6 menghadirkan fitur *webpacker-by-default* yang membuat aplikasi Rails menjadi aplikasi yang *hybrid-by-default*. Maka daripada itu API menjadi sangat penting karena sudah menjadi bagian dari core development pada Rails nantinya.

Saya pun sekarang sudah membagi Rails menjadi dua layer yang berbeda yaitu layer web dan layer API:

```rb
# config/routes.rb

scope module: :web do
  resources :users
end

namespace :api do
  namespace :v1 do
    resources :users
  end
end
```

Berbicara tentang API maka kita akan berbicara tentang *request spec* yang memang tipe kode test yang khusus untuk melakukan test pada API.

Tulisan ini akan singkat seperti biasanya, saya hanya ingin berbagi bagaimana saya mengetest api saya, dan bagaimana solusi saya atas masalah API yang memerlukan otentikasi.

Seperti biasa, saya akan menjelaskannya sambil membuat studi kasus. Kita akan membaut dua studi kasus yang berbeda, yaitu:
1. Menampikan data user dari id tertentu.
2. Menampilkan data user yang sedang login.

Oke, sekarang mari kita bahas satu-per-satu

#### 1. Menampilkan data user dari id tertentu
Kita mulai dari kode testnya terlebih dahulu:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show spesific user json ', type: :request do
  it 'returns user json' do
    user = create(:user, username: 'pquest', email: 'pquest@gmail.com')
    get "/api/v1/users/#{user.id}"
    response_json = JSON.parse(response.body)
    expect(response_json['username']).to eq 'pquest'
    expect(response_json['email']).to eq 'pquest@gmail.com'
  end
end
```

Testnya akan failed, sekarang waktunya untuk membuat testnya menjadi sukses.

Tambahkan routing apinya di `config/routes.rb`:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:show]
    end
  end
end
```

Lalu terakhir buat controllernya `app/controllers/api/v1/users_controller.rb`:

```rb
# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      def show
        user = User.find_by(id: params[:id])
        render json: {
          username: user.username,
          email: user.email
        }
      end
    end
  end
end
```

Selesai. Maka studi kasus yang pertama kita sudah selesai.

Sebagai catatan saja, mungkin anda bisa lihat kalo saya lebih suka untuk menggunakan real data dalam melakukan ekspektasinya, contohnya daripada menulis `expect(response_json['username']).to eq user.username` saya lebih suka untuk menulisnya menjadi `expect(response_json['username']).to eq 'pquest'`.

Mungkin bagi anda tidak terlalu mempermasalahakan hal tersebut tapi secara psikologi `user.username` tidak semua orang yakin 100% kalo nilainya pasti `pquest` :).

Lalu catatan yang kedua adalah menggunakan `JSON.parse`. Dengan method itu kita mengekspektasikan responsenya layaknya object, bukan string.

#### 2. Menampilkan data user yang sedang login
Sebagai aplikasi *hybrid*, maka dalam otentikasinya akan berkutat pada *sessions*, berbeda dangan aplikasi, model SPA yang otentikasinya menggunakan jwt token, token yang terus dilempar setiap requestnya sebagai identikasi dari pelempar request yang bersangkutan.

Sedangkan pada request spec berbeda dengan controller spec. Dimana request spec tidak support membuatkan session baru pada kode testnya. Maka, untuk request spec dengan model yang seperti ini kita akan menggunakan *mock* atau *stub*.

Contohnya kode test untuk studi kasus ini menjadi:

```rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show current user json', type: :request do
  it 'returns current user json' do
    user = create(:user, username: 'pquest', email: 'pquest@gmail.com')
    sign_in_as(user)
    get '/api/v1/me'
    response_json = JSON.parse(response.body)
    expect(response_json['username']).to eq 'pquest'
    expect(response_json['email']).to eq 'pquest@gmail.com'
  end

  private

  def sign_in_as(user)
    allow_any_instance_of(ApplicationController).to(
      receive(:current_user).and_return(user)
    )
  end
end
```

Pada kode test diatas kita akan melakukan *stub* pada *return value* untuk *method* `current_user` di dalam kelas `ApplicationController`.

Untuk implementasinya kita tambahkan kode di `config/routes.rb`

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:show]
      resources :me, only: [:index]
    end
  end
end
```

Lalu untuk controllernya:

```rb
# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      def index
        render json: {
          username: current_user.username,
          email: current_user.email
        }
      end
    end
  end
end
```

Maka kode test kita akan *passed*. Method `current_user` sendiri kita dapatkan dari session *user_id* yang dibuat ketika login lewat form.

```rb
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def current_user
    User.find_by(id: session[:user_id])
  end
end
```


-----
Sekian untuk tulisan kali ini, kiranya tulisan ini bisa bermafaat untuk pembaca skalian.

*Happy hacking~*
