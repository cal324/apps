require 'json'
require 'rake'

task 'default' => 'develop:kind'

$tasks = []
$mutex = Mutex.new

task 'argocd' do
  `kustomize build https://github.com/cal324/apps/base/argocd/?ref=HEAD | kubectl apply -n argocd -f -`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-server --for condition=Ready --timeout=300s`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-dex-server --for condition=Ready --timeout=300s`
  puts `kubectl wait po -n argocd -l app.kubernetes.io/name=argocd-repo-server --for condition=Ready --timeout=300s`
  #sleep 10
end

task 'kind' do
  puts `FILE=spec/kind_config.yaml; kind create cluster --config=$FILE`
  puts `kubectl cluster-info --context kind-kind`
end

task 'cluster_api' do
end

task 'capz' do
end

task 'aks' do
end

(1..5).each do |i|
  task ('wave' + i.to_s) do
    puts "wave#{i} ..."
    sleep 3
    $tasks.each(&:join)
  end
end

apps = %w(istio monitoring tracing fluent-aggregator database rook)

apps.each do |name|
  task name do |task|
    execute_task task.name
  end

  task ('@' + name) do |task|
    $tasks << Thread.new do
      execute_task (task.name.gsub(/@/,''))
    end
  end
end

namespace :develop do
  task :kind => %w(kind argocd istio @tracing @monitoring wave1 @fluent-aggregator @database wave2)
  task :capz => %w(cluster_api capz argocd @istio @rook wave1 @tracing @monitoring wave2 @fluent-aggregator @database wave3)
  task :aks  => %w(aks argocd istio @tracing @monitoring wave1 @fluent-aggregator @database wave2)
end

namespace :main do
  task :kind => %w(kind argocd istio @tracing @monitoring wave1 @fluent-aggregator @database wave2)
  task :capz => %w(cluster_api capz argocd @istio @rook wave1 @tracing @monitoring wave2 @fluent-aggregator @database wave3)
  task :aks  => %w(aks argocd istio @tracing @monitoring wave1 @fluent-aggregator @database wave2)
end

def execute_task(name)
  branch, kubernetes = Rake.application.top_level_tasks[0].split(':')
  puts `erb revesion=#{branch} kubernetes=#{kubernetes} sample/#{name}.yaml | kubectl apply -f -`
  sleep 5
  Applications.new(name).wait
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
