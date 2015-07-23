require 'csv'

class Compare_new_old
	def initialize(repo,p_new,p_old,out)
		@repo_name      = repo;
		@pcf_new_file   = p_new;
		@pcf_old_file   = p_old;
		@output_file    = out;
		@pcf_new_data   = Array.new();
		@pcf_old_data   = Array.new();
		@final_data     = Array.new();
		@no_change      = "No change"
		@change         = "Version Changed"
		@new		    = "New in 1.5"
	end
	
	def path()
		if(!File.exist?(@output_file))
			Dir.mkdir(@output_file);
		end
		@output_file = @output_file + "/" + @pcf_new_file.split('.')[0] + @pcf_new_file.split('.')[1] + ".csv"
		p "create path succeed!"
	end
	
	def read_data(p14 = @pcf_old_file,p15 = @pcf_new_file)
		#cf-mongodb,terminal-table,1.4.5,https://github.com/tj/terminal-table ,MIT
		#repo_name,name,version,url,license
		if p14 != ''
			CSV.foreach(p14) do | row|
				@pcf_old_data << row
			end
		end
		#aws-sdk,1.60.2,Apache 2.0,https://rubygems.org/gems/aws-sdk/versions/1.60.2 ,github url
		# name,version,licnese,rubygems url,github url
		CSV.foreach(p15) do | row|
			@pcf_new_data << row
		end
		p "read data succeed!"
	end#read_data end
	
	def version_compare(new_v,old_v)
		if new_v == nil or old_v == nil
			return ''
		end
		new = new_v.split('.');
		old = old_v.split('.');
		if new.size == 3 and old.size == 2
			if new[0] == old[0] and new[1] == old[1] and new[2] == '0'
				return "mark"
			end
		end
		return ''
	end
	
	def compare(p14 = @pcf_old_file, pcf15 = @pcf_new_data, pcf14 = @pcf_old_data )
		#p "#{pcf14[2][0]},#{pcf14[2][1]},#{pcf14[2][2]},#{pcf14[2][3]},#{pcf14[2][4]}"
		name 	  = ''
		version15 = ''
		version14 = ''
		url		  = ''
		license   = ''
		license14 = ''
		github15  = ''
		url14     = ''
		tmp       = ''	
		final     = Array.new();
		final << "name,1.5version,1.4version,URL,license,Delta Information,repo_name,PCF1.5_github_url,PCF1.4_url\n"
		if p14 == ''
			for i in (0 ... pcf15.size) do
				name 	  = pcf15[i][0]
				version15 = pcf15[i][1]
				version14 = "None"
				url		  = pcf15[i][3]
				license   = pcf15[i][2]
				github15  = pcf15[i][4]
				final << "#{name},#{version15},#{version14},#{url},#{license},#{@new},#{@repo_name},#{github15},\n"
			end
		else
			for i in (0 ... pcf15.size) do
				flag = "close"
				# no change
				for j in (0 ... pcf14.size) do
					# pcf14 and pcf15  name,version  equal
					if pcf15[i][0] == pcf14[j][1] and pcf15[i][1] == pcf14[j][2]
						# name, 15version,14version,url,license,No change,repo name
						name 	  = pcf15[i][0]
						version15 = pcf15[i][1]
						version14 = pcf14[j][2]
						url		  = pcf14[j][3]
						license   = pcf14[j][4]
				
						final << "#{name},#{version15},#{version14},#{url},#{license},#{@no_change},#{@repo_name},,\n"
						flag = "open"
						break;
					end
				end
				next if flag == "open"
				#change
				for j in (0 ... pcf14.size) do
					# pcf14 and pcf15  name,version  equal
					if pcf15[i][0] == pcf14[j][1] and pcf15[i][1] != pcf14[j][2]
						# name, 15version,14version,url,license,Version Changed,repo name
						name 	  = pcf15[i][0]
						version15 = pcf15[i][1]
						version14 = pcf14[j][2]
						url		  = pcf15[i][3]
						license   = pcf15[i][2]
						license14 = pcf14[j][4]
						github15  = pcf15[i][4]
						url14     = pcf14[j][3]
						tmp       = "#{name},#{version15},#{version14},#{url},#{license},#{@change},#{@repo_name},#{github15},"
						#CSV ,, is nil
						if pcf15[i][2] == '' or pcf15[i][2] == 'N/A' or pcf15[i][2] == nil
							
							tmp += "#{url14},#{license14},"
						else
							tmp += ",,"
						end
						tmp += version_compare(pcf15[i][1],pcf14[j][2])
						
						tmp += ",\n"
						
						final << tmp
						flag = "open"
						break;
					end
				end
				next if flag == "open"
				#new
				if final.size == i+1
					# name, 15version,14version,url,license,New in 1.5,repo name,github URL
					name 	  = pcf15[i][0]
					version15 = pcf15[i][1]
					version14 = "None"
					url		  = pcf15[i][3]
					license   = pcf15[i][2]
					github15  = pcf15[i][4]
					final << "#{name},#{version15},#{version14},#{url},#{license},#{@new},#{@repo_name},#{github15},\n"
				end
			end# end for
			@final_data = final;
		
		end# end if
		p "compare succeed!"
	end#compare() end
	
	def write_file(file_path =@output_file, data = @final_data)
		File.open(file_path,'w') do | file |
			data.each do | content |
			 	file.write(content)                                         
		   	end
		end	
		p "write file succeed!"
	end #write_file() end
	
end# class end


repo_name = "cf-neo4j"
#if repo new  than p14=''
p14 = "PCF-1_4-cf-neo4j.csv"
p15 = "develop-system_test-test_app-Gemfile.lock?token=AJOcPLjP06PjRwNx6M9XwY_E431pv3S1ks5VuJG3wA%3D%3D.txt"
#folder
file_final = "./compare"


com = Compare_new_old.new(repo_name,p15,p14,file_final)

com.path()
com.read_data()
com.compare()
com.write_file()













