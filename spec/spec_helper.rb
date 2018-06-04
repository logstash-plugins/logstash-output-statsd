require "logstash/devutils/rspec/spec_helper"
require "socket"

class StatsdServer

  attr_reader :received, :port

  def initialize
    @sync_lock = Mutex.new
    @terminated = false
    @received   = []
  end

  def register(port, protocol)
    @port = port
    if protocol == "udp"
      @socket = UDPSocket.new
      @socket.bind("127.0.0.1", port)
    else
      @socket = TCPserver.new("127.0.0.1", port)
    end
  end


  def run(port, protocol = "udp")
    register(port, protocol)

    Thread.new do
      if protocol == "udp"
        udp_receive
      else
        tcp_receive
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

private

def tcp_receive
  client = @socket.accept
  Timeout.timeout(5) { sleep(0.1) while client.nil? }
  metric = client.recvfrom(100).first
  append(metric)
  client.close
end

def udp_receive
  while(!closed?)
    metric, _ = @socket.recvfrom(100)
    append(metric)
  end
end

RSpec.configure do |c|
  srand(c.seed)
end
