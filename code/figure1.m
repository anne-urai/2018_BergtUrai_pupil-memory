function figure1

global mypath;

conds   = {'img_raw', 'aud'};
mrks    = {'o', 'd'};
rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);
piyg    = cbrewer('div', 'PiYG', 10);

vars2plot = {'recalled_d1', 'recalled_d2', 'recog_oldnew', 'dprime', 'confidence_recog', 'pupil_dilation_enc'};
for v = 1:length(vars2plot),
    
    for c = 1:length(conds),
        
        close all; subplot(441); hold on;
        
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
            txt = sprintf('t(%d) = %.2f\np < 0.001', stats.df, stats.tstat);
        else
            txt = sprintf('t(%d) = %.2f\np = %.3f', stats.df, stats.tstat, pval);
        end
        
        % layout of the plot
        axis tight; xlims = get(gca, 'xlim'); ylims = get(gca, 'ylim');
        newlims = [min([xlims ylims]) max([xlims ylims])];
        xlim(newlims); ylim(newlims); axis square;
        xtick = roundn(newlims, -1);
        set(gca, 'xtick', unique([min(xtick) get(gca, 'xtick')]), ...
            'ytick', unique([min(xtick) get(gca, 'xtick')]));
        r = refline(1, 0); r.Color = 'k'; r.LineWidth = 0.5;
        
        % stats text
        text(mean([mean(newlims), mean(newlims)]), ...
            mean([min(newlims), min(newlims), mean(newlims)]), txt, 'fontsize', 4);
        
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
        print(gcf, '-dpdf', sprintf('%s/figures/scatter_v%d_%s.pdf', mypath, v, conds{c}));
        
        %% also a good old barplot...
        close all; subplot(441); hold on;
        
        %% plot this
        close all; subplot(471); hold on;
        plotdat.b = [avgdat.var(avgdat.emotional == 0), avgdat.var(avgdat.emotional == 1)];
        plotBetasSwarm(plotdat.b, rdgy([end 1], :));
        set(gca, 'xtick', 1:2, 'xticklabel', {'Neutral', 'Emotional'}, 'xticklabelrotation', -35);
        [~, pval] = ttest(plotdat.b(:, 1), plotdat.b(:, 2));
        mysigstar(gca, 1:2, max(get(gca, 'ylim')), pval, 'k', 'down');
        
        switch vars2plot{v}
            case 'recalled_d1'
                ylabel('Fraction recalled, day 1');
            case 'recalled_d2'
                ylabel('Fraction recalled, day 2');
            case 'recog_oldnew'
                ylabel('Fraction recognized, day 2');
            case 'dprime'
                ylabel('Recognition d''');
            case 'confidence_recog'
                ylabel('Recognition confidence');
            case 'pupil_dilation_enc'
                ylabel('Pupil response');
        end
        
        tightfig;
        xlim([0.7 2.3]);
        switch c
            case 1
                ylim([0 0.8]); set(gca, 'ytick', 0:0.2:0.6);
            case 2
                ylim([0 0.6]); set(gca, 'ytick', 0:0.2:0.4);
        end
        offsetAxes;
        print(gcf, '-dpdf', sprintf('%s/figures/scatter_v%d_%s_bar.pdf', mypath, v, conds{c}));
        
        
    end
    
end
end