require "logstash/devutils/rspec/spec_helper"
require "socket"

class StatsdServer

  attr_reader :received, :port

  def initialize
    @sync_lock = Mutex.new
    @terminated = false
    @received   = []
  end

  def register(port)
    @port   = port
    @socket = UDPSocket.new
    @socket.bind("127.0.0.1", port)
  end

  def run(port)
    register(port)
    Thread.new do
      while(!closed?)
        metric, _ = @socket.recvfrom(100)
        append(metric)
      end
    end
    self
  end

  def append(metric)
    @sync_lock.synchronize do
      @received << metric
    end
  end

  def close
    @sync_lock.synchronize do
      @terminated = true
    end
  end

  def closed?
    @terminated == true
  end

end

RSpec.configure do |c|
  srand(c.seed)
end
