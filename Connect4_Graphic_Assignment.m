clear
clc
close("all")

import('simpleGameEngine')

%% Initialize

%Import 16 Sprites from SpriteSheet (16 should be reserved for a blank space)
game_scene = simpleGameEngine('SpriteSheet.png',25,25,5,[255,255,255]);


title_scene = simpleGameEngine('Title.png',64,64,3,[255,255,255]);


titlePlot = zeros(7);
for k = 0:6
    titlePlot(k+1,:) = (1+7*k):(7+k*7);
end
drawScene(title_scene, titlePlot)
title("Title scene for Connect4 (Press Start)")

start = false;

while(~start)
    mouseBut = [];
        while(isempty(mouseBut) || mouseBut ~= 1)
            [mouseRow,mouseCol,mouseBut] = getMouseInput(title_scene);
        end   
    if(mouseRow >= 2 && mouseRow <= 6)
        if(mouseCol >= 3 && mouseCol <= 5)
            start = true;
        end
    end
       
end



close(gcf)
while true

%Initialize board and other Essential Variables
stone = [];
mark = [];
height = zeros([1,7]);
moves = [];
solutions = zeros([1,7]);
current_player = [];
mouseCol = [];

%Create board amd lastBoard (Used for dropping animation)
board = zeros([6,7]);
lastBoard = zeros([6,7]);

%Winning and final board state variables
won = false;
drawn = false;
finalBoardOverlay = [];
dropSpeed = 0.045; %0.045

%Indicate which players will be bot driven
player_1_auto = 1;
player_2_auto = 0;

%Check using the natural log for AI level
randWeight = 10;
randWeight = randWeight ^ 0.75;

%Draw blank board
drawScene(game_scene, boardToPlot(board,16))


%% Main Game Loop

%Bool to keep track of the first round of placement
firstMove = true;

while(~won && ~drawn)
    %Get solutions for current board state if bot is playing (Done to save time if no calculations need to be made)
    if (player_1_auto || player_2_auto)
        solutions = getSolutions(returnPosition(moves), solutions);
    end

    %Determine Current player for placing and graphical use
    current_player = 1 + mod(length(moves), 2);

    %Plot the board with the background layer, and use the boardToPlot function to convert the board array to something plottable
    drawScene(game_scene, boardToPlot(board, current_player))
    title("Static board displayed while user chooses input")

    %Either select a move using the weighted random algorithm or wait for user input    
    if(player_1_auto && current_player == 1)
        mouseCol = chooseAImove(solutions(end,:), randWeight);

    elseif(player_2_auto && current_player == 2)
        mouseCol = chooseAImove(solutions(end,:), randWeight);

    %If it is the users turn wait for input and then place
    else
        %Wait for mouse input to be valid and assign mouseCol to it
    %mouseBut = [];
    %while(isempty(mouseBut) || mouseBut ~= 1)
    %    [mouseRow,mouseCol,mouseBut] = getMouseInput(game_scene);
    %end

    

    end

    %If the attempted move is playable, place the stone, if not return back to the start of the loop
    if (canplay(won, height, mouseCol))

        %Set current height at column to 1 or 2 (For Red or Yellow)
        board(height(1,mouseCol)+1, mouseCol) = current_player;
        height(mouseCol) = 1 + height(mouseCol);
    
        %Update moves to reflect last placed stone
        moves = [moves, mouseCol];

        %Only check if the board is won after the first move (If checked before there will be no X or Y values to evaluate)
        if(~firstMove)
            [won,finalBoardOverlay] = gamewon(board, height, moves);
        end

        %Animate dropping
        for stoneRow = 1:7-height(mouseCol)
            stoneFall = zeros([6,7]);
            stoneFall(stoneRow,mouseCol) = current_player;
            drawScene(game_scene, boardToPlot(lastBoard, 13), boardToPlot(flip(stoneFall),13));
            title("Board displayed while stone drops")
            pause(dropSpeed)
        end
        lastBoard = board;

    end

    %Set wonCount to true after first loop
    firstMove = false;

    if (length(moves) == 42) && (won == false)
        drawn = true;
    end


end

%Draw scene one final time after game is won to reflect final positions (Inputting 13 for current player will result in the Indicator cell being blank)
if(won==true)
    drawScene(game_scene, boardToPlot(board, 13), finalBoardOverlay)
    fprintf("%d WON!\n",length(moves))
end

pause(3)

clearBoard(board, game_scene, dropSpeed)

end


%% Establish functions for playing

function moves2int = returnPosition(moves)
    moves2int = "";
    for i = 1:length(moves)
            moves2int = moves2int + moves(i);
    end
