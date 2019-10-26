---
layout: post
title: "Refactoring Vue.js"
date: 2019-10-26 11:00:00 +0700
categories: vuejs, refactorign
comments: true
published: true
---

Pada tulisan ini saya mau ngobroling tentang vue.js

Ditulisan pertama saya tentang vue.js ini saya mau ngobrolin tentang bagaimana melakukan refactoring di vue.js. Jelas sebenernya refactoring adalah studi yang luas yang tidak mungkin dibahas hanya dengan satu halaman saja.

Pada tulisan ini kita akan membahas salah satu dari sekian banyaknya saja, yang menurut saya yang konsepnya lumayan *powerful*. Yaitu adalah melakukan refactoring dengan *dekomposisi komponen*. Singkatnya membuat komponen yang besar menjadi kecil-kecil.

Seperti biasa, kita akan membahasnya dengan studi kasus. Untuk tulisan ini kita akan mencoba membuat fitur untuk menambahkan note baru. Di form tersebut ada dua field yang berbeda yaitu *title* dan *body*. Jika kedua field tersebut diisi maka pesan yang dikembalikan adalah *"Note has been publised"*, namun jika salah satu atau keduanya field tidak diisi maka akan dibalikan pesan *error*.

Kita akan menggunakan Rails dalam implementasinya, karena kita akan menggunakan *test-driven development*.

Oke, mari mulai.

Pertama, mari kita buat kode testnya terlebih dahulu, kira-kira:

```rb
# frozen_string_literal: true

# filename: spec/system/notes/create_spec

require 'rails_helper'

RSpec.describe 'Create Note', type: :system, js: true do
  it 'returns success message' do
    visit new_note_path
    fill_in :note_title, with: 'Refactoring Vue.js'
    fill_in :note_body, with: 'Create small components'
    click_on 'Submit'
    expect(page).to have_content 'Note has been published'
  end

  it 'returns error message when title was blank' do
    visit new_note_path
    fill_in :note_title, with: ''
    fill_in :note_body, with: 'Create small components'
    click_on 'Submit'
    expect(page).to have_content "Title can't be blank"
  end

  it 'returns error message when body was blank' do
    visit new_note_path
    fill_in :note_title, with: 'Refactoring Vue.js'
    fill_in :note_body, with: ''
    click_on 'Submit'
    expect(page).to have_content "Body can't be blank"
  end
end
```

Jalankan. Lalu kode test kita akan error.

Sekarang waktunya kita membuat kode testnya menjadi sukses.

Silahkan buatkan routesnya:

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  resources :notes
end
```

Lalu buat controllernya:

```rb
# frozen_string_literal: true

class NotesController < ApplicationController
  def new; end
end
```

Lalu buatkan view-nya:

```html
<div class="container">
  <div class="row">
    <div class="col-md-4 mt-4 mx-auto">
      <note-form></note-form>
    </div>
  </div>
</div>
```

Lalu *register* komponen tersebut di `application.js`

```js
import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import App from '../app.vue'
import NoteForm from '../note_form.vue'

Vue.use(TurbolinksAdapter)

document.addEventListener('turbolinks:load', () => {
  const app = new Vue({
    el: '#app',
    components: { App, NoteForm }
  })
})
```

Lalu buat komponen `note-form`-nya.

```html
<template>
  <div id="note-form">
    <div v-if="successMessage">
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        <span>{{ successMessage }}</span>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
    <div v-if="errors.length > 0">
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <li v-for="error of errors" :key="error">{{ error }}</li>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
    <div class="form-group row">
      <label for="note_title" class="col-form-label col-md-4">Title</label>
      <div class="col-md-8">
        <input type="text" id="note_title" v-model="note.title" class="form-control">
      </div>
    </div>
    <div class="form-group row">
      <label for="note_body" class="col-form-label col-md-4">Body</label>
      <div class="col-md-8">
        <input type="text" id="note_body" v-model="note.body" class="form-control">
      </div>
    </div>
    <button @click="submit()" class="btn btn-primary btn-block">Submit</button>
  </div>
</template>

<script>
export default {
  name: "NoteForm",
  data() {
    return {
      successMessage: "",
      errors: [],
      note: {
        title: "",
        body: ""
      }
    };
  },
  methods: {
    submit() {
      this.errors = [];
      this.validation(this.note);
      if (this.errors.length > 0) {
        return false;
      }
      this.successMessage = "Note has been published";
    },
    validation(note) {
      let message = "";
      if (note.title == "") {
        message = "Title can't be blank";
        this.errors.push(message);
      }
      if (note.body == "") {
        message = "Body can't be blank";
        this.errors.push(message);
      }
    }
  }
};
</script>
```

Lalu jalankan testnya kembali, maka kode testnya akan *passed* atau sukses.

Sekarang waktunya refactoring!

Pertama, mari kita buat komponen baru `alert-success` sebagai komponen yang menangani pesan suksesnya.

```html
<!-- filename: app/javascripts/alert/success.vue -->

