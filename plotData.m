

function b = plotData(timeaxis, pupildat, table, splitby, colors, statcols)

if ~exist('colors', 'var'), colors  = viridis(5); end

switch numel(splitby)
    case 1
        [gr, sjidx] = findgroups(table.(splitby{1}));
        contrast = ones(size(sjidx));
    case 2
        [gr, sjidx, contrast] = findgroups(table.(splitby{1}), table.(splitby{2}));
        
        % check that we only use those subjects who have data in the two conditions
        [sjgr, sjcheck] = findgroups(sjidx);
        check = splitapply(@nanmean, contrast, sjgr);
        removesj = sjcheck(check ~= nanmean(unique(contrast)));
        if ~isempty(removesj),
            disp('REMOVING SUBJECTS, COULDNT FIND FULL FACTORIAL DESIGN');
            table.subj_idx(ismember(table.subj_idx, removesj)) = NaN;
            [gr, sjidx, contrast] = findgroups(table.(splitby{1}), table.(splitby{2}));
        end
        
    case 3
        [gr, sjidx, contrast1, contrast2] = findgroups(table.(splitby{1}), table.(splitby{2}), table.(splitby{3}));
        contrast = findgroups(contrast1, contrast2);

        % check that we only use those subjects who have data in the two conditions
        [sjgr, sjcheck] = findgroups(sjidx);
        check = splitapply(@nanmean, contrast1, sjgr);
        removesj = sjcheck(check ~= nanmean(unique(contrast1)));
        if ~isempty(removesj),
            disp('REMOVING SUBJECTS, COULDNT FIND FULL FACTORIAL DESIGN');
            table.subj_idx(ismember(table.subj_idx, removesj)) = NaN;
            [gr, sjidx, contrast1, contrast2] = findgroups(table.(splitby{1}), table.(splitby{2}), table.(splitby{3}));
            contrast = findgroups(contrast1, contrast2);
        end
        
        [sjgr, sjcheck] = findgroups(sjidx);
        check = splitapply(@nanmean, contrast2, sjgr);
        removesj = sjcheck(check ~= nanmean(unique(contrast2)));
        if ~isempty(removesj),
            disp('REMOVING SUBJECTS, COULDNT FIND FULL FACTORIAL DESIGN');
            table.subj_idx(ismember(table.subj_idx, removesj)) = NaN;
            [gr, sjidx, contrast1, contrast2] = findgroups(table.(splitby{1}), table.(splitby{2}), table.(splitby{3}));
            contrast = findgroups(contrast1, contrast2);
        end
end

meanFun = @(x) nanmean(x, 1); % make sure to average over the 1st dim always
newdat = splitapply(meanFun, pupildat(~isnan(gr), :), gr(~isnan(gr)));

% only use the parts that are not contaminated by the offset?
newdat(:, timeaxis < -2 | timeaxis > 3) = NaN;

% average over participants, not contrasts!
mn      = splitapply(@nanmean, newdat, findgroups(contrast));
sem     = permute(  splitapply(@nanstd, newdat, findgroups(contrast)) ...
    ./ sqrt(numel(unique(sjidx))), [2 3 1]);
if ndims(sem) == 2, sem = sem'; end

% colors  = cbrewer('div', 'RdBu', size(mn, 1));
b       = boundedline(timeaxis, mn, sem, 'nan', 'gap', 'cmap', colors);

axis tight; vline(0, 'color', 'k', 'linewidth', 0.5);
ylabel('Pupil response (z)');

% stats
if numel(unique(contrast)) == 2,
    c = unique(contrast);
    [h, p, stat] = ttest_clustercorr(newdat(contrast == c(1), :), newdat(contrast == c(2), :));
    
    plot(timeaxis(find(h == 1)), min(get(gca, 'ylim'))*ones(length(find(h==1))), 'k.', 'markersize', 3);
disp([min(timeaxis(find(h == 1))) max(timeaxis(find(h == 1)))]);


elseif numel(splitby) == 3 && numel(unique(contrast1)) == 2 && numel(unique(contrast2)) == 2,
    c = unique(contrast2);
    emotions = unique(contrast1);
    % separately test recalled vs forgotten for emotional and neutral
    % stimuli
    for e = 1:2,
        [h, p, stat] = ttest_clustercorr(newdat(contrast1 == emotions(e) & contrast2 == c(1), :), ...
            newdat(contrast1 == emotions(e) & contrast2 == c(2), :));

        plot(timeaxis(find(h == 1)), min(get(gca, 'ylim'))*ones(length(find(h==1))), ...
            'k', 'markersize', 3, 'color', statcols(e, :));
        disp([min(timeaxis(find(h == 1))) max(timeaxis(find(h == 1)))]);
        if e == 1, axis tight; axisNotSoTight(gca, 0.05); end
    end
end

axis tight;
offsetAxes;
end
