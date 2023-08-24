require 'yaml'
require 'erb'

def get_app_yaml_name(group, app_name, common)
  if group == 'kind' or group == 'aks' or group == 'capz'
    "../overlays/#{group}/templates/#{app_name}.yaml"
  else
    "../#{common['path']}/templates/#{app_name}.yaml"
  end
end

def get_version_from_app_yaml(app_yaml_name)
  begin
    file = File.open(app_yaml_name, 'r')
    yaml = YAML.safe_load(file)
    if yaml['spec']['sources'].nil?
      yaml['spec']['source']['targetRevision']
    else
      yaml['spec']['sources'][0]['targetRevision']
    end
  rescue Errno::ENOENT => e
    puts "Could not open file #{app_yaml_name}. So, create a new file. Don't forget to replace targetRevision: REPLACE_ME"
    'REPLACE_ME'
  end
end

CONFIG_FILE = 'values.yaml'.freeze
TEMPLATE_FILE = 'template.yaml'.freeze

config = YAML.safe_load(File.open(CONFIG_FILE, 'r'))
global = config['global']

config['values'].each do |value|
  group = value.keys[0]
  puts "group: #{group} ..."
  common = value[group]['common']
  value[group].each do |params|
    app_name = params[0]
    param = params[1]
    puts "  app_name: #{app_name}"
    next if app_name == 'common'

    app_yaml_name = get_app_yaml_name(group, app_name, common)
    param['source-targetRevision'] = get_version_from_app_yaml(app_yaml_name)
    yaml = ERB.new(File.read(TEMPLATE_FILE)).result(binding)
    YAML.dump(YAML.safe_load(yaml), File.open(app_yaml_name, 'w'))
  end
end

