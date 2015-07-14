require 'anemone'
require './task'
require './utils'
require './accessor'
require './exceptions'
require "weakref"#û�õ�

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
      p = Proc.new do | url | # Proc �����
        gemfile      = getHtmlWithAnemone(url) { |page| page.body } #Ƕ��һ����
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

    def getLicenseFromGithub(url)
      licenseUrlList ||= []
      licenseName      = ""
      licenseUrl       = ""
      licenseText      = ""

      getHtmlWithAnemone(url) do |page|

        if page.html?
            page.doc.css('a[rel=nofollow]').each do | text |
              hrefValue = text.css("/@href").map(&:value)[0]
              licenseUrlList << hrefValue if text.inner_text == 'Homepage'    and hrefValue =~ /github.com/
              licenseUrlList << hrefValue if text.inner_text == 'Source Code' and hrefValue =~ /github.com/
              text = WeakRef.new(text)
            end
        end
      page = WeakRef.new(page)
      #anemone = WeakRef.new(anemone)
      end
      return nil if licenseUrlList.empty?
      #p "++++++++++++++++++++++"
      unless licenseUrlList[0] =~ /https/
        licenseUrlList[0].gsub!(/http/,'https')
      end
      #p "githubURL : #{licenseUrlList[0]}"
      #page_size = 0
      getHtmlWithAnemone(licenseUrlList[0]) do |page|
        #puts "page memory size: #{ObjectSpace.memsize_of page}"
        if page.html?
          page.doc.xpath("//a[@title]").each do | title |
            if  title.css('/@title').map(&:value).to_s =~ /(copying|license){1}(.[a-zA-Z]{0,})?[^\w\s&quot;-]+/i  and title.css('/@title').map(&:value)[0].to_s[0] =~/c|l/i
              licenseName   =  title.css('/@title').map(&:value)[0]
              licenseName ||= ""
              #p "licenseName : #{licenseName}"
            end
          end
            unless licenseName.empty?
              licenseUrl   = page.doc.css("a[title='#{licenseName}']").css('/@href').map(&:value)[0]
              licenseUrl ||= ""
              break
            end
            #p "licenseUrl : #{licenseUrl}"
        else
          #p "Not get license info , not a html page ?"
          #p "......................"
        end
        page = WeakRef.new(page)
        #puts "page memory size: #{ObjectSpace.memsize_of page}"
      end

      if !licenseUrl.empty?
        licenseUrl = "https://github.com" + licenseUrl
        license    = nil
        #return licenseUrl,""
        #p licenseUrl

        getHtmlWithAnemone(licenseUrl) do |page|
          if page.html?
            rawLicenseUrl = page.doc.css('a#raw-url').css('/@href').map(&:value)[0]
            rawLicenseUrl ||= ""
            if !rawLicenseUrl.empty?
              rawLicenseUrl = "https://github.com" + rawLicenseUrl
              #p "rawLicenseUrl : #{rawLicenseUrl}"
              licenseRaw    = getHtmlWithAnemone(rawLicenseUrl) { |page|  page.doc.css('a').css('/@href').map(&:value)[0]  }
              #"<html><body>You are being <a href=\"https://raw.githubusercontent.com/sporkmonger/addressable/master/LICENSE.txt\">redirected</a>.</body></html>"
              licenseRaw ||= ""
              licenseText   = getHtmlWithAnemone(licenseRaw) { |page| page.body  } unless licenseRaw.empty?
              licenseText ||= ""
              #puts "licenseText memory size: #{ObjectSpace.memsize_of licenseText}"
              license       = ex_word(licenseText.gsub(/\\n/,' ').gsub(/\\t/,' ')) unless licenseText.empty?
              #licenseText = WeakRef.new(licenseText)
              #GC.start
              #p "License : #{license}"
              #p "----------------------------"
              if license =="ERROR"
                license = nil
              end
            end
          end

        #page = WeakRef.new(page)
        end #end block

        return licenseUrl,license || ""#����
      end
      return licenseUrlList[0],""
    end

    def setGemLicense
      raise Error.new("Failed to get Gemfile from #{@url}.") if getGemfile?


      p = Proc.new do |  ruby_pair |
        #p ruby_pair
        ruby_name        = ruby_pair.strip.split(',')[0]
        version          = ruby_pair.strip.split(',')[1]
        #"1.0" => "1.0.0"  Completing
        if !version.eql? nil and version.count('.')  == 1
          version += '.0'
        end
        url = "https://rubygems.org/gems/"
        url += "#{ruby_name}"         unless ruby_name.empty?
        url += "/versions/#{version}" unless version.eql? nil
        
        pair = getHtmlWithAnemone(url) do |page|
                p "url:#{url}"
                if page == nil
                    p "page == nil"
                end
                if page.doc == nil
                    p "page.doc == nil"
                    p page
                    page = getHtmlWithAnemone(url)
                end
                if page.doc.css == nil
                    p "page.doc.css == nil"
                end
               license = page.doc.css("span.gem__ruby-version").css('p').inner_text
               #����ж��license ��ôȡ��һ��
               license = license.split(',')[0]
               version = page.doc.css("i.page__subheading").inner_text
               [version,license]
        #page = WeakRef.new(page)
        end


        unless pair.eql? nil
          if pair[1] == 'N/A'
            licenseInfo = ""
            licenseUrl  = getLicenseFromGithub(url)
            if licenseUrl.eql? nil#û�з����ڴ�
              licenseInfo = "Not Found Github Url"
              #p "++++++++++++++++++++++"
              #p "#{ruby_name},#{version},#{licenseInfo}"
              #p "----------------------"
            elsif !licenseUrl.empty?
              licenseInfo = licenseUrl[0]
              pair[1]     = licenseUrl[1] unless licenseUrl[1].empty?
            end
            @licenseList << "#{ruby_name},#{pair[0]},#{pair[1]},#{url},#{licenseInfo}\n"
          else
            @licenseList << "#{ruby_name},#{pair[0]},#{pair[1]},#{url}\n"
          end
          #p "#{ruby_name},#{pair[0]},#{pair[1]},#{url}\n"
        else
          #licenseList << "#{ruby_name},#{version},#{url},Not Found The Page\n"
          #Adjust searching depth of the URL
          #@getGemLicenseTask.instance_eval do
          #p "enter instance_eval #{ruby_name}..."
          #@queue << "#{ruby_name}," #without version
          p.call("#{ruby_name},")#p�ϱߵ�P �ڲ�����������ѭ��
          #end
        end #end unless
        
      end #end Proc

      @failureList = @getGemLicenseTask.importQueue(@gemfile[:gemfile],:extract_ruby)
      @failureList ||= []
      @gemfileList = @getGemLicenseTask.get_queue();# no have "\n"
      output_gemfilelock(@gemfile[:name],@gemfileList);
      #@getGemLicenseTask.execution(p)
      @getGemLicenseTask.execut();
      @getGemLicenseTask.pool_shutdown
      @licenseList = @getGemLicenseTask.get_licenselist()
      #p "@gemfileList == #{@gemfileList.size}"
      #p "@failureList : #{@failureList.size}"
      #p "@licenseList : #{@licenseList.size}"
      
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