end


function [row, col, button] = liveMouseInfo(obj)


end


function newSolutions = getSolutions(position, solutions)
    %Make get request to server to find optimal plays given current board state
    %Signifigantly more efficent than doing calculations in MATLAB given some of its bitwise limitations
    url = 'https://connect4.gamesolver.org/solve?pos=';
    data = webread(url + position);
    
    newSolutions = solutions;

    newSolutions(length(data.pos)+1,:) = data.score;
end


function signNormalizedMat = normalizeMatSign(matrix)
    %Create a matrix of the same width as the input distribution but filled entirely with its lowest value
    mMins = repmat(min(matrix), [1, size(matrix, 2)]);
    signNormalizedMat = matrix - mMins + 1;
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


function board2plot = boardToPlot(board, current_player)
    %Create Matrix for for sprite sheet positions
    board2plot = cat(1,[16,16,16,16,16,16,16],flip(board,1));

    %Change all zeros in the board to 16 (Reserved blank space in spritesheet)
    for i = find(board2plot == 0)
       board2plot(i) = 3;
    end

    %Change all ones in the board to 4 (Combined board and stone sprite)
    for i = find(board2plot == 1)
       board2plot(i) = 4;
    end

        %Change all twos in the board to 5 (Combined board and stone sprite)
    for i = find(board2plot == 2)
       board2plot(i) = 5;
    end
    
    %Change 1,1 to stone about to be placed
    board2plot(1,4) = current_player;

end


function canPlay = canplay(won, height, col)
    canPlay = ~won && (height(col) < 6);
end


function [won,overlay] = gamewon(board, height, moves)
    won = false;
    overlay = [];
    x = moves(length(moves));
    y = height(x);
    
    if (y > 3 && (board(y - 1,x) == board(y,x)) && (board(y-2,x) == board(y,x)) && (board(y-3,x) == board(y,x))) 
        won = true;
        overlay = calculate_overlay(x, y, 0, -1);
    end

    for dy = -1:1
        nb = 0;

        dx = 1;
        while((x + dx <= 7) && (y + dx * dy <= 6) && y + dx * dy > 0)
            if (board(y + dx * dy, x + dx) == board(y,x))
                nb = nb + 1;
            else; break;
            end 
            dx = dx + 1;
        end


        dx= -1;
        while((x + dx > 0) && (y + dx * dy <= 6) && (y + dx * dy > 0))
            if (board(y + dx * dy, x + dx) == board(y,x))
                nb = nb + 1;
            else; break;
            end
            dx = dx - 1;
        end
        

        if (nb >= 3)
            won = true;
            overlay = calculate_overlay(x+dx+1, y+(dx*dy)+sign(dy), dx, dy);
            break
        end
    end
end
         

function overlay = calculate_overlay(x, y, dx, dy)
    %Mark Xs on the board starting at (x,y) pointing in the vector dx*dy

    %Print the input values for debugging
    %fprintf("X:%d Y:%d dX:%d dY:%d",x,y,dx,dy)

    %Take only the signs of dx and dy as they are all that matter for this calculation
    dx = abs(sign(dx));
    dy = sign(dy);
                                                    
    %Create an array filled with 16 to overlay be rendered
    overlay = zeros([6,7]) + 16;
    for i = 0:3
        %Set the value of the matrix to 6 in the specified direction for 3 pieces away from the winning play
        overlay(y + (i * dy), x + (i * dx)) = 6;
    end
    %Flip the overlay and attatch an extra row of blank sprites at the top to match the blank row present already
    overlay = cat(1,[16,16,16,16,16,16,16],flip(overlay,1));
end


function clearBoard(board, my_scene, dropSpeed)
    for i = 1:7
        %Clear the bottom row of the board and populate the top of the board with zeros to simulate falling
        board(1,:) = [];
        board(6,:) = [0,0,0,0,0,0,0];

        drawScene(my_scene, boardToPlot(board, 13));
        pause(dropSpeed*2);
    end   
end




%% Evaluate

%The most difficult part of this process was the original solving algorithm i adapted from a c++ project. MATLAB lacks
%import features to allow for this math to be done quickly. A week or so ago I decided make requests to an online connect 4 solver
%As it saves time and I can still adequately explain how and why everything happens. I still need to work on the GUI as you can tell but I'm
%Mostly happy with everything. I would like to know if this game engine allows for live mouse updating. I've tried all of the standard methods
%such as 
%get(gca, 'CurrentPoint');
%but for some reason it doesn't like working with the game engine figures. If this could be resolved I would love to know what to do.