<template>
  <div id="alert-success">
    <div v-if="message != ''">
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        <span>{{ message }}</span>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "AlertSuccess",
  props: {
    message: String
  }
};
</script>
```

Sekarang kita gunakan komponen ini di komponen `note-form`:

```html
<template>
  <div id="note-form">
    <alert-success :message="successMessage"></alert-success>
    <div v-if="errors.length > 0">
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <li v-for="error of errors" :key="error">{{ error }}</li>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
    <div class="form-group row">
      <label for="note_title" class="col-form-label col-md-4">Title</label>
      <div class="col-md-8">
        <input type="text" id="note_title" v-model="note.title" class="form-control">
      </div>
    </div>
    <div class="form-group row">
      <label for="note_body" class="col-form-label col-md-4">Body</label>
      <div class="col-md-8">
        <input type="text" id="note_body" v-model="note.body" class="form-control">
      </div>
    </div>
    <button @click="submit()" class="btn btn-primary btn-block">Submit</button>
  </div>
</template>

<script>
import AlertSuccess from "alert/success.vue";

export default {
  name: "NoteForm",
  data() {
    return {
      successMessage: "",
      errors: [],
      note: {
        title: "",
        body: ""
      }
    };
  },
  methods: {
    submit() {
      this.errors = [];
      this.validation(this.note);
      if (this.errors.length > 0) {
        return false;
      }
      this.successMessage = "Note has been published";
    },
    validation(note) {
      let message = "";
      if (note.title == "") {
        message = "Title can't be blank";
        this.errors.push(message);
      }
      if (note.body == "") {
        message = "Body can't be blank";
        this.errors.push(message);
      }
    }
  },
  components: { AlertSuccess, AlertErrors }
};
</script>
```

Jalankan kode testnya lagi, dan kode testnya masih *passed*.

Sekarang waktunya untuk implementasi konsep yang sama pada *error responsenya*.

Kita buat komponen `alert-errors`:

```html
<template>
  <div id="alert-errors">
    <div v-if="errors.length > 0">
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <li v-for="error of errors" :key="error">{{ error }}</li>
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "AlertErrors",
  props: {
    errors: Array
  }
};
</script>
```

Sekarang, kita gunakan komponen ini di `note-form`:

```html
<template>
  <div id="note-form">
    <alert-success :message="successMessage"></alert-success>
    <alert-errors :errors="errors"></alert-errors>
    <div class="form-group row">
      <label for="note_title" class="col-form-label col-md-4">Title</label>
      <div class="col-md-8">
        <input type="text" id="note_title" v-model="note.title" class="form-control">
      </div>
    </div>
    <div class="form-group row">
      <label for="note_body" class="col-form-label col-md-4">Body</label>
      <div class="col-md-8">
        <input type="text" id="note_body" v-model="note.body" class="form-control">
      </div>
    </div>
    <button @click="submit()" class="btn btn-primary btn-block">Submit</button>
  </div>
</template>

<script>
import AlertSuccess from "alert/success.vue";
import AlertErrors from "alert/errors.vue";

export default {
  name: "NoteForm",
  data() {
    return {
      successMessage: "",
      errors: [],
      note: {
        title: "",
        body: ""
      }
    };
  },
  methods: {
    submit() {
      this.errors = [];
      this.validation(this.note);
      if (this.errors.length > 0) {
        return false;
      }
      this.successMessage = "Note has been published";
    },
    validation(note) {
      let message = "";
      if (note.title == "") {
        message = "Title can't be blank";
        this.errors.push(message);
      }
      if (note.body == "") {
        message = "Body can't be blank";
        this.errors.push(message);
      }
    }
  },
  components: { AlertSuccess, AlertErrors }
};
</script>
```

Jalankan testnya lagi, dan hasilnya masih *passed*.

-------
Melakukan dekomposisi pada komponen yang besar menjadi komponen-komponen kecil yang independen selain memberikan kode lebih mudah dibaca, itu juga memberikan kodenya kita lebih *reuseable*. Komponen-komponen kecil tadi bisa digunakan di komponen lain yang membutuhkannya.

Untuk kode sumbernya anda dapat temukan disini: [sugar-for-pirate-king/refactoring-vue](https://github.com/sugar-for-pirate-king/refactoring-vue)

Sekian tulisan kali ini, semoga dapat bermamfaat bagi pembaca skalian.
