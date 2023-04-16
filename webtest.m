clc
clear


url = 'https://connect4.gamesolver.org/solve?pos=';

tic
data = webread(url + "4544");
toc

