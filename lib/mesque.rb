require 'mesque/version'

class Mesque
  def initialize(bunny)
    @bunny = bunny
    @q = @bunny.create_channel.queue('mesque', durable: true)
  end

  def enqueue(klass, *args)
    pub(class: klass, args: args)
  end

  def <<(obj)
    vars = obj.instance_variables.map { |k| [k, obj.instance_variable_get(k)] }
    pub(class: obj.class, vars: Hash[vars])
  end

  def work(queue = 'mesque')
    @bunny.with_channel do |ch|
      ch.qos 20
      ch.subscribe(queue, ack: true, block: true) do |delivery, props, body|
        begin
          json = JSON.parse msg, symbolize_keys: true
          if json[:args]
            job = json[:class].constantize
            job.perform(*json[:args]) 
          elsif json[:vars]
            job = json[:class].constantize.new
            json[:vars].each do |k, v|
              job.instance_variable_set("@#{k}", v)
            end
            job.work
          end
          ch.acknowledge(delivery.delivery_tag, false)
        rescue Exception => e
          puts "[ERROR] #{e}"
          ch.reject(delivery.delivery_tag, true)
        end
      end
    end
  end

  private
  def pub(msg)
    @q.publish(msg.to_json, 
               content_type: 'application/json',
               persistent: true)
  end
end

