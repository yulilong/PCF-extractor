require './accessor'
require './utils'
require 'thread/pool'
module Extractor
  class Task
     include Accessor,Utils
   
     def initialize pool_num = 1
         @queue   = []
         @licenseList       = []   #success List string
         @pool = Thread.pool(pool_num)
     end

     def queue_empty?
         @queue.empty?
     end

     def queue_clear
         @queue.clear 
     end
     
     def get_queue()
        return @queue
     end
     
     def get_licenselist()
        return @licenseList
     end

     def pool_shutdown
       @pool.shutdown
       GC.start
     end



     def importQueue(file,readMethodName,mode = 0)
         queue_clear unless queue_empty?
         if mode == 1
           @queue << file
           #p "tsak + #{@queue}"
           return
         end
         p "size : #{@queue.size}"
         self.send readMethodName.to_sym,file,@queue 
     end

     def execution(exec_block,flag = 0)
       @queue.each do | task |
            #exec_block.call(task)
         @pool.process {
           exec_block.call(task)
           sleep 1
         }
       end
       @pool.wait(:done)
       exec_block = WeakRef.new(exec_block)
     end #execution
     
     
     
     def execut()
        @queue.each do | task |
            @pool.process {
                @licenseList << rubygems(task)
                sleep 1
            }
        end
        #return @licenseList
     end
     

  end #class Task end
end #module Extractor end



















