require "weakref"
module Extractor
  module Accessor
      def readInLine(file,container)
          File.open(file,"r").each_line do | line |
               container << line.strip unless line.eql? nil or line.strip.empty?
          end
      end

      def readWithCommaSeparate(file,container)
          File.open(file,"r").each_line do | line |
               container << line.split(',')  unless line.eql? nil or line.strip.empty?
          end
      end
    
      #For test
      def readTest(str,container)
          str = " builder, 2.1.2\n   cookiejar,0.3.2\n webmock\n"
          str.each_line do | line |
               container << line.strip.split(',')  
          end
      end
 
      def writeRubyFile(filename,fileContent,mode = 'w')
           File.open(filename,mode) do | file |
               fileContent.each do | content |
                     file.write(content)                                         
               end
           end
           #p "fileContent memory size: #{ObjectSpace.memsize_of fileContent}"
           fileContent = WeakRef.new(fileContent)
           #p "fileContent memory size: #{ObjectSpace.memsize_of fileContent}"
      end 
      
      #2015-07-13
      #url    :gemfile.lock link,
      #choice : 
      def path(url,choice)
      
        if(!File.exist?("./output"))
           Dir.mkdir("./output");
        end 
        arr = url.split('/')
        filename = "output/"+ arr[3] + '#' + arr[4];
        if(!File.exist?(filename))
            Dir.mkdir(filename) #if folder not exist,then creat it.
        end
        filename = filename + "/";
        log = filename + "log";
        fail_file = filename + "failureList";
        if(!File.exist?(log))
            Dir.mkdir(log)
        end
        log = log + "/";
        for i in (5 ... arr.size()-1) do
            filename = filename + arr[i] + "-";
            log  = log + arr[i] + "-";
        end
        filename = filename + arr[arr.size()-1] + ".txt";
        log = log + arr[arr.size()-1]+ '.log'
        if choice == 1
            return filename
        elsif choice == 2
            return log
        elsif choice == 3
            return fail_file
        end
      end
      
      #2015-07-13
      #url  :gemfile.lock link,
      #date :gemfile.lock data
      def output_gemfilelock(url,data)
        log = path(url,2);
        File.open(log,'w') do | file |
            data.each do | content |
                file.write(content + "\n")                                         
            end
        end
      end
      
      #description: license is N/A Move to the bottom
      #input      : data 
      #location   : license location
      #flag       : N/A
      #description: 把 hula,,,https://ruby  这样的信息放到下边
      def sort(input,location,flag = "N/A")
          i = 0;
          j = input.size() - 1;
          while(i != j)
              if input[i] != nil and input[i].split(',')[location] == flag
                 tmp = input[i]
                 input[i] = input[j]
                 input[j] = tmp
                 i = i - 1
                 j = j - 1
              end
              i = i + 1
          end
          i = 0;
          j = input.size() - 1;
          while(i != j)
              if input[i] != nil  and input[i].split(',')[location] == '' 
                 tmp = input[i]
                 input[i] = input[j]
                 input[j] = tmp
                 i = i - 1
                 j = j - 1
              end
              i = i + 1
          end
      end
      #2015-07-13
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

            return licenseUrl,license || ""#数组
          end
          return licenseUrlList[0],""
      end#def getLicenseFromGithub(url)  end
      
      #2015-07-13
      def rubygems(ruby_pair,flag = "close",vs = '')#flag = "close"#避免无限次自调用自己
        
        ruby_name        = ruby_pair.strip.split(',')[0]
        version          = ruby_pair.strip.split(',')[1]
        if !version.eql? nil and version.count('.')  == 1
          version += '.0'
        end
        url = "https://rubygems.org/gems/"
        url += "#{ruby_name}"         unless ruby_name.empty?
        url += "/versions/#{version}" unless version.eql? nil
        
        pair = getHtmlWithAnemone(url) do |page|
                if page == nil
                    p "page not found"
                end
               license = page.doc.css("span.gem__ruby-version").css('p').inner_text
               if license == nil
                p "#{ruby_name} is nil "
               end
               #如果有多个license 那么取第一个
               license = license.split(',')[0]
               version = page.doc.css("i.page__subheading").inner_text
               [version,license]
        end
        
        unless pair.eql? nil
          if pair[1] == 'N/A'
            licenseInfo = ""
            licenseUrl  = getLicenseFromGithub(url)
            if licenseUrl.eql? nil#没有分配内存
              licenseInfo = "Not Found Github Url"
            elsif !licenseUrl.empty?
              licenseInfo = licenseUrl[0]
              pair[1]     = licenseUrl[1] unless licenseUrl[1].empty?
            end
            if flag == "open"
            	p "#{ruby_name},#{pair[0]},#{pair[1]},#{url},#{licenseInfo}\n"
            end
            return "#{ruby_name},#{pair[0]},#{pair[1]},#{url},#{licenseInfo}\n"
            
          else
          	if flag == "open"
            	p "#{ruby_name},#{pair[0]},#{pair[1]},#{url}\n"
            end	
            return "#{ruby_name},#{pair[0]},#{pair[1]},#{url},\n"
          end
        else
            if flag == "close"
                p "#{ruby_name},"
                flag = "open"
                rubygems("#{ruby_name},",flag,version);#内部调用类似于循环
                
            elsif flag == "open"
                p "#{ruby_name},#{vs},,Page not found,\n"
                return "#{ruby_name},#{vs},,Page not found,\n"
            end
          
          #end
        end #end unless
        
      end 
      #description: delete repeat pacakge
      #ruby_pair  : name and version
      def delete_repeat(ruby_pair)
        for i in (0 ... ruby_pair.size) do
            for j in (i+1 ... ruby_pair.size) do
                #strip:删除头部和尾部的所有空白字符。空白字符是指" \t\r\n\f\v"。
                if ruby_pair[i].strip == ruby_pair[j].strip 
                    ruby_pair[j] = "delete"
                end
            end
        end
      end
      #description: 把没找到license 的放在后面
      def append(arr, bb)
        if arr.size == bb.size
            return ;
        end
        for i in (0 ... arr.size) do
            version = arr[i].strip.split(',')[1]
            if !version.eql? nil and version.count('.')  == 1
              version += '.0'
            end
            #去掉重复的
            for k in (i + 1 ... arr.size) do
                if arr[i] == arr[k]
                    arr[k] = "11111111"
                end
            end
            for j in (0 ... bb.size) do
                if arr[i].strip.split(',')[0] == bb[j].strip.split(',')[0] and version == bb[j].strip.split(',')[1]
                    arr[i] = "11111111"
                    break
                end
            end
            
        end
        for i in (0 ... arr.size) do
            if arr[i] != "11111111"
                bb << arr[i] + "\n"
            end
        end
      end
      
      
      def rule(string)
          exact_name          = ''
          exact_version       = '' 
          index_version_begin = 0
          index_version_end   = 0
          flag                = "open"

          #stack 1
          stack1 = Array.new();
    
          #stack 2
          stack2 = Array.new();
    
          result = string =~ /[ ][(]/;# no return nil
    
    
          if (string.size() == 0 ) then
             exact_name = "ERROR";
          #only package name        
          elsif (result == nil)
                for i in (0 ... string.size())  do
                   if (string[i] =~ /[0-9a-zA-Z_-]/)
                      stack1.push(string[i]);
                   else
                      exact_name = "ERROR";
                      break;
                   end
                end
          # name and version
          else       
               for i in (0 ... string.size()) do
                  if (string[i] == ' ' and string[i+1] == '(')
                     break;
                  end    
               end
               #name    
               for j in (0 ... i)  do #string[i] == ' '
                   if (string[j] =~ /[0-9a-zA-Z_-]/)
                      stack1.push(string[j]);
                   else
                      exact_name = "ERROR";                
                      break;
                   end
               end        
        
               if (string =~ /[^!][=]/ )
                  for j in (i ...string.size()) do
                      if (string[j-1] != '!' and string[j] == '=' and string[j+1] == ' ')
                         index_version_begin = j+2;
                         index_version_end   = j+2;
                         for k in (j+2 ... string.size()) do
                            if (string[k] == ',' or string[k] == ')')
                               index_version_end = k;
                               break;
                            end    
                         end
                         break;
                      elsif ((string[j] =~ /[0-9a-zA-Z.><~!=(, ]/)  == nil )
                            exact_name = "ERROR";
                            break;
                      end
                  end
               else
                  for j in (i ... string.size()) do
                     if (string[j] == '=')
                        flag = "close";
                     elsif (string[j] == ',')
                        flag = "open";
                     end
                     if (flag == "open" and (string[j] == ' ' or string[j] == '(') and string[j+1] =~ /[0-9a-zA-Z.]/ )
                        index_version_begin = j+1;
                        index_version_end   = j+1;
                        for k in (j+1 ... string.size()) do
                           if (string[k] == ',' or string[k] == ')')
                               index_version_end = k;
                               break;
                           end
                        end
                        break;
                     elsif ((string[j] =~ /[0-9a-zA-Z.><~!=(, ]/)  == nil )
                            exact_name = "ERROR";
                            break;
                     end
                  end
               end
               #version        
               for k in (index_version_begin ... index_version_end) do
                  if (string[k] =~ /[0-9a-zA-Z.]/)
                     stack2.push(string[k]);
                  else
                     exact_name = "ERROR";
                     break;
                  end
               end
             end    
   
             # return package name and package version    
             if (exact_name == "ERROR")
                return exact_name
             else
                return stack1.join() + "," + stack2.join();
             end
         end # end rule

         #input:input string
         #rs:separate symbol
         #start_1,start_2,start_3:      the start flags of name and version
         #finish_1锛宖inish_2锛宖inish_3:  the end flags of name and version
         # return: failed string list
         #
         #
         def extract_ruby(input,container,rs = '\n',start_1 = "GEM",start_2 = "rubygem",start_3 = "specs",finish_1 = "",finish_2 = "PLATFORMS",finish_3 = "ruby")
             if (input.size() == 0) then
                #puts "string is nil!"
                return nil
             end
    
             index_start = 0;
             index_end   = 0;
             line        = '';
             line1       = ''
             line2       = ''
             flag        = "close";
    
             lines       = Array.new();
             out_lines   = Array.new();#return valid
             succeed     = Array.new();
             failure     = Array.new();
             input.each_line do |line|
                    lines.push(line);
             end
             for i in (0...lines.size()-2) do
                if (lines[i] == "\n" or lines[i] == "")
                    line = "";
                else
                    line = lines[i].strip();
                end
                if (lines[i+1] == "\n" or lines[i+1] == "")
                   line1 = "";
                else
                   line1 = lines[i+1].strip();
                end
                if (lines[i+2] == "\n" or lines[i+2] == "")
                   line2 = "";
                else
                   line2 = lines[i+2].strip();
                end
                #puts line
                if (flag == "close" and line.include? start_1 and line1.include? start_2)
                    for j in (i+2 ... lines.size()-2) do
                        line = lines[j].strip();
                        if line.include? start_3
                            flag        = "open"
                            index_start = j+1;
                            index_end   = i+1;
                        end
                    end
                   
                end
                if (flag == "open" and line.include? finish_1 and line1.include? finish_2 and line2.include? finish_3)
                   #puts "OK1";
                   index_end = i;
                   break;
                end
             end
    
    
             if (index_end > index_start)
                for j in (index_start ... index_end) do
                   if (lines[j] == "\n" or lines[j] == "")
                      line = "ERROR";
                   else
                      line = rule(lines[j].strip());
                   end    
            
                   if (line == "ERROR")
                      failure.push(lines[j].lstrip);
                   else
                      succeed.push(line);
                   end
                end
               container.concat(succeed)
                succeed.clear
               return failure
             else        
               return nil
             end
        end #extract_ruby 
  end
end
