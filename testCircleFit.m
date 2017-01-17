dataPath = 'd:\Data\#Biotec\Messungen\2017-01-10_Spheroids';

filename = 'Brillouin';

load_path = [dataPath filesep 'RawData'];
save_path = [dataPath filesep 'EvalData'];
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
loadFile = [load_path filesep filename '.h5'];
file = Utils.HDF5Storage.h5bmread(loadFile);

img = file.readPayloadData(1, 1, 10, 'data');

%%
peaks = struct();
peaks.x = [25, 144, 214, 271];
peaks.y = [12, 119, 199, 274];

start = [1, size(img,1), mean(size(img))];

%% start value for circle fit
newxb = 1:size(img,2);

[~, initialCurve] = circle(start, newxb, NaN, -1);
[estimates2b, ~, ~, ~] = fitSpectrum(peaks.x, peaks.y, start);
[~, fittedCurve] = circle(estimates2b, newxb, NaN, -1);

%%
figure;
hold on;
imagesc(img);
plot(peaks.x, peaks.y, 'color', 'red', 'linestyle', 'none', 'marker', 'x', 'markersize', 15, 'linewidth', 2);
t(1) = plot(newxb, initialCurve, 'color', 'red', 'linestyle', '--', 'linewidth', 2);
t(2) = plot(newxb, fittedCurve, 'color', 'green', 'linestyle', '--', 'linewidth', 2);
set(gca, 'yDir', 'reverse');
axis equal;
axis([1 size(img,2), 1, size(img,1)]);
caxis([90 500]);
legend(t, 'Initial','Fitted');