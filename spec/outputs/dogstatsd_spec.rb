# encoding: utf-8
require 'logstash/outputs/dogstatsd'
require_relative '../spec_helper'

describe LogStash::Outputs::Dogstatsd do
  let(:output) { described_class.new(config) }

  let(:config) do
    {
      'host' => '127.0.0.1',
      'port' => 8125
    }.merge(metric_config)
  end
  let(:metric_config) { {} }

  describe 'registration and close' do
    it 'registers without errors' do
      output = LogStash::Plugin.lookup('output', 'dogstatsd').new
      expect { output.register }.to_not raise_error
    end
  end

  describe '#send' do
    before { output.register }
    subject { output.receive(LogStash::Event.new(event)) }

    let(:event) { { 'something_count' => 10 } }

    context 'increment metrics' do
      let(:metric_config) { { 'increment' => [metric_to_track] } }
      let(:metric_to_track) { 'metric.name.here' }

      context 'with a plain ol metric name' do
        it 'tracks' do
          expect_any_instance_of(Datadog::Statsd).to receive(:send_to_socket)
            .with("#{metric_to_track}:1|c")
          subject
        end
      end

      context 'with tags' do
        let(:metric_config) { super().merge('metric_tags' => ['foo:%{value}']) }
        let(:event) { { 'value' => 'helloworld' } }

        it 'sprintf tags' do
          expect_any_instance_of(Datadog::Statsd).to receive(:send_to_socket)
            .with("#{metric_to_track}:1|c|#foo:helloworld")
          subject
        end
      end
    end

    context 'histogram metrics' do
      let(:metric_to_track) { 'metric.name.here' }
      let(:metric_config) { { 'histogram' => { '%{metric_name}' => '%{track_value}' } } }
      let(:event) { super().merge('metric_name' => metric_to_track, 'track_value' => 123) }

      context 'with event fields in the metric name and value' do
        it 'tracks' do
          expect_any_instance_of(Datadog::Statsd).to receive(:send_to_socket)
            .with("#{metric_to_track}:123|h")
          subject
        end
      end
    end
  end
end
