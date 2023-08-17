#! /usr/bin/env ruby
require 'json'

$DEBUG_FORMAT = "\e[%sm%-65s %-35s %-10s %-10s\e[0m"

module ResourceCommon
  def is_healthy?
    status = (@status == 'Synced' or @status == 'OutOfSync')
    health = (@health == 'Healthy' or @health == 'null')
    status and health
  end

  def print_header
    header = [37, 'name', 'kind', 'status', 'health']
    puts $DEBUG_FORMAT % header
    puts $DEBUG_FORMAT % header.map{|i|'-'*i.size}
  end

  def debug(indent = 0, print_error_only = false)
    puts ' '*indent + $DEBUG_FORMAT % [is_healthy? ? 32 : 31, @name, @kind, @status, @health] #unless (print_error_only and is_healthy?)
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
    @health = @resource.key?('health') ? @resource['health']['status'] : 'null'
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
    @health = @json.key?('health') ? @json['health']['status'] : 'null'
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
      break if all_ok?
      puts %x(date)
      debug
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
          app.debug
          break
        rescue => e
          puts "not found #{resource.name} #{e} ..."
          p e.backtrace
        end
      end
    end
  end
end


a = Applications.new ARGV[0]
a.wait

