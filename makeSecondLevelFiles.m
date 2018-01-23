function makeSecondLevelFiles

% THIS SCRIPT MAKES A SECOND-LEVEL FILE FROM THE FIRSTLEVEL ONE and writes
% this to Excel

global mypath
conds = {'images', 'words'};
for c = 1:length(conds),
    
    emotions = [0 1];
    emotionNames = {'neut', 'neg'};
    for e = 1:2,
        
        tic;
        % GET THE RIGHT DATA
        dat = readtable(sprintf('%s/data/alldata_%s.csv', mypath, conds{c}));
        dat = dat(dat.emotional == emotions(e), :);
        [gr, sjidx] = findgroups(dat.subj_idx);
        tmptab = array2table([sjidx ], 'variablenames', {'subj_idx'});
        
        %% AVERAGE EVERYTHING!
        avgflds = dat.Properties.VariableNames';
        avgflds = setdiff(avgflds, {'subj_idx', 'emotional', 'image', 'trialnr_enc', 'word'}); % exclude some
        for f = 1:length(avgflds),
            tmptab.([conds{c} '_' avgflds{f} '_' emotionNames{e}]) = splitapply(@nanmean, dat.(avgflds{f}), gr);
        end
        
        %% ALSO ADD SOME OTHER VARIABLES that are a bit more complex
        
        % 1. logistic regression of pupil onto recall
        avgflds = {'recalled_d1', 'recalled_d2', 'recog_oldnew'};
        for f = 1:length(avgflds),
            tmptab.([conds{c} '_regression_pupil_' avgflds{f} '_' emotionNames{e}]) = ...
                splitapply(@logresfun, dat.(avgflds{f}), dat.pupil_dilation_enc, gr);
        end
        
        % 2. pupil for recalled vs. not-recalled, hits and misses
        selectiveMeanFun = @(x,y) nanmean(x(y==1));
        for f = 1:length(avgflds),
            categories = unique(dat.(avgflds{f})); % for each outcome, mean pupil dilation
            categories = categories(~isnan(categories));
            assert(length(categories) == 2, 'too many categories');
            
            for cidx = 1:length(categories),
                tmptab.([conds{c} '_pupil_dilation_enc_' avgflds{f} '_' num2str(categories(cidx)) '_' emotionNames{e}]) = ...
                    splitapply(selectiveMeanFun, dat.pupil_dilation_enc, double(dat.(avgflds{f}) == categories(cidx)), gr);
            end
        end
        
        % 3. hitrate and false alarm rate
        hitrateFun = @(x,y) nanmean(x(y==1));
        tmptab.([conds{c} '_recog_hitrate_' emotionNames{e}]) = ...
            splitapply(hitrateFun, dat.recog_oldnew, dat.target_oldnew, gr);
        
        falseAlarmFun = @(x,y) nanmean(x(y==0));
        tmptab.([conds{c} '_recog_falsealarmrate_' emotionNames{e}]) = ...
            splitapply(falseAlarmFun, dat.recog_oldnew, dat.target_oldnew, gr);
        
        % keep this all in for appending later
        allinfo{c, e} = tmptab;
        toc;
    end
end

%% NOW APPEND IMAGES AND WORD DATA
allimages   = join(allinfo{1, :});
plotOverview(allimages, 'images');
allwords    = join(allinfo{2, :});
plotOverview(allwords, 'words');

fulltab     = outerjoin(allimages, allwords, 'keys', {'subj_idx'});
fulltab.subj_idx = fulltab.subj_idx_allimages;
fulltab(:, {'subj_idx_allwords', 'subj_idx_allimages'}) = [];
writetable(fulltab, sprintf('%s/data/secondLevel_matlab.xls', mypath));

%% THEN MERGE WITH ANNE BERGT'S SPSS FILE!
spssdat = readtable(sprintf('%s/data/fromSPSS/pupilsandmemory_second_level.csv', mypath), ...
    'treatasempty', 'NA', 'readrownames', 0);
spssdat.subj_idx = spssdat.VPN; % apparently this is the subject nr
spssdat(:, {'Var1', 'VPN', 'VPNummer', 'filter__'}) = [];
plotOverview(spssdat, 'spss');

alldatacombined = innerjoin(fulltab, spssdat, 'keys', {'subj_idx'});
% excel cannot write a file that big... remove some crap!
alldatacombined(:, {'sex','age','AkademikerIn','BMI','BDI','STAI_trait', ...
    'STAI_state_d1','STAI_state_d2','TICS_UEBE','TICS_SOUE','TICS_ERDR','TICS_UNZU', ...
    'TICS_UEFO','TICS_MANG','TICS_SOZS','TICS_SOZI','TICS_SORG','TICS_SSCS'}) = [];
writetable(alldatacombined, sprintf('%s/data/secondLevel_matlab_SPSS.xls', mypath));

%% DO SOME SANITY CHECKS, confirm that the two datasets return more or less the same info

figure; corrplot(alldatacombined, {'images_recalled_d1_neut', 'images_recalled_d2_neut', ...
  'images_recalled_d1_neg', 'images_recalled_d2_neg'}, ...
  {'pic_d1freerecall_neut', 'pic_d2freerecall_neut', 'pic_d1freerecall_neg', 'pic_d2freerecall_neg'});
suplabel('Matlab', 'x'); suplabel('SPSS', 'y');
print(gcf, '-dpdf', sprintf('%s/figures/correlationplot_comparison_recall_images.pdf', mypath));

clf; corrplot(alldatacombined, {'words_recalled_d1_neut', 'words_recalled_d2_neut', ...
  'words_recalled_d1_neg', 'words_recalled_d2_neg'}, ...
  {'word_d1freerecall_neut', 'word_d2freerecall_neut', 'word_d1freerecall_neg', 'word_d2freerecall_neg'});
suplabel('Matlab', 'x'); suplabel('SPSS', 'y');
print(gcf, '-dpdf', sprintf('%s/figures/correlationplot_comparison_recall_words.pdf', mypath));

%% WRITE TO EXCEL FOR LARS

end

function plotOverview(dat, name)

global mypath
close all; figure;
r = corrcoef(dat{:, 2:end}, 'rows', 'complete');
r = tril(r);
colormap(cbrewer('div', 'RdBu', 64));
imagesc(r); axis image; box off;
set(gca, 'xtick', 1:size(dat,2)-1, 'xticklabel', ...
    regexprep(dat.Properties.VariableNames(2:end), '_', ' '), 'xticklabelrotation', -90);
set(gca, 'ytick', 1:size(dat,2)-1, 'yticklabel', ...
    regexprep(dat.Properties.VariableNames(2:end), '_', ' '));
colorbar; prettyColorbar('r');
print(gcf, '-dpdf', sprintf('%s/figures/correlationplot_%s.pdf', mypath, name));
end

