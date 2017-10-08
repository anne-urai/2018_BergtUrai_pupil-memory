function pupilOverview_aud

global mypath;

set(groot, 'defaultaxesfontsize', 5, 'defaultaxestitlefontsizemultiplier', 1, ...
    'defaultaxestitlefontweight', 'normal', ...
    'defaultfigurerenderermode', 'manual', 'defaultfigurerenderer', 'painters');


for baselineCorrect = [0 1],
    close all;
    load(sprintf('%s/auditory/alldata_aud.mat', mypath), 'dat', 'pupil');
    pupil.time = nanmean(pupil.time);
    colors = viridis(3);
    
    % CORRECT SINGLE-TRIAL BASELINE
    if baselineCorrect,
        pupil.pupil_timecourse_enc = pupil.pupil_timecourse_enc - pupil.pupil_baseline_enc;
    end
    
    % ========================================================= %
    % Hypothesis 1: The pupil dilates more when being confronted with emotional (vs. neutral) material.
    % ========================================================= %
    
    % 1. Overall response
    subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, dat, {'subj_idx'});
    title('Encoding');
    
    % 2. EMOTIONAL VS NEUTRAL PICTURES
    subplot(442); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, dat, {'subj_idx', 'emotional'});
    betterLegend(h, {'Neutral', 'Emotional'});
    title('Encoding');
    
    % ========================================================= %
    % Hypothesis 3: Material with more (vs. less) pupil dilation at encoding is being better remembered.
    % first, for neutral stimuli
    % ========================================================= %
    
    subplot(445); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0, :), ...
        dat(dat.emotional == 0, :), {'subj_idx', 'recalled_d1'});
    betterLegend(h, {'Forgotten', 'Recalled'});
    title('Recall, day 1 - neutral');
    
    subplot(446); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0, :), ...
        dat(dat.emotional == 0, :), {'subj_idx', 'recalled_d2'});
    betterLegend(h, {'Forgotten', 'Recalled'});
    title('Recall, day 2 - neutral');
    
    subplot(447); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0, :), ...
        dat(dat.emotional == 0, :), {'subj_idx', 'recog_oldnew'});
    betterLegend(h, {'Miss', 'Hit'});
    title('Recognition, day 2 - neutral');
    
    subplot(448); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0, :), ...
        dat(dat.emotional == 0, :), {'subj_idx', 'confidence_recog'});
    betterLegend(h, {'0', '1', '2', '3'});
    title('Recognition confidence, day 2 - neutral');
    
    % ========================================================= %
    % Hypothesis 3: Material with more (vs. less) pupil dilation at encoding is being better remembered.
    % first, for neutral stimuli
    % ========================================================= %
    
    subplot(449); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 1, :), ...
        dat(dat.emotional == 1, :), {'subj_idx', 'recalled_d1'});
    betterLegend(h, {'Forgotten', 'Recalled'});
    title('Recall, day 1 - emotional');
    xlabel('Time from word onset (s)');
    
    subplot(4,4,10); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 1, :), ...
        dat(dat.emotional == 1, :), {'subj_idx', 'recalled_d2'});
    betterLegend(h, {'Forgotten', 'Recalled'});
    title('Recall, day 2 - emotional');
    xlabel('Time from word onset (s)');
    
    subplot(4,4,11); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 1, :), ...
        dat(dat.emotional == 1, :), {'subj_idx', 'recog_oldnew'});
    betterLegend(h, {'Miss', 'Hit'});
    title('Recognition, day 2 - emotional');
    xlabel('Time from word onset (s)');
    
    subplot(4,4,12); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 1, :), ...
        dat(dat.emotional == 1, :), {'subj_idx', 'confidence_recog'});
    betterLegend(h, {'0', '1', '2', '3'});
    title('Recognition confidence, day 2 - emotional');
    xlabel('Time from word onset (s)');
    
    switch baselineCorrect
        case 0
            suplabel('Pupil dilation during encoding, not baseline corrected', 'x');
            print(gcf, '-dpdf', sprintf('%s/figures/words.pdf', mypath));
        case 1
            suplabel('Pupil dilation during encoding, baseline corrected', 'x');
            print(gcf, '-dpdf', sprintf('%s/figures/words_baselinecorrected.pdf', mypath));
    end
end

end
