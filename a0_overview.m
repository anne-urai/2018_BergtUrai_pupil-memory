
% make sure to add the code path
cd('/Users/anne/Desktop/code/pupil-memory');

set(groot, 'defaultaxesfontsize', 6, 'defaultaxestitlefontsizemultiplier', 1, ...
    'defaultaxestitlefontweight', 'bold', ...
    'defaultfigurerenderermode', 'manual', 'defaultfigurerenderer', 'painters');

% where is the data stored?
global mypath
mypath = '~/Data/pupil-memory';

%% As a reminder: Word number 98 has to be removed from the analysis, because
% there are two words that are labelled "98". There is no data for word number 218.
readInData_aud;

% without removing the luminance fluctuations
readInData_img(0);
readInData_img(1);

% write to csv for Lars
load(sprintf('%s/data/alldata_%s.mat', mypath, 'aud'), 'dat');
writetable(dat, sprintf('%s/data/alldata_words.csv', mypath));

load(sprintf('%s/data/alldata_%s.mat', mypath, 'img_raw'), 'dat');
writetable(dat, sprintf('%s/data/alldata_images.csv', mypath));

% PLOT FIGURES
pupilOverview_aud;
pupilOverview_img;

% DO STATS, MAKE SCATTER PLOTS
figure1;
figure1_correlations;

suppfigure1_emotionratings;
figure2;
logisticRegressionPlots;


