%% Main function to generate tests
function tests = nfit_2peaksTest
    tests = functiontests(localfunctions);
end

%% Test Functions
% Test maxima and width search
function testMaximaSearch(testCase)
    rng(42); % seed random number generator for comparability
    s = 1:1000;
    [s0, s1, B0, B1, w0, floor] = deal(300, 700, 100, 150, 20, 100);
    start = [310, 690, 24, 110+floor, 140+floor];
    expSolution = [s0, s1, w0, B0+floor, B1+floor];
    lorentziancurve = create_2peaks(s, s0, s1, B0, B1, w0, floor);
	actSolution = NaN(20,size(expSolution,2));
    for jj = 1:20
        lorentziancurve_noise = awgn(lorentziancurve,25,'measured');
        [actSolution(jj,:), ~, ~, ~] = nfit_2peaks(s, lorentziancurve_noise, start, floor);
    end
    actSolution = mean(actSolution,1);
%     figure;plot(lorentziancurve_noise);hold on; plot(FittedCurve);
    verifyEqual(testCase,actSolution,expSolution,'RelTol',[0.001, 0.001, 0.01, 0.01, 0.01]);
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
	testCase.TestData.origPath = pwd;
	cd('..');
end

function teardownOnce(testCase)  % do not change function name
	cd(testCase.TestData.origPath);
end

%% Optional fresh fixtures  
function setup(testCase)  % do not change function name
% open a figure, for example
end

function teardown(testCase)  % do not change function name
% close figure, for example
end