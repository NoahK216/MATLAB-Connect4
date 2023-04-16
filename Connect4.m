clear
clc
close("all")

%% Initialize

%Import 16 Sprites from SpriteSheet (16 should be reserved for a blank space)
game_scene = simpleGameEngine('SpriteSheet.png',25,25,5,[255,255,255]);

%Making quit a global variable is the best solution I could find as storing user data in the figure seemed more messy and overall worse than having a global variable
global pauseScreen;

%The same is true for the difficulty variables, too many callback functions and uses to be cleanly transfered anywhere other than the figure
global AIdifficulty1;
global AIdifficulty2;

%Initialize the difficulty to zero, AKA human player
AIdifficulty1 = 0;
AIdifficulty2 = 0;


%Must draw empty board here otherwise sliders do not display properly in start screen
drawScene(game_scene, boardToPlot(zeros([6,7]), 1))
    
%Store only the quit variable from the pause menu as the restart button does nothing on start screen
[~, quit] = displayMenu(game_scene, zeros([6,7]), 1, false, true);


%OVERALL LOOP (Runs until User quits the program)
while(~quit)

%Initialize basic variables used all throughout the code
height = zeros([1,7]);
moves = zeros([1,42]);
moveCount = 0;
current_player = 1;
mouseCol = [];
mouseBut = [];

%This is always the score for an empty board
solutions = [-2 -1 0 1 0 -1 -2];

%Create board and lastBoard (Used for dropping animation)
board = zeros([6,7]);
lastBoard = zeros([6,7]);

%Winning and final board state variables
pauseScreen = false;
won = false;
drawn = false;
quit = false;
restart = false;
finalBoardOverlay = [];

%Used in case a larger sprite sheet was needed to reference a white or "blank" sprite
blankSprite = 16;

%Drop constants to determine time between frames when falling
dropSpeed = 0.055;
dropAccel = 0.0025;


%Establish a callback function to quit out of games at any point without pausing for input
set(game_scene.my_figure,'WindowKeyPressFcn',@RetrieveKeyboardData);

%% Main Game Loop

%Bool to keep track of the first round of placement
firstMove = true;

