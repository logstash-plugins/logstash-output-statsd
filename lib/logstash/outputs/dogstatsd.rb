# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# dogstatsd is a fork of the statsd protocol which aggregates statistics, such
# as counters and timers, and ships them over UDP to the dogstatsd-server
# running as part of the Datadog Agent. Dogstatsd adds support for metric tags,
# which are used to slice metrics along various dimensions.
#
# You can learn about statsd here:
#
# * http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/[Etsy blog post announcing statsd]
# * https://github.com/etsy/statsd[statsd on github]
#
# A simple example usage of this is to count HTTP hits by response code; to learn
# more about that, check out the ../tutorials/metrics-from-logs[log metrics tutorial]
#
# Example:
# [source,ruby]
# output {
#  dogstatsd {
#   metric_tags => {
#     "host" => "%{host}"
#   }
#   count => {
#    "http.bytes" => "%{bytes}"
#   }
#  }
# }
class LogStash::Outputs::Dogstatsd < LogStash::Outputs::Base
  ## Regex stolen from statsd code
  RESERVED_CHARACTERS_REGEX = /[\:\|\@]/
  config_name "dogstatsd"

  # The address of the dogstatsd server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connect to on your dogstatsd server.
  config :port, :validate => :number, :default => 8125

  # An increment metric. Metric names as array.
  config :increment, :validate => :array, :default => []

  # A decrement metric. Metric names as array.
  config :decrement, :validate => :array, :default => []

  # A histogram metric, which a statsd timing but conceptually maps to any
  # numeric value, not just durations. `metric_name => value` as hash
  config :histogram, :validate => :hash, :default => {}

  # A count metric. `metric_name => count` as hash
  config :count, :validate => :hash, :default => {}

  # A set metric. `metric_name => "string"` to append as hash
  config :set, :validate => :hash, :default => {}

  # A gauge metric. `metric_name => gauge` as hash.
  config :gauge, :validate => :hash, :default => {}

  # The sample rate for the metric.
  config :sample_rate, :validate => :number, :default => 1

  # The tags to apply to each metric.
  config :metric_tags, :validate => :hash, :default => {}

  public
  def register
    require 'statsd'
    @client = Statsd.new(@host, @port)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    @logger.debug? and @logger.debug("Event: #{event}")

    tags = process_tags(event, @metric_tags)
    metric_opts = { :sample_rate => @sample_rate, :tags => tags }

    @increment.each do |metric|
      @client.increment(event.sprintf(metric), metric_opts)
    end

    @decrement.each do |metric|
      @client.decrement(event.sprintf(metric), metric_opts)
    end

    @count.each do |metric, val|
      @client.count(event.sprintf(metric), event.sprintf(val), metric_opts)
    end

    @histogram.each do |metric, val|
      @client.histogram(event.sprintf(metric), event.sprintf(val), metric_opts)
    end

    @set.each do |metric, val|
      @client.set(event.sprintf(metric), event.sprintf(val), metric_opts)
    end

    @gauge.each do |metric, val|
      @client.gauge(event.sprintf(metric), event.sprintf(val), metric_opts)
    end
  end # def receive

  private
  # Returns an array of tags like ["tag1:value1", "tag2:value2"]
  def process_tags(event, tags)
    tags.map { |k, v| event.sprintf(k) + ':' + event.sprintf(v) }
  end
end # class LogStash::Outputs::Statsd
