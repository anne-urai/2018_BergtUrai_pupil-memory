
cd /Users/anne/Drive/Dropbox/code/pupil-memory

global mypath
mypath = '~/Data/pupil-memory';

% As a reminder: Word number 98 has to be removed from the analysis, because 
% there are two words that are labelled "98". There is no data for word number 218.
readInData_aud;
pupilOverview_aud;

% READ IN ALL PUPIL AND BEHAVIOURAL FILES
readInData_img;
pupilOverview_img;

