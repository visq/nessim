#!/usr/bin/env ruby
#
# Yay!
# netsim - Fun simulating sensor nodes
#
# For simulation, we have
#  - actors, which are either stimulated or react on events (messages)
#  - messages, which have sender, receiver, action (triggering a receiver method) and id
#  - channels (with properties such as reliability and delay) between actors

# Basic Ontology

class Message
  attr_reader :sender, :receiver, :id, :action
  def initialize(sender, receiver, id, action = :message)
    @sender, @receiver, @id, @action = sender, receiver, id, action
  end
  def to_s
    "#<Message #{id}: #{sender.actorid}->#{receiver.actorid}.#{action}>"
  end
end

class Channel
  def initialize(system)
    @system = system
  end
  def schedule_receive(msg, time)
    @system.schedule(time) {
      msg.receiver.send(msg.action, msg)
    }
  end
end

class Actor
  attr_reader :actorid, :system
  attr_reader :stats
  def initialize(actorid,system)
    @actorid, @system = actorid, system
    @stats = Statistics.new
  end
  def trace(key, msg)
    @stats.tick(key)
    @system.trace(msg)
  end
  def to_s
    "#<Actor #{actorid}>"
  end
end

# The system

class Job
  attr_reader :time, :job
  def initialize(time, job)
    @time, @job = time, job
  end
  def run
    @job.call
  end
  def before(o)
    @time < o.time
  end
end

class System
  attr_reader :time, :channels
  def initialize
    @channels = {}
    reset
  end
  
  def reset
    @time = 0
    @table = PQueue.new(proc{|x,y| x.before(y)})
  end
  
  # delays a task for time t
  def delay(t)
    proc = callcc { |cont| Proc.new { cont.call(nil) } }
    if proc
      @table.push(Job.new(@time + t,proc))
      @cont.call
    end
  end
  
  # schedule a proc at time t
  def schedule(t, &proc)
    @table.push(Job.new(t,proc))
  end

  # run simulation
  def run
    while(! @table.empty?)      
      job = @table.pop
      @time = job.time
      callcc { |syscont|
        @cont = syscont
        job.run
      }
    end
  end
  
  def send(msg)
    channel = channels[ [msg.sender.actorid, msg.receiver.actorid] ]
    raise Exception.new("no such channel for #{msg}") unless channel
    channel.send(msg)
  end
  
  def trace(msg)
    printf("[TRACE %4d] %s\n",@time,msg) if $TRACE
  end
end

# A few default implementations

class LossyChannel < Channel
  def initialize(delay, loss_prob, system)
    super(system)
    @delay = delay
    @loss_prob = loss_prob
  end
  def send(msg)
    if(rand >= @loss_prob)
      schedule_receive(msg, @system.time + @delay)
    end
  end
end


# Helping Friends
require 'pqueue'

class Statistics
  attr_reader :histo
  def initialize
    @histo = {}
  end
  def tick(key)
    @histo[key]=0 unless @histo[key]
    @histo[key] += 1
  end
end
