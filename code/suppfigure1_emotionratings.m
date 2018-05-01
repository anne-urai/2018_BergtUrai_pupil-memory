function suppfigure1_emotionratings

global mypath;
load(sprintf('%s/data/alldata_%s.mat', mypath, 'img_raw'), 'dat');

rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);

wrongtrls = (dat.emotional == 0 & dat.emotion_score > 0) | ...
    (dat.emotional == 1 & dat.emotion_score == 0);
dat.subj_idx(wrongtrls) = NaN;

[gr, sjnr, emotion_score] = findgroups(dat.subj_idx, dat.emotion_score);
avgdat          = array2table([sjnr emotion_score], 'variablenames', {'subj_idx', 'emotion_score'});

vars2plot = {'recalled_d1', 'recalled_d2', 'recog_oldnew', 'pupil_dilation_enc'};
for v = 1:length(vars2plot),
    avgdat.(vars2plot{v})    = splitapply(@nanmean, dat.(vars2plot{v}), gr);
    
    close all; subplot(441); hold on;
    % make mat
    thisdat = avgdat(:, {'subj_idx', 'emotion_score', vars2plot{v}});
    thisdat = unstack(thisdat,vars2plot{v},  'emotion_score');
    mat = thisdat{:, 2:end};
    
    % plot
    %plot(mat', 'k-', 'color', [0.5 0.5 0.5], 'linewidth', 0.3);
    p = ploterr(1, nanmean(mat(:, 1)), [], nanstd(mat(:, 1)) ./ sqrt(size(mat, 1)), 'k-', 'abshhxy', 0);
    set(p(1), 'marker', '.', 'markeredgecolor', rdgy(end, :), 'markersize', 15);
    set(p(2), 'color', rdgy(end, :));
    
    p = ploterr(2:4, nanmean(mat(:, 2:4)), [], nanstd(mat(:, 2:4)) ./ sqrt(size(mat, 1)), 'k-', 'abshhxy', 0);
    set(p(1), 'marker', '.', 'markeredgecolor', rdgy(1, :), 'markersize', 15);
    set(p(2), 'color', rdgy(1, :));
    
    switch vars2plot{v}
        case 'recalled_d1'
            ylabel('Fraction recalled, day 1');
        case 'recalled_d2'
            ylabel('Fraction recalled, day 2');
        case 'recog_oldnew'
            ylabel('Fraction recognized, day 2');
        case 'dprime'
            ylabel('Recognition d''');
        case 'pupil_dilation_enc'
            ylabel('Pupil response (z)');
    end
    
    % STATS
    x       = mat(:, 2:4);
    % remove subject with missing rating
    x(isnan(mean(mat, 2)), :) = [];
    s       = repmat([1:size(x, 1)]', 1,3);
    f       = repmat(1:3, size(x, 1), 1);
    %f2       = repmat([1 1 2], 54, 1);
    stats   = rm_anova(x(:), s(:), {f(:)});
    
    if stats.f1.pvalue  < 0.001,
        text(1.9, nanmean(mat(:, 1)), ...
            sprintf('F(%d,%d) = %.2f, p < 0.001', stats.f1.df(1), stats.f1.df(2), stats.f1.fstats), 'fontsize', 4);
    else
        text(1.9, nanmean(mat(:, 1)), ...
            sprintf('F(%d,%d) = %.2f, p = %.3f', stats.f1.df(1), stats.f1.df(2), stats.f1.fstats, stats.f1.pvalue), 'fontsize', 4);
    end
    
    % also add some stupid significance stars for post-hoc comparisons
    if stats.f1.pvalue < 0.05,
        [h, pval12] = ttest(mat(:, 2), mat(:, 3));
        [h, pval23] = ttest(mat(:, 3), mat(:, 4));
        [h, pval13] = ttest(mat(:, 2), mat(:, 4));
        
        ylims = get(gca, 'ylim');
        mysigstar(gca, [2.1, 2.9], max(ylims), pval12, 'k', 'down');
        mysigstar(gca, [3.1, 3.9], max(ylims), pval23, 'k', 'down');
        mysigstar(gca, [2.1, 3.9], mean([ nanmean(mat(:, 2)), nanmean(mat(:, 1))]), pval13, 'k', 'up');
    end
    
    axis square;
    set(gca, 'xtick', 1:4, 'xticklabel', {'Neutral', 'Barely negative', 'Rather negative', 'Very negative'}, ...
        'xticklabelrotation', -30);
    offsetAxes; tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/emotionratings_v%d.pdf', mypath, v));
    
end


end