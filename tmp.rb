

arr = ["123,456","123,456","55",  "46","55","32","1","2","3","4","5","32","1","5"]
bb =  ["123,456","123",   "55,44","46","55","32"]



def delete(arr, bb)
    for i in (0 ... arr.size) do
        #È¥µôÖØ¸´µÄ
            for k in (i + 1 ... arr.size) do
                if arr[i] == arr[k]
                    arr[k] = "use"
                end
            end
        for j in (0 ... bb.size) do
            if arr[i].strip.split(',')[0] == bb[j].strip.split(',')[0] and arr[i].strip.split(',')[1] == bb[j].strip.split(',')[1]
                arr[i] = "use"
                break
            end
        end
        
    end
    for i in (0 ... arr.size) do
        if arr[i] != "use"
            bb << arr[i]
        end
    end
end

delete(arr, bb)
bb.each do |a|
    p a
end
















