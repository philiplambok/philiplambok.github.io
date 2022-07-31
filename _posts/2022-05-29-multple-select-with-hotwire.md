---
layout: post
title:  "Building table with checkboxes using Rails Hotwire"
date:   2022-07-31 11:14:00 +0700
categories: rails, hotwire, dynamic-form
comments: true
published: true
---

Currently, I’m doing [some experiments](https://github.com/philiplambok/experiments) with Hotwire. 

One of my experiments is allowing users to select multiple records with checkbox in one table, and do the same action to that selected records. 

Here’s the sample feature:

![overview](/assets/table-dynamic.gif)

In this blog post i want to share how i build this.

To build this, we can separate two 2 activity, the first one is building the checkbox feature, and the second one is integrating the checkbox feature with our backend. 

On the checkbox feature, I build it with Stimulus.js. 

This is the HTML code

```html
<div data-controller="tables" >
  <%= form_with(url: confirm_destroy_admins_path, method: :post, data: { action: 'turbo:submit-end->tables#modalShow' }) do |form| %>
    <div class="d-flex justify-content-between">
      <h1>Admins</h1>
      <div>
        <%= form.submit 'Delete', 
            class: 'btn btn-danger d-none', 
            data: { 'tables-target': 'deleteBtn' } %>
      </div>
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>
            <%= form.check_box('ids', { multiple: true, data: { action: 'change->tables#toggleAll', 'tables-target': 'masterCheck' } }, 'all', nil) %>
          </th>
          <th>Name</th>
          <th>Email</th>
        </tr>
      </thead>
      <tbody>
        <% @admins.each do |admin| %>
          <tr>
            <td>
              <%= form.check_box('ids', { multiple: true, data: { 'tables-target': 'items', action: 'change->tables#sync' } }, admin.id, nil) %>
            </td>
            <td><%= admin.name %></td>
            <td><%= admin.email %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  <% end  %>
</div>
```

Here’s the JS code:

```js
import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="tables"
export default class extends Controller {
  static targets = ['items', 'masterCheck', 'deleteBtn']

  modalShow(event) {
    new bootstrap.Modal('#confirm-modal').show()
  }

  toggleAll(event){
    this.itemsTargets.forEach((el) => {
      el.checked = event.target.checked
    })
    if(event.target.checked === true){
      this.deleteBtnTarget.classList.remove("d-none")
      this.deleteBtnTarget.classList.add('d-block')
    } else {
      this.deleteBtnTarget.classList.add('d-none')
    }
  }

  sync(_event) {
    const checkedItems = this.itemsTargets.filter((el) => {
      return el.checked == true
    })
    if(checkedItems.length == this.itemsTargets.length){
      this.masterCheckTarget.checked = true
    } else {
      this.masterCheckTarget.checked = false
    }
    if(checkedItems.length > 0){
      this.deleteBtnTarget.classList.remove("d-none")
      this.deleteBtnTarget.classList.add('d-block')
    } else {
      this.deleteBtnTarget.classList.add('d-none')
    }
  }
}
```

There are 2 actions that I create to build the feature, which are `#toggleAll` and `#sycn`. 

`#toggleAll` is the action that is triggered by the master checkbox (checkbox on the table header). And `#sync` is the action that is triggered by every item inside table body. 

After the checkbox behavior is completed, the next thing that we need to build is to show the confirm modal. 

Here's the flow

![confirm modal flow.png](/assets/confirm-modal-flow.png)

Here’s the controller code:

```ruby
class AdminsController < ApplicationController
  def index
    @admins = Admin.all
  end

  def confirm_destroy
    @admins = Admin.where(id: params[:ids])
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @admins = Admin.where(id: params[:ids])
    deleted_records = @admins.size
    @admins.delete_all
    flash[:success] = "Successfully deleted #{deleted_records} records"
    redirect_to admins_index_path
  end
end
```

```erb
<%# app/views/admins/confirm_destroy.turbo_stream.html.erb %>

<%= turbo_stream.update "confirm-modal-content" do %>
  <div class="modal-header">
    <h5 class="modal-title">Are you sure to delete <%= @admins.size %> data?</h5>
    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
  </div>

  <div class="modal-body">
    <p>List the admin's emails</p>
    <% @admins.each do |admin| %>
      <li><%= admin.email %></li>
    <% end %>
  </div>

  <div class="modal-footer">
    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
    <%= button_to 'Yes, please delete', admins_path(ids: @admins.ids), method: :delete, class: 'btn btn-danger'  %>
  </div>
<% end %>
```

And finally, as you see, in the modal we create links for the actually delete actions.

That's all. For the complete code, you can see it in [this repository](https://github.com/philiplambok/experiments). 

Happy hacking!