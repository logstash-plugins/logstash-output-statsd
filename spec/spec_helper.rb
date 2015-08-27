require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/dogstatsd'

RSpec.configure do |c|
  c.before do
    allow_any_instance_of(Datadog::Statsd).to receive(:send_to_socket)
  end
end
