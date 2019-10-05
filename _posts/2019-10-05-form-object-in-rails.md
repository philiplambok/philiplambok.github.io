---
layout: post
title: "Pengenalan form object di Rails"
date: 2019-10-05 12:00:00 +0700
categories: tdd, rails6, vue.js
comments: true
published: true
---

Setelah sekian lama pensi, akhirnya ada kesempatan untuk nulis lagi.

Pada kesempatan ini saya mau bahas *form object*. Jika anda sudah mengenal atau pernah menggunakan form object di projek anda, mungkin tulisan ini bisa untuk refrerensi.

Saya yakin dari pembaca sudah banyak menggenal form object. Form object adalah sebuah object yang mempresentasikan sebuah form. Jadi dengan form object ini, sebuah form yang kita buat adalah sebuah object yang utuh.

Form object ini baiknya digunakan ketika anda memiliki sebuah form yang melibatkan lebih dari satu model, atau bahkan form anda tidak memiliki table atau model apapun. Namun jika form anda hanya terdiri dari satu model, maka anda tidak perlu menggunakan form object ini karena akan *over engineering*.

Seperti biasa, agar konsepnya lebih masuk kita akan membuat sebuah studi kasus. Studi kasusnya simple saja.Kita akan membuat sebuah form untuk menginput organisasi baru.

Kira-kira formnya akan seperti in:

```
Nama Organisasi: <String>
Nama Anda: <String>
Email Anda: <String>

<Button Submit>
```

Dan untuk rancangan tablenya akan seperti ini:
```
table_name: organizations
id: integer
name: string
user_id: integer
created_at: datetime
updated_at: datetime

---

table_name: users
id: integer
name: string
email: string
created_at: string
updated_at: string
```

Jadi, form yang akan kita buat akan memuat dua buah model yang berbeda.


Sekarang mari kita buat form tersebut dengan menulis kode testnya terlebih dahulu:

```rb
require 'rails_helper'

RSpec.describe 'Create new organization', type: :system do
  context 'with valid params' do
    it 'returns success message' do
      visit new_organization_path
      fill_in :organization_form_name, with: 'Ruby conf'
      fill_in :organization_form_user_name, with: 'Philip Lambok'
      fill_in :organization_form_user_email, with: 'philiplambok@gmail.com'
      click_on 'Submit'
      expect(page).to have_content 'Organization has been created'
    end
  end

  context 'with invalid params' do
    it 'returns error message' do
      visit new_organization_path
      click_on 'Submit'
      expect(page).to have_content "Name can't be blank"
      expect(page).to have_content "User name can't be blank"
      expect(page).to have_content "User email can't be blank"
    end
  end
end
```

Setelah specnya telah dibuat, maka sekarang mari kita buat kode testnya menjadi *passed*.

Tambahkan `routes.rb`
```rb
Rails.application.routes.draw do
  resources :organizations
end
```

Tambahkan controller `organizations_controller.rb`
```rb
class OrganizationsController < ApplicationController
  def new
    @form = OrganizationForm.new
  end

  def create
    form = OrganizationForm.new(form_params)
    if form.save
      flash[:success] = 'Organization has been created'
    else
      flash[:error] = form.errors.full_messages.join(', ')
    end
    redirect_to new_organization_path
  end

  private

  def form_params
    params.require(:organization_form).permit(
      :name, :user_name, :user_email
    )
  end
end
```

Lalu sekarang tambahkan form object: `organization_form.rb`-nya

```rb
class OrganizationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :user_name, :string
  attribute :user_email, :string

  validates :name, presence: true
  validates :user_name, presence: true
  validates :user_email, presence: true

  def save
    return false if invalid?

    user = User.new(name: user_name, email: user_email)
    user.save
    organization = user.organizations.build(name: name)
    organization.save

    true
  end
end
```

Jangan lupa juga untuk model-modelnya:
```rb
class Organization < ApplicationRecord
  belongs_to :user
end

class User < ApplicationRecord
  has_many :organizations
end
```

Dan terakhir untuk views-nya

```erb
<% flash.each do |key, value| %>
  <p><%= value %></p>
<% end %>

<%= form_with model: @form, url: organizations_path, local: true do |form| %>
  <div>
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>
  <div>
    <%= form.label :user_name %>
    <%= form.text_field :user_name %>
  </div>
  <div>
    <%= form.label :user_email %>
    <%= form.text_field :user_email %>
  </div>
  <%= form.submit "Submit" %>
<% end %>
```

Lalu jalankan testnya, maka hasilnya akan *passed*.

Pada form object ini saya menggunakan dua module yang ada di active-model, yaitu [`ActiveModel::Model`](https://api.rubyonrails.org/classes/ActiveModel/Model.html) agar form kita bisa layaknya model memiliki build-in `validations`, `errors`, `invalid`, `valid`, dll.

Selain itu juga saya menggunakan [`ActiveModel::Attributes`](https://api.rubyonrails.org/classes/ActiveModel/Attributes/ClassMethods.html) agar saya bisa menggunakan callback `attribute` di form object yang saya punya.

Dibandingkan dengan menggunakan `attr_accessor`, menggunakan `attribute` kita bisa men-*define* tipe data dari attribute kita, dan juga kita bisa membuat default value disaat kita perlu.

-----
Saya kira cukup untuk tulisan tentang pengenalan form object ini, jika anda tertarik dengan kode sumbernya dapat melihat kodenya [disini](https://github.com/sugar-for-pirate-king/how-to-use-form-object).

Selamat hacking~