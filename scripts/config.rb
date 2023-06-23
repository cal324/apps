require 'yaml'

open('config.yaml'){ |f| YAML.load(f) }.each do |data|
  env, template, output = %w(env template output).map{|i|data[1][i]}
  puts "output: #{output}"
  `. env/#{env}; envsubst < templates/#{template} > ~/apps/#{output}`
end
