require 'csv'

repo_name = "p-rabbitmq"
p14 = "PCF-1_4-p-rabbitmq.csv"
p15 = "develop-Gemfile.lock?token=AJOcPP22Vy5U-jNoQj1n3PcTiie82fVpks5VrfzUwA%3D%3D.txt"

file_final = "./compare"
if(!File.exist?(file_final))
	Dir.mkdir(file_final);
end 

file_final = file_final + "/" + p15.split('.')[0] + p15.split('.')[1] + ".csv"


no_change = "No change"
change    = "Version Changed"
new		  = "New in 1.5"
pcf14 = Array.new();
pcf15 = Array.new();
final = Array.new();

#cf-mongodb,terminal-table,1.4.5,https://github.com/tj/terminal-table ,MIT
#repo_name,name,version,url,license
CSV.foreach(p14) do | row|
    pcf14 << row
end
#aws-sdk,1.60.2,Apache 2.0,https://rubygems.org/gems/aws-sdk/versions/1.60.2 ,github url
# name,version,licnese,rubygems url,github url
CSV.foreach(p15) do | row|
    pcf15 << row
end

#p "#{pcf14[2][0]},#{pcf14[2][1]},#{pcf14[2][2]},#{pcf14[2][3]},#{pcf14[2][4]}"
#p "#{pcf15[2][0]},#{pcf15[2][1]},#{pcf15[2][2]},#{pcf15[2][3]},#{pcf15[2][4]}"
name 	  = ''
version15 = ''
version14 = ''
url		  = ''
license   = ''
github15  = ''
url14     = ''

final << "name,1.5version,1.4version,URL,license,Delta Information,repo_name,PCF1.5_github_url,PCF1.4_url\n"
if p14 == ''
	for i in (0 ... pcf15.size) do
		name 	  = pcf15[i][0]
		version15 = pcf15[i][1]
		version14 = "None"
		url		  = pcf15[i][3]
		license   = pcf15[i][2]
		github15  = pcf15[i][4]
		final << "#{name},#{version15},#{version14},#{url},#{license},#{new},#{repo_name},#{github15},\n"
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
				final << "#{name},#{version15},#{version14},#{url},#{license},#{no_change},#{repo_name},,\n"
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
				github15  = pcf15[i][4]
				url14     = pcf14[j][3]
				final << "#{name},#{version15},#{version14},#{url},#{license},#{change},#{repo_name},#{github15},#{url14}\n"
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
			final << "#{name},#{version15},#{version14},#{url},#{license},#{new},#{repo_name},#{github15},\n"
		end
	end# end for

end# end if


#write file
File.open(file_final,'w') do | file |
	final.each do | content |
     	file.write(content)                                         
   	end
end













