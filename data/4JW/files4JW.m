
global mypath

%% words

load(sprintf('%s/data/alldata_%s.mat', mypath, 'aud'));
writetable(dat, 'tabledata_words.csv');
csvwrite('pupiltrials_words.csv', [mean(pupil.time); pupil.pupil_timecourse_recog]);

load(sprintf('%s/data/alldata_%s.mat', mypath, 'img_raw'));
writetable(dat, 'tabledata_img.csv');
csvwrite('pupiltrials_img.csv', [mean(pupil.time); pupil.pupil_timecourse_recog]);

