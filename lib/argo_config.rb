require 'yaml'
require 'erb'

def get_app_yaml_name(group, app_name, common)
  if group == 'kind' or group == 'aks' or group == 'capz'
    "overlays/#{group}/templates/#{app_name}.yaml"
  else
    "#{common['path']}/templates/#{app_name}.yaml"
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



