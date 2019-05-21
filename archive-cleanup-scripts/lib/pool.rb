# X11 License, Copyright © 2012, Kim Burgestrand kim@burgestrand.se

require 'thread'

class Pool
  def initialize(size)
    @size = size
    @jobs = Queue.new

    @pool = Array.new(@size) do |i|
      Thread.new do
        Thread.current[:id] = i
        catch(:exit) do
          loop do
            job, args = @jobs.pop
            job.call(*args)
          end
        end
      end
    end
  end

  def schedule(*args, &block)
    @jobs << [block, args]
  end

  def shutdown
    @size.times do
      schedule { throw :exit }
    end
    @pool.map(&:join)
  end
end

=begin
p = Pool.new 20

20.times do |i|
  p.schedule do
    sleep rand(4) + 2
    puts "Job #{i} finished by thread #{Thread.current[:id]}"
  end
end

at_exit { p.shutdown }
=end
