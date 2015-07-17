require 'anemone'
require './task'
require './utils'
require './accessor'
require './exceptions'
require "weakref"#没用到

module Extractor
  class Extractor
    include Utils,Accessor
  end

  class RubyExtractor < Extractor
    def initialize url,pool_num = 10
      #raise Error.new("File(#{file}) is not exist.") unless File.exist?(file)
      @url               = url
      @getGemFileTask    = Task.new
      @getGemLicenseTask = Task.new(pool_num)
      @gemfile           = {}   #hash table
      @licenseList       = []   #success List string
      @failureList       = []   #failure List
      @gemfileList       = Array.new();
    end

    
    
    def setGemfile
      @getGemFileTask.importQueue(@url,nil,1)
      p = Proc.new do | url | # Proc 代码快
        gemfile      = getHtmlWithAnemone(url) { |page| page.body } #嵌入一个快
        #
        raise Error.new("Page #{url} that you're visiting is not found.") if gemfile.eql? nil
        @gemfile[:name]    = url#raw gemfile.lock link
        @gemfile[:gemfile] = gemfile# gemfile.lock content
        #gemfile.replace("")
      end #end Proc
      @getGemFileTask.execution(p)
      @getGemFileTask.pool_shutdown
    end

    def getGemfile
      @gemfile
    end

    def getGemfile?
       @gemfile.empty?
    end

    def setGemLicense
      raise Error.new("Failed to get Gemfile from #{@url}.") if getGemfile?
      
      @failureList = @getGemLicenseTask.importQueue(@gemfile[:gemfile],:extract_ruby)
      @failureList ||= []
      @gemfileList = @getGemLicenseTask.get_queue();# no have "\n"
      output_gemfilelock(@gemfile[:name],@gemfileList);
      #@getGemLicenseTask.execution(p)
      @getGemLicenseTask.execut();
      @getGemLicenseTask.pool_shutdown
      @licenseList = @getGemLicenseTask.get_licenselist()
      
    end

    def writeFile
      #Write into file
      #filename = "#{@gemfile[:name].split('/')[4]}_output.txt"
      filename = path(@gemfile[:name],1);
      fail_file = path(@gemfile[:name],3);
      
      if !@failureList.empty?
        #@licenseList << "---------Failed to extract name and version-----------\n"
        #@licenseList.concat(@failureList)
        writeRubyFile(fail_file,@failureList,'a')
      end
      #2015-07-06
      sort(@licenseList,2)
      append(@gemfileList,@licenseList)
      writeRubyFile(filename,@licenseList)
      #@gemfile[:gemfile]     = WeakRef.new(@gemfile[:gemfile])
#      p "@licenseList memory size: #{ObjectSpace.memsize_of @licenseList}"
#      p "@getGemLicenseTask memory size: #{ObjectSpace.memsize_of @getGemLicenseTask}"
#      p "@getGemFileTask  memory size: #{ObjectSpace.memsize_of @getGemFileTask }"
      @licenseList     = WeakRef.new(@licenseList)
      @gemfile     = WeakRef.new(@gemfile)
      @getGemLicenseTask     = WeakRef.new(@getGemLicenseTask)
      @getGemFileTask     = WeakRef.new(@getGemFileTask)
      GC.start
#      p "@gemfile memory size: #{ObjectSpace.memsize_of @gemfile}"
#      p "@licenseList memory size: #{ObjectSpace.memsize_of @licenseList}"
#      p "@getGemLicenseTask memory size: #{ObjectSpace.memsize_of @getGemLicenseTask}"
#      p "@getGemFileTask  memory size: #{ObjectSpace.memsize_of @getGemFileTask }"
    end

  end # end RubyExtractor

  class GoExtractor < Extractor
     
  end # end GoExtractor

  class JavaExtractor < Extractor

  end # end JavaExtractor
end
