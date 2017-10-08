function readInData_aud

global mypath
addpath('~/Documents/fieldtrip/');
ft_defaults;

%global mypath
subjects    = 1:58;
subjects(ismember(subjects, [13 14 20 51 34])) = [];
% subjects    = 1:3;
% subject 43 has a weird time axis

keepPupilTimecourses = 1;
quickTest   = 0;
prestim     = 2;
poststim    = 4;
fsample     = 50; % massively speeds up deconvolution

for sj = subjects,
    
    if exist(sprintf('%s/auditory/P%02d_aud.mat', mypath, sj), 'file'),
        %    continue;
    end
    
    %% ================================= %
    % BEHAVIOUR: ENCODING, PHASE 1
    %% ================================= %
    
    behavfile = dir(sprintf('%s/behaviour/phase1/result/%d*_%s_*.xls', mypath, sj, 'aud'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat = readtable(sprintf('%s/behaviour/phase1/result/%s', mypath, behavfile));
    
    % rename some variables
    dat.Properties.VariableNames{'Trialnummer'}        = 'trialnr';
    dat.Properties.VariableNames{'Wortnummer'}         = 'word';
    % dat(dat.word == 98, :) = [];
    
    %% ================================= %
    % PUPIL: ENCODING, PHASE 1
    %% ================================= %
    
    if exist(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'aud'), 'file'),
        
        pupil = processPupilData(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'aud'), fsample);
        
        % remove blinks and saccades
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset' pupil.blinkoffset'], [pupil.saccoffset' pupil.saccoffset'], 1, 1);
        print(gcf, '-dpdf', regexprep(sprintf('%s/pupil/%02d_d1_%s.txt', mypath, sj, 'aud'), '.txt', '_blinkregress.pdf'));
        
        % epoch pupil
        % pupil.trial_clean = nan(size(pupil.trial'));
        pupil.trial       = nan(size(pupil.trial'));
        
        for t = 1:length(pupil.stimonset),
            pupil.trial(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 1);
        end
        pupil.time = -prestim:1/pupil.fsample:poststim;
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
        
        dat.pupil_baseline_enc      = nanmean(pupil.trial(:, (pupil.time > -2 & pupil.time < 0)), 2);
        dat.pupil_dilation_enc      = nanmean(pupil.trial(:, (pupil.time > 1 & pupil.time < 4)), 2);
        if keepPupilTimecourses,
            dat.pupil_timecourse_enc  = pupil.trial;
        end
    else
        dat.pupil_baseline_enc = nan(size(dat.word));
        dat.pupil_dilation_enc = nan(size(dat.word));
        
        if keepPupilTimecourses
            pupil.time = -prestim: 1/fsample :poststim;
            dat.pupil_timecourse_enc = nan(length(dat.word), length(pupil.time));
        end
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECOGNITION
    %% ================================= %
    
    behavfile = dir(sprintf('%s/behaviour/phase2/result/%d*_%s_*.xls', mypath, sj, 'aud'));
    % subject numbers have single precision, filter
    behavfile = behavfile((~cellfun(@isempty, regexp({behavfile(:).name}, sprintf('^%d[a-z]', sj))))).name;
    dat2 = readtable(sprintf('%s/behaviour/phase2/result/%s', mypath, behavfile));
    
    % rename some variables
    dat2.Properties.VariableNames{'Trialnummer'}        = 'trialnr';
    dat2.Properties.VariableNames{'Wortnummer'}         = 'word';
    dat2.Properties.VariableNames{'KorrekteAntwort_0_neu_1_alt_'}        = 'target_oldnew';
    dat2.Properties.VariableNames{'GegebeneAntwort_0_neu_1_alt_'}        = 'recog_oldnew';
    dat2.Properties.VariableNames{'SignalDetection_0_0_0_correctRejection_1_1_1_hit_0_1_2_falseAla'} = 'recog_sdt';
    dat2.Properties.VariableNames{'SicherheitsratingF_r_alte_W_rter_1Bis4_'}  = 'confidence_recog';
    dat2.Properties.VariableNames{'Reaktionszeit_inMs_'}        = 'rt_recog';
    dat2.Properties.VariableNames{'ReaktionszeitF_rSicherheitsrating_inMs_'}        = 'rt_confidence_recog';
    dat2.Properties.VariableNames{'MemoryScore_gegebeneAntwortxSicherheitsrating_ErgibtWertZwische'}        = 'memory_score';
    
    assert(isnan(nanmean(dat2.confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    assert(isnan(nanmean(dat2.rt_confidence_recog(dat2.recog_oldnew == 0))), 'mismatch');
    dat2.memory_score(dat2.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    % dat2(dat2.word == 98, :) = [];
    % assert(length(unique(dat2.word)) == length(dat2.word), 'trial nr mismatch');
    
    %% ================================= %
    % PUPIL: RECOGNITION, PHASE 2
    %% ================================= %
    
    if exist(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'aud'), 'file'),
        
        pupil = processPupilData(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'aud'), fsample);
        
        % regress out blinks
        pupil.dat(:, 1) = blink_regressout(pupil.dat(:, 1), pupil.fsample, ...
            [pupil.blinkoffset' pupil.blinkoffset'], [pupil.saccoffset' pupil.saccoffset'], 1, 1);
        print(gcf, '-dpdf', regexprep(sprintf('%s/pupil/%02d_d2_%s.txt', mypath, sj, 'aud'), '.txt', '_blinkregress.pdf'));
        
        % epoch pupil
        pupil.trial       = nan(size(pupil.trial'));
        
        % epoch pupil
        for t = 1:length(pupil.stimonset),
            pupil.trial(t, :) = pupil.dat(pupil.stimonset(t) - prestim*pupil.fsample ...
                : pupil.stimonset(t) + poststim*pupil.fsample, 1);
        end
        pupil.time = -prestim:1/pupil.fsample:poststim;
        
        %% ================================= %
        % MATCH PUPIL TO BEHAVIOURAL DATA
        %% ================================= %
           
        dat2.pupil_baseline_recog      = nanmean(pupil.trial(:, (pupil.time > -2 & pupil.time < 0)), 2);
        dat2.pupil_dilation_recog      = nanmean(pupil.trial(:, (pupil.time > 1 & pupil.time < 4)), 2);
        
        if keepPupilTimecourses,
            dat2.pupil_timecourse_recog          = pupil.trial;
        end
    else
        dat2.pupil_baseline_recog = nan(size(dat2.word));
        dat2.pupil_dilation_recog = nan(size(dat2.word));
        
        if keepPupilTimecourses
            pupil.time = -prestim: 1/fsample :poststim;
            dat2.pupil_timecourse_recog = nan(length(dat2.word), length(pupil.time));
        end
    end
    
    %% ================================= %
    % BEHAVIOUR: PHASE 2, RECALL
    %% ================================= %
    
    dat3 = readtable(sprintf('%s/recall/%02d_Worter.csv', mypath, sj));
    
    vars = dat3.Properties.VariableNames;
    for v = 1:length(vars),
        dat3.Properties.VariableNames{vars{v}} = regexprep(vars{v}, '_*', '_');
    end
    
    dat3.Properties.VariableNames{'x_Wortnummer'}                   = 'word';
    dat3.Properties.VariableNames{'Emotionalit_t_des_Wortes'}       = 'emotional';
    dat3.Properties.VariableNames{'d1_free_recall_remembered'}      = 'recalled_d1';
    dat3.Properties.VariableNames{'d2_free_recall_remembered'}      = 'recalled_d2';
    dat3.Properties.VariableNames{'recognition_correct'}            = 'target_oldnew';
    dat3.Properties.VariableNames{'recognition_response'}           = 'recog_oldnew';
    dat3.Properties.VariableNames{'recognition_signal_detection'}   = 'recog_sdt';
    dat3.Properties.VariableNames{'RT_recognition'}                 = 'rt_recog';
    dat3.Properties.VariableNames{'recognition_certainty_old'}      = 'confidence_recog';
    dat3.Properties.VariableNames{'RT_certainty_rating'}            = 'rt_confidence_recog';
    dat3.memory_score(dat3.target_oldnew == 0) = NaN; % do not compute a memory score for new items
    
    % something weird in the recall variables...
    if any(isnan(dat3.recalled_d1)),
        dat3.recalled_d1(isnan(dat3.recalled_d1)) = 0;
        dat3.recalled_d2(isnan(dat3.recalled_d2)) = 0;
    end
    
    % set recall to 0 for new words
    dat3.recalled_d1(dat3.target_oldnew == 0) = NaN;
    dat3.recalled_d2(dat3.target_oldnew == 0) = NaN;
    
    % remove old pupil values
    dat3(:, strncmp(dat3.Properties.VariableNames, 'pupil', 5)) = [];
    dat3(:, strncmp(dat3.Properties.VariableNames, 'filter', 6)) = [];
    
    % recode RTs to numbers instead of strings
    rt2num = @(x) cellfun(@str2double,x,'un',1);
    if iscell(dat3.rt_confidence_recog),
        dat3.rt_confidence_recog    = rt2num(dat3.rt_confidence_recog);
    end
    if iscell(dat3.rt_recog),
        dat3.rt_recog               = rt2num(dat3.rt_recog);
    end
    dat3(:, strncmp(dat3.Properties.VariableNames, 'rt', 2)) = [];
    
    % remove rows where all entries are empty, duplicate image nrs
    dat3(isnan(nanmean(dat3{:, 2:end}, 2)), :) = [];
    assert(length(unique(dat3.word)) == length(dat3.word), 'trial nr mismatch');
    
    %% ================================= %
    % INTEGRATE ALL OF THOSE INTO 1 FILE
    %% ================================= %
    
    % dont use word nr 98
    dat(dat.word == 98, :)      = [];
    dat2(dat2.word == 98, :)    = [];
    dat3(dat3.word == 98, :)    = [];
    assert(isempty(find(dat3.word == 218)), 'word nr 218 was never presented');
    
    dat4 = outerjoin(dat, dat2, 'keys', {'word'});
    assert(isequaln(dat4.word_dat2(~isnan(dat4.word_dat)), ...
        dat4.word_dat(~isnan(dat4.word_dat))), 'mismatch');
    dat4.Properties.VariableNames{'word_dat2'} = 'word';
    dat4.word_dat = [];
    dat4 = outerjoin(dat4, dat3, 'keys', {'word'});
    
    assert(isequaln(dat4.word_dat3, ...
        dat4.word_dat4), 'mismatch');
    
    % do a few checks & clean up
    dat4 = removeDuplicateVars(dat4, {'confidence_recog', 'word', ...
        'memory_score', 'recog_oldnew', 'recog_sdt','target_oldnew'});
    
    %% BASELINE CORRECTION
    dat4.pupil_dilation_enc = dat4.pupil_dilation_enc - dat4.pupil_baseline_enc;
    dat4.pupil_dilation_recog = dat4.pupil_dilation_recog - dat4.pupil_baseline_recog;
    
    if keepPupilTimecourses,
        
        % save as a matfile with separate pupil and trialinfo
        pupvars     = strncmp(dat4.Properties.VariableNames', 'pupil', 5);
        puptime     = -prestim: 1/pupil.fsample :poststim;
        pupil       = table2struct(dat4(:, pupvars), 'toscalar', true);
        pupil.time  = puptime;
        
        dat4(:, strncmp(dat4.Properties.VariableNames', 'pupil_timecourse', 16)) = [];
        dat = dat4;
        savefast(sprintf('%s/auditory/P%02d_aud.mat', mypath, sj), 'dat', 'pupil');
    end
    
    % always also keep the csv
    writetable(dat4, sprintf('%s/auditory/P%02d_aud.csv', mypath, sj));
 
end

% ===================== %
% APPEND over sj
% ===================== %

disp('appending over subjects...');

if keepPupilTimecourses
    % separate out trialinfo and timecourses
    
    alltab = {};
    for sj = subjects
        load(sprintf('%s/auditory/P%02d_aud.mat', mypath, sj));
        dat.subj_idx        = sj*ones(size(dat.word));
        try dat.filter_     = [];  end
        try dat.hit_rate    = [];  end
        allpupil(sj)        = pupil;
        alltab{sj}          = dat;
    end
    allpupil(cellfun(@isempty, alltab))   = [];
    alltab(cellfun(@isempty, alltab))     = [];
    
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
    savefast(sprintf('%s/auditory/alldata_aud.mat', mypath), 'dat', 'pupil');
    
end

% always keep csv

alltab = {};
for sj = subjects,
    thistab                 = readtable(sprintf('%s/auditory/P%02d_aud.csv', mypath, sj));
    thistab.subj_idx        = sj*ones(size(thistab.word));
    try thistab.filter_     = [];  end
    try thistab.hit_rate    = [];  end
    
    alltab{sj}              = thistab;
end

alltab(cellfun(@isempty, alltab))   = [];
fulltab = cat(1, alltab{:});
fulltab = fulltab(:, [end 1:end-1]);
writetable(fulltab, sprintf('%s/auditory/alldata_aud.csv', mypath));

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

