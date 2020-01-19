---
layout: post
title: "Tips menulis kode test untuk komponen di Vue.js"
date: 2020-01-19 11:00:00 +0700
categories: vuejs, testing
comments: true
published: true
---

Hampir semua tulisan di blog saya ini judulnya kalo enggak bereksperimen ya tips and trik ~/~

Selain karna bingung mau kasih nama judulnya apa, juga enggak yakin dengan kebenaran dari konten yang di tulis :) 

Tulisan kali ini juga enggak akan jauh berbeda dengan tulisan yang di tulis sebelumnya: [Bermain testing di Vue.js](https://philiplambok.github.io/vuejs,/testing/2020/01/09/bereksperimen-dengan-mocking-object-di-vuejs.html)

Jika di tulisan sebelumnya, saya berbagi gimana cara nulis kode test dan sedikit contoh mocking di Vue.js. Tulisan kali ini lebih gimana cara nulis kode test yang benar di Vue.js (*best practice*).

Tulisan ini terinspirasi dari Sepuh Kent C. Dodds yang saya temukan di twit ini: 

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Maybe this will help justify the rational: <a href="https://t.co/MMj5eK5WQf">https://t.co/MMj5eK5WQf</a></p>&mdash; Kent C. Dodds 🧢 (@kentcdodds) <a href="https://twitter.com/kentcdodds/status/1217810669405261824?ref_src=twsrc%5Etfw">January 16, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Pada [tulisan itu](https://kentcdodds.com/blog/testing-implementation-details), ia berbagi bagaimana cara menulis kode test yang bener, dimana kode test kita memberikan *false negative* dan *false positive*. Silahkan baca artikel itu dahulu sebelum melanjutkan membaca artikel ini.

Seperti yang anda lihat di sinopsis judulnya Kent menulis: 

> Testing implementation details is a recipe for disaster.

Pada artikel tersebut kita disarankan untuk tidak mengetes internal interface dari komponen, contohnya adalah tidak mengakses instance dari Vue.js-nya `wrapper.vm`.

Seperti biasa saya akan mencontohnya dengan menulis kode test menggunakan [testing-library](https://testing-library.com/) dan akan menulis ulang dengan vue-test-utils, karena mungkin di projek anda, anda tidak menggunakan vue-test-utils.

Testing-library ada sebuah paket yang ditulis untuk menulis kode test secara best practice, dia seperti capybara di Rails. Testing-library akan mengetes aplikasi anda dengan *user-centric ways*, anda tidak bisa mengakses internal interface komponen anda dengan paket ini.

Mari kita mulai pembahasannya dengan membuat simple form input username. Ketika user mengetik namanya, maka di halaman yang sama akan mengeluarkan pesan *Hello, username*.

Untuk kode testnya kira-kira seperti ini: 

```js
import { render, fireEvent } from '@testing-library/vue'
import PagesIndex from '~/pages/index.vue'

describe('Pages index page spec', () => {
  test('Testing username form', async () => {
    const { getByText, getByLabelText } = render(PagesIndex)
    // Menyimpan DOM dari username inpput field (yang diambil dari labelnya) 
    const usernameInput = getByLabelText(/username/i)
    // Menganti username input textnya menjadi 'Kokomi'
    await fireEvent.update(usernameInput, 'Kokomi')
    // Mentrigger keyup pada username field inputnya
    await fireEvent.keyUp(usernameInput)
    // Mengekspektasikan ada tulisan Hello, Kokomi
    getByText('Hello, Kokomi')
  })
})
```

Untuk kode produksinya kira-kira seperti ini: 

```vue
# pages/index.vue

<template>
  <div>
    <p>Hello, {{ username }}</p>
    <hr>
    <UsernameFieldForm @username-changed="changeUsername" />
  </div>
</template>

<script>
import UsernameFieldForm from '~/components/UsernameFieldForm'

export default {
  name: '',
  components: {
    UsernameFieldForm
  },
  data () {
    return {
      username: 'world'
    }
  },
  methods: {
    changeUsername (updatedUsername) {
      this.username = updatedUsername
    }
  }
}
</script>
```

```vue
# components/UsernameFieldForm.vue

<template>
  <div>
    <label for="username">Username</label>
    <input id="username" v-model="username" @keyup="updateUsername" name="username" type="text">
  </div>
</template>

<script>
export default {
  name: 'UsernameFieldForm',
  data () {
    return {
      username: ''
    }
  },
  methods: {
    updateUsername () {
      this.$emit('username-changed', this.username)
    }
  }
}
</script>
```

Dan jalankan kode testnya, maka kode testnya akan passed. 

Kode test diatas adalah kode test yang di rekomendasikan. Jika anda ingin melakukan refactor mengganti event triggernya dari `username-changed` to `username-change` kode test tersebut akan passed dan tidak memberikan *false negative*, karena kita tidak mengekspektasikan nama *emitted*-nya.

Jika kita ingin menulis kode test tersebut dengan versi *vue-test-utils*, maka anda dapat menulisnya kira-kira seperti ini: 

```js
import { mount } from '@vue/test-utils'
import Vue from 'vue'
import PagesIndex from '~/pages/index.vue'

describe('Pages index spec by vue test utils', () => {
  test('Testing username form', async () => {
    const wrapper = mount(PagesIndex)
    const usernameField = wrapper.find('#username')
    usernameField.setValue('Kokomi')
    usernameField.trigger('keyup')
    await Vue.nextTick()
    expect(wrapper.text()).toContain('Hello, Kokomi')
  })
})
```

----

Terima kasih telah membaca tulisan sedernaha ini, jika anda ingin sumber kodenya bisa di lihat [disini](https://github.com/sugar-for-pirate-king/nuxt-testing-lib), semoga tulisan ini dapat bermamfaat bagi pembaca skalian.

*Happy hacking ~*
