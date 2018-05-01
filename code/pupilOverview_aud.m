function pupilOverview_aud
global mypath;

for baselineCorrect = [1],
    load(sprintf('%s/data/alldata_aud.mat', mypath), 'dat', 'pupil');
    pupil.time = nanmean(pupil.time);
    rdgy = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);
    piyg = cbrewer('div', 'PiYG', 10);
    
    % CORRECT SINGLE-TRIAL BASELINE
    if baselineCorrect,
        pupil.pupil_timecourse_enc = pupil.pupil_timecourse_enc - pupil.pupil_baseline_enc;
    end
    
    
    % ========================================================= %
    % CONSOLIDATION
    % ========================================================= %
    
    dat.recall_score = zeros(size(dat.recalled_d1));
    dat.recall_score(dat.recalled_d1 == 0 & dat.recalled_d2 == 0)   = 0; % neither
    dat.recall_score(dat.recalled_d1 == 1 & dat.recalled_d2 == 0)   = 1; % only d1
    dat.recall_score(dat.recalled_d1 == 0 & dat.recalled_d2 == 1)   = 2; % only d2
    dat.recall_score(dat.recalled_d1 == 1 & dat.recalled_d2 == 1)   = 3; % both
    dat.consolidation = nan(size(dat.recall_score));
    dat.consolidation(dat.recall_score == 1) = 0;
    dat.consolidation(dat.recall_score == 3) = 1;
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0,:), ...
        dat(dat.emotional == 0,:), {'subj_idx', 'consolidation'}, rdgy([end-3 end], :));
    title('Neutral, consolidation');
    betterLegend(h, {'d1', 'both'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v7.pdf', mypath, baselineCorrect));
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 1,:), ...
        dat(dat.emotional == 1,:), {'subj_idx',  'consolidation'}, rdgy([4 1], :));
    title('Emotional, consolidation');
    betterLegend(h, {'d1', 'both'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v8.pdf', mypath, baselineCorrect));
    
    % skip the rest
    continue;
    
    % ========================================================= %
    % Hypothesis 1: The pupil dilates more when being confronted with emotional (vs. neutral) material.
    % ========================================================= %
    
    % 2. EMOTIONAL VS NEUTRAL PICTURES
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, dat, {'subj_idx', 'emotional'}, rdgy([end 2], :));
    title('Memory encoding: words');
    lh = betterLegend(h, {'Neutral', 'Emotional'}, 'word');
    lh.Visible = 'off';
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v2.pdf', mypath, baselineCorrect));
    
    % ========================================================= %
    % Hypothesis 3: Material with more (vs. less) pupil dilation at encoding is being better remembered.
    % first, for neutral stimuli
    % ========================================================= %
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, dat, ...
        {'subj_idx', 'emotional', 'recalled_d1'}, rdgy([end-4 4 end 1], :), rdgy([end 1], :));
    %title('Recall, day 1');
    %title('Memory encoding: words');
    
    betterLegend(h, {'Neutral, forgotten', 'Emotional, forgotten', 'Neutral, recalled', 'Emotional, recalled'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v3.pdf', mypath, baselineCorrect));
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, ...
        dat, {'subj_idx', 'emotional', 'recalled_d2'}, rdgy([end-4 4 end 1], :), rdgy([end 1], :));
    %title('Recall, day 2');
    betterLegend(h, {'Neutral, forgotten', 'Emotional, forgotten', 'Neutral, recalled', 'Emotional, recalled'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v4.pdf', mypath, baselineCorrect));
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc, ...
        dat, {'subj_idx', 'emotional', 'recog_oldnew'}, rdgy([end-4 4 end 1], :), rdgy([end 1], :));
    %title('Recognition, day 2');
    %title('Memory encoding: words');
    betterLegend(h, {'Neutral, miss', 'Emotional, miss', 'Neutral, hit', 'Emotional, hit'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v5.pdf', mypath, baselineCorrect));
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0,:), ...
        dat(dat.emotional == 0, :), {'subj_idx', 'confidence_recog'}, rdgy(8:end, :));
    %title('Recognition confidence, day 2 - neutral');
    betterLegend(h, {'0', '1', '2', '3'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v6.pdf', mypath, baselineCorrect));
    
    close all; subplot(441); hold on;
    h = plotData(pupil.time, pupil.pupil_timecourse_enc(dat.emotional == 0,:), ...
        dat(dat.emotional == 0,:), {'subj_idx', 'emotional', 'confidence_recog'}, rdgy(4:-1:1, :));
    title('Recognition confidence, day 2 - emotional');
    betterLegend(h, {'0', '1', '2', '3'}, 'word');
    print(gcf, '-dpdf', sprintf('%s/figures/words_bl%d_v6.pdf', mypath, baselineCorrect));
    
    
end

end
