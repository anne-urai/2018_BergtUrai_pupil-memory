function consolidationPupil

global mypath;

conds       = {'img_raw', 'aud'};
rdgy        = cbrewer('div', 'RdBu', 15); rdgy = rdgy([ end-1 2], :);

for c = 1:length(conds),
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
        
        % for each subject, how are these responses distributed?
        [gr, sjidx, scoreidx] = findgroups(dat.subj_idx, dat.recall_score);
        fractions   = splitapply(@numel, dat.recall_score, gr);
        thistab     = array2table([fractions sjidx scoreidx], ...
            'variablenames', {'nrtrials', 'subj_idx', 'recall_score'});
        thistab     = unstack(thistab, 'nrtrials',  'recall_score');
        thismat     = thistab{:, 2:end};
        thismat     = thismat ./ nansum(thismat, 2);
        
        % ignore the ones that were forgotten completely
        thismat = thismat(:, [4 2 3]);
        thismat(isnan(thismat)) = 0; % if there is nothing, means this is not even present so 0
        
        %% PLOT THIS!
        close all; subplot(441); hold on;
        plot(thismat', '.-', 'color', [0.8 0.8 0.8], 'linewidth', 0.3, 'markersize', 3);
        p = ploterr(1:size(thismat, 2), nanmean(thismat), [], ...
            nanstd(thismat) ./ sqrt(size(thismat, 1)) * 1.96, 'k.', 'abshhxy', 0);
        
        %% markers and colors depend on emotionality and condition
        set(p(1), 'marker', '.', 'markeredgecolor', rdgy(e, :), 'markersize', 10);
        set(p(2), 'color', rdgy(e, :));
        
        set(gca, 'xtick', 1:size(thismat, 2), 'xticklabel', ...
            {'D1 & D2', 'D1 only', 'D2 only'}, 'xticklabelrotation', -30);
        xlabel('Successful recall');
        ylabel('Fraction of stimuli');
        % ylim([0 0.12]); set(gca, 'ytick', [0:0.4:0.12]);
        axis tight; axis square; box off; offsetAxes;
        
        ylim([-0.0125 0.274]);
        
        if c == 1 && e == 1,
            title('Neutral images');
        elseif c == 1 && e == 2,
            title('Emotional images');
        elseif c == 2 && e == 1,
            title('Neutral words');
        elseif c == 2 && e == 2,
            title('Emotional words');
        end
        
        print(gcf, '-depsc', sprintf('%s/figures/consolidation_%s_emotional%d.eps', ...
            mypath, conds{c}, emotions(e)));
        
        tightfig;
        print(gcf, '-dpdf', sprintf('%s/figures/consolidation_%s_emotional%d.pdf', ...
            mypath, conds{c}, emotions(e)));
        
    end
end
