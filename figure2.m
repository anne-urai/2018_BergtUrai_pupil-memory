function figure2

global mypath;

conds       = {'img_raw', 'aud'};
mrks        = {'o', 'd'};
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);
rdgy_scat   = cbrewer('div', 'RdBu', 15); rdgy_scat = rdgy_scat([end-4 5], :);
vars2split  = {'recalled_d1', 'recalled_d2', 'recog_oldnew'};
statkinds   = {'logres', 'logres_single'}; % 'ttest', 'anova', 'glme'};

for statidx = 1:length(statkinds),
    clear txt;
    for v = 1:length(vars2split),
        
        close all; subplot(441); hold on;
        cnt = 1;
        
        for c = 1:length(conds),
            emotions = [0 1];
            for e = 1:2,
                
                % get the data
                load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                
                dat = dat(dat.emotional == emotions(e), :);
                [gr, sjnr, emotional] = findgroups(dat.subj_idx, dat.(vars2split{v}));
                avgdat = array2table([sjnr emotional], 'variablenames', {'subj_idx', 'split'});
                
                % average over subjects
                avgdat.pupil = splitapply(@nanmean, dat.pupil_dilation_enc, gr);
                
                % remove subjects who did not recall any stimuli
                [gr, sjidx] = findgroups(avgdat.subj_idx);
                wrongsj = sjidx(find(splitapply(@nanmean, avgdat.split, gr) ~= 0.5));
                avgdat(ismember(avgdat.subj_idx, wrongsj),:) = [];
                
                % plot this!
                scatter(avgdat.pupil(avgdat.split == 0), avgdat.pupil(avgdat.split == 1), ...
                    1, rdgy_scat(e, :), mrks{c});
            end
        end
        
        % layout of the plot
        axis tight; xlims = get(gca, 'xlim'); ylims = get(gca, 'ylim');
        newlims = [min([xlims ylims]) max([xlims ylims])];
        xlim(newlims); ylim(newlims); axis square;
        r = refline(1, 0); r.Color = 'k'; r.LineWidth = 0.5;
        
        for c = 1:length(conds),
            emotions = [0 1];
            for e = 1:2,
                
                % get the data
                load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                dat = dat(dat.emotional == emotions(e), :);
                [gr, sjnr, emotional] = findgroups(dat.subj_idx, dat.(vars2split{v}));
                avgdat = array2table([sjnr emotional], 'variablenames', {'subj_idx', 'split'});
                
                % average over subjects
                avgdat.pupil = splitapply(@nanmean, dat.pupil_dilation_enc, gr);
                
                % remove subjects who did not recall any stimuli
                [gr, sjidx] = findgroups(avgdat.subj_idx);
                wrongsj = sjidx(find(splitapply(@nanmean, avgdat.split, gr) ~= 0.5));
                avgdat(ismember(avgdat.subj_idx, wrongsj),:) = [];
                
                % add the sem + mean on top
                p = ploterr(nanmean(avgdat.pupil(avgdat.split == 0)), nanmean(avgdat.pupil(avgdat.split == 1)), ...
                    nanstd(avgdat.pupil(avgdat.split == 0)) ./ sqrt(size(avgdat.pupil(avgdat.split == 0))), ...
                    nanstd(avgdat.pupil(avgdat.split == 1)) ./ sqrt(size(avgdat.pupil(avgdat.split == 1))), ...
                    'abshhxy', 0);
                set(p(1), 'marker', mrks{c}, 'markersize', 3, 'color', rdgy(e, :), 'linewidth', 0.5);
                set(p(2), 'color', rdgy(e, :), 'linewidth', 0.5); set(p(3), 'color', rdgy(e, :), 'linewidth', 0.5);
                
                % COLOR THE MARKERS
                [h, pval, ci, stats] = ttest(avgdat.pupil(avgdat.split == 0), ...
                    avgdat.pupil(avgdat.split == 1));
                
                if h,
                    set(p(1), 'markerfacecolor', rdgy(e, :), 'markeredgecolor', rdgy(e, :));
                elseif ~h,
                    set(p(1), 'markerfacecolor', 'w', 'markeredgecolor', rdgy(e, :));
                end
                
                % ================================== %
                % add stats!
                % ================================== %
                
                switch conds{c}
                    case 'img_raw'
                        condtxt = 'images';
                    case 'aud'
                        condtxt = 'words';
                end
                switch emotions(e)
                    case 1
                        emtxt = 'Emotional';
                    case 0
                        emtxt = 'Neutral';
                end
                
                switch statkinds{statidx}
                    
                    case 'logres'                        
                        if e == 2,
                            load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                            dat.emotional = sign(dat.emotional-0.5);
                            
                            % do a logistic regression of pupil onto the outcome
                            logresfun = @(x,y) {glmfit(y, x, 'binomial', 'link', 'logit')};
                            b = splitapply(logresfun, dat.(vars2split{v}), [dat.emotional dat.pupil_dilation_enc ...
                                dat.emotional.*dat.pupil_dilation_enc], ...
                                findgroups(dat.subj_idx));
                            b = cat(2, b{:})';
                            b(b==0) = NaN;
                            
                            % test the pupil coefficient, skip the intercept
                            for bix = 1:size(b, 2),
                                pval(bix) = permtest(b(:, bix));
                            end
                            [~, ~, ~, tstats] = ttest(b);
                            
                            % grab the stats I need
                            clear anovastats;
                            anovastats.pValue = pval;
                            anovastats.FStat = nanmean(b);
                            anovastats.DF1 = tstats.df;
                            
                            % NOW WRITE THE STATS)
                            if anovastats.pValue(2) < 0.001,
                                txt{cnt} = sprintf('%s\nEmotional b = %.2f, p < 0.001', capitalize(condtxt), ...
                                    anovastats.FStat(2));
                            else
                                txt{cnt} = sprintf('%s\nEmotional b = %.2f, p = %.3f', capitalize(condtxt), ...
                                    anovastats.FStat(2), anovastats.pValue(2));
                            end
                            cnt = cnt + 1;
                            
                            if anovastats.pValue(3) < 0.001,
                                txt{cnt} = sprintf('Pupil b = %.2f, p < 0.001', ...
                                    anovastats.FStat(3));
                            else
                                txt{cnt} = sprintf('Pupil b = %.2f, p = %.3f', ...
                                    anovastats.FStat(3), anovastats.pValue(3));
                            end
                            cnt = cnt + 1;
                            
                            if anovastats.pValue(4) < 0.001,
                                txt{cnt} = sprintf('Interaction b = %.2f, p < 0.001', ...
                                    anovastats.FStat(4));
                            else
                                txt{cnt} = sprintf('Interaction b = %.2f, p = %.3f', ...
                                    anovastats.FStat(4), anovastats.pValue(4));
                            end
                            cnt = cnt + 1;
                            txt{cnt} = ' ';
                            cnt = cnt + 1;
                        end
                        
                    case 'logres_single'
                        
                        load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                        dat.emotional = sign(dat.emotional-0.5);
                        
                        % do a logistic regression of pupil onto the outcome
                        logresfun = @(x,y) {glmfit(y, x, 'binomial', 'link', 'logit')};
                        b = splitapply(logresfun, dat.(vars2split{v}), dat.pupil_dilation_enc, findgroups(dat.subj_idx));
                        b = cat(2, b{:})';
                        b(b==0) = NaN;
                        
                        % test the pupil coefficient, skip the intercept
                        pval = permtest(b(:, 2));
                        
                        % stats separately for each condition
                        if pval < 0.001,
                            txt{cnt} = sprintf('%s %s\nb = %.2f, p < 0.001', emtxt, condtxt, nanmean(b(:, 2)));
                        else
                            txt{cnt} = sprintf('%s %s\nb = %.2f, p = %.3f', emtxt, condtxt, nanmean(b(:, 2)), pval);
                        end
                        cnt = cnt + 1;
                        
                    case 'ttest'
                        
                        % stats separately for each condition
                        if pval < 0.001,
                            txt{cnt} = sprintf('%s %s\nb(%d) = %.2f, p < 0.001', emtxt, condtxt, stats.df, stats.tstat);
                        else
                            txt{cnt} = sprintf('%s %s\nb(%d) = %.2f, p = %.3f', emtxt, condtxt, stats.df, stats.tstat, pval);
                        end
                        cnt = cnt + 1;
                        
                    case 'anova'
                        % only do at the end
                        if e == 2,
                            
                            % do an ANOVA for words and one for images?
                            load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                            dat.outcome = dat.(vars2split{v});
                            [gr, sjnr, split, emotional] = findgroups(dat.subj_idx, dat.(vars2split{v}), dat.emotional);
                            avgdat = array2table([sjnr, split, emotional], 'variablenames', {'subj_idx', 'split', 'emotional'});
                            
                            % average over subjects
                            avgdat.pupil = splitapply(@nanmean, dat.pupil_dilation_enc, gr);
                            
                            % remove subjects who did not recall any stimuli
                            [gr, sjidx] = findgroups(avgdat.subj_idx);
                            wrongsj = sjidx(find(splitapply(@nanmean, avgdat.split, gr) ~= 0.5));
                            avgdat(ismember(avgdat.subj_idx, wrongsj),:) = [];
                            
                            % remove cells with missing pupil values
                            avgdat(ismember(avgdat.subj_idx, unique(avgdat.subj_idx(isnan(avgdat.pupil)))),:) = [];
                            
                            % repeated measures ANOVA
                            anovastats = rm_anova(avgdat.pupil, avgdat.subj_idx, {avgdat.emotional avgdat.split});
                            assert(~isnan(anovastats.f1.pvalue), 'missing data, anova returns nan');
                            
                            % NOW WRITE THE STATS
                            if anovastats.f1.pvalue < 0.001,
                                txt{cnt} = sprintf('%s\nEmotional F(%d,%d) = %.2f, p < 0.001', capitalize(condtxt), ...
                                    anovastats.f1.df(1), anovastats.f1.df(2), anovastats.f1.fstats);
                            else
                                txt{cnt} = sprintf('%s\nEmotional F(%d,%d) = %.2f, p = %.3f', capitalize(condtxt), ...
                                    anovastats.f1.df(1), anovastats.f1.df(2), anovastats.f1.fstats, anovastats.f1.pvalue);
                            end
                            cnt = cnt + 1;
                            
                            % Remembered/forgotten
                            if anovastats.f2.pvalue < 0.001,
                                txt{cnt} = sprintf('Memory F(%d,%d) = %.2f, p < 0.001', ...
                                    anovastats.f2.df(1), anovastats.f2.df(2), anovastats.f2.fstats);
                            else
                                txt{cnt} = sprintf('Memory F(%d,%d) = %.2f, p = %.3f',  ...
                                    anovastats.f2.df(1), anovastats.f2.df(2), anovastats.f2.fstats, anovastats.f2.pvalue);
                            end
                            cnt = cnt + 1;
                            
                            if anovastats.f1xf2.pvalue < 0.001,
                                txt{cnt} = sprintf('Interaction F(%d,%d) = %.2f, p < 0.001',  ...
                                    anovastats.f1xf2.df(1), anovastats.f1xf2.df(2), anovastats.f1xf2.fstats);
                            else
                                txt{cnt} = sprintf('Interaction F(%d,%d) = %.2f, p = %.3f',  ...
                                    anovastats.f1xf2.df(1), anovastats.f1xf2.df(2), anovastats.f1xf2.fstats, anovastats.f1xf2.pvalue);
                            end
                            cnt = cnt + 1;
                            txt{cnt} = ' ';
                            cnt = cnt + 1;
                        end
                        
                    case 'glme'
                        
                        if e == 2,
                            % GLME
                            load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                            dat.outcome   = dat.(vars2split{v});
                            dat.emotional = sign(dat.emotional-0.5);
                     
                            glme = fitglme(dat, ['outcome ~ 1 + emotional*pupil_dilation_enc +' ...
                                '(1+emotional*pupil_dilation_enc|subj_idx)'], ...
                                'Distribution', 'Binomial', 'Link', 'Logit');
                            
                            % grab the stats I need
                            anovastats = glme.anova;
                            
                            % NOW WRITE THE STATS)
                            if anovastats.pValue(2) < 0.001,
                                txt{cnt} = sprintf('%s\nEmotional F(%d,%d) = %.2f, p < 0.001', capitalize(condtxt), ...
                                    anovastats.DF1(2), anovastats.DF2(2), anovastats.FStat(2));
                            else
                                txt{cnt} = sprintf('%s\nEmotional F(%d,%d) = %.2f, p = %.3f', capitalize(condtxt), ...
                                    anovastats.DF1(2), anovastats.DF2(2), anovastats.FStat(2), anovastats.pValue(2));
                            end
                            cnt = cnt + 1;
                            
                            if anovastats.pValue(3) < 0.001,
                                txt{cnt} = sprintf('Pupil F(%d,%d) = %.2f, p < 0.001', ...
                                    anovastats.DF1(3), anovastats.DF2(3), anovastats.FStat(3));
                            else
                                txt{cnt} = sprintf('Pupil F(%d,%d) = %.2f, p = %.3f', ...
                                    anovastats.DF1(3), anovastats.DF2(3), anovastats.FStat(3), anovastats.pValue(3));
                            end
                            cnt = cnt + 1;
                            
                            if anovastats.pValue(4) < 0.001,
                                txt{cnt} = sprintf('Interaction F(%d,%d) = %.2f, p < 0.001', ...
                                    anovastats.DF1(4), anovastats.DF2(4), anovastats.FStat(4));
                            else
                                txt{cnt} = sprintf('Interaction F(%d,%d) = %.2f, p = %.3f', ...
                                    anovastats.DF1(4), anovastats.DF2(4), anovastats.FStat(4), anovastats.pValue(4));
                            end
                            cnt = cnt + 1;
                            txt{cnt} = ' ';
                            cnt = cnt + 1;
                        end
                end
            end
        end
        
        switch vars2split{v}
            case 'recalled_d1'
                xlabel('Pupil: Recalled');
                ylabel('Pupil: Forgotten');
            case 'recalled_d2'
                xlabel('Pupil: Recalled');
                ylabel('Pupil: Forgotten');
            case 'recog_oldnew'
                xlabel('Pupil: Hit');
                ylabel('Pupil: Miss');
        end
        
        offsetAxes;
        set(gca, 'xtick', get(gca, 'ytick'));
        
        % plot the stats text on the side
        subplot(4,4,2);
        text(-0.4, mean(get(gca, 'ylim')), ...
            txt, 'verticalalignment', 'middle', 'fontsize', 5);
        axis off;
        
        tightfig;
        print(gcf, '-dpdf', sprintf('%s/figures/scatter_figure2_v%d_%s.pdf', mypath, v, statkinds{statidx}));
        
    end
end
end
