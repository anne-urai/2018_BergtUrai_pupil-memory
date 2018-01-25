
% THIS SCRIPT MAKES A SECOND-LEVEL FILE FROM THE FIRSTLEVEL ONE and writes
% this to Excel

rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);
global mypath

dat = readtable(sprintf('%s/data/secondLevel_matlab.xls', mypath));
vars = dat.Properties.VariableNames';
for v = 1:length(vars),
    if strfind(vars{v}, 'neut'),
        
        % grab the two variables
        thisdat = [dat.(vars{v}) dat.(regexprep(vars{v}, 'neut', 'neg'))];
        
        %% plot this
        close all;
        sp1 = subplot(461); hold on;
        plotBetasSwarm(thisdat, rdgy([end 1], :));
        set(gca, 'xtick', 1:2, 'xticklabel', {'Neutral', 'Emotional'}, 'xticklabelrotation', -30);
        
        switch vars{v}
            case {'images_recalled_d1_neut', 'words_recalled_d1_neut'}
                ylabel('Fraction recalled, day 1');
            case {'images_recalled_d2_neut', 'words_recalled_d2_neut'}
                ylabel('Fraction recalled, day 2');
            case {'words_regression_pupil_recalled_d1_neut', 'images_regression_pupil_recalled_d1_neut'}
                ylabel({'Recall day 1', 'Logistic regression weights'});
            case {'words_regression_pupil_recalled_d2_neut', 'images_regression_pupil_recalled_d2_neut'}
                ylabel({'Recall day 2', 'Logistic regression weights'});
                
            case {'words_recog_dprime_neut', 'images_recog_dprime_neut'}
                ylabel('Recognition d''');
            case {'words_confidence_recog_neut', 'images_confidence_recog_neut'};
                ylabel('Recognition confidence (1-4)');
            case {'images_pupil_dilation_enc_neut', 'words_pupil_dilation_enc_neut'}
                ylabel('Pupil response (z)');
            otherwise
                ylabel(regexprep(vars{v}(1:end-5), '_', ' '));
        end
        
        %% ADD STATISTICS
        [~, pval, ~, stats] = ttest(thisdat(:, 1));
        if pval < 0.001,
            txt{1} = sprintf('Neutral t(%d) = %.3f, p < 0.001', stats.df, stats.tstat);
        else
            txt{1} = sprintf('Neutral t(%d) = %.3f, p = %.3f', stats.df, stats.tstat, pval);
        end
        
        [~, pval, ~, stats] = ttest(thisdat(:, 2));
        if pval < 0.001,
            txt{2} = sprintf('Emotional t(%d) = %.3f, p < 0.001', stats.df, stats.tstat);
        else
            txt{2} = sprintf('Emotional t(%d) = %.3f, p = %.3f', stats.df, stats.tstat, pval);
        end
        
        [~, pval, ~, stats] = ttest(thisdat(:, 2), thisdat(:, 1));
        if pval < 0.001,
            txt{3} = sprintf('Emotional vs. Neutral t(%d) = %.3f, p < 0.001', stats.df, stats.tstat);
        else
            txt{3} = sprintf('Emotional vs. Neutral t(%d) = %.3f, p = %.3f', stats.df, stats.tstat, pval);
        end
        
        text(3, mean(get(gca, 'ylim')), ...
            txt, 'verticalalignment', 'middle', 'fontsize', 5);
        axis tight;
        subplot(4,4,2); axis off;
        %  axis off;
        
        % make sure the axis label is visible
        tightfig;
        set(sp1, 'xlim', [0.7 3]);
        offsetAxes(sp1);
        print(gcf, '-depsc', sprintf('%s/figures/barplots_%s_withstats.eps', mypath, vars{v}(1:end-5)));
        print(gcf, '-dpng', sprintf('%s/figures/barplots_%s_withstats.png', mypath, vars{v}(1:end-5)));
        
    end
end