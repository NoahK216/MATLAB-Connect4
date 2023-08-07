clc
clear

for(nikolaiCount = 1:10)
    for(wholeCount = 1:1000)
        tic()
        for(tCount = 1:1000)
            i = 1;
            while(i < 100)
               A(i) = i;
               i = i + 1;
            end
            time1(tCount) = toc;
        end
        
        
        tic()
        for(tCount = 1:1000)
            i = 1;
            while(i <= 99)
               B(i) = i;
               i = i + 1;
            end
            time2(tCount) = toc;
        end
    
        clear A
        clear B
        clear i
        
        result(wholeCount) = (time1(tCount) < time2(tCount));
    end

clc
percent(nikolaiCount) = mean(result)*100;
fprintf("Nikolai was right %.0f percent of the time\n", percent(nikolaiCount))
end

figure()
plot(percent)
ylim([0 100])
