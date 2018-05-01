function logisticRegressionPlots

global mypath;

conds       = {'img_raw', 'aud'};
mrks        = {'o', 'd'};
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);
rdgy_scat   = cbrewer('div', 'RdBu', 15); rdgy_scat = rdgy_scat([end-4 5], :);
vars2split  = {'recalled_d1', 'recalled_d2', 'recog_oldnew', 'consolidation'};

whichStat = 'ttest';

for v = 1:length(vars2split),
    for c = 1:length(conds),
        
        clear plotdat
        emotions = [0 1];
        for e = 1:2,
            
            % get the data
            load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
            dat = dat(dat.emotional == emotions(e), :);
            
            %% FIRST, CHECK THE RECALL DATA
            dat.recall_score = zeros(size(dat.recalled_d1));
            dat.recall_score(dat.recalled_d1 == 0 & dat.recalled_d2 == 0)   = 0; % neither
            dat.recall_score(dat.recalled_d1 == 1 & dat.recalled_d2 == 0)   = 1; % only d1
            dat.recall_score(dat.recalled_d1 == 0 & dat.recalled_d2 == 1)   = 2; % only d2
            dat.recall_score(dat.recalled_d1 == 1 & dat.recalled_d2 == 1)   = 3; % both
            dat.consolidation = nan(size(dat.recall_score));
            dat.consolidation(dat.recall_score == 1) = 0;
            dat.consolidation(dat.recall_score == 3) = 1;
            
            % do a logistic regression of pupil onto the outcome
            b = splitapply(@logresfun, dat.(vars2split{v}), dat.pupil_dilation_enc, findgroups(dat.subj_idx));
            
            % test the pupil coefficient, skip the intercept
            pval = permtest(b);
            
            plotdat.b(:, e) = b;
            plotdat.pval(e) = pval;
            
            dat.outcome   = dat.(vars2split{v});
            glme{e} = fitglme(dat, ['outcome ~ 1 + pupil_dilation_enc +' ...
                '(1+pupil_dilation_enc|subj_idx)'], ...
                'Distribution', 'Binomial', 'Link', 'Logit');
        end
        
        %% plot this
        close all; subplot(471); hold on;
        plotBetasSwarm(plotdat.b, rdgy([1 end], :));
        set(gca, 'xtick', 1:2, 'xticklabel', {'Neutral', 'Emotional'}, 'xticklabelrotation', -35);
        
        % plot the fixed effects from glme on top!
        for e = 1:2,
            switch whichStat
                case 'glme'
                    ploterr(e+0.1, glme{e}.Coefficients.Estimate(2), [], ...
                        [glme{e}.Coefficients.Lower(2), glme{e}.Coefficients.Upper(2)],  '.k', 'abshhxy', 0);
                    mysigstar(gca, e, max(get(gca, 'ylim')), glme{e}.Coefficients.pValue(2));
                case 'permtest'
                    mysigstar(gca, e, max(get(gca, 'ylim')), permtest(plotdat.b(:, e)));
                case 'ttest'
                    [~, pval] = ttest(plotdat.b(:, e));
                    % mysigstar(gca, e, max(get(gca, 'ylim')), pval);
            end
        end
        
        %% GLME STATS
        switch whichStat
            case 'glme'
                load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
                dat.outcome   = dat.(vars2split{v});
                glmeD = fitglme(dat, ['outcome ~ 1 + pupil_dilation_enc*emotional +' ...
                    '(1+pupil_dilation_enc*emotional|subj_idx)'], ...
                    'Distribution', 'Binomial', 'Link', 'Logit');
                mysigstar(gca, 1:2, 0.9*min(get(gca, 'ylim')), glmeD.Coefficients.pValue(4), 'k', 'up');
            case 'permtest'
                mysigstar(gca, 1:2, 0.9*min(get(gca, 'ylim')), permtest(plotdat.b(:,1), plotdat.b(:, 2)), 'k', 'up');
            case 'ttest'
                [~, pval] = ttest(plotdat.b(:, 1), plotdat.b(:, 2));
                %  mysigstar(gca, 1:2, 0.9*min(get(gca, 'ylim')), pval, 'k', 'up');
        end
        
        switch vars2split{v}
            case 'recalled_d1'
                ylabel({'Recall day 1' 'Logistic regression weights'});
            case 'recalled_d2'
                ylabel({'Recall day 2' 'Logistic regression weights'});
            case 'recog_oldnew'
                ylabel({'Recognition day 2' 'Logistic regression weights'});
            case 'consolidation'
                ylabel({'Recognition day 1 vs. both' 'Logistic regression weights'});
        end
        
        tightfig;
        xlim([0.7 2.3]);
        offsetAxes;
        
        print(gcf, '-dpdf', sprintf('%s/figures/logres_figure2_v%d_%s_%s.pdf', ...
            mypath, v, conds{c}, whichStat));
        
    end
end
end
