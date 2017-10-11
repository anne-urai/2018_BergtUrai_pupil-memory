function data = processPupilData(thisfile, newfsample)

% processing script to analyze SMI pupil data
% Anne Urai, 2017
% anne.urai@gmail.com

close all; 

% determine the timing
prestim     = 3;
poststim    = 3;

% ============================================ %
% let the user select a file
% ============================================ %

if ~exist('thisfile', 'var'),
    [FileNames,PathName] = uigetfile('*.txt', 'multiselect', 'on');
    % if only one file was selected
    if ischar(FileNames), FileNames = {FileNames}; end
    FileNames = fullfile(PathName, FileName);
else
    FileNames{1} = thisfile;
end
    
for fileIdx = 1:length(FileNames),
    
    clearvars -except FileNames fileIdx PathName prestim poststim newfsample
    FileName = FileNames{fileIdx};
    
    % ============================================ %
    % read in and output a useful set of data structures
    % ============================================ %
    
    [data, event] = read_SMI_file(FileName);
    disp(data.fsample);
    
    % ============================================ %
    % AVERAGE TOGETHER THE PUPIL OVER THE TWO EYES
    % ============================================ %
    
    data.dat(:, 7) = mean(data.dat(:, 1:2), 2);
    data.dat(:, 8) = mean(data.dat(:, 3:4), 2);
    data.dat(:, 9) = mean(data.dat(:, 5:6), 2);
    data.dat = data.dat(:, 7:9);
    data.label = {'pupil', 'gazex', 'gazey'};

    % ============================================ %
    % remove any data before the first and after the last stim
    % ============================================ %
    
    % remove anything more than 3s before onset of the first stim
    trialIdx = find(~cellfun(@isempty, regexp([event(:).value], 'trial')));
    [~, sample] = min(abs(data.time - event(trialIdx(1)).time ));
    sample = sample - prestim*data.fsample; % remove first 2 seconds
    if sample < 1, sample = 1; end
    data.dat(1:sample, :) = NaN;
    
    % remove anything more than 3s after offset of the last stim
    [~, sample] = min(abs(data.time - event(trialIdx(end)).time ));
    sample = sample + poststim*data.fsample; % remove first 2 seconds
    if sample > length(data.time), sample = length(data.time); end
    data.dat(sample:end, :) = NaN;
    
    % ============================================ %
    % zscore the pupil channels across the whole interval
    % ============================================ %
    
    % normalize within the whole session
    nanzscore = @(x) (x - nanmean(x)) ./ nanstd(x);
    data.dat(:, 1) = nanzscore(data.dat(:, 1));
    
    % ============================================ %
    % epoch into trials around the trial: trigger
    % ============================================ %
    
    trialIdx = find(~cellfun(@isempty, regexp([event(:).value], 'trial')));
    data.trialtime = -prestim:1/data.fsample:poststim;

    for t = 1:length(trialIdx),
        % find the sample that marks the beginning of this trial
        [~, sample] = min(abs(data.time - event(trialIdx(t)).time ));
        
        % take the data from pre- to poststim
        data.stimonset(t)   = sample;
        
        try
            data.trial(t, :) = data.dat(sample - prestim*data.fsample : sample + poststim*data.fsample, 1);
        catch
            data.trial(t, :) = nan(size(data.trialtime));
        end
        
    end
    
    % ============================================ %
    % overview plot
    % ============================================ %
    
    close all; figure;
    subplot(3,3,1:3); hold on;
    plot(data.time, data.dat(:, 1)); xlabel('Time (s)');
    ylabel('Pupil (z)');
    title(FileName, 'interpreter', 'none'); axis tight; box off;
    xlim(data.time([1 end]));
    
    subplot(3,3,4); hold on;
    plot(data.trialtime, squeeze(mean(data.trial(:, :))));
    xlabel('Time from stimulus (s)');
    ylabel('Pupil response (z)');
    box off; axis tight; set(gca, 'xtick', -prestim:1:poststim);
    plot([0 0], get(gca, 'ylim'), 'color', [0.5 0.5 0.5]);
    
    print(gcf, '-dpdf', regexprep(FileName, '.txt', '_pupil.pdf'));
    
    % ============================================ %
    % WRITE TO CSV
    % ============================================ %
    
    outp.bl             = squeeze(nanmean(data.trial(:, find(data.trialtime < 0)), 3));
    outp.dilation       = squeeze(nanmean(data.trial(:, find(data.trialtime > 0)), 3)) - outp.bl;
    outp.trial_num      = cellfun(@str2double, regexp([event(trialIdx).value], '\d*', 'match'))';
    
    % save
    outp = struct2table(outp);
    writetable(outp, regexprep(FileName, '.txt', '_pupil.csv'));
    
    % ============================================ %
    % DOWNSAMPLE
    % ============================================ %
    
    if newfsample ~= data.fsample,
        
        data.time       = resample(data.time, newfsample, data.fsample);
        data.dat        = resample(data.dat, newfsample, data.fsample);
        data.trialtime  = min(data.trialtime) : 1/ newfsample : max(data.trialtime);
        data.trial      = resample(data.trial', newfsample, data.fsample);
        assert(length(data.trialtime) == size(data.trial, 1), 'timeaxis does not match data');
        
        % resample timepoints: blinkoffset, saccoffset, stimonset
        resample_points     = @(pts, oldfs, newfs) round(pts * (newfs/oldfs));
        data.blinkoffset    = resample_points(data.blinkoffset, data.fsample, newfsample);
        data.saccoffset     = resample_points(data.saccoffset, data.fsample, newfsample);
        data.stimonset      = resample_points(data.stimonset, data.fsample, newfsample);
        data.fsample        = newfsample;

    end
end % files
end

function [asc, event] = read_SMI_file(filename)
% reads an SMI file with triggers
% inspired by read_eyelink_asc
% Anne Urai, 2017

% ============================================ %
% in matlab > 2013b, can use readtable
% ============================================ %

disp(['reading ' filename]);
t           = readtable(filename, 'headerlines', 4, 'readvariablenames', true);
t.RecordingTime_ms_ = 0.001 * (t.RecordingTime_ms_ - t.RecordingTime_ms_(1));

% now put into asc
asc.time    = t.RecordingTime_ms_; % convert to seconds
asc.fsample = round( 1 ./ (median(diff(asc.time)))); % compute sampling rate

% ============================================ %
% the real data, pupil size and gaze position
% ============================================ %

disp('converting to data...');
chans = 7:12;
for c = 1:length(chans),
    dat             = t{:, chans(c)};
    dat             = regexprep(dat, '-', '0'); % get rid of missing data
    
    % https://nl.mathworks.com/matlabcentral/answers/18509-cell-conversion-to-double
    % for performance overview
    dat             = sscanf(sprintf('%s*', dat{:}), '%f*');
    
    asc.dat(:, c)   = dat;
    asc.label(c)    = t.Properties.VariableNames(chans(c));
end

% ============================================ %
% find and set blinks to NaN
% ============================================ %

disp('interpolating blinks...')
blinkIdxLeft            = ~cellfun(@isempty, regexp(t.CategoryLeft, 'Blink'));
blinkIdxRight           = ~cellfun(@isempty, regexp(t.CategoryRight, 'Blink'));
blinkIdxBoth            = (blinkIdxLeft | blinkIdxRight);
asc.dat(blinkIdxBoth, :) = NaN;

% return blink offsets 
[~, ~, asc.blinkoffset] = runLengthEncode(double(blinkIdxBoth)');
asc.blinkoffset(asc.blinkoffset > length(asc.dat)) = []; % remove offset idx at the end

saccIdxLeft             = ~cellfun(@isempty, regexp(t.CategoryLeft, 'Saccade'));
saccIdxRight            = ~cellfun(@isempty, regexp(t.CategoryRight, 'Saccade'));
saccIdxBoth             = (saccIdxLeft | saccIdxRight);

% return blink offsets 
[~, ~, asc.saccoffset] = runLengthEncode(double(saccIdxBoth)');
asc.saccoffset(asc.saccoffset > length(asc.dat)) = []; % remove offset idx at the end

% also find times where the signal dropped but SMI did not detect a blink
for c = 1:2, % only the two pupil channels
    blinkIdxDetected        = (asc.dat(:, c) < nanmean(asc.dat(:, c)) - 2 * nanstd(asc.dat(:, c)));
    asc.dat(blinkIdxDetected, c) = NaN;
end

% ============================================ %
% interpolate blinks
% ============================================ %

for c = 1:2, % only the two pupil channels
    asc.dat(isnan(asc.dat(:, c)), c) = interp1(find(~isnan(asc.dat(:, c))), ...
        asc.dat(~isnan(asc.dat(:, c)), c), find(isnan(asc.dat(:, c))), 'linear');
end

% ============================================ %
% parse messages and epoch data
% ============================================ %

msgIdx = ~cellfun(@isempty, regexp(t.Content, '\w'));
t = t(msgIdx, [1 end]);

evcell = cell(height(t), 1);
event = struct('time', evcell, 'value', evcell);

for i = 1:height(t),
    event(i).time   = t.RecordingTime_ms_(i); % in seconds from start of recording
    event(i).value  = t.Content(i);
end

end
