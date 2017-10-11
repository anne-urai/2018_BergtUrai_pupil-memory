function readInData_img(removeLuminance)

global mypath
addpath('~/Documents/fieldtrip/');
ft_defaults;

%global mypath
subjects    = 1:58;
subjects(ismember(subjects, [13 14 20 51])) = [];
% subjects    = 1:3;

keepPupilTimecourses = 1;
quickTest   = 0;
prestim     = 2;
poststim    = 4;
fsample     = 50; % massively speeds up deconvolution

for sj = subjects
    
    if exist(sprintf('%s/visual/P%02d_img.csv', mypath, sj), 'file'),
       % continue;
    end
    
    %% ================================= %
    % BEHAVIOUR: ENCODING, PHASE 1
    %% ================================= %
    
    behavfile = dir(sprintf('%s/behaviour/phase1/result/%d*_%s_*.xls', mypath, sj, 'img'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat = readtable(sprintf('%s/behaviour/phase1/result/%s', mypath, behavfile));
    
    % rename some variables
    dat.Properties.VariableNames{'Trialnummer'}        = 'trialnr';
    dat.Properties.VariableNames{'Bildnummer'}         = 'image';
    dat.Properties.VariableNames{'Emotionalit_tDesBildes_0_neutral_1_emotional_'}        = 'emotional';
    dat.Properties.VariableNames{'AntwortEmotionsrating_von0_3_'}        = 'emotion_score';
    dat.Properties.VariableNames{'Reaktionszeit_inMs_'}        = 'rt_emotion';
    dat.emotional = [];
    
    %% ================================= %
    % PUPIL: ENCODING, PHASE 1
    %% ================================= %
    
    if exist(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'img'), 'file'),
        
        pupil = processPupilData(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'img'), fsample);
        
        % remove blinks and saccades
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset' pupil.blinkoffset'], [pupil.saccoffset' pupil.saccoffset'], 1, 1);
        print(gcf, '-dpdf', regexprep(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'img'), '.txt', '_blinkregress.pdf'));
        
        if quickTest,
            pupil.dat(:, 4) = pupil.dat(:, 1);
        else
            % ESTIMATE IRF OF THE LIGHT RESPONSE USING DECONVOLUTION
            if removeLuminance,
                pupil.dat(:, 4) = removeLightResponse(pupil.dat(:, 1), pupil.fsample, pupil.stimonset);
            else
                pupil.dat(:, 4) = pupil.dat(:, 1);
            end
            
        end
        pupil.label{4}  = 'cleanpupil';
        
        % epoch pupil
        pupil.trial_clean = nan(size(pupil.trial'));
        pupil.trial       = nan(size(pupil.trial'));
        
        for t = 1:length(pupil.stimonset),
            pupil.trial(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 1);
            pupil.trial_clean(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 4);
        end
        pupil.time = -prestim:1/pupil.fsample:poststim;
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
        
        dat.pupil_baseline_enc      = nanmean(pupil.trial_clean(:, (pupil.time > -2 & pupil.time < 0)), 2);
        dat.pupil_dilation_enc      = nanmean(pupil.trial_clean(:, (pupil.time > 1 & pupil.time < 4)), 2);

        if keepPupilTimecourses,
            dat.pupil_timecourse_clean_enc  = pupil.trial_clean;
            dat.pupil_timecourse_enc        = pupil.trial;
        end
    else
        dat.pupil_baseline_enc = nan(size(dat.image));
        dat.pupil_dilation_enc = nan(size(dat.image));
        
        if keepPupilTimecourses
            pupil.time = -prestim: 1/fsample :poststim;
            dat.pupil_timecourse_enc = nan(length(dat.image), length(pupil.time));
            dat.pupil_timecourse_clean_enc = nan(length(dat.image), length(pupil.time));
        end
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECOGNITION
    %% ================================= %
    
    behavfile = dir(sprintf('%s/behaviour/phase2/result/%d*_%s_*.xls', mypath, sj, 'img'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat2 = readtable(sprintf('%s/behaviour/phase2/result/%s', mypath, behavfile));
    
    % rename some variables
    dat2.Properties.VariableNames{'Trialnummer'}                            = 'trialnr';
    dat2.Properties.VariableNames{'Bildnummer'}                             = 'image';
    dat2.Properties.VariableNames{'KorrekteAntwort_0_neu_1_alt_'}           = 'target_oldnew';
    dat2.Properties.VariableNames{'GegebeneAntwort_0_neu_1_alt_'}           = 'recog_oldnew';
    dat2.Properties.VariableNames{'SignalDetection_0_0_0_correctRejection_1_1_1_hit_0_1_2_falseAla'} = 'recog_sdt';
    dat2.Properties.VariableNames{'SicherheitsratingF_r_alte_Bilder_1Bis4_'}  = 'confidence_recog';
    dat2.Properties.VariableNames{'Reaktionszeit_inMs_'}                    = 'rt_recog';
    dat2.Properties.VariableNames{'ReaktionszeitF_rSicherheitsrating_inMs_'} = 'rt_confidence_recog';
    dat2.Properties.VariableNames{'MemoryScore_gegebeneAntwortxSicherheitsrating_ErgibtWertZwische'} = 'memory_score';
    
    assert(isnan(nanmean(dat2.confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    assert(isnan(nanmean(dat2.rt_confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    dat2.memory_score(dat2.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    assert(length(unique(dat2.image)) == length(dat2.image), 'trial nr mismatch');
    
    %% ================================= %
    % PUPIL: RECOGNITION, PHASE 2
    %% ================================= %
    
    if exist(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'img'), 'file'),
        
        pupil = processPupilData(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'img'), fsample);
        
        % regress out blinks
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset' pupil.blinkoffset'], [pupil.saccoffset' pupil.saccoffset'], 1, 1);
        print(gcf, '-dpdf', regexprep(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'img'), '.txt', '_blinkregress.pdf'));
        
        if quickTest,
            pupil.dat(:, 4) = pupil.dat(:, 1);
        else
            % ESTIMATE IRF OF THE LIGHT RESPONSE USING DECONVOLUTION
            if removeLuminance,
                pupil.dat(:, 4) = removeLightResponse(pupil.dat(:, 1), pupil.fsample, pupil.stimonset);
            else
                pupil.dat(:, 4) = pupil.dat(:, 1);
            end
        end
        pupil.label{4}  = 'cleanpupil';
        
        % epoch pupil
        pupil.trial_clean = nan(size(pupil.trial'));
        pupil.trial       = nan(size(pupil.trial'));
        
        % epoch pupil
        pupil.trial_clean = nan(size(pupil.trial));
        for t = 1:length(pupil.stimonset),
            pupil.trial(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 1);
            pupil.trial_clean(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 4);
        end
        pupil.time = -prestim:1/pupil.fsample:poststim;
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
        
        dat2.pupil_baseline_recog      = nanmean(pupil.trial_clean(:, (pupil.time > -2 & pupil.time < 0)), 2);
        dat2.pupil_dilation_recog      = nanmean(pupil.trial_clean(:, (pupil.time > 1 & pupil.time < 4)), 2);
        if keepPupilTimecourses,
            dat2.pupil_timecourse_clean_recog    = pupil.trial_clean;
            dat2.pupil_timecourse_recog          = pupil.trial;
        end
    else
        dat2.pupil_baseline_recog = nan(size(dat2.image));
        dat2.pupil_dilation_recog = nan(size(dat2.image));
        
        if keepPupilTimecourses
            pupil.time = -prestim: 1/fsample :poststim;
            dat2.pupil_timecourse_clean_recog = nan(length(dat2.image), length(pupil.time));
            dat2.pupil_timecourse_recog = nan(length(dat2.image), length(pupil.time));
        end
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECALL
    %% ================================= %
    
    dat3 = readtable(sprintf('%s/recall/%02d_Bilder.csv', mypath, sj));
    
    vars = dat3.Properties.VariableNames;
    for v = 1:length(vars),
        dat3.Properties.VariableNames{vars{v}} = regexprep(vars{v}, '_*', '_');
    end
    
    dat3.Properties.VariableNames{'x_Bildnummer'}                   = 'image';
    dat3.Properties.VariableNames{'Antwort_Emotionsrating'}         = 'emotion_score';
    dat3.Properties.VariableNames{'RT_Emotionsrating'}              = 'rt_emotion';
    dat3.Properties.VariableNames{'Emotionalit_t_des_Bildes'}       = 'emotional';
    dat3.Properties.VariableNames{'d1_free_recall_remembered'}      = 'recalled_d1';
    dat3.Properties.VariableNames{'d2_free_recall_remembered'}      = 'recalled_d2';
    dat3.Properties.VariableNames{'recognition_correct'}            = 'target_oldnew';
    dat3.Properties.VariableNames{'recognition_response'}           = 'recog_oldnew';
    dat3.Properties.VariableNames{'recognition_signal_detection'}   = 'recog_sdt';
    dat3.Properties.VariableNames{'RT_recognition'}                 = 'rt_recog';
    dat3.Properties.VariableNames{'recognition_certainty_old'}      = 'confidence_recog';
    dat3.Properties.VariableNames{'RT_certainty_rating'}            = 'rt_confidence_recog';
    dat3.memory_score(dat3.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    
    % remove old pupil values
    dat3(:, strncmp(dat3.Properties.VariableNames, 'pupil', 5)) = [];
    
    % set recall to 0 for new words
    dat3.recalled_d1(dat3.target_oldnew == 0) = NaN;
    dat3.recalled_d2(dat3.target_oldnew == 0) = NaN;
    
    % recode RTs to numbers instead of strings
    rt2num = @(x) cellfun(@str2double,x,'un',1);
    if iscell(dat3.rt_confidence_recog),
        dat3.rt_confidence_recog    = rt2num(dat3.rt_confidence_recog);
    end
    if iscell(dat3.rt_emotion),
        dat3.rt_emotion             = rt2num(dat3.rt_emotion);
    end
    if iscell(dat3.rt_recog),
        dat3.rt_recog               = rt2num(dat3.rt_recog);
    end
    dat3(:, strncmp(dat3.Properties.VariableNames, 'rt', 2)) = [];
    
    % remove rows where all entries are empty, duplicate image nrs
    dat3(isnan(nanmean(dat3{:, 2:end}, 2)), :) = [];
    assert(length(unique(dat3.image)) == length(dat3.image), 'trial nr mismatch');
    
    %% ================================= %
    % INTEGRATE ALL OF THOSE INTO 1 FILE
    %% ================================= %
    
    dat4 = outerjoin(dat, dat2, 'keys', {'image'});
    dat4.Properties.VariableNames{'image_dat2'} = 'image';
    dat4.image_dat = [];
    dat4 = outerjoin(dat4, dat3, 'keys', {'image'});
    
    % do a few checks & clean up
    dat4 = removeDuplicateVars(dat4, {'confidence_recog', 'emotion_score', 'image', ...
        'memory_score', 'recog_oldnew', 'recog_sdt','target_oldnew'});
    
    %% BASELINE CORRECTION
    dat4.pupil_dilation_enc     = dat4.pupil_dilation_enc - dat4.pupil_baseline_enc;
    dat4.pupil_dilation_recog   = dat4.pupil_dilation_recog - dat4.pupil_baseline_recog;
    
    if keepPupilTimecourses
        % save as a matfile with separate pupil and trialinfo
        pupvars = strncmp(dat4.Properties.VariableNames', 'pupil', 5);
        puptime = -prestim: 1/pupil.fsample :poststim;
        pupil   = table2struct(dat4(:, pupvars), 'toscalar', true);
        pupil.time = puptime;
        
        dat4(:, strncmp(dat4.Properties.VariableNames', 'pupil_timecourse', 16)) = [];
        dat = dat4;
        savefast(sprintf('%s/visual/P%02d_img.mat', mypath, sj), 'dat', 'pupil');
    end
    
    writetable(dat4, sprintf('%s/visual/P%02d_img.csv', mypath, sj));
    
end

% ===================== %
% APPEND over sj
% ===================== %

disp('appending over subjects...');

alltab = {};
for sj = subjects,
    thistab                 = readtable(sprintf('%s/visual/P%02d_img.csv', mypath, sj));
    thistab.subj_idx        = sj*ones(size(thistab.image));
    try thistab.filter_     = [];  end
    alltab{sj}              = thistab;
end

alltab(cellfun(@isempty, alltab))   = [];
fulltab = cat(1, alltab{:});
fulltab = fulltab(:, [end 1:end-1]);
if removeLuminance,
    writetable(fulltab, sprintf('%s/visual/alldata_img_luminanceRemoved.csv', mypath));
else
    writetable(fulltab, sprintf('%s/visual/alldata_img_raw.csv', mypath));
end

if keepPupilTimecourses,
    % separate out trialinfo and timecourses
    
    alltab = {};
    for sj = subjects
        load(sprintf('%s/visual/P%02d_img.mat', mypath, sj));
        dat.subj_idx        = sj*ones(size(dat.image));
        try dat.filter_     = [];  end
        allpupil(sj)        = pupil;
        alltab{sj}          = dat;
    end
    allpupil(cellfun(@isempty, alltab))     = [];
    alltab(cellfun(@isempty, alltab))       = [];
    
    % now append
    try
        fulltab = cat(1, alltab{:});
        fulltab = fulltab(:, [end 1:end-1]);
    catch
        assert(1==0);
    end
    
    flds = fieldnames(allpupil(1));
    for f = 1:length(flds),
        fullpupil.(flds{f}) = cat(1, allpupil(:).(flds{f}));
    end
    
    % save
    dat     = fulltab;
    pupil   = fullpupil;
    
    if removeLuminance,
        savefast(sprintf('%s/visual/alldata_img_luminanceRemoved.mat', mypath), 'dat', 'pupil');
    else
        savefast(sprintf('%s/visual/alldata_img_raw.mat', mypath), 'dat', 'pupil');
    end
end

end

function dat = removeDuplicateVars(dat, vars)

for v = 1:length(vars),
    v1 = [vars{v} '_dat3'];
    v2 = [vars{v} '_dat4'];
    
    assert(isequaln(dat.(v1), dat.(v2)), 'mismatch');
    dat.(v1) = [];
    dat.Properties.VariableNames{v2} = vars{v};
end
end

