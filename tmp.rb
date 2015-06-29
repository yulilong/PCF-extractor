require 'csv'

array = Array.new();

CSV.foreach("11.txt") do | row|
    array << row
end
for i in (0 ... array.size()) do
    puts "#{array[i][0]},#{array[i][1]},#{array[i][2]}\n"
end

p "**************"

def sort(input,location)
    i = 0;
    j = input.size() - 1;
    while(i != j)
        if input[i][location] == "N/A"
            tmp = input[i]
            input[i] = input[j]
            input[j] = tmp
            i = i - 1
            j = j - 1
        end
        i = i + 1
    end
end
a = array
sort(a,2)

for i in (0 ... array.size()) do
    puts "#{array[i][0]},#{array[i][1]},#{array[i][2]}\n"
end
