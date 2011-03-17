#!/usr/bin/env ruby

# A simple demo

require 'system'

class ActorA < Actor
  attr_reader :timeout, :retries
  def initialize(actorid, timeout, retries, system)
    super(actorid, system)
    @timeout, @retries, @received = timeout, retries, {}
  end
  def sendMessage(msgid, receiver)
    trace(:request, "Send Request Message #{msgid}")
    (@retries + 1).times do |i|
      request = Message.new(self, receiver, msgid)
      @system.send(request)
      trace(:send, "Send Message #{msgid}, retry #{i}")
      system.delay(timeout)
      break if @received[msgid]
    end
  end
  def acknowledge(msg)
    trace(:acknowledged, "Acknowledge Message: #{msg}")
    @received[msg.id] = true
  end
end

class ActorB < Actor
  def initialize(actorid, system)
    super(actorid, system)
  end

  def message(msg)
    trace(:received, "Received Message: #{msg}")

    reply = Message.new(self, msg.sender, msg.id, :acknowledge)
    @system.send(reply)
  end
end

# demo
puts "#{"-"*78}\nUsage Info: ruby demo.rb <demo = 0> <runs = 3> (demo \\in {0,1})\n#{"-"*78}"
demo, runs = (ARGV[0] || 0), (ARGV[1] || 3)
$TRACE = runs < 10

sys = System.new
actA, actB = nil, nil

if demo == 0
  # Simulation of Exercise 1
  actA = ActorA.new(1, 11, 10, sys) # timeout > max_delay(1->2) + max_delay(2->1) !! 
  actB = ActorB.new(2, sys)
  sys.channels[ [1,2] ] = LossyChannel.new(5, 0.5, sys)
  sys.channels[ [2,1] ] = LossyChannel.new(5, 0.5, sys)
else
  # Simulation of Exercise 2
  magic_loss = 1/Math.sqrt(2) # 0.7071
  actA = ActorA.new(1, 11, 1000, sys) # timeout > max_delay(1->2) + max_delay(2->1) !! 
  actB = ActorB.new(2, sys)
  sys.channels[ [1,2] ] = LossyChannel.new(5, magic_loss, sys)
  sys.channels[ [2,1] ] = LossyChannel.new(5, magic_loss, sys)
end
runs.times do |i|
  sys.reset
  sys.trace("=== Run #{i+1} ===")
  sys.schedule(0) { actA.sendMessage(i,actB) }
  sys.run
end
puts("-"*78)
puts "#{actA}\n\t#{actA.stats.histo.inspect}"
puts "#{actB}\n\t#{actB.stats.histo.inspect}"
