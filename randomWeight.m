clear
clc
close all


%randWeight = randWeight ^ 0.75;

dist = [-2 -1 0 1 0 -1 -2];



chooseAImove(dist, 3)



randWeight = 1:100;
solutions = [];

for k = 1:100
    for i = 1:2000
        solutions(i) = chooseAImove(dist, adjustWeight(k));
    end
    funnymode(k) = sum(solutions==4)/2000;
end

plot(funnymode);

figure()
plot((randWeight))


function adjWeight = adjustWeight(weight)
    for i = 1:length(weight)
        adjWeight(i) = (weight(i)<95)*((weight(i)/20))^1.3 + (weight(i)>=95)*100;
    end
end

function getPlay = chooseAImove(solutions, AIlevel)
    distribution = solutions;
                
    %Remove 100 from the array of solutions to create more accurate normalized values
    distributionAdj = distribution(distribution ~= 100);
                
    %Normalize the matrix so that the lowest value becomes one and all other values are adjusted linearly
    normalizedM = normalizeMatSign(distributionAdj);

    %Dot exponentiate every value in the matrix to AIlevel, this will make all but the highest normalized value shrink signifigantly in the end, or decrease the odds that
    %any but the best option is selected
    exponentiatedDist = normalizedM .^ AIlevel;

    %Normalize the newly exponentiated distribution to effectively apply the 
    finalDist = normalizeMatSign(exponentiatedDist);
                
    %Set the odds equal to the cumulative sum of NormalizedM, the zero at the beggining is present for reinsertion of the 100s for correct column selection
    Odds = [0, cumsum(finalDist./sum(finalDist))]; 
                
    %Initialize the adjusted odds array (This is the final array that will be used to calculate choosen column)
    adjOdds = zeros([1,7]);

    %Offset in used to keep track of how many 100s have been encountered in the original Odds array. Every time one is encountered offset is incremented.
    %This is done so that the final output will have a string of the same value in places where the columns are full, which will cause those columns to never be selected
    offset = -1;

    %For loop representing the 7 columns avaliable to be played
    for i = 1:7
        %If the value at i of original solution provided is not 100 do not change the offset and set adjOdds(i) to the value at odds of i-offset
        if distribution(i) ~= 100
            adjOdds(i) = Odds(i-offset);

        %Increment offset if the value at distribution(i) is 100
        else
            offset = offset + 1;
            adjOdds(i) = Odds(max(i-offset,1));
                        
        end
    end
    
    %The choosen move is determined by the first value in the array greater than a random float between 0 and 1
    getPlay = find(adjOdds>=rand,1,'first');
end

function signNormalizedMat = normalizeMatSign(matrix)
    %Create a matrix of the same width as the input distribution but filled entirely with its lowest value
    mMins = repmat(min(matrix), [1, size(matrix, 2)]);
    signNormalizedMat = matrix - mMins + 1;
end
