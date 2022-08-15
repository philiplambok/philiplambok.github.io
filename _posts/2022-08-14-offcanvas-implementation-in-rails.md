---
layout: post
title:  "Bootstrap Offcanvas Implementation in Rails Hotwire"
date:   2022-08-14 11:14:00 +0700
categories: rails, hotwire, dynamic-form
comments: true
published: true
---
Hello, world!

Today, from this blog post, I just want to share my experiment that just I do. 

I tried to implement [the Offcanvas Bootstrap](https://getbootstrap.com/docs/5.0/components/offcanvas/) in Rails Hotwire.

If this is the first time you heard about Offcanvas, you can just think that Offcanvas is basically the improved modal. [Datadog](https://www.datadoghq.com/) already using this kind of approach in production, and i think more companies already using this also.

One feature that I liked in Offcanvas is they have [a static backdrop](https://getbootstrap.com/docs/5.0/components/modal/#static-backdrop). If you use this modal for form submission, that feature can help you to prevent your customer to accidentally closing the modal. 

So, let's see the output that we want to build:

![offcanvas.gif](/assets/offcanvas.gif)

The feature is so simple, we have list of products with name and amount, and we want to allow users to update the specific product.

We really care about our application, so we want to increase the UX by using animation rather than redirection. So, as you see, when user want to update Product #50, we show the Offcanvas with animation, then user click save, then we close the Offcanvas with animation, and then we update the record in the table.

Maybe the gif is not really seen good animation, you can test it by yourself at [this link](https://experiments-rails7.herokuapp.com/products). 

So, how do we implement this? you can see this sequence:

![offcanvas-sequence.png](/assets/offcanvas-sequence.png)

Here's the view looks like:

```
<%# /app/views/products/index.html.erb %>
<div class="row">
  <div class="col-md-6">
    <h1>Products</h1>

    <table class="table">
      <tr>
        <th>Id</th>
        <th>Name</th>
        <th>Amount</th>
      </tr>
      <% @products.each do |product| %>
        <%= render product %>

        <div class="offcanvas offcanvas-end" data-controller="canvas" data-bs-backdrop="static" tabindex="-1" id="<%= dom_id(product, :action) %>" aria-labelledby="staticBackdropLabel">
          <div class="offcanvas-header">
            <h5 class="offcanvas-title" id="staticBackdropLabel">Product #<%= product.id %></h5>
            <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close" data-canvas-target="closeBtn"></button>
          </div>
          <div class="offcanvas-body">
            <%= form_with(model: product, data: { action: 'turbo:submit-end->canvas#hide' }) do |form| %>
              <div class="mb-3">
                <%= form.label :name, class: 'form-label' %>
                <%= form.text_field :name, class: 'form-control', value: product.name %>
              </div>
              <div class="mb-3">
                <%= form.label :amount, class: 'form-label' %>
                <%= form.number_field :amount, class: 'form-control', value: product.amount %>
              </div>
              <%= form.submit 'Save', class: 'btn btn-link m-0 p-0'  %>
            <% end %>
          </div>
        </div>
      <% end %>
    </table>
  </div>
</div>
```

```
<%# app/views/products/_product.html.erb %>
 <tr id="<%= dom_id(product) %>">
  <td>
    <%= link_to product.id, '#', data: { 'bs-toggle': 'offcanvas', 'bs-target': "##{dom_id(product, :action)}" }, 'aria-controls': 'staticBackdrop' %>
  </td>
  <td><%= product.name %></td>
  <td><%= product.amount %></td>
</tr>
```

```js
// app/javascripts/controllers/canvas_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['closeBtn']

  hide() {
    this.closeBtnTarget.click()
  }
}
```

I'm using the default bootstrap Offcanvas, you can see the documentation to know more detail about the API. And I'm using stimulus to close the button after server request was completed using stimulus action `turbo:submit-end->canvas#hide`, and on `hide()` i just triggered the click button in the close button DOM. 

The client code is completed, and now we see the server code:
```rb
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def update
    @product = Product.find params[:id]
    @product.update!(product_params)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :amount)
  end
end
```

```
<%# app/views/products/update.turbo_stream.erb %>
<%= turbo_stream.replace(dom_id(@product)) do %>
  <%= render @product %>
<% end %>
```

In this code, we creating the turbo stream component, that we will be the response to the update request. 

Here's the sample response
```html
<turbo-stream action="replace" target="product_47"><template>
   <tr id="product_47">
  <td>
    <a data-bs-toggle="offcanvas" data-bs-target="#action_product_47" aria-controls="staticBackdrop" href="#">47</a>
  </td>
  <td>Chilli con Carne</td>
  <td>215180</td>
</tr>
</template></turbo-stream>
```

Next, we will handle the error submissions. We will show the error message inside the Canvas.

![error-canvas.gif](/assets/error-canvas.gif)

To do that, first, we need to add the validations inside the Product modal.

```rb
# app/models/product.rb
class Product < ApplicationRecord
  validates :name, presence: true
  validates :amount, presence: true
end
```

Then, we need to update the server controller, to handle the new validations:

```rb
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  # ...
  def update
    @product = Product.find params[:id]
    @product.update!(product_params)
    respond_to do |format|
      format.turbo_stream
    end
  rescue ActiveRecord::RecordInvalid => e
    @error = e
    render status: :unprocessable_entity
  end
  # ...
end 
```

```
<%# app/views/update.turbo_stream.erb %>
<% if @error.present? %>
  <%= turbo_stream.update(dom_id(@product, :error)) do %>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
      <span><%= @error %></span>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  <% end %>
<% else %>
  <%= turbo_stream.replace(dom_id(@product)) do %>
    <%= render @product %>
  <% end %>
<% end %>
```

When update failed, we respond with a 422 status code, and inside the response body we return the turbo_stream update component to update a DOM that we already reserved in the view. That DOM is reserved to show the alert error message.

Here's the updated view code:

```
<%# app/views/products/index.html.erb %>
<div class="offcanvas-body">
  <div id="<%= dom_id(product, :error) %>"></div>
  <%= form_with(model: product, data: { action: 'turbo:submit-end->canvas#hide' }) do |form| %>
    <div class="mb-3">
      <%= form.label :name, class: 'form-label' %>
      <%= form.text_field :name, class: 'form-control', value: product.name %>
    </div>
    <div class="mb-3">
      <%= form.label :amount, class: 'form-label' %>
      <%= form.number_field :amount, class: 'form-control', value: product.amount %>
    </div>
    <%= form.submit 'Save', class: 'btn btn-link m-0 p-0'  %>
  <% end %>
</div>
```

We create a blank `<div id="<%= dom_id(product, :error) %>"></div>` that we will use to show the bootstrap alert component to show the error message to the customer.

Then, we also need to update our stimulus controller to prevent closing the canvas model when the response was failed due to validations:

```js
// app/controllers/canvas_controller.rb
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['closeBtn']

  hide(event) {
    if(event.detail.success) {
      this.closeBtnTarget.click()
    }
  }
}
```

Done, now the error handling working as we expect.

If you want to see the full of source code, you can see it in [this repository](https://github.com/philiplambok/experiments).

Thank you for the reading, happy hacking!