require 'mesque/version'
require 'json'

class Mesque
  def initialize(bunny)
    @bunny = bunny
    @q = @bunny.create_channel.queue('mesque', durable: true)
  end

  def enqueue(klass, *args)
    call_hook(:before_enqueue, klass, *args)
    pub(class: klass, args: args)
    call_hook(:after_enqueue, klass, *args)
  end

  def <<(obj)
    call_hook(:before_enqueue, klass)
    vars = obj.instance_variables.map do |k|
      [ k[1..-1], obj.instance_variable_get(k) ]
    end
    pub(class: obj.class, vars: Hash[vars])
    call_hook(:after_enqueue, klass)
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
            args = json[:args]
            call_hook(job, :before_perform, *args)
            job.perform(*args)
            call_hook(job, :after_perform, *args)
          elsif json[:vars] # Resque 2.0 style
            job = json[:class].constantize.new
            json[:vars].each do |k, v|
              job.instance_variable_set("@#{k}", v)
            end
            call_hook(job, :before_perform)
            job.work
            call_hook(job, :after_perform)
          end
          ch.acknowledge(delivery.delivery_tag, false)
        rescue Exception => e
          call_hook(job, :on_failure, e, *args)
          puts "[ERROR] Mesque failed with: #{payload}"
          puts "#{e.inspect}\n  #{e.backtrace.join("\n  ")}"
          ch.reject(delivery.delivery_tag, false)
        end
      end
    end
  end

  private
  def pub(msg)
    @q.publish(msg.to_json, content_type: 'application/json', persistent: true)
  end

  def call_hook(obj, method, *args)
    obj.methods.select{|m| m.to_s.start_with? hook.to_s }.each{ |m| obj.send(m, *args) }
  end
end

