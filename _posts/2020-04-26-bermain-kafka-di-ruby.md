---
layout: post
comments: true
title:  "Bermain Kafka di Ruby"
date:   2020-04-26 10:10:00 +0700
categories: rails
comments:   true
published: true
---

Akhirnya setelah sekian lama ada waktu untuk balik nulis lagi, hehehe.

Sebenernya belakangan ini lagi banyak waktu lenggang dibanding sebelum-sebelumnya karna mungkin udah sebulan lebih full-time work from home. 

Tapi entah kenapa waktu terbakar untuk hal-hal yang lain, hmnn.

Akhirnya di weekend ini coba belajar hal yang baru, yaitu kafka. Dan seperti biasa setiap belajar yang baru enaknya sambil bikin projek kecil-kecilan.

Untuk yang belum kenal, simplenya kafka itu semacam sidekiq (message bus) tapi bisa dipake di multi server atau *distributed*. Seperti yang kita tahu sidekiq hanya support di single server.

Pada tulisan ini gw coba sharing projek kecil-kecilan yang baru gw buat untuk mengimplementasi kafka di Ruby. Tapi kiita tidak menggunakan port [ruby-kafka](https://github.com/zendesk/ruby-kafka), tapi akan menggunakan [phobos](https://github.com/phobos/phobos).

Yups, karna api dari Phobos, sangat-sangat kawaii <3

Projek kita akan sangat simple, di projek ini kita hanya cukup meyimpan payload yang dikirim lewat public api yang kita siapkan. 

Dari public api itu, kita menambah antrian di kafka kita (Producing), lalu kita membuat sebuah listener yang akan mengkonsumsi antrian yang di kafka, dari listener itu kita akan menyimpan data payloadnya ke database kita. 

Mari kita mulai: 

### Install Kafka di OS X

Sebelumnya pastikan java sudah terinstal dulu.

```
$> brew install kafka
$> zkserver start
$> kafka-server-start /usr/local/etc/kafka/server.properties
```

Jika anda pengguna linux atau windows bisa google sendiri yaa, hehe.

### Membuat projek rails baru

Silahkan buat aplikasi rails baru menggunakan CLI. 

```
$> rails new play-ruby-kafka --api -T --database=mysql
```


### Install Phobos

Silahkan tambahkan gem ini di Gemfile

```rb
gem 'phobos'
```

Lalu jalankan `$> bundle install`.

Setelah phobos terinstall, maka jalankan perintah ini: 

```
$> bundle exec phobos init
```

Maka anda akan digenerate 2 file: 
- `config/phobos.yml` seperti namanya, yaitu tempat mapping topic dan handler dan juga configurasi-configurasi.  
- `phobos_boot.rb` tempat untuk register listenernya.

### Membuat Public API

Kita akan membuat 3 api: membuat antrian, membuat message dan list of messages data.

```rb
# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    resources :queues, only: %i[create]
    resources :messages, only: %i[index create]
  end
end
```

```rb
# frozen_string_literal: true

module Api
  class QueuesController < ApplicationController
    def create
      payload = params[:payload]
      MessageProcedur.producer.publish(
        topic: 'test',
        payload: payload,
        key: 'sample-key'
      )
      render json: { payload: payload }
    end
  end
end
```


```rb
# frozen_string_literal: true

module Api
  class MessagesController < ApplicationController
    def index
      render json: Message.all
    end

    def create
      Message.create!(payload: params[:payload])
    end
  end
end
```

Lalu kita buat `config/initializers/phobos.rb` untuk register tempat config kita:

```rb
Phobos.configure('config/phobos.yml')
```

Untuk procedur `/app/procedures/message_procedur.rb`, kodenya simple saja:

```rb
# frozen_string_literal: true

class MessageProcedur
  include Phobos::Producer
end
```

Dan untuk handler-nya `app/handlers/message_handler.rb`, juga simple saja: 

```rb
# frozen_string_literal: true

require 'net/http'

class MessageHandler
  include Phobos::Handler

  def consume(payload, _metadata)
    uri = URI('http://localhost:4000/api/messages')
    Net::HTTP.post_form(uri, payload: payload)
  end
end
```

Untuk menghindari issue autoloading-nya ada baiknya kita tambahkan autoload ke kedua path tersebut di `config/application.rb`

```rb
config.autoload_paths << Rails.root.join('app', 'procedures')
config.autoload_paths << Rails.root.join('app', 'handlers')
```

Lalu di `phobos_boot.rb`-nya kita register handlernya: 

```rb
require_relative 'app/handlers/message_handler'

Phobos.configure('config/phobos.yml')

listener = Phobos::Listener.new(
  handler: MessageHandler,
  group_id: 'test-1',
  topic: 'test'
)

# start method blocks
Thread.new { listener.start }
```

Dan mapping handlernya di `config/phobos.yml`: 

```yml
listeners:
  - handler: MessageHandler
    topic: test
    # id of the group that the consumer should join
    group_id: test-1
    # Number of threads created for this listener, each thread will behave as an independent consumer.
    # They don't share any state
    max_concurrency: 1
    # Once the consumer group has checkpointed its progress in the topic's partitions,
    # the consumers will always start from the checkpointed offsets, regardless of config
    # As such, this setting only applies when the consumer initially starts consuming from a topic
```

Lalu jalankan `rails server` dan `bundle exec phobos start` (begitu juga dengan kafka-nya). 

Lalu tembak API `POST /api/queues` dengan body

```json
{
  "payload": "Sample payload"
}
```

Lalu anda akan menadapat satu data di `GET /api/messages`

```json
[
  {
    "id": 1,
    "payload": "Sample payload",
    "created_at": "2020-04-26T04:31:25.170Z",
    "updated_at": "2020-04-26T04:31:25.170Z"
  },
]
```

----

Maka, anda berhasil mengimplementasikan kafka di Ruby. Mirip seperti sidekiq, bedanya kita memiliki listener yang jalan terus menerus(lihat `phobos_boot.rb`).

Anda bisa lihat sample codenya di [https://github.com/philiplambok/play-ruby-kafka](https://github.com/philiplambok/play-ruby-kafka)

Sekiranya itu saja untuk tulisan hari ini, happy hacking~
