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

Then, the feature already working as we expect.
