---
layout: post
title:  "Another Hotwire Experiment"
date:   2022-11-13 07:14:00 +0700
categories: hotwire
comments: true
published: true
---

Again, continuing my learning on Hotwire, I just want to share what I already build, and how. 

I hope you can get something from this, enjoy the reading!

Here's the sample feature that we want to build:

![](/assets/invoice-hotwire-demo.gif)

It's an interactive form to create an invoice. 

## Hotwire

Before we go deep into technical details, let's define some words. Hotwire is a tool or framework to help programmers build an interactive feature (*aka Javascript things*) on Rails. 

Examples of interactive features:
- When you want to sign up to Twitter, and then there is a message shows up to check if your username or password valid every time you type input in that text field.
- When you chat online via the WhatsApp web app, then there is a new message show up to you before you request or refresh the page.
- And so on.

Before Hotwire comes up, we still can build that kind of feature in Rails. We can use vanilla JS integrated using [Sprockets](https://github.com/rails/sprockets), component-based javascript frameworks like React.js or Vue.js integrated using [Webpacker](https://guides.rubyonrails.org/webpacker.html), JQuery, or another thing.

I can say that we don't have a default answer for how to write this thing in Rails, and I don't get the joy of writing those features before Hotwire comes up.

Now, we have the default answer. Hotwire has already been [added to the menu](https://github.com/rails/rails/pull/42999), [the menu is omakase](https://rubyonrails.org/doctrine#omakase)!

And I can promise with this tool, you can find joy again in writing Javascript in Rails.

## Stimulus.js

[Hotwire](https://hotwired.dev/) is a tool or framework that contains some jargon like Turbo, Stimulus.js, and Strada. Strada is not released yet at this time, so let's ignore this for now. 

- [Turbo](https://turbo.hotwired.dev/) is a new Turbolinks. We'll talk in detail about this when building the feature.
- [Stimulus.js](https://stimulus.hotwired.dev/) is a javascript framework for the HTML that you already have.

Stimulus allows us to make an interactive feature with HTML that we already have it. It's different from some popular component-based JS frameworks like Vue.js, and React.js. 

In a component-based JS framework, we need to generate the HTML from JS code or another templating format. The disadvantage of that approach compared with Hotwire ways is we have a lot of work.

Stimulus.js is an MVC Javascript framework. They have Models, Controllers, and Views just like Rails.

You can see the sample of codes from their [web homepage](https://stimulus.hotwired.dev/).

Here are the sample HTML, and JS codes:

```html
<!--HTML from anywhere-->
<div data-controller="hello">
  <input data-hello-target="name" type="text">

  <button data-action="click->hello#greet">
    Greet
  </button>

  <span data-hello-target="output">
  </span>
</div>
```


```js
// hello_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "name", "output" ]

  greet() {
    this.outputTarget.textContent =
      `Hello, ${this.nameTarget.value}!`
  }
}
```

The HTML we can generate from our lovely [Erb](https://github.com/ruby/erb), does not need a new template engine or JS code to generate. 

This is the example result:

![](/assets/hello-world-stimulus.gif)

`hello_controller.js` is the controller, which is the class responsible for accepting input, processing it, and making it a result or output.

`this.nameTarget`, and `this.outputTarget` were models. `this.nameTarget` will refer to the `input` field, and `this.outputTarget` will refer to `span` field. They connected via `data-model-target` attribute.

`data-action="click->hello#greet"` means that if users click the button, please run the `greet` method inside `Hello` controller. Have a similar concept with `Rails` routes. 

In Rails routes we see

```rb
get 'hello', to: 'hello#world'
```

Is means if users request to `/hello` via the `GET` method, please run the `world` method inside the `Hello` controller.

That's all for the concept, if you already understand this, you can write Stimulus.js with joy.

## Study case

Now, let's try to build something with Hotwire. 

We will create a create invoice form feature. In that form, we need to allow the user to choose the customer and then the list of products attached to that invoice.

This feature was inspired by [the accounting software](https://www.jurnal.id/en/features/online-invoice/) that I currently working for.

Here's the example database design for the feature:

![](/assets/db-design.png)

Here's the example UI:

![](/assets/ui.png)

First, let's build the customer input:

![](/assets/customer-input.gif)

To build this feature we can create a select tag, where the value from the options was the customer's email:

```erb
<%= form.select :customer, 
                Customer.all.pluck(:name, :email), 
                { prompt: 'Select Customer' }, 
                { required: true, class: 'form-control', data: { action: 'change->invoices#updateEmail' } } %>
```

And create the disabled email text field, where we show the information about the selected customer's email. 

```erb
<%= form.text_field :email, class: 'form-control', disabled: true, class: 'form-control', data: { 'invoices-target': 'emailField' }  %>
```

After that, we can trigger a Stimulus action.

```
data: { action: 'change->invoices#updateEmail' }
```

This means that every time users change the value from the `select` tag, we can run the `updateEmail` method inside the `invoices` controller.

```js
// app/controllers/invoices_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emailField"]

  updateEmail(event){
    this.emailFieldTarget.value = event.target.value
  }
}
```

In that method, we can receive the selected customer email by `even.target.value` then we update the DOM of the email field.

That's all. Now, the selection of customer input already working as expected.

Now, we continue to implement the selection product feature:

![](/assets/product-01.gif)

On this feature, we will:
1. Provide the list of products. And after users choose one of the products:
3. Update the unit text field with `1`.
4. Update the price per unit text field.
5. Update the total with "unit * price per unit".

This is the code for showing the list of products:

```erb
<%= product_form.select :product_id, 
                              options_for_select(products_options), 
                              { prompt: 'Select product' }, 
                              class: 'form-control',
                              required: true, 
                              data: { 'invoice-products-target': 'productItem', action: 'change->invoice-products#updatePrices' } %>
```

```rb
# app/controllers/invoices_controller.rb
# ...
def products_options
  products = Product.all
  products.map { |product| [product.name, product.id, { data: { price_per_unit: product.amount } }] }
end
# ...
```

From the backend, we need to show the information about the product's price per unit information to the client.

Here's the client's code:

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invoice-products"
export default class extends Controller {
  static targets = ["unit", "productItem", "pricePerUnit", "total"]

  // ...
  updatePrices(event) {
    if(event.target.selectedOptions[0].value == '') {
      this.unitTarget.value = ''
      this.pricePerUnitTarget.value = ''
      this.totalTarget.value = ''
    } else {
      this.pricePerUnitTarget.value = this.toIdr(this.findPricePerUnitFor(event.target))
      this.unitTarget.value = 1
    }
    this.totalTarget.dispatchEvent(new Event('change'))
    this.unitTarget.dispatchEvent(new Event('change'))
  }

  findPricePerUnitFor(element) {
    return element.selectedOptions[0].dataset.pricePerUnit
  }

  toIdr(number) {
    const idr = new Intl.NumberFormat('id').format(number)
    return `Rp ${idr}`
  }
}
```

`findPricePerUnitFor` will fetch the related price per unit product information. You can learn more about the APIs from this [documentation](https://developer.mozilla.org/en-US/docs/Learn/HTML/Howto/Use_data_attributes).

One more thing, as you realize we need to make the unit text field responsive. When users change the unit to any number, we need to update the total price. We can implement this feature with add logic in our client like this:

```erb
<%= product_form.number_field :unit, class: 'form-control', required: true, data: { action: 'change->invoice-products#updateProductItemPrice', 'invoice-products-target': 'unit' } %>
```

```js

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invoice-products"
export default class extends Controller {
  static targets = ["unit", "productItem", "pricePerUnit", "total"]

  updateProductItemPrice(event) {
    const pricePerUnit = this.findPricePerUnitFor(this.productItemTarget)
    const total = pricePerUnit * event.target.value
    this.totalTarget.value = this.toIdr(total)
    this.totalTarget.setAttribute('data-amount', total)
    this.totalTarget.dispatchEvent(new Event('change'))
  }

  // ...
}
```

Now, the customer selection feature is already done.

Next, we will continue building the "add new product" link.

![](/assets/add-product-link.gif)

It's time to talk about Turbo. Because to implement this kind of feature, we need to write in Turbo.

You can imagine Turbo is just like a _remote_ form that you already know. 

In Hotwire, we can create a link, that can process in the background, and then change the existing DOM without refreshing any page or changing any URL state. 

I already create [an article](http://localhost:4000/rails,/hotwire,/dynamic-form/2022/08/14/offcanvas-implementation-in-rails.html) that provides a sample workflow in Turbo, you can check out that article to learn more about that.

So, without further do, here's the implementation for that feature.

