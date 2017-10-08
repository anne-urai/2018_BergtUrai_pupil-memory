function residuals = removeLightResponse(dat, fsample, sample)

% start at 2s before the presentation of the image
sample  = sample - 2*fsample;
impulse = 6; % picture was on the screen for 3s, remove for 4

% dont use samples beyond the data that was collected
% (even if the trialinfo has sampels there)
useSmp  = 1:length(dat);
% remove the IRF from 3s before to
nrCols  = impulse*fsample;

designM = zeros(length(useSmp), nrCols);
disp('making design matrix');

% create a logical vector to speed up the analyses
samplelogical           = zeros(length(useSmp), 1);
samplelogical(sample)   = 1; % first sample of this regressor

% put samples in design matrix at the right spot
r = 1;
begincol = r + (r-1)*impulse*fsample;
for c = begincol : begincol + impulse*fsample,
    % for each col, put ones at the next sample valuess
    designM(:, c)   = samplelogical;
    samplelogical   = [0; samplelogical(1:end-1)]; % shift
end
assert(length(dat) == length(designM), 'mismatch in samples');

% do the actual deconvolution
tic; deconvolvedPupil = pinv(designM) * dat; toc; % pinv more robust than inv?

% clean this from the data
% compute predicted response
predic      = designM * deconvolvedPupil;

% subtract the mean of both to not get weird offsets
predic      = predic - mean(predic);
dat         = dat - mean(dat);

% take the predicted nuisances out
residuals   = dat - predic;

end