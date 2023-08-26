require 'json'
require 'yaml'
require 'erb'
require 'rake'

$tasks = []
$mutex = Mutex.new
$command = 'create'

task :c
task :create
task :d do
  $command = 'delete'
end
task :delete do
  $command = 'delete'
end

task 'argocd' do
  `kustomize build https://github.com/cal324/apps/base/argocd/?ref=HEAD | kubectl apply -n argocd -f -`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-server --for condition=Ready --timeout=300s`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-dex-server --for condition=Ready --timeout=300s`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-repo-server --for condition=Ready --timeout=300s`
  #sleep 10
end

task 'kind' do
  puts `unset KUBECONFIG; FILE=spec/kind_config.yaml; kind create cluster --config=$FILE`
  puts `kubectl cluster-info --context kind-kind`
end

task 'cluster_api' do
end

task 'capz' do
end

task 'aks' do
end

# Tasks for waiting when tasks are started in parallel
(1..5).each do |i|
  task ('wave' + i.to_s) do
    puts "wave#{i} ..."
    sleep 3
    $tasks.each(&:join)
  end
end

apps = %w(istio monitoring tracing fluent-aggregator database rook kafka)

apps.each do |name|
  # sequential processing
  task name do |task|
    execute_task task.name
  end

  # parallel processing
  task ('@' + name) do |task|
    $tasks << Thread.new do
      execute_task (task.name.gsub(/@/,''))
    end
  end
end

# Definition of tasks to build the entire environment(ex. default, deployment, production ...)
$config = YAML.load(open('config.yaml'))
$config['configs'].each do |env|
  task env['name'] => env['tasks']
end

# default: Revision specifies the current branch
# environment (ex. development, production ...): Follow config.yaml
# other: Determined by task dependencies
#        Direct execution from the rake command line => The default task settings are applied
#        Calls from dependencies => Dependency task settings are applied
def replace(name)
  top_level_tasks = Rake.application.top_level_tasks[0]
  config = $config['configs'].select{|config|config['name'] == top_level_tasks}[0]
  config = $config['configs'].select{|config|config['name'] == 'default'}[0] if config == nil
  if config['name'] == 'default'
    config['targetrevision'] = `git branch --show-current`
    config['values_targetrevision'] = `git branch --show-current`
  end
  yaml = ERB.new(File.read('scripts/sample.yaml')).result(binding)
  File.open("/tmp/#{name}.yaml", 'w') do |file|
    YAML.dump(YAML.safe_load(yaml), file)
  end
end

def execute_task(name)
  replace(name)
  # The default is create, and if delete is specified in the rake command line argument
  if $command == 'create'
    puts `kubectl apply -f /tmp/#{name}.yaml`
    sleep 5
    Applications.new(name).wait
    #puts `rspec -e #{name} spec/post_deploy.spec`
  else $command == 'delete'
    puts `kubectl delete -f /tmp/#{name}.yaml`
  end
end

$DEBUG_FORMAT = "\e[%sm%-65s %-35s %-10s %-10s %-s\e[0m"

module ResourceCommon
  def is_healthy?
    status = (@status == 'Synced' or @status == 'OutOfSync')
    health = (@health == 'Healthy' or @health == '-')
    status and health
  end

  def print_header
    puts %x(date)
    header = [37, 'name', 'kind', 'status', 'health', 'message']
    puts $DEBUG_FORMAT % header
    puts $DEBUG_FORMAT % header.map{|i|'-'*i.size}
  end

  def debug(indent = 0, print_error_only = false)
    puts ' '*indent + $DEBUG_FORMAT % [is_healthy? ? 32 : 31, @name, @kind, @status, @health, @message] #unless (print_error_only and is_healthy?)
  end
end

class Resource
  include ResourceCommon
  attr_accessor :name
  def initialize(resource)
    @resource = resource
    @kind = @resource['kind']
    @name = @resource['name']
    @status = @resource['status']
    @health = @resource.key?('health') ? @resource['health']['status'] : '-'
    @message = (@resource.key?('health') and @resource['health'].key?('message')) ? @resource['health']['message'] : ''
  end
end

class Application
  include ResourceCommon
  attr_accessor :name
  def initialize(name)
    @name = name
    update
  end

  def update
    @json = JSON.parse(%x(kubectl get apps -n argocd #{@name} -o json))
    @kind = @json['kind']
    @status = @json['status']['sync']['status']
    @health = @json.key?('health') ? @json['health']['status'] : '-'
    @message = (@json.key?('health') and @json['health'].key?('message')) ? @json['health']['message'] : ''
  end

  def resources
    @json['status']['resources'].sort{|a,b|a['syncWave'] <=> b['syncWave']}.map do |resource|
      Resource.new(resource)
    end
  end

  def all_ok?
    resources.map{|resource|resource.is_healthy?}.all?
  end

  def wait
    while true
      $mutex.synchronize{debug}
      break if all_ok?
      sleep 10
      update
    end
  end

  def debug
    print_header
    super
    resources.each do |resource|
      resource.debug
    end
    puts ''
  end
end

class Applications < Application
  def debug
    resources.each do |resource|
      app = Application.new resource.name
      app.debug
    end
  end

  def wait
    resources.each do |resource|
      while true
        begin
          app = Application.new resource.name
          app.wait
          break
        rescue => e
          #puts "not found #{resource.name} #{e} ..."
          sleep 1
          #p e.backtrace
        end
      end
    end
  end
end
