% function imageLuminance

global mypath;

luminance = nan(1, 300);
for i = 1:300,
    filename = dir(sprintf('%s/stimulus_material/img/%03d_*', mypath, i));
    img = imread(sprintf('%s/stimulus_material/img/%s', mypath, filename.name));
    luminance(i) = nanmean(img(:)) ./ 256;
end


%% ADD TO THE IMAGE FILE
load(sprintf('%s/data/alldata_img_raw.mat', mypath), 'dat');
dat.luminance = nan(size(dat.subj_idx));
for d = 1:height(dat),
    dat.luminance(d) = luminance(dat.image(d));
end

tmpdat = dat(dat.subj_idx == 1, :);
figure; subplot(331); hold on;
histogram(tmpdat.luminance(tmpdat.emotional == 0), 10);
histogram(tmpdat.luminance(tmpdat.emotional == 1), 10);

vline(nanmean(tmpdat.luminance(tmpdat.emotional == 0)), 'b');
vline(nanmean(tmpdat.luminance(tmpdat.emotional == 1)), 'r');
xlabel('Luminance (mean pixel intensity)'); ylabel('Image count');
[h, pval, ci, stats] = ttest2(tmpdat.luminance(tmpdat.emotional == 0), tmpdat.luminance(tmpdat.emotional == 1));
title(sprintf('Luminance difference t(%d) = %.2f, p = %.3f', stats.df, stats.tstat, pval));
tightfig;
lh = legend({'Neutral', 'Emotional'}); lh.Position(1) = lh.Position(1) + 0.06;
legend boxoff;
print(gcf, '-dpdf', sprintf('%s/figures/luminance.pdf', mypath));

%% does this correlate?
pupE    = splitapply(@nanmean, dat.pupil_dilation_enc, findgroups(dat.image));
pupR    = splitapply(@nanmean, dat.pupil_dilation_recog, findgroups(dat.image));
lum     = splitapply(@nanmean, dat.luminance, findgroups(dat.image));
emotion = splitapply(@nanmean, dat.emotional, findgroups(dat.image));
newdat  = array2table([pupE pupR lum emotion], 'variablenames', ...
    {'EncodingPupil', 'RecognitionPupil', 'Luminance', 'Emotional'});

close all;
corrplot(newdat,  {'Luminance'}, {'EncodingPupil', 'RecognitionPupil'}, 'Emotional');
print(gcf, '-dpdf', sprintf('%s/figures/luminance_corrplot.pdf', mypath));

close all;
corrplot(newdat(newdat.Emotional == 1, :),  {'Luminance'}, {'EncodingPupil', 'RecognitionPupil'});
print(gcf, '-dpdf', sprintf('%s/figures/luminance_corrplot_emotional.pdf', mypath));

close all;
corrplot(newdat(newdat.Emotional == 0, :),  {'Luminance'}, {'EncodingPupil', 'RecognitionPupil'});
print(gcf, '-dpdf', sprintf('%s/figures/luminance_corrplot_neutral.pdf', mypath));

