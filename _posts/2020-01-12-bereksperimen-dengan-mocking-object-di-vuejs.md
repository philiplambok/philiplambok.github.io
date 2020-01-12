---
layout: post
title: "Bermain testing di Vue.js"
date: 2020-01-09 11:00:00 +0700
categories: vuejs, testing
comments: true
published: true
---

Hi, Setelah sekian lama pensi akhirnya ada kesempatan untuk nulis lagi :)

Pada tulisan kali ini, gw mau berbagi hasil eksperimen hari ini dalam mengoprek testing Vue.js di Nuxt Framework.

Goal pada kali ini adalah setidaknya kita akan bahas: 
- Bagaimana cara testing component di Vue.js.
- Bagaimana cara testing component yang di dalemnya ada component juga.
- Bagaimana caranya testing component yang di dalemnya ada request api menggunakan axios.

#### Goal pertama: Cara testing component di Vue.js

Kita akan membuat component yang menampilkan list dari items yang dikirim melalui props. 

```js
// test/components/list.spec.js
import { mount } from '@vue/test-utils'
import List from '~/components/list.vue'

describe('List component spec', () => {
  test('returns expected list', () => {
    const wrapper = mount(List, {
      propsData: {
        items: [
          'Username',
          'Emails'
        ]
      }
    })
    const items = ['Username', 'Emails']
    items.forEach(item => {
      expect(wrapper.text()).toContain(item)
    })
  })
})
```

Test diatas akan error, sekarang kita buat kode testnya menjadi passed, dengan membuatkan componentnya sesuai kritiria yang diinginkan. 

```
# components/list.vue

<template>
  <div>
    <li v-for="(item, index) in items" :key="index">
      show-item
    </li>
  </div>
</template>

<script>
export default {
  name: 'List', 
  props: {
    items: {
      type: Array,
      required: true
    }
  }
}
</script>
```

Maka testnya akan berhasil, goal pertama selesai :)

#### Goal kedua: Bagaimana cara testing component yang di dalamnya ada componentnya juga.

Anda akan sering bertemu dengan kasus ini, karena secara *best practice* kita tidak ingin satu halaman hanya memiliki satu component. Karena pada tulisan ini kita menggunakan nuxt, maka kita ambil contohnya adalah component pada `/pages`. 

Pada file `/pages/index.vue` kita akan menggunakan componentnya sebelumnya yaitu `List`.

```js
import { mount } from '@vue/test-utils'
import PagesIndex from '~/pages/index.vue' 

describe('Root page spec', () => {
  test('returns expected list items', () => {
    const wrapper = mount(PagesIndex, {
      data() {
        return {
          lists: [
            'Username', 
            'Email'
          ]
        }
      },
      stubs: ['ListComponent']
    })
    const lists = ['Username', 'Email']
    lists.forEach(listItem  => {
      expect(wrapper.text()).toContain(listItem)
    })
  })
})
```

Kode diatas akan failed sekarang kita buat passed dengan menulis kode produksinya:

```vue
# pages/index.vue

<template>
  <div>
    <List :items="lists" />
  </div>
</template>

<script>
import List from '~/components/list'
export default {
  name: 'RootPage',
  data(){
    return {
      lists: []
    }
  },
  components: {
    List
  }, 
}
</script>
```

Oke, maka kode testnya menjadi passed. Maka, dengan ini goal kedua kita sudah tercapai.

#### Goal terakhir: Bagaimana caranya testing component yang di dalemnya ada request api menggunakan axios

Kali ini kita akan menggunakan axios. Sebuah paket yang cukup terkenal di lingkungan di javascript untuk request api.

Untuk kasus ini saya akan membuat fitur yang simple saja, yaitu fetch data ketika user menekan tombol  "fetch employee" dan data yang diterima axios akan ditampilkan di dalam component. Kira-kira untuk test codenya bisa seperti ini:

```js
// test/pages/index.spec.js
import { mount } from '@vue/test-utils'
import PagesIndex from '~/pages/index.vue' 
import Vue from 'vue'

describe('Root page spec', () => {
  // ...
  test('returns employee name', async () => {
    const wrapper = mount(PagesIndex, {
      stubs: ['ListComponent'],
    })
    const fetchEmployeeButton = wrapper.find('#fetch-employee')
    fetchEmployeeButton.trigger('click')
    await Vue.nextTick()
    expect(wrapper.text()).toContain('Employee name: Budi')
  })
})
```

Dalam request api ini saya akan menggunakan plugin karena di kantor saya juga kebetulan menggunakan plugin untuk request apinya. Untuk kode produksi kira-kira seperti ini: 


```vue
# pages/index.vue

<template>
  <div>
    <List :items="lists" />
    <span v-if="employee !== null">Employee name: {{ employee.employee_name }}</span>
    <button id="fetch-employee" @click.prevent="fetchEmployee()">Fetch employee</button>
  </div>
</template>

<script>
import List from '~/components/list'
export default {
  name: 'RootPage',
  data(){
    return {
      employee: null,
      lists: []
    }
  },
  methods: {
    async fetchEmployee() {
      const { data } = await this.$employeeClient.show(1)
      this.employee = data.data
    },
  },
  components: {
    List
  }, 
}
</script>
```

Tapi setelah kode dijalankan test kita masih failed. Namun memang itu expectednya, karena pada kode test kita belum melakukan mockingnya yaitu memalsukan return dari kode `this.$employeeClient.show(1)`.

Sekarang kita lakukan mockingnya dengan merubah kode test kita:

```js
// test/pages/index.spec.js
import { mount } from '@vue/test-utils'
import PagesIndex from '~/pages/index.vue' 
import Vue from 'vue'
import employeeClient from '~/plugins/employeeClient'

describe('Root page spec', () => {
  // ....
  test('returns employee name', async () => {
    const wrapper = mount(PagesIndex, {
      stubs: ['ListComponent'],
      use: [employeeClient],
      mocks: {
        $employeeClient: {
          show: (id) => {
            return {
              data: {
                data: {
                  employee_name: 'Budi'
                }
              }
            }
          }
        }
      }
    })
    const fetchEmployeeButton = wrapper.find('#fetch-employee')
    fetchEmployeeButton.trigger('click')
    await Vue.nextTick()
    expect(wrapper.text()).toContain('Employee name: Budi')
  })
})
```

Sekarang jalankan kembali testnya, dan lihat hasilnya kode kita akan menjadi passed. Maka goal terakhir telah tercapai :) 

------

Terima kasih telah membaca tulisan sederhana ini, jika anda ingin melihat kode sumbernya dapat lihat [disini](https://github.com/sugar-for-pirate-king/nuxt-testing).

Semoga tulisan ini dapat bermamfaat bagi pembaca skalian,

*Happy hacking~*