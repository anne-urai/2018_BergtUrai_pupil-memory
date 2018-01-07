function figure1

global mypath;

conds   = {'img_raw', 'aud'};
mrks    = {'o', 'd'};
rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);
piyg    = cbrewer('div', 'PiYG', 10);

vars2plot = {'recalled_d1', 'recalled_d2', 'recog_oldnew', 'dprime', 'confidence_recog', 'pupil_dilation_enc'};
for v = 1:length(vars2plot),
    
    close all; subplot(441); hold on;
    for c = 1:length(conds),
        
        % get the data
        load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
        [gr, sjnr, emotional] = findgroups(dat.subj_idx, dat.emotional);
        avgdat = array2table([sjnr emotional], 'variablenames', {'subj_idx', 'emotional'});
        
        % average over subjects
        switch vars2plot{v}
            case 'dprime'
                avgdat.var = splitapply(@dprime, dat.target_oldnew, dat.recog_oldnew, gr);
            case 'confidence_recog'
                % only use hit trials
                dat.confidence_recog(dat.recog_oldnew == 0 | dat.target_oldnew == 0) = NaN;
                avgdat.var = splitapply(@nanmean, dat.(vars2plot{v}), gr);
            otherwise
                avgdat.var = splitapply(@nanmean, dat.(vars2plot{v}), gr);
        end
        
        % plot this!
        scatter(avgdat.var(avgdat.emotional == 0), avgdat.var(avgdat.emotional == 1), ...
            1, [0.5 0.5 0.5], mrks{c});
        
        % add the sem + mean on top
        p = ploterr(nanmean(avgdat.var(avgdat.emotional == 0)), nanmean(avgdat.var(avgdat.emotional == 1)), ...
            nanstd(avgdat.var(avgdat.emotional == 0)) ./ sqrt(size(avgdat.var(avgdat.emotional == 0))), ...
            nanstd(avgdat.var(avgdat.emotional == 1)) ./ sqrt(size(avgdat.var(avgdat.emotional == 1))), ...
            'abshhxy', 0);
        set(p(1), 'marker', mrks{c}, 'markersize', 3, 'color', 'k', 'linewidth', 0.5);
        set(p(2), 'color', 'k', 'linewidth', 0.5); set(p(3), 'color', 'k', 'linewidth', 0.5);
        ph{c} = p;
        
        % add stats!
        [h, pval, ci, stats] = ttest(avgdat.var(avgdat.emotional == 0), ...
            avgdat.var(avgdat.emotional == 1));
        
        if h,
            set(p(1), 'markerfacecolor', 'k', 'markeredgecolor', 'k');
        elseif ~h,
            set(p(1), 'markerfacecolor', 'w', 'markeredgecolor', 'k');
        end
        
        switch conds{c}
            case 'img_raw'
                legtxt = 'Images';
            case 'aud'
                legtxt = 'Words';
        end
        
        if pval < 0.001,
            txt{c} = sprintf('%s\nt(%d) = %.2f, p < 0.001', legtxt, stats.df, stats.tstat);
        else
            txt{c} = sprintf('%s\nt(%d) = %.2f, p = %.3f', legtxt, stats.df, stats.tstat, pval);
        end
        
    end
    
    % layout of the plot
    axis tight; xlims = get(gca, 'xlim'); ylims = get(gca, 'ylim');
    newlims = [min([xlims ylims]) max([xlims ylims])];
    xlim(newlims); ylim(newlims); axis square;
    r = refline(1, 0); r.Color = 'k'; r.LineWidth = 0.5;
    
    % stats text
    text(mean([min(newlims), mean(newlims), mean(newlims)]), ...
        mean([min(newlims), min(newlims), mean(newlims)]), txt, 'fontsize', 4);
    %lh = legend([ph{1}(1) ph{2}(1)], txt, 'location', 'southeast');
    %lh.Box = 'off';
    %lh.FontSize = 4;
    
    % axes
    xlabel('Neutral');
    ylabel('Emotional');
    set(gca, 'ycolor', rdgy(1, :));
    set(gca, 'xcolor', rdgy(end, :));
    set(gca, 'xtick', get(gca, 'ytick'));
    
    switch vars2plot{v}
        case 'recalled_d1'
            title('Fraction recalled, day 1');
        case 'recalled_d2'
            title('Fraction recalled, day 2');
        case 'recog_oldnew'
            title('Fraction recognized, day 2');
        case 'dprime'
            title('Recognition d''');
        case 'confidence_recog'
            title('Recognition confidence');
        case 'pupil_dilation_enc'
            title('Pupil response');
    end
    
    offsetAxes; tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/scatter_v%d.pdf', mypath, v));
    
end
end