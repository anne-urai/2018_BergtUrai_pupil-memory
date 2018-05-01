function figure1_correlations

global mypath;

conds   = {'img_raw', 'aud'};
mrks    = {'o', 'd'};
rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);

vars2plot = {'recalled_d1', 'recalled_d2', 'recog_oldnew',};
for v = 1:length(vars2plot),
    
    for c = 1:length(conds),
        
        close all; subplot(441); hold on;
        % get the data
        load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
        [gr, sjnr, emotional] = findgroups(dat.subj_idx, dat.emotional);
        avgdat          = array2table([sjnr emotional], 'variablenames', {'subj_idx', 'emotional'});
        avgdat.pupil    = splitapply(@nanmean, dat.pupil_dilation_enc, gr);
        
        % average over subjects
        switch vars2plot{v}
            case 'dprime'
                avgdat.var = splitapply(@dprime, dat.target_oldnew, dat.recog_oldnew, gr);
            otherwise
                avgdat.var = splitapply(@nanmean, dat.(vars2plot{v}), gr);
        end
        
        % take the difference between emotional and neutral
        assert(isequal(avgdat.subj_idx(avgdat.emotional == 1), ...
            avgdat.subj_idx(avgdat.emotional == 0)), 'subj_idx does not match');
        pupdiff = avgdat.pupil(avgdat.emotional == 1) - avgdat.pupil(avgdat.emotional == 0);
        vardiff = avgdat.var(avgdat.emotional == 1) - avgdat.var(avgdat.emotional == 0);
        
        s = scatter(pupdiff, vardiff, ...
            15, [0.5 0.5 0.5], mrks{c}, 'filled');
        s.MarkerEdgeColor = 'w';
        
        l       = lsline;
        l(1).LineWidth = 0.5;
        l(1).Color = 'k';
        [r, pval] = corr(pupdiff, vardiff, 'rows', 'pairwise', 'type', 'pearson');
        txt{1} = sprintf('r = %.3f, p = %.3f', r, pval);
        
        %% also add the same datapoints from Anne Bergt's file
        spssdat = readtable(sprintf('%s/data/fromSPSS/pupilsandmemory_second_level.csv', mypath), ...
            'TreatAsEmpty', 'NA');
        switch conds{c}
            case 'img_raw'
                cname = 'pic';
            case 'aud'
                cname = 'word';
        end
        
        pupdiff = spssdat.([cname '_pupil_d1_dilation_neg']) - spssdat.([cname '_pupil_d1_dilation_neut']);
        try
            pupdiff = (spssdat.([cname '_diff_pupil_left_dilation_neut_neg']) + ...
                spssdat.([cname '_diff_pupil_right_dilation_neut_neg'])) ./ 2;
        catch
            pupdiff = spssdat.([cname '_diff_pupil_dilation_neut_neg']);
        end
        switch vars2plot{v}
            case 'recalled_d1'
                vardiff = spssdat.([cname '_d1freerecall_neg']) - spssdat.([cname '_d1freerecall_neut']);
                vardiff = spssdat.([cname '_diff_d1freerecall_neut_neg']);
            case 'recalled_d2'
                vardiff = spssdat.([cname '_d2freerecall_neg']) - spssdat.([cname '_d2freerecall_neut']);
                vardiff = spssdat.([cname '_diff_d2freerecall_neut_neg']);
            case 'recog_oldnew'
                vardiff = spssdat.([cname '_hitrate_neg']) - spssdat.([cname '_hitrate_neut']);
        end
        
        s = scatter(pupdiff, vardiff, ...
            5, [0.5 0.7 0.5], mrks{c}, 'filled');
        s.MarkerEdgeColor = 'none';
        
        l       = lsline;
        l(1).Color = 'k';
        l(2).Color = [0.3 0.7 0.3];
        
        [r, pval] = corr(pupdiff, vardiff, 'rows', 'pairwise', 'type', 'pearson');
        txt{2} = sprintf('r = %.3f, p = %.3f', r, pval);
        
        xlabel({'Emotional vs. neutral' 'Pupil response (z)'});
        switch vars2plot{v}
            case 'recalled_d1'
                ylabel({'Emotional vs.neutral', 'Fraction recalled, day 1'});
            case 'recalled_d2'
                ylabel({'Emotional vs.neutral', 'Fraction recalled, day 2'});
            case 'recog_oldnew'
                ylabel({'Emotional vs.neutral', 'Fraction recognized, day 2'});
            case 'dprime'
                ylabel({'Emotional vs.neutral', 'Recognition d'''});
        end
        
        axis tight; xlims = get(gca, 'xlim'); ylims = get(gca, 'ylim');
        text(mean([mean(xlims), mean(xlims)]), ...
            mean([min(ylims), min(ylims), mean(ylims)]), txt, 'fontsize', 4);
        
        axis square;
        offsetAxes; tightfig;
        print(gcf, '-dpdf', sprintf('%s/figures/scatter_correlation_v%d_%s.pdf', mypath, v, conds{c}));
    end
    
end
end