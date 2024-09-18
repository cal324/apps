require 'json'
require 'ruby-progressbar'
require 'logger'

$mutex = Mutex.new
$DEBUG_FORMAT = "\e[%sm%-65s %-35s %-10s %-10s %-s\e[0m"
$log = Logger.new('/tmp/tw.log')

module ResourceCommon
  def is_healthy?
    status = (@status == 'Synced' or @status == 'OutOfSync')
    health = (@health == 'Healthy' or @health == '-')
    status and health
  end

  def print_header
    $log.info %x(date)
    header = [37, 'name', 'kind', 'status', 'health', 'message']
    $log.info $DEBUG_FORMAT % header
    $log.info $DEBUG_FORMAT % header.map{|i|'-'*i.size}
  end

  def debug(indent = 0, print_error_only = false)
    $log.info ' '*indent + $DEBUG_FORMAT % [is_healthy? ? 32 : 31, @name, @kind, @status, @health, @message] #unless (print_error_only and is_healthy?)
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
      sleep 3
      update
    end
  end

  def debug
    $bar.progress = resources.map{|resource|resource.is_healthy?}.count(true)
    print_header
    super
    resources.each do |resource|
      resource.debug
    end
    $log.info ''
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
          $bar = ProgressBar.create(:title => resource.name, total: app.resources.size)
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
