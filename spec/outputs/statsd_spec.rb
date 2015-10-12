# encoding: utf-8
require "logstash/outputs/statsd"
require_relative "../spec_helper"

describe LogStash::Outputs::Statsd do

  let(:host)   { "localhost" }
  let(:port)   { @server.port }

  before(:all) do
    @server = StatsdServer.new.run(random_port)
  end

  after(:all) do
    @server.close
  end

  describe "registration and close" do

    it "should register without errors" do
      output = LogStash::Plugin.lookup("output", "statsd").new
      expect {output.register}.to_not raise_error
    end

  end

  describe "#send" do

    context "count metrics" do

      let(:config) do
        { "host" => host, "sender" => "spec", "port" => port, "count" => [ "foo.bar", "0.1" ] }
      end

      let(:properties) do
        { "metric" => "foo.bar", "count" => 10 }
      end

      let(:event) { LogStash::Event.new(properties) }

      subject { LogStash::Outputs::Statsd.new(config) }

      before(:each) do
        subject.register
      end

      it "should receive data send to the server" do
        subject.receive(event)
        expect(@server.received).to include("logstash.spec.foo.bar:0.1|c")
      end

    end
  end

end
