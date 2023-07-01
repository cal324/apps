require 'json'

def get_prometheus_metrics(query)
    result = %x(curl --resolve az-prometheus:30080:127.0.0.1 http://az-prometheus:30080/api/v1/query_range --data-urlencode 'query=#{query}' -d "start=`date +%s -d '10 minutes ago'`" -d "end=`date +%s`" -d 'step=60s' -s)
    puts result
    JSON[result]['data']['result'].first['values']
end

RSpec.describe 'Confirmation of post-deploy operation' do

  it 'Ability to reference fluentd information in prometheus.' do
    values = get_prometheus_metrics 'fluentd_output_status_emit_count{type="loki"}'
    expect(values.count).to be >= 1
    expect(values.last[1].to_i).to be >= 1
  end

  it 'Ability to reference fluent-bit information in prometheus.' do
    values = get_prometheus_metrics 'fluentbit_output_proc_records_total'
    expect(values.count).to be >= 1
    expect(values.last[1].to_i).to be >= 1
  end

end
