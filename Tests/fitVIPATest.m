%% Main function to generate tests
function tests = fitVIPATest
    tests = functiontests(localfunctions);
end

%% Test Functions
% test error of fitting function
function testError(testCase)
    % peakPos was extracted from
    % '20160901_SugarSolution\RawData\Solution_merged.h5->Calibration'
    peakPos = [177.9883349639289 274.4037572964120 350.4270515646328 417.2567485589303];
    VIPAstart = getStartparameters();
    constants = getConstants();
    
    VIPAparams = fitVIPA(peakPos, VIPAstart, constants);
    expSolution = 0;
    verifyEqual(testCase,VIPAparams.error,expSolution, 'AbsTol',1.5e-11);
end

%% Optional file fixtures  
function setupOnce(testCase)  % do not change function name
	testCase.TestData.origPath = pwd;
	cd('..');
end

function teardownOnce(testCase)  % do not change function name
	cd(testCase.TestData.origPath);
end