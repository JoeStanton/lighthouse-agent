require 'docile'
require 'ruby-units'
require 'open-uri'

require 'socket'
require 'timeout'

def success(url)
  open url
  true
rescue Exception => e
  false
end

def listening(port)
  Timeout::timeout(1) do
    begin
      s = TCPSocket.new("127.0.0.1", port)
      s.close
      return true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      return false
    end
  end
rescue Timeout::Error
  false
end

def cpu_load_average
  0.9
end

def memory_usage
  Unit('51MB')
end

def disk_usage(mount = "/")
  `df -P`.lines.each do |r|
    f = r.split(/\s+/)
    if f[5] == mount
      return Unit.new(f[4])
    end
  end
end

def response_time(url)
  '1s'
end

def running(process)
  `pgrep #{process}`
  $?.success?
end

def redis_key_size
  1000
end

class DSL
  def self.load(file)
    system = System.new
    dsl = File.read file
    system.instance_eval dsl, file
    system
  end

  def self.parse(&block)
    system = System.new
    system.instance_eval &block
    system
  end
end

class System
  attr_accessor :services

  def initialize
    @services = []
  end

  # DSL entry point
  def service(name, &block)
    instance = Service.new(name)
    Docile.dsl_eval instance, &block if block_given?
    services << instance
    instance
  end
end

class Node
  attr_accessor :name, :dependencies, :check_interval, :host_check_interval

  def initialize(name)
    @name = name
    @dependencies = []
    @private_ports = []
    @public_ports = []
  end

  def description(value = nil)
    if value
      @description = value
    else
      @description
    end
  end

  def dependency(name)
    @dependencies << name
  end

  def host_health(options = nil, &block)
    if block_given?
      @host_check_interval = options[:interval] || 30
      @host_health = block
    else
      @host_health
    end
  end

  def health(options = {}, &block)
    if block_given?
      @check_interval = options[:interval] || 30
      @health = block
    else
      @health
    end
  end

  def healthy?
    @health.call if @health
  end
end

class Service < Node
  attr_accessor :components

  def initialize(name)
    super
    @components = []
  end

  def component(name, &block)
    instance = Component.new(name)
    Docile.dsl_eval instance, &block if block_given?
    components << instance
    instance
  end
end

class Component < Node
  attr_accessor :private_ports, :public_ports

  def listen(port)
    @private_ports << port
  end

  def public_listen(port)
    @public_ports << port
  end
end
