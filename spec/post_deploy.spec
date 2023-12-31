require 'json'

def get_prometheus_metrics(query)
    result = %x(curl --resolve az-prometheus:30080:127.0.0.1 http://az-prometheus:30080/api/v1/query_range --data-urlencode 'query=#{query}' -d "start=`date +%s -d '10 minutes ago'`" -d "end=`date +%s`" -d 'step=60s' -s)
    debug result
    JSON[result]['data']['result'].first['values']
end

def debug(data)
  puts ''
  puts '======================== DEBUG BEGIN ========================'
  p data
  puts '======================== DEBUG END   ========================'
end

RSpec.describe 'Confirmation of post-deploy operation' do

  it 'logging: Ability to reference fluentd information in prometheus.' do
    values = get_prometheus_metrics 'fluentd_output_status_emit_count{type="loki"}'
    expect(values.count).to be >= 1
    expect(values.last[1].to_i).to be >= 1
  end

  it 'logging: Ability to reference fluent-bit information in prometheus.' do
    values = get_prometheus_metrics 'fluentbit_output_proc_records_total'
    expect(values.count).to be >= 1
    expect(values.last[1].to_i).to be >= 1
  end

  it 'database: The version table must be selectable in TiDB.' do
    result = %x(mysql --comments -h 127.0.0.1 -P 30002 -u root -e 'SELECT version();')
    debug result
    expect(result).to match /version\(\)/
    expect(result).to match /TiDB/
  end

  it 'kafka: Ability to communicate' do
    require 'rdkafka'
    config = {
      :"bootstrap.servers" => "127.0.0.1:30004",
    }

    producer = Rdkafka::Config.new(config).producer
    delivery_handles = []

    delivery_handles << producer.produce(
      topic:   "my-topic",
      payload: "Payload test",
      key:     "Key test"
    )
    delivery_handles.each(&:wait)

    config = {
      :"bootstrap.servers" => "127.0.0.1:30004",
      :"group.id" => "ruby-test"
    }

    consumer = Rdkafka::Config.new(config).consumer
    consumer.subscribe("my-topic")

    result = 'no result'
    consumer.each do |message|
      result = message
      debug result
      break
    end

    expect(result.payload).to match /Payload test/
  end

end
