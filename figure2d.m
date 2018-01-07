

global mypath;
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);
conds       = {'img_raw', 'aud'};

for c = 1:length(conds),
    
    close all; subplot(441); hold on;
    
    emotions = [0 1];
    for e = 1:2,
        
        load(sprintf('%s/data/alldata_%s.mat', mypath, conds{c}), 'dat');
        dat = dat(dat.emotional == emotions(e), :);

        % within correctly recognized trials, does the pupil predict better
        % recognition performance?
        
        [gr, sjnr, confidence_recog] = findgroups(dat.subj_idx, dat.confidence_recog);
        avgdat          = array2table([sjnr confidence_recog], 'variablenames', {'subj_idx', 'confidence_recog'});
        avgdat.pupil    = splitapply(@nanmean, dat.pupil_dilation_enc, gr);
        
        % only take the pupil when averaged over at least 10 trials
        nrtrls  = splitapply(@numel, dat.pupil_dilation_enc, gr);
        avgdat.pupil(nrtrls < 10) = NaN;
        
        thisdat = unstack(avgdat, 'pupil',  'confidence_recog');
        mat = thisdat{:, 2:end};
        
        p = ploterr(1:4, nanmean(mat), [], nanstd(mat) ./ sqrt(size(mat, 1)), 'k-', 'abshhxy', 0);
        set(p(1), 'marker', '.', 'markeredgecolor', rdgy(e, :), 'markersize', 15);
        set(p(2), 'color', rdgy(e, :));
    end
    
    % (1= ?gar nicht sicher?, 2= ?etwas sicher?, 3= ?ziemlich sicher? und 4= ?sehr sicher?
    set(gca, 'xtick', 1:4, 'xticklabel', ...
        {'Not sure', 'Bit sure', 'Pretty sure', 'Very sure'}, 'xticklabelrotation', -30);
    
    axis tight; 
    axis square; offsetAxes;
    ylabel('Pupil response (z)');
    
    switch c
        case 1
            title('Memory task: images');
        case 2
            title('Memory task: words');
    end
    tightfig;
    print(gcf, '-dpdf', sprintf('%s/figures/confidence_recog_v%d.pdf', mypath, c));

end