while(~won && ~drawn && ~restart && ~quit)
    %Determine Current player for placing and graphical use
    current_player = 1 + mod(moveCount, 2);

    %Plot the board with the background layer, and use the boardToPlot function to convert the board array to something plottable
    drawScene(game_scene, boardToPlot(board, current_player))

    %Get solutions to be played by bot only if bot is current player
    if  ~firstMove && ((AIdifficulty1~=0) == current_player) || ((AIdifficulty2~=0)*2 == current_player) && (~won && ~drawn && ~quit)
        %Call drawnow so that the current piece is visible in case the server fetch takes a long time
        drawnow;
        solutions = getSolutions(returnPosition(moves, moveCount), solutions);
    end
    
    %Either select a move using the weighted random algorithm or wait for user input   
    if((AIdifficulty1~=0) == current_player)
        mouseCol = chooseAImove(solutions(end,:), adjustWeight(AIdifficulty1));

    elseif((AIdifficulty2~=0)*2 == current_player)
        mouseCol = chooseAImove(solutions(end,:), adjustWeight(AIdifficulty2));

    %User Input
    else
        mouseBut = [];
        %Wait for mouse input to be valid and assign mouseCol to it
        while((isempty(mouseBut) || mouseBut ~= 1) && ~quit && ~restart) && ~(((AIdifficulty1~=0) == current_player) || ((AIdifficulty2~=0)*2 == current_player))

            %Get mouse button and position
            [mouseRow,mouseCol,mouseBut] = getMouseInput(game_scene);

            %Set quit to true if escape is pressed on the keyboard during this time
            pauseScreen = pauseScreen || (mouseBut == 27);

            %Display the menu if the pause screen has been called
            if(pauseScreen)
               [restart, quit] = displayMenu(game_scene, board, current_player, false, false);
            end
        end
    end
    

    %If the attempted move is playable, place the stone, if not return back to the start of the loop
    if (~quit && ~restart && canplay(won, height, mouseCol))
        %Set current height at column to 1 or 2 (For Red or Yellow)
        newHeightAtCol = height(mouseCol)+1;
        board(newHeightAtCol, mouseCol) = current_player;
        height(mouseCol) = newHeightAtCol;

        %Update moves to reflect last placed stone
        moveCount = moveCount + 1;
        moves(moveCount) = mouseCol;

        %Check if the last move won the game and save an overlay array if it did
        [won,finalBoardOverlay] = gamewon(board, height, moves, moveCount);


        %Animate stones falling, and collision
        for i = 1:9-height(mouseCol)
            stoneFall = zeros([6,7]);

            %Set stone row to the current row of the stone, or the lowest placeable spot (done for animation of bouncing)
            stoneRow = min(i,7-height(mouseCol));

            %Add 3 to current player value if i equals 8 in order to add the little bounce animation
            stoneFall(stoneRow,mouseCol) = current_player + (i == 8-height(mouseCol))*3;

            %Draw the scene with the previous board in place, and the falling stone overlayed (Both with not current stone displayed up top)
            drawScene(game_scene, boardToPlot(lastBoard, blankSprite), boardToPlot(flip(stoneFall),blankSprite));
            
            %Pause for slightly longer during stone bounce, unless the winning move was just played because it looks slightly worse
            if (won && (i == 7-height(mouseCol) || i == 8-height(mouseCol)))
                pauseTime = 0;
            elseif (i == 8-height(mouseCol))
                pauseTime = 0.08;
            else
                %Use the final velocity kinematic equation to determine drop pause time 
                %(stoneRow here is used as a substitution for time and pauseTime is proportional to velocity)
                pauseTime = (dropSpeed - (dropAccel*stoneRow));
            end

            %Pause for the set pauseTime
            pause(pauseTime)

            %Pause in the middle of fall if requested (but not during a bounce because it looks silly)
            if(pauseScreen && ~(i == 7-height(mouseCol) || i == 8-height(mouseCol)))
                %Some adjustments need to be made so that the screen becomes only one layer
                fallingPauseScreen = lastBoard + flip(stoneFall);
                [restart, quit] = displayMenu(game_scene, fallingPauseScreen, current_player, true, false);
            end
        end

        %Set lastboard for use in next drop
        lastBoard = board;
    end


    %Set firstMove to false after first loop (and every subsequent move but that doesn't matter)
    firstMove = false;

    %Calculate if the game is a draw after the last stone has been placed so that the game doesn't end instantly
    if (moveCount == 42 && ~won)
        drawn = true;
    end

end

%Draw scene one final time after game is won to reflect final positions (Inputting 16 for current player will result in the Indicator cell being blank)
if(won==true)
    animateWinIndc(game_scene, board, finalBoardOverlay)
    if(current_player == 1)
        player = "Red";
    else
        player = "Yellow";
    end
    fprintf("%s Won With %d moves!\n",player, moveCount)
else
    fprintf("Draw!\n")
end

%pause the game for three seconds before clearing the board to give players time to take it in (unless the game is restarted or quit)
if(~quit && ~restart)
    pause(3)
end

%Clear the board in preparation for next game
clearBoard(board, game_scene, dropSpeed, dropAccel)

end

%Close figure after game is finished
close("all")


%% Establish functions for playing


function [restart, quit] = displayMenu(game_scene, board, current_player, inFall, startScreen)
    %Import outer global variables into the function
    global pauseScreen;
    global AIdifficulty1;
    global AIdifficulty2;

    %Establish function-wide global variables
    global slider1Val;
    global slider2Val;

    %Done because sliders save values from last opened figure for some reason
    if(startScreen)
        slider1Val = 0;
        slider2Val = 0;
    end

    %Set output variables to both be false by default
    restart = false;
    quit = false;

    %Reference variable used for spacing in text placement
    sceneSize = 875;

    
    % Position vector format: [Xpos Ypos Width Height]
    Slider1 = uicontrol('style','slider','position',[sceneSize*1/6 sceneSize/3 200 20], 'min', 0, 'max', 100);
    set(Slider1, 'Value', AIdifficulty1);
    addlistener(Slider1, 'Value', 'PostSet', @slider1callback);


    Slider2 = uicontrol('style','slider','position',[705 sceneSize/3 200 20], 'min', 0, 'max', 100);
    set(Slider2, 'Value', AIdifficulty2);
    addlistener(Slider2, 'Value', 'PostSet', @slider2callback);



    %Create board used for background during pause screen (takes old board sprites and changes them to be different sprites that look the same but with a gray overlay)
    pauseBoard = board + 8;
    for i = find(pauseBoard == 8)
       pauseBoard(i) = 11;
    end
    pauseBoard = cat(1,[12,12,12,12,12,12,12],flip(pauseBoard,1));
    pauseBoard(1,4) = (current_player*~inFall)+12;

    %Render the newly made board
    drawScene(game_scene, pauseBoard);


    %Establish defaults for text placement
    menuFontSize = 50;
    menuFontColor = [1 1 1];
    menuFontType = 'Eras Bold ITC';

    textOffset = 95;
    textOrigin = sceneSize/2 - 150;

    %Create bounds that if clicked in will trigger different actions
    %Formatted [X1 X2 Y1 Y2]
    startBounds = [358 518 263 310];
    resumeBounds = [307 569 264 313];
    restartBounds = [318 558 360 405];
    quitBounds = [363 512 453 501];
    

    %Messy text establishment
    titleText = text(sceneSize/2, 100, ['{\color{white}Connect ' '\color{red}4}'],'FontSize',84,'FontName', menuFontType, ...
        'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');

    if(startScreen)
        resumeBounds = startBounds;
        resumeText = text(sceneSize/2, textOrigin, 'Start','FontSize',menuFontSize,'Color', menuFontColor,'FontName', menuFontType, ...
            'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');
    else
        resumeText = text(sceneSize/2, textOrigin, 'Resume','FontSize',menuFontSize,'Color', menuFontColor,'FontName', menuFontType, ...
            'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');
    end

    restartText = text(sceneSize/2, textOrigin + textOffset, 'Restart','FontSize',menuFontSize,'Color', menuFontColor,'FontName', menuFontType, ...
        'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');

    quitText = text(sceneSize/2, textOrigin +  2*textOffset, 'Quit','FontSize',menuFontSize,'Color', menuFontColor,'FontName', menuFontType, ...
        'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');

    hintText = text(sceneSize/2, textOrigin +  4*textOffset -30, '*Set AI Level to Zero for human Player','FontSize',12,'Color', menuFontColor,'FontName', menuFontType, ...
    'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');

    AI1levelText = text(sceneSize*1/6 + 12, 670, sprintf("AI 1 Level: %.0f", AIdifficulty1),'FontSize',20,'Color', menuFontColor,'FontName', menuFontType, ...
    'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');

    AI2levelText = text(705 + 12, 670, sprintf("AI 2 Level: %.0f", AIdifficulty2),'FontSize',20,'Color', menuFontColor,'FontName', menuFontType, ...
    'FontUnits','normalized', VerticalAlignment='middle', HorizontalAlignment='center');


    %The main loop used in the pause screen
    mouseBut = [];
    close = false;
    while (isempty(mouseBut) || mouseBut ~= 27 || startScreen) && ~close

        %Get mouse input
        [X,Y,mouseBut] = ginput(1);

        if ~isempty(mouseBut)
            restart = mouseBut == 114;
            quit = mouseBut == 113;
            close = restart || quit;
        end

        if (mouseBut == 1) && ~((isempty(X) || isempty(Y)))
            restart = restart || betweenCoords([X, Y], restartBounds);
            quit = quit || betweenCoords([X, Y], quitBounds);
            close = restart || quit || betweenCoords([X, Y], resumeBounds);
        end

    end
    
    %Delete pause screen elements so they do not display over the normal screen
    delete([titleText resumeText restartText quitText hintText Slider1 Slider2 AI1levelText AI2levelText])

    %Redraw correct screen and set pauseScreen to false
    drawScene(game_scene, boardToPlot(board, current_player))
    pauseScreen = false;

    
    %Set AI difficulty only after exiting the menu as it doesn't matter before that point
    AIdifficulty1 = slider1Val;
    AIdifficulty2 = slider2Val;


    function slider1callback(~, eventdata)
        slider1Val = get(eventdata.AffectedObject, 'Value');
        AI1levelText.String = sprintf("AI 1 Level: %.0f", slider1Val);
    end

    function slider2callback(~, eventdata)
        slider2Val = get(eventdata.AffectedObject, 'Value');
        AI2levelText.String = sprintf("AI 2 Level: %.0f", slider2Val);
    end

    function betweenBounds = betweenCoords(n, bounds)
        betweenBounds = (n(1) > bounds(1))&&(n(1) < bounds(2))&&(n(2) > bounds(3))&&(n(2) < bounds(4));
    end

end


function RetrieveKeyboardData(~,eventdata)
    global pauseScreen;
    %The character that doesn't properly render is the value returned by WindowKeyPressed when escape is hit
    if(eventdata.Character == "")
        %Set quit to true if esacpe is hit
        pauseScreen = true;
    end
end


function moves2int = returnPosition(moves, moveCount)
    %Encode board state as a list of placements for easier searching
    moves2int = "";
    for i = 1:moveCount
            moves2int = moves2int + moves(i);
    end
end


function newSolutions = getSolutions(position, solutions)
    %Make get request to server to find optimal plays given current board state (Done as it proved faster than calculating them on MATLAB since it lacks some important bit hacks)
    url = 'https://connect4.gamesolver.org/solve?pos=';
    data = webread(url + position);
    
    newSolutions = solutions;
    data.score'

    %Add new solutions to the end of the solutions array
    newSolutions(length(data.pos)+1,:) = data.score;
end


function adjWeight = adjustWeight(weight)
    %Used in the weighted random system for a more linear response to level changes
    %Piecewise function that ensures correct move is played after a weight of anywhere above 95
    adjWeight = (weight<95)*((weight/20))^1.3 + (weight>=95)*100;
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

    %Normalize   the newly exponentiated distribution to effectively apply the 
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

    function signNormalizedMat = normalizeMatSign(matrix)
        %Create a matrix of the same width as the input distribution but filled entirely with its lowest value
        mMins = repmat(min(matrix), [1, size(matrix, 2)]);
    
        %This equation turns the lowest value into one and raises every other value accordingly
        signNormalizedMat = matrix - mMins + 1;
    end
end


function board2plot = boardToPlot(board, current_player)
    %Create Matrix for for sprite sheet positions
    board2plot = cat(1,[16 16 16 16 16 16 16],flip(board,1));

    %Spritesheet is made in such a way that adding 3 to board values will give the proper sprite index (Except for the row of 16s just added)
    for i = find(board2plot ~= 16)
        board2plot(i) = board2plot(i) + 3;
    end

    %Change 1,4 to stone about to be placed
    board2plot(1,4) = current_player;
end


function canPlay = canplay(won, height, col)
    %Simple function to determine if a stone can be placed at the current column
    canPlay = ~won && (height(col) < 6);
end


function [won,overlay] = gamewon(board, height, moves, moveCount)
    %Calculate if the last move caused the game to be won
    won = false;
    overlay = [];
    x = moves(moveCount);
    y = height(x);
    

    %Easiest check for win is if the last move topped off a 3 tall tower of the same color
    if (y > 3 && (board(y - 1,x) == board(y,x)) && (board(y-2,x) == board(y,x)) && (board(y-3,x) == board(y,x))) 
        won = true;
        overlay = calculate_overlay(x, y, 0, -1);
    end

    %Otherwise we begin checking a downard diagonal, then horizontal, then upward diagonal
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
        
        %nb is the count of concurrent pieces in line with the just placed piece so if it is greater than 3 the game has been won
        if (nb >= 3)
            won = true;
            overlay = calculate_overlay(x+dx+1, y+(dx*dy)+sign(dy), dx, dy);
            break
        end
    end
end
         

function overlay = calculate_overlay(x, y, dx, dy)
    %Mark Xs on the board starting at (x,y) pointing in the direction of dx*dy

    %Print the input values for debugging
    %fprintf("X:%d Y:%d dX:%d dY:%d",x,y,dx,dy)

    %Take only the signs of dx and dy as they are all that matter for this calculation
    dx = abs(sign(dx));
    dy = sign(dy);
                                                    
    %Create an array filled with 0 for the overlay to be rendered
    overlay = zeros([6,7]);
    for i = 0:3
        %Set the value of the matrix to 6 in the specified direction for 3 pieces away from the winning play
        overlay(y + (i * dy), x + (i * dx)) = 6;
        
    end
    %Flip the overlay and attatch an extra row of blank sprites at the top to match the blank row present already
    overlay = cat(1,zeros([1,7]),flip(overlay,1));
    
end


%Animate the Xs that mark the winning play sweeping across the winning pieces from left to right, top to bottom
function animateWinIndc(game_scene, board, overlay)
    %Get the row and column indexs of all of the markers seperately to make the animation simpler and create a 7X7 array filled with 16s
    [row, col] = find(overlay==6,4);
    newOverlay = zeros([7,7]) + 16;

    for i = 1:4
        newOverlay(row(i),col(i)) = 6;
        drawScene(game_scene, boardToPlot(board, 16), newOverlay)
        pause(0.025)
    end
    drawScene(game_scene, boardToPlot(board, 16), newOverlay)
end


function clearBoard(board, my_scene, dropSpeed, dropAccel)
    for i = 1:7
        %Clear the bottom row of the board and populate the top of the board with zeros to simulate falling
        board(1,:) = [];
        board(6,:) = [0,0,0,0,0,0,0];

        drawScene(my_scene, boardToPlot(board, 16));

        %Simple acceleration equation to speed up pieces slightly as they fall
        pauseTime = dropSpeed - (dropAccel*i);
        
        %Do not pause on last loop for cleaner transition
        if(i ~= 7) 
            pause(pauseTime); 
        end
    end   
end








