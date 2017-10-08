

function b = plotData(timeaxis, pupildat, table, splitby, colors)

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
end

meanFun = @(x) nanmean(x, 1); % make sure to average over the 1st dim always
newdat = splitapply(meanFun, pupildat(~isnan(gr), :), gr(~isnan(gr)));

% average over participants, not contrasts!
mn      = splitapply(@nanmean, newdat, findgroups(contrast));
sem     = permute(  splitapply(@nanstd, newdat, findgroups(contrast)) ...
    ./ sqrt(numel(unique(sjidx))), [2 3 1]);
if ndims(sem) == 2, sem = sem'; end

% colors  = cbrewer('div', 'RdBu', size(mn, 1));
b       = boundedline(timeaxis, mn, sem, 'nan', 'gap', 'cmap', colors);

axis tight;
ylabel('Pupil response (z)');

% stats
if numel(unique(contrast)) == 2,
    c = unique(contrast);
    
    try
    [h, p, stat] = ttest_clustercorr(newdat(contrast == c(1), :), newdat(contrast == c(2), :));
    plot(timeaxis(find(h == 1)), min(get(gca, 'ylim'))*ones(length(find(h==1))), 'k.');
    catch
        assert(1==0);
    end
elseif numel(unique(contrast)) > 2, % regress 0-4
    c = unique(contrast);
    [h, p, stat] = regress_clustercorr(newdat, contrast+1, sjidx);
    plot(timeaxis(find(h == 1)), min(get(gca, 'ylim'))*ones(length(find(h==1))), 'k.');
end

offsetAxes;
end
