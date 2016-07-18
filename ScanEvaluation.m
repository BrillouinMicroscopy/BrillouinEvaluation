
%set path
path = 'd:\brillouin-microscopy\Messdaten\FocusScan\SelfBuild\meas07\';
dist = 50000;    %scanDistance

% read .tiff files in directory
files = dir(fullfile(path, '*.tiff'));
% get filenumber
FileNum = size(files, 1);


images = cell(FileNum, 1);
IntensitySum = zeros(FileNum, 1);
% read files
for n = 1:1:FileNum
    
    images{n} = imread(fullfile(path, files(n).name));
    
    % sum up files to get overall intensity
    IntensitySum(n) = sum(images{n}(:));
end

%% Plot intensity
figure();
x = linspace(0, dist, FileNum);
plot(x, IntensitySum)
% ylim(1e8*[1.1 1.4]);