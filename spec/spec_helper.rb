require 'logstash/devutils/rspec/spec_helper'
require 'socket'
require 'statsd'

RSpec.configure do |c|
  c.before do
    allow_any_instance_of(Statsd).to receive(:send_to_socket)
  end
end
