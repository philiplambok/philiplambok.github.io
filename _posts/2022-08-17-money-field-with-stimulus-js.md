---
layout: post
title:  "Money field with Stimulus.js"
date:   2022-08-17 09:14:00 +0700
categories: rails, stimulus, money-field
comments: true
published: true
---

In the last post, we already talked about [how to implement Bootstrap Offcanvas in Rails Hotwire](https://philiplambok.github.io/rails,/hotwire,/dynamic-form/2022/08/14/offcanvas-implementation-in-rails.html). 

We are building some product creation features. But, the amount of input still uses the number field, and we can improve that with the money field.

The money field means our text field is responsive to the customer input. It will do some real-time parsing from raw string to currency format.

We will add that feature with Stimulus.js.

![money field](/assets/money-field.gif)

First, we need to create our Stimulus Money Controller. You can do that with runs this command in your terminal:

```sh
rails g stimulus money
```

And here's the implementation:

```js
// app/javascripts/controllers/money_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toIdr(event){
    const onlyIntegerSubmittedValue = event.srcElement.value.split('').filter((el) => {
      return Number.isInteger(parseInt(el))
    }).join('')

    let idrInReversed = ''
    onlyIntegerSubmittedValue.split('').reverse().forEach((el, index) => {
      if(index % 3 === 0 && index !== 0) {
        idrInReversed += ','
      }
      idrInReversed += el
    })

    const idr = idrInReversed.split("").reverse().join('')
    event.srcElement.value = idr
  }
}
```

Yes, you can do it with `gsub` and pattern matching action, but in this blog post, I want to do it with some primitive data structure, only with basic string and array operation.

Then, we need to update our Rails view to integrate our stimulus controller with the actual text input:

```
<%# /app/views/products/_product.html.erb %>
<div class="mb-3">
  <%= form.label :amount, class: 'form-label' %>
  <div class="input-group">
    <span class="input-group-text">Rp</span>
    <%= form.text_field :amount, class: 'form-control', value: to_idr_number(product.amount), 
        data: { controller: 'money', action: 'keyup->money#toIdr' } %>
  </div>
</div>
```

```rb
# app/helpers/application_helper.rb
module ApplicationHelper
  def to_idr(number)
    number_to_currency(number, unit: 'Rp', locale: :id, precision: 0)
  end

  def to_idr_number(number)
    number_to_currency(number, unit: '', locale: :id, precision: 0)
  end
end
```

The last thing, we need to update our controller to handle the new input format:

```rb
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  # ...
  def product_params
    {
      name: params[:product][:name],
      amount: params[:product][:amount].to_s.delete(',')
    }
  end
end
```
 
Finally, we successfully created the money field feature for [our application](https://experiments-rails7.herokuapp.com/products).

The MoneyController is not production used, but feel free to copy and paste the function to the production codebase.

Thank you for reading, and happy hacking!
 