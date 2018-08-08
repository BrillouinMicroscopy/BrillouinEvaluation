%% Main function to generate tests
function tests = nfit_4peaksTest
    tests = functiontests(localfunctions);
end

%% Test Functions
% Test maxima and width search
function testMaximaSearch(testCase)
    rng(42); % seed random number generator for comparability
    s = 1:1000;
    [s0, s1, s2, s3, B0, B1, B2, B3, w0, w1, floor] = deal(200, 400, 600, 800, 100, 60, 80, 150, 20, 15, 100);
    start = [210, 410, 590, 790, 24, 13, 110+floor, 55+floor, 75+floor, 140+floor];
    expSolution = [s0, s1, s2, s3, w0, w1, B0+floor, B1+floor, B2+floor, B3+floor];
    lorentziancurve = create_4peaks(s, s0, s1, s2, s3, B0, B1, B2, B3, w0, w1, floor);
	actSolution = NaN(20,size(expSolution,2));
    for jj = 1:20
        lorentziancurve_noise = awgn(lorentziancurve,25,'measured');
        [actSolution(jj,:), ~, ~, ~] = nfit_4peaks(s, lorentziancurve_noise, start, floor);
    end
    actSolution = mean(actSolution,1);
%     figure;plot(lorentziancurve_noise);hold on; plot(FittedCurve);
    verifyEqual(testCase,actSolution,expSolution,'RelTol',[0.001, 0.001, 0.001, 0.001, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01]);
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