
% Code to fit the history-dependent drift diffusion models described in
% Urai AE, Gee JW de, Donner TH (2018) Choice history biases subsequent evidence accumulation. bioRxiv:251595
%
% MIT License
% Copyright (c) Anne Urai, 2018
% anne.urai@gmail.com

global mypath
dat = readtable(sprintf('%s/data/secondLevel_matlab_SPSS.xls', mypath));

%% COMPUTE NEGATIVE VS. NEUTRAL DIFFERENCE
conds = {'images', 'words'}
for c = 1:2,
    
    memoryVars = {'recalled_d1_neut', 'recalled_d2_neut', ...
        'pupil_dilation_enc_neut', 'regression_pupil_recalled_d1_neut', 'regression_pupil_recalled_d2_neut'};
    
    memoryVars = cellfun(@horzcat, repmat(conds(c), [size(memoryVars), 1]), ...
        repmat({'_'}, [size(memoryVars), 1]), memoryVars, 'un', 0);
    
    for m = 1:length(memoryVars),
        dat.(regexprep(memoryVars{m}, '_neut', '')) = dat.(regexprep(memoryVars{m}, '_neut', '_neg')) - ...
            dat.(memoryVars{m}) ;
    end
end

%% TICS SUBSCORES?
% close all;
% corrplot(dat, {'TICS_UEBE','TICS_SOUE','TICS_ERDR','TICS_UNZU','TICS_UEFO','TICS_MANG','TICS_SOZS','TICS_SOZI','TICS_SORG','TICS_SSCS'});
% print(gcf, '-dpdf', sprintf('%s/figures/TICS_subscores.pdf', mypath));

%%
conds = {'images', 'words'}
for c = 1:2,
    
    personalityVars = {'BDI', 'STAI_trait', 'STAI_state_d1', 'TICS_SSCS'};
    memoryVars = {'recalled_d1', 'recalled_d2',  'pupil_dilation_enc', ...
        'regression_pupil_recalled_d1', 'regression_pupil_recalled_d2'};
    % add the condition name
    memoryVars = cellfun(@horzcat, repmat(conds(c), [size(memoryVars), 1]), ...
        repmat({'_'}, [size(memoryVars), 1]), memoryVars, 'un', 0);
    
    % get critical p-value
    [pvals, pvalsgroup] = corrplot(dat, personalityVars, memoryVars);
    [h, crit_p, adj_ci_cvrg, adj_p] = fdr_bh(pvals);
    disp(crit_p);
    
    % now plot
    close all;
    colors = cbrewer('qual', 'Set1', 9);
    set(gcf, 'defaultaxescolororder', colors([9 1 2], :), ...
        'defaultfigurecolormap', colors([9 1 2], :), 'defaultaxesfontsize', 4);
    colormap(colors([9 1 2], :));
    corrplot(dat, personalityVars, memoryVars, [], crit_p);
    % tightfig;
    
    % rename the axes
    
    
    print(gcf, '-dpdf', sprintf('%s/figures/personality_correlation_%s.pdf', mypath, conds{c}));
    
end