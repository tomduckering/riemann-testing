class RiemannRunner
  
  def initialize(config_file:, silence_riemann_output: true)
    @config_file = config_file
    @silence_riemann_output = silence_riemann_output
    @pid = nil
    @riemann_port = 5555
    
    @output_target = :out
    if @silence_riemann_output
      @output_target = "/dev/null"
    end
    
    
    abort("riemann is not on the PATH") unless system("which riemann > /dev/null 2>&1")
  end
  
  def is_port_open?(ip, port,timeout_in_seconds=30,sleep_time_in_seconds=1)
    puts "Waiting for port #{port} on #{ip} to open" unless @silence_riemann_output
    begin
      Timeout::timeout(timeout_in_seconds) do
        begin
          s = TCPSocket.new(ip, port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep(sleep_time_in_seconds)
          retry
        end
      end
    rescue Timeout::Error
      puts "It never opened. Abandoning." unless @silence_riemann_output
      return false
    end
  end
  
  def start()
    puts "Starting riemann with config: #{@config_file}" unless @silence_riemann_output
    @pid = Process.spawn("riemann start #{@config_file}", [:out,:err]=>@output_target)
    Process.detach @pid
    if is_port_open?("127.0.0.1",@riemann_port)
      puts "Riemann is listening" unless @silence_riemann_output
    else
      puts "Nothing listening on #{@riemann_port}. Seems like Riemann didn't start properly."
    end
  end
  
  def reset()
    puts "Resetting Riemann with SIGHUP to #{@pid}" unless @silence_riemann_output
    Process.kill("HUP",@pid)
  end
  
  def stop()
    puts "Terminating Riemann with SIGTERM to #{@pid}" unless @silence_riemann_output
    Process.kill("TERM",@pid)
  end

end
