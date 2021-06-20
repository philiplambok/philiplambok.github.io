---
layout: post
title:  "Active Record Encryption"
date:   2021-06-20 10:10:00 +0700
categories: rails, hotwire
comments: true
published: true
---

Hello!

In this article, I will try to share my experience about working with the new feature in Rails: "Active Record Encryption". 

By the way, from now, I will try to writing (also think) in English when publishing an article in this blog because I will try to improve my English skill :)

----

I think in nowadays encryption will be the heart of the application, so I am really excited that Rails will has build-in encryption API (that probably will be released in the upcoming Rails 7). 

I have tried several library about encryption before this, like [lockbox](https://github.com/ankane/lockbox), and [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted). With lockbox, I have a blog post about that: [Enkripsi Data di Rails
](https://philiplambok.github.io/rails,/encryption/2020/05/22/enkripsi-database-di-rails.html), and with attr_encrypted, I am using this in daily work job.

Lockbox is a new library that came in principle "easy to use", you can see from their API, and also they has the build-in feature for migrating legacy data and rotating the keys. But for the attr_encrypted it doesn’t have built-in features like migration data, or rotating keys instead you should think by yourself, but because it’s elder and more popular from Lockbox, I think attr_encrypted is more stable.

But, in this post, I don’t want to explain the comparison of these packages, instead, I want to share about the new active record encryption.

We will talk about:

- How to implement it in the fresh table
- How to migrating the existing plain data to encrypted data
- How to rotate the keys

## Installation

So, first, the installation. We will use the edge of the rails for this, so you can run with this command:

```sh
$ rails new try-active-record-encryption --master --database=mysql -T
```

We will use rails github master branch, since the active record encryption still not released yet when this article was written.

## Add the Active Record Encryption

After we successully generate the rails application, we will run this command to create the needed keys:

```sh
$ bin/rails db:encryption:init
primary_key: 9f8e08d77d121e282d5e6813937fc430
  deterministic_key: gReNA2ZZgi8z5OKLBqqMYPpTVYalhQMp
  key_derivation_salt: q6xHC9V0L1lKd1OPng5Y6MFKoIbEEWYM
```

You can add this to your rails credentials, by running this command:

```sh
$ EDITOR=nano rails credentials:edit
```

And paste the `active_record_encryption` key to that file. Note: you can change the editor (nano) to your favorite terminal editors like vi, vim, or emacs.

After you successfully added the encryption keys, you can implement the encryption in your model. 

Let's create a new model:

```sh
$ rails g model Article title:text body:text
```

I prefer to use `text` field when storing encrypted data since the encrypted data will be overload (it means the size will be bigger rather than plain data). 

So, in the article model, you can implement encrypt like this:

```rb
# app/models/article.rb
class Article < ApplicationRecord
  encrypts :title
end
```

Yups thats it!

And you can try to add new record by console like this:

```
$ bin/rails c
Running via Spring preloader in process 51510
Loading development environment (Rails 7.0.0.alpha)
irb(main):001:0> Article.create title: "Hello, world", body: "sample body"
  TRANSACTION (0.3ms)  BEGIN
  Article Create (0.4ms)  INSERT INTO `articles` (`title`, `body`, `created_at`, `updated_at`) VALUES ('{\"p\":\"LalKiAR0STeNu7QL\",\"h\":{\"iv\":\"NkV+r1FYTZWxBtjJ\",\"at\":\"asWpEcxw7ppd/7zUTDaCPw==\"}}', 'sample body', '2021-06-20 11:15:40.884861', '2021-06-20 11:15:40.884861')
  TRANSACTION (0.7ms)  COMMIT
=> 
#<Article:0x00007fd3ccc19380
 id: 1,
 title: "Hello, world",
 body: "sample body",
 created_at: Sun, 20 Jun 2021 11:15:40.884861000 UTC +00:00,
 updated_at: Sun, 20 Jun 2021 11:15:40.884861000 UTC +00:00>
```

Then it's works! in database we don't store the plain "Hello, world", instead we will store a json string like this:

```
{\"p\":\"ll21rWpxN7Trx9ww\",\"h\":{\"iv\":\"832T/EwP/Cn4Z9ny\",\"at\":\"SlMJtHa+LOWXusPEYfxr8g==\"}}
```

So, we can tell this is the encrypted version of 'Hello, world'.

## Migrating legacy plain data to encrypted data

In this section we will try to encrypt the legacy plain data, in this case that is the body field. In the previous section we already add new record, so now in database we already store plain text which is "sample body".

The first thing to do when want to migrating the plain data to encrypted one is to add this config:

```rb
# config/application.rb
config.active_record.encryption.support_unencrypted_data = true
```

This config to add ability to reading plain data in encypted attributes. So, when can make sure there is no downtime when migration the data.

The second thing is modify the model, to add the `encrypts` callback to body attribute:

```rb
# app/models/article.rb
class Article < ApplicationRecord
  encrypts :title
  encrypts :body
end
```

After that, you can run this command, to migrating the deta

```rb
$ bin/rails c 
irb(main):003:1* Article.all.each do |article|
irb(main):004:1*   article.encrypt
irb(main):005:0> end
  Article Load (0.2ms)  SELECT `articles`.* FROM `articles`
  TRANSACTION (0.2ms)  BEGIN
  Article Update (8.4ms)  UPDATE `articles` SET `articles`.`title` = '{\"p\":\"CboWd5E1pnNWRSiw\",\"h\":{\"iv\":\"V3t5qpnkzHyytRrc\",\"at\":\"MGp/guZeSWyZbYl7Mo0k2Q==\"}}', `articles`.`body` = '{\"p\":\"DtarlSr//ROYII0=\",\"h\":{\"iv\":\"zQvZCEnNP8baDFTn\",\"at\":\"QeMfimZ9Gb5G2rMb5tLZXw==\"}}' WHERE `articles`.`id` = 1
  TRANSACTION (1.1ms)  COMMIT
=> 
[#<Article:0x00007f8af745c5c0
  id: 1,
  title: "Hello, world",
  body: "sample body",
  created_at: Sun, 20 Jun 2021 11:15:40.884861000 UTC +00:00,
  updated_at: Sun, 20 Jun 2021 11:15:40.884861000 UTC +00:00>]
```

So, now the body field is encypted.

```
{\"p\":\"DtarlSr//ROYII0=\",\"h\":{\"iv\":\"zQvZCEnNP8baDFTn\",\"at\":\"QeMfimZ9Gb5G2rMb5tLZXw==\"}}
```

## Rotating the keys

To make sure the app is secure, it's good to keep rotating the secret keys in every spesific time. So, in this section I will share to how rotating keys in active record encryption.

Active record encryption supports multiple secret keys, so we can add new secret key by adding the key like this:

```yml
active_record_encryption:
  primary_key:
    - 9f8e08d77d121e282d5e6813937fc430
    - 121bd2026c924a6e0407b21a79c5a8a8 # the new keys (active)
  deterministic_key: gReNA2ZZgi8z5OKLBqqMYPpTVYalhQMp
  key_derivation_salt: q6xHC9V0L1lKd1OPng5Y6MFKoIbEEWYM
```

So, when we add new keys like this, the new record will use the actived key `121bd2026c924a6e0407b21a79c5a8a8`. And for the old records we still can read since we still have the keys in the credentials file `9f8e08d77d121e282d5e6813937fc430`.

To make all data use the newest secret key, you can do like this:

```rb
Article.all.each do |article|
  article.encrypt
end
```

And after that, you can safe to delete the old key:

```yml
active_record_encryption:
  primary_key: 121bd2026c924a6e0407b21a79c5a8a8
  deterministic_key: gReNA2ZZgi8z5OKLBqqMYPpTVYalhQMp
  key_derivation_salt: q6xHC9V0L1lKd1OPng5Y6MFKoIbEEWYM
```

For rotating keys there is some error in rails guides right now, if you see in [this](https://edgeguides.rubyonrails.org/active_record_encryption.html#rotating-keys), the active keys pointing to the first key, but after i tried in local, the active key will pointing to the last key, I try to fix this guides, if you are interested you can check this [PR](https://github.com/rails/rails/pull/42542).

----

I think that's all, thanks for reading and happy hacking!