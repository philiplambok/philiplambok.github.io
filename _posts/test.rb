# / app/controllers/trains/queue_controller.rb
class Trains::QueueController < ApplicationController
  # ...
  def destroy
    TrainQueueService::Destroy.new(train).perform
  end
end

# / app/services/train_queue_service/destroy.rb
module TrainQueueService
  class Destroy
    def initialize(train)
      @train = train
    end

    # Logic:
    # 1. Kita menaikan antrian dari semua kereta
    # yang antriannya dibawah kereta yang ingin dihapus
    # 2. Lalu, baru kita menghapus kereta yang bersangkutan
    # 3. Terakhir, kita membuatkan lognya.
    def perform
      queue = Train::Queue.find_by(train: @train)
      queues = Train::Queue.where('number < ?', queue.number)
      queues.each(&:decrease_number!)
      _queue = queue
      queue.destroy
      log_message = "Kereta dengan tipe #{@train.name} terhapus dari antrian ke #{_queue.number}"
      Log.create(description: log_message)
    end
  end
end
