%% HOW TO USE THIS CODE
% First, change mypath in line 12 to the place where the data is stored.
%
% This folder should look like:
% - mypath
% -- data
% --- alldata_images.csv
% --- alldata_words.csv
% --- alldata_img_raw.mat
% --- alldata_aud.mat
% -- figures
%
% When running the script, each panel will appear as its own small figure
% in the figures folder. Start the script in the folder where the code is
% located, and running it should give the full set of images that make up
% the final figures (except for some Illustrator final touches).
%
% code from: https://github.com/anne-urai/pupil-memory
% any helper functions (mainly for plotting) are at
% https://github.com/anne-urai/Tools, make sure to add these to your path
% as well
%
% Anne Urai, 2018 / anne.urai@gmail.com

%% make sure to add the code path
% cd('/Users/anne/Desktop/code/pupil-memory');
set(groot, 'defaultaxesfontsize', 6, 'defaultaxestitlefontsizemultiplier', 1, ...
    'defaultaxestitlefontweight', 'bold', ...
    'defaultfigurerenderermode', 'manual', 'defaultfigurerenderer', 'painters');

% where is the data stored?
global mypath
mypath = '~/Data/pupil-memory';

%% ONLY RUN THIS TO READ IN FROM THE RAW DATA TO FIRST-LEVEL FILES
if 0,
    %% As a reminder: Word number 98 has to be removed from the analysis, because
    % there are two words that are labelled "98". There is no data for word number 218.
    readInData_aud;
    
    % without removing the luminance fluctuations
    readInData_img(0);
    readInData_img(1);
    
    % write to csv for Lars
    load(sprintf('%s/data/alldata_%s.mat', mypath, 'aud'), 'dat');
    writetable(dat, sprintf('%s/data/alldata_words.csv', mypath));
    writetable(dat, sprintf('%s/data/alldata_words.xls', mypath));
    
    load(sprintf('%s/data/alldata_%s.mat', mypath, 'img_raw'), 'dat');
    writetable(dat, sprintf('%s/data/alldata_images.csv', mypath));
    writetable(dat, sprintf('%s/data/alldata_images.xls', mypath));
    
end

%% MAKE SECOND LEVEL FILE!
makeSecondLevelFiles;

%% PLOT FIGURES
pupilOverview_aud;
pupilOverview_img;
figure1;
figure1_correlations;
suppfigure1_emotionratings;
figure2;
logisticRegressionPlots;

allBarPlots;
supplementarycorrelationplot;
consolidationPupil;
