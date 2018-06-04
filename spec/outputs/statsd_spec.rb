# encoding: utf-8
require_relative "../spec_helper"
require "logstash/outputs/statsd"
require "socket"

describe LogStash::Outputs::Statsd do

  describe "registration and close" do
    it "should register without errors" do
      output = LogStash::Plugin.lookup("output", "statsd").new
      expect {output.register}.to_not raise_error
    end
  end

  describe "IO" do
    let(:host) { "localhost" }
    let(:port) { rand(2000..10000) }
    let!(:server) { StatsdServer.new.run(port, protocol) }

    after(:each) { server.close }

    shared_examples "it receives sent data" do
      let(:config) do
        { "host" => host, "sender" => "spec", "port" => port, "protocol" => protocol, "count" => [ "foo.bar", "0.1" ] }
      end
      let(:properties) do
        { "metric" => "foo.bar", "count" => 10 }
      end
      let(:event) { LogStash::Event.new(properties) }

      subject { LogStash::Outputs::Statsd.new(config) }

      before(:each) { subject.register }

      it "should receive data send to the server" do
        subject.receive(event)
        # Since we are dealing with threads and networks,
        # we might experience delays or timing issues.
        # lets try a few times before giving up completely.
        try { expect(server.received).to include("logstash.spec.foo.bar:0.1|c") }
      end
    end

    describe "UDP" do
      let(:protocol) { "udp" }

      context "#send" do
        include_examples "it receives sent data"
      end
    end

    describe "TCP" do
      let(:protocol) { "tcp" }

      context "#send" do
        include_examples "it receives sent data"
      end
    end
  end
end
