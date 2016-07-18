%% Main function to generate tests
function tests = GetMaximaTest
    tests = functiontests(localfunctions);
end

%% Test Functions
% test localisation of Maxima
function testLocalisation(testCase)
    X = 10;
    Y = 10;
    spectrum = zeros(Y,X);
    spectrum(4:5,3) = 6;
    spectrum(8,9) = 7;
    spectrum(8,2) = 4;
    spectrum(1,5) = 2;
    spectrum(3,7:8) = 5;
    backround = 0;
    cut = 0;
    
    actSolution = GetMaxima(spectrum,backround,cut,X,Y);
    expSolution = [9, 8, 7; 3, 4, 6; 3, 5, 6; 7, 3, 5; 8, 3, 5; 2, 8, 4; 5, 1, 2].';
    verifyEqual(testCase,actSolution,expSolution)
end


% Test discarding of backround
function testBackround(testCase)
    X = 10;
    Y = 10;
    spectrum = zeros(Y,X);
    spectrum(4:5,3) = 6;
    spectrum(8,9) = 7;
    spectrum(8,2) = 4;
    spectrum(1,5) = 2;
    spectrum(3,7:8) = 5;
    backround = 4;
    cut = 0;
    
    actSolution = GetMaxima(spectrum,backround,cut,X,Y);
    expSolution = [9, 8, 7; 3, 4, 6; 3, 5, 6; 7, 3, 5; 8, 3, 5].';
    verifyEqual(testCase,actSolution,expSolution)
end

% Test cutout from spectrum
function testCutout(testCase)
    X = 10;
    Y = 10;
    spectrum = zeros(Y,X);
    spectrum(4:5,3) = 6;
    spectrum(8,9) = 7;
    spectrum(8,2) = 4;
    spectrum(2,5) = 2;
    spectrum(3,7:8) = 5;
    backround = 0;
    cut = 2;
    
    actSolution = GetMaxima(spectrum,backround,cut,X,Y);
    expSolution = [9, 8, 7; 3, 4, 6; 7, 3, 5; 2, 8, 4].';
    verifyEqual(testCase,actSolution,expSolution)
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
	testCase.TestData.origPath = pwd;
	cd('..');
end

function teardownOnce(testCase)  % do not change function name
	cd(testCase.TestData.origPath);
end