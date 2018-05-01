% function imageLuminance

global mypath;
targetMean = 114; % background color

luminance_orig = nan(1, 300);
luminance_corrected = nan(1, 300);
for i = 1:300,
    filename = dir(sprintf('%s/stimulus_material/images/%03d_*', mypath, i));
    img = imread(sprintf('%s/stimulus_material/images/%s', mypath, filename.name));
    luminance_orig(i) = nanmean(img(:)) ./ 256;
    
    % correct, see email Carlo 8 January 2008
    if size( img,3 ) == 3 % make sure image is grayscale
        img = rgb2gray( img );
    end
    imgMean = mean( mean( img ) );
    meanDiff = round( targetMean-imgMean );
    img = img+meanDiff;
    
    % make sure this falls within the appropoate range
    assert(all(img(:) >= 0 & img(:) <= 256), 'image out of bounds');
    luminance_corrected(i) = nanmean(img(:)) ./ 256;
end

%% ADD TO THE IMAGE FILE
load(sprintf('%s/data/alldata_img_raw.mat', mypath), 'dat');

dat.luminance_orig = nan(size(dat.subj_idx));
dat.luminance_corrected = nan(size(dat.subj_idx));
for d = 1:height(dat),
    dat.luminance_orig(d)      = luminance_orig(dat.image(d));
    dat.luminance_corrected(d) = luminance_corrected(dat.image(d));
end

tmpdat = dat(dat.subj_idx == 1, :);
close all; figure; lumfields = {'luminance_orig', 'luminance_corrected'};
for l = 1:length(lumfields),
    subplot(3,3,l); hold on;
    histogram(tmpdat.(lumfields{l})(tmpdat.emotional == 0), 10);
    histogram(tmpdat.(lumfields{l})(tmpdat.emotional == 1), 10);
    
    vline(nanmean(tmpdat.(lumfields{l})(tmpdat.emotional == 0)), 'b');
    vline(nanmean(tmpdat.(lumfields{l})(tmpdat.emotional == 1)), 'r');
    xlabel(regexprep(lumfields{l}, '_', ' ')); ylabel('Image count');
    [h, pval, ci, stats] = ttest2(tmpdat.(lumfields{l})(tmpdat.emotional == 0), tmpdat.(lumfields{l})(tmpdat.emotional == 1));
    title(sprintf('Luminance difference t(%d) = %.2f, p = %.3f', stats.df, stats.tstat, pval));
    % xlim([0 1]);
end
lh = legend({'Neutral', 'Emotional'}); lh.Position(1) = lh.Position(1) + 0.06;
legend boxoff;

subplot(334);
plot(tmpdat.luminance_orig, tmpdat.luminance_corrected, '.');
axis tight; l = lsline; l.Color = 'k'; axis square; offsetAxes; box off;
xlabel('Original luminance'); ylabel('Corrected luminance');

tightfig;
print(gcf, '-dpdf', sprintf('%s/figures/luminance.pdf', mypath));

%% does this correlate?
pupE    = splitapply(@nanmean, dat.pupil_dilation_enc, findgroups(dat.image));
pupR    = splitapply(@nanmean, dat.pupil_dilation_recog, findgroups(dat.image));
lum     = splitapply(@nanmean, dat.luminance_corrected, findgroups(dat.image));
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

