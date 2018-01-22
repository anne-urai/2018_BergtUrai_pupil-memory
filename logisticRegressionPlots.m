function logisticRegressionPlots

global mypath;

conds       = {'img_raw', 'aud'};
mrks        = {'o', 'd'};
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);
rdgy_scat   = cbrewer('div', 'RdBu', 15); rdgy_scat = rdgy_scat([end-4 5], :);
vars2split  = {'recalled_d1', 'recalled_d2', 'recog_oldnew'};
warning('error', 'stats:glmfit:IllConditioned'); % remove those subjects
warning('error', 'stats:glmfit:IterationLimit');

for v = 1:length(vars2split),
    for c = 1:length(conds),
        
        clear plotdat
        emotions = [0 1];
        for e = 1:2,
            
            % get the data
            load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
            dat = dat(dat.emotional == emotions(e), :);
            
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
            ploterr(e+0.1, glme{e}.Coefficients.Estimate(2), [], ...
                [glme{e}.Coefficients.Lower(2), glme{e}.Coefficients.Upper(2)],  '.k', 'abshhxy', 0);
            mysigstar(gca, e, max(get(gca, 'ylim')), glme{e}.Coefficients.pValue(2));
        end
        
        switch vars2split{v}
            case 'recalled_d1'
                ylabel({'Recall day 1' 'Logistic regression weights'});
            case 'recalled_d2'
                ylabel({'Recall day 2' 'Logistic regression weights'});
            case 'recog_oldnew'
                ylabel({'Recognition day 2' 'Logistic regression weights'});
        end
        
        tightfig;
        xlim([0.7 2.3]);
        offsetAxes;
        
        print(gcf, '-dpdf', sprintf('%s/figures/logres_figure2_v%d_%s.pdf', mypath, v, conds{c}));
        
    end
end
end

function b = logresfun(x,y)

try
    b = glmfit(y, x, 'binomial', 'link', 'logit');
    b = b(2);
catch
    % if there
    b = nan(1);
end
%if abs(b) > 2, b = nan; end

end

