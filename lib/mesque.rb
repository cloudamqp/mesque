require 'mesque/version'
require 'json'

class Mesque
  def initialize(bunny)
    @bunny = bunny
    @q = @bunny.create_channel.queue('mesque', durable: true)
  end

  def enqueue(klass, *args)
    pub(class: klass, args: args)
  end

  def <<(obj)
    vars = obj.instance_variables.map do |k|
      [ k[1..-1], obj.instance_variable_get(k) ]
    end
    pub(class: obj.class, vars: Hash[vars])
  end

  def work(queue = 'mesque')
    @bunny.with_channel do |ch|
      ch.qos 20
      q = ch.queue queue, durable: true
      q.subscribe(ack: true, block: true) do |delivery, props, payload|
        begin
          json = JSON.parse payload, symbolize_names: true
          if json[:args] # Resque 1.x and Sidekiq style
            job = json[:class].constantize
            job.perform(*json[:args])
          elsif json[:vars] # Resque 2.0 style
            job = json[:class].constantize.new
            json[:vars].each do |k, v|
              job.instance_variable_set("@#{k}", v)
            end
            job.work
          end
          ch.acknowledge(delivery.delivery_tag, false)
        rescue Exception => e
          puts "[ERROR] Mesque failed with: #{payload}"
          puts "#{e.inspect}\n  #{e.backtrace.join("\n  ")}"
          ch.reject(delivery.delivery_tag, true)
        end
      end
    end
  end

  private
  def pub(msg)
    @q.publish(msg.to_json, content_type: 'application/json', persistent: true)
  end
end

