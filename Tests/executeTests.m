% assume it always fails
exit_code = 1;

% MATLAB runs the test
result = runtests('fitVIPATest.m');

% check the result
if ~logical(nnz(~[result.Passed])) && ~logical(nnz([result.Failed])) && ~logical(nnz([result.Incomplete]))
    exit_code = 0;
end

% write the ExitCode
fid = fopen('ExitCode.txt','w');
fprintf(fid,'%d',exit_code);
fclose(fid);

% Ensure that we ALWAYS call exit that is always a success so that CI doesn't stop
exit(exit_code);