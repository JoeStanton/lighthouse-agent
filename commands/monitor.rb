require 'dante'

require_relative '../lib/monitor'
Thread.abort_on_exception=true

class LighthouseAgent
  desc :start_monitor, "Continuously monitor the specified service"
  def start_monitor(system)
    return puts 'Must run as root'.red unless Process.uid == 0
    system = load_system(system)
    Dante::Runner.new(process_name(system)).execute(daemonize: true) { Monitor.start!(system) }
  end

  desc :stop_monitor, "Stop monitoring the specified service"
  def stop_monitor(system)
    return puts 'Must run as root'.red unless Process.uid == 0
    system = load_system(system)
    Dante::Runner.new(process_name(system)).execute(kill: true)
  end
  
  desc :restart_monitor, "Restart monitoring the specified service"
  def restart_monitor(system)
    return puts 'Must run as root'.red unless Process.uid == 0
    stop_monitor(system)
    start_monitor(system)
  end

  no_commands {
    def process_name(system)
      "lighthouse-#{StringHelpers.slugify(system.services.first.name)}"
    end
  }

end
