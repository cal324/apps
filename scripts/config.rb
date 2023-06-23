require 'yaml'
require 'erb'

CONFIG_FILE = 'values.yaml'
TEMPLATE_FILE = 'template.yaml' 

config = YAML.load(open(CONFIG_FILE))
global = config['global']

config['values'].each do |value|
  group = value.keys[0]
  common = value[group]['common']
  value[group].each do |params|
    app_name, param = params[0], params[1]
    if app_name != 'common'
      yaml = ERB.new(File.read(TEMPLATE_FILE)).result(binding)
      YAML.dump(YAML.load(yaml), File.open("../#{common['path']}/templates/#{app_name}.yaml", 'w'))
    end
  end
end

