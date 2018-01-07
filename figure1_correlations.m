function figure1_correlations

global mypath;

conds   = {'img_raw', 'aud'};
mrks    = {'o', 'd'};
rdgy    = cbrewer('div', 'RdBu', 15); rdgy = rdgy(2:end-1, :);

vars2plot = {'recalled_d1', 'recalled_d2', 'recog_oldnew', 'dprime'};
for v = 1:length(vars2plot),
    
    close all; subplot(441); hold on;
    for c = 1:length(conds),
        
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
        pupdiff = avgdat.pupil(avgdat.emotional == 1) - avgdat.pupil(avgdat.emotional == 0);
        vardiff = avgdat.var(avgdat.emotional == 1) - avgdat.var(avgdat.emotional == 0);
        
        scatter(pupdiff, vardiff, ...
            5, [0.5 0.5 0.5], mrks{c});
        l       = lsline;
        l(1).LineWidth = 0.5;
        try
            l(2).LineWidth = 0.5;
        end
        
        switch conds{c}
            case 'img_raw'
                legtxt = 'Images';
            case 'aud'
                legtxt = 'Words';
        end
        
        [r, pval] = corr(pupdiff, vardiff, 'rows', 'complete');
        txt{c} = sprintf('%s r = %.3f, p = %.3f', legtxt, r, pval');
        if pval < 0.05,
            l(1).Color = 'k';
        else
            l(1).Color = [0.8 0.8 0.8];
        end
    end
    
    xlabel('Pupil emotional-neutral');
    switch vars2plot{v}
        case 'recalled_d1'
            ylabel({'Fraction recalled, day 1', 'emotional-neutral'});
        case 'recalled_d2'
            ylabel({'Fraction recalled, day 2', 'emotional-neutral'});
        case 'recog_oldnew'
            ylabel({'Fraction recognized, day 2', 'emotional-neutral'});
        case 'dprime'
            ylabel({'Recognition d''', 'emotional-neutral'});
    end
    
    axis tight; axis square;
    title(txt);
    offsetAxes; tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/scatter_correlation_v%d.pdf', mypath, v));
end
end