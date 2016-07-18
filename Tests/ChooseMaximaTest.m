%% Main function to generate tests
function tests = ChooseMaximaTest
    tests = functiontests(localfunctions);
end

%% Test Functions
% test choosing
function testChoose(testCase)
    X = 10;
    Y = 10;
    maxima = [9, 8, 7; 3, 4, 6; 3, 5, 6; 7, 3, 5; 6, 7, 5; 2, 8, 4; 5, 1, 2].';
    gap = 0;
    
    [actSolution1, actSolution2] = ChooseMaxima(maxima, X, Y, gap);
    expSolution = [[5, 1, 2],[9, 8, 7]];
    verifyEqual(testCase,[actSolution1, actSolution2],expSolution)
end

% test gap
function testGap(testCase)
    X = 10;
    Y = 10;
    maxima = [9, 8, 7; 3, 4, 6; 3, 5, 6; 7, 3, 5; 7, 6, 5; 2, 8, 4; 5, 1, 2].';
    gap = 2;
    
    [actSolution1, actSolution2] = ChooseMaxima(maxima, X, Y, gap);
    expSolution = [[3, 4, 6],[7, 6, 5]];
    verifyEqual(testCase,[actSolution1, actSolution2],expSolution)
end


%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
	testCase.TestData.origPath = pwd;
	cd('..');
end

function teardownOnce(testCase)  % do not change function name
	cd(testCase.TestData.origPath);
end