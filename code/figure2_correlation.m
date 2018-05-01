%function figure2_correlation

clearvars -except mypath
global mypath;

conds       = {'img_raw', 'aud'};
mrks        = {'o', 'd'};
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);
rdgy_scat   = cbrewer('div', 'RdBu', 15); rdgy_scat = rdgy_scat([end-4 5], :);

close all; subplot(441); hold on;
cnt = 1;

for c = 1:length(conds),
    
    load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat', 'pupil');
    pupil.time = nanmean(pupil.time);
    % baseline correct
    pupil.pupil_timecourse_enc = pupil.pupil_timecourse_enc - pupil.pupil_baseline_enc;
    
    % preallocate
    corrdat.dprime_emotional = nan(max(unique(dat.subj_idx)), 401);
    corrdat.crit_emotional   = nan(max(unique(dat.subj_idx)), 401);
    corrdat.dprime_neutral   = nan(max(unique(dat.subj_idx)), 401);
    corrdat.crit_neutral     = nan(max(unique(dat.subj_idx)), 401);
    
    emotions = [0 1];
    for e = 1:2,
        for sj = unique(dat.subj_idx)',
            idx = find(dat.subj_idx == sj & dat.emotional == emotions(e));
            thisdat = dat(idx, :);
            
            % skip if this su
            if all(all(isnan(pupil.pupil_timecourse_enc(idx, :)))),
                continue;
            end
            
            for tidx = 1:size(pupil.pupil_timecourse_enc, 2),
                
                % grab timecourse, sliding window of 240 ms
                slidingwindow = tidx-6:tidx+6;
                slidingwindow(slidingwindow <= 0 | slidingwindow >= length(pupil.time)) = [];
                thispup = nanmean(pupil.pupil_timecourse_enc(idx, slidingwindow), 2);
                
                % divide this into 10 quantiles
                qntls   = quantile(thispup, 3);
                pupbins = discretize(thispup, [1.1*min(thispup) qntls 1.1*max(thispup)]);
                nrbins  = unique(pupbins);
                nrbins  = nrbins(~isnan(nrbins));
                
                % then for each quantile, compute dprime and criterion
                dprimebins      = nan(size(nrbins));
                criterionbins   = nan(size(nrbins));
                for b = unique(nrbins)',
                    [dprimebins(b), criterionbins(b)] = dprime( ...
                        thisdat.target_oldnew(pupbins == b | thisdat.target_oldnew == 0), ...
                        thisdat.recog_oldnew(pupbins == b | thisdat.target_oldnew == 0));
                end
                
                % correlate the two
                switch emotions(e)
                    case 0
                        corrdat.dprime_neutral(sj, tidx)    = corr(nrbins, dprimebins, 'type', 'spearman');
                        corrdat.crit_neutral(sj, tidx)      = corr(nrbins, criterionbins, 'type', 'spearman');
                    case 1
                        corrdat.dprime_emotional(sj, tidx)  = corr(nrbins, dprimebins, 'type', 'spearman');
                        corrdat.crit_emotional(sj, tidx)    = corr(nrbins, criterionbins, 'type', 'spearman');
                end
            end
        end
    end
    
    %% PLOT
    
    rdgy = cbrewer('div', 'RdBu', 15);
    colors = rdgy([2 4 end-3 end-1], :);
    
    close all; subplot(441); hold on;
    plot(pupil.time, nanmean(corrdat.dprime_neutral), 'color', colors(2, :));
    h = ttest_clustercorr(corrdat.dprime_neutral);
    if sum(h) > 0,
        plot(pupil.time((h == 1)), nanmean(corrdat.dprime_neutral(:, (h == 1))),'.', 'color', colors(1, :));
    end
    
    plot(pupil.time, nanmean(corrdat.dprime_emotional), 'color', colors(3,:));
    h = ttest_clustercorr(corrdat.dprime_emotional);
    if sum(h) > 0,
        plot(pupil.time((h == 1)), nanmean(corrdat.dprime_emotional(:, (h == 1))),'.', 'color', colors(4, :));
    end
    
    xlabel('Time from stimulus (s)');
    ylabel('Correlation to d''');
    axis tight; ylim([-0.3 0.3]); hline(0); vline(0); offsetAxes;
    tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/dprime_pupil_correlation_%s.pdf', mypath, conds{c}));
    
    close all; subplot(442); hold on;
    plot(pupil.time, nanmean(corrdat.crit_neutral), 'color', colors(2, :));
    h = ttest_clustercorr(corrdat.crit_neutral);
    if sum(h) > 0,
        plot(pupil.time((h == 1)), nanmean(corrdat.crit_neutral(:, (h == 1))), '.', 'color', colors(1, :));
    end
    plot(pupil.time, nanmean(corrdat.crit_emotional), 'color', colors(3, :));
    h = ttest_clustercorr(corrdat.crit_emotional);
    if sum(h) > 0,
        plot(pupil.time((h == 1)), nanmean(corrdat.crit_emotional(:, (h == 1))), '.', 'color', colors(4, :));
    end
    xlabel('Time from stimulus (s)');
    ylabel('Correlation to c');
    axis tight; ylim([-0.3 0.3]); hline(0); vline(0); offsetAxes;
    tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/criterion_pupil_correlation_%s.pdf', mypath, conds{c}));
    
end

%end

%% ALSO MAKE SCATTER PLOTS FOR HIGH VS. LOW PUPIL WITHIN EACH EMOTION CATEGORY

