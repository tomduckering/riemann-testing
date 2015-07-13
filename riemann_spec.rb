require 'rspec'
require_relative './fake_logstash'
require_relative './riemann_runner'
require 'riemann/client'

describe "riemann.config" do
  
  before(:all) do
    
    #Start fake logstash listener
    @fake_logstash_server = FakeLogstashServer.new(port: 5665, silent: true)
    @fake_logstash_server.start

    riemann_config_file = self.class.description

    #Start riemann
    @riemann_runner = RiemannRunner.new(config_file: riemann_config_file, silence_riemann_output: true)
    @riemann_runner.start
    
    #Create a client for talking to riemann
    @riemann_client = Riemann::Client.new
  end
  
  before(:each) do
    #reset gathered responses
    @fake_logstash_server.reset_responses
  end
  
  after(:all) do
    @riemann_runner.stop
  end
  
  def query_by_service_name(service_name)
    "service =~ \"#{service_name}\""
  end
  
  def wait_for_riemann_to_send_stuff_back()
    sleep(0.5)
  end
  
  context "basic event indexing" do
    
    it "indexes events we know about" do
      #Given some...
      events = [{host: "host-a", service: "service-to-index", another_field:"boo"}]
      
      #When we send them to riemann
      events.each {|event| @riemann_client << event}
      wait_for_riemann_to_send_stuff_back
      
      expect(@riemann_client[query_by_service_name("service-to-index")]).to_not be_empty
    end
      
    it "does not index random events that we've not catered for" do
      #Given some...
      events = [
        {host: "host-b", service: "unknownservice"}
      ]
      
      events.each {|event| @riemann_client << event}
      wait_for_riemann_to_send_stuff_back
      
      # 'true' is the query for everything - obviously!
      expect(@riemann_client[query_by_service_name("unknownservice%")]).to be_empty
      
    end
  end
  
  context "deals with knowing riemann is plugged in correctly" do
    
    it 'periodically sends events to show that riemann is alive' do
      sleep(10)
      expect(@fake_logstash_server.responses).to include a_hash_including(service: "riemann-is-alive")
    end
  end

  context "forwarding events to logstash" do
    it "sends events to logstash that we expect" do
      #Given some...
      events = [{host: "host-c", service: "send-to-logstash"}]
      
      # When I lob them at riemann
      events.each {|event| @riemann_client << event}
      wait_for_riemann_to_send_stuff_back
            
      #I should get a reponse as I expect.
      expect(@fake_logstash_server.responses).to include a_hash_including(host: "host-c", service: "send-to-logstash", tags:["seen-by-riemann"])
      
    end
    
    it "does not send events to logstash that we don't want sent to logstash" do
      #Given some...
      events = [{host: "host-d", service: "do-not-send-to-logstash"}]
      
      # When I lob them at riemann
      events.each {|event| @riemann_client << event}
      wait_for_riemann_to_send_stuff_back
      
      expect(@fake_logstash_server.responses).to_not include a_hash_including(host: "host-d", service: "do-not-send-to-logstash", tags:["seen-by-riemann"]) 
    end
  end
end
