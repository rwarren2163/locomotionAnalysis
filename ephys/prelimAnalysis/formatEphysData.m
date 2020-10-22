function formatEphysData(session, varargin)
% prepares spikes for matlab-land by getting spike times wrt spike clock,
% and maybe by computing instantaneous firing rates as well...


% settings
s.spkRateFs = 200;         % sampling frequency of instantaneous firing rate
s.kernelRise = .005;       % (s) rise for double exponential kernel
s.kernelFall = .02;        % (s) fall for double exponential kernel
s.kernelSig = .02;         % (s) if a gaussian kernel is used
s.kernel = 'doubleExp';    % 'gauss', or 'doubleExp'
s.forceAlignment = false;  % whether to run the alignement algorithm to find best matches between spike and ephys sync signals // if false, only runs the algorithm when there are different numbers of events in each channel
s.plot = true;             % whether to show plot when forcing alignment... 
s.outputFileName = fullfile(getenv('OBSDATADIR'), 'sessions', session, 'neuralData.mat');


% initializations
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % parse name-value pairs
addpath(fullfile(getenv('GITDIR'), 'analysis-tools'))
addpath(fullfile(getenv('GITDIR'), 'npy-matlab'))
ephysFolder = dir(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'ephys_*'));
ephysFolder = ephysFolder.name;
ephysInfo = getSessionEphysInfo(session);

% get mapping from open ephys to spike times
[channel, eventTimes, info] = load_open_ephys_data_faster(...
    fullfile(getenv('OBSDATADIR'), 'sessions', session, ephysFolder, 'all_channels.events'));  % load event data
eventChannel = unique(channel);  % assumes only one digital input is used!
syncEphysTimes = eventTimes(logical(info.eventId) & channel==eventChannel); % only take rising edge of event channel
syncSpikeTimes = load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'run.mat'), ephysInfo.syncSignal);
syncSpikeTimes = syncSpikeTimes.(ephysInfo.syncSignal).times(syncSpikeTimes.(ephysInfo.syncSignal).level==1);

% check if we need to force the alignment algorithm
runAlignment = length(syncEphysTimes)~=length(syncSpikeTimes) || s.forceAlignment;

% simple linear mapping alignment
if ~runAlignment
    openEphysToSpikeMapping = polyfit(syncEphysTimes, syncSpikeTimes, 1); % get linear mapping from open ephys to spike
    predictedEventSpikeTimes = polyval(openEphysToSpikeMapping, syncEphysTimes);
    if max(abs(predictedEventSpikeTimes - syncSpikeTimes)) > .003
        fprintf('%s: WARNING! Same number of events in both channels, but linear mapping fails. Running alignment algorithm.\n', session)
        runAlignment = true;
    end
end

% hard-core alignment algorithm
if runAlignment
    if ~s.forceAlignment
        fprintf('%s: WARNING! %i events in spike and %i events in openEphys. Running alignment algorithm.\n', ...
            session, length(syncSpikeTimes), length(syncEphysTimes))
    else
        fprintf('forcing alignment algorithm\n')
    end
    
    % find signal offset
    % ------------------
    
    % turn times into delta functions
    fs = 1000;
    tRng = max(range(syncSpikeTimes), range(syncEphysTimes));
    tMin = min([syncEphysTimes; syncSpikeTimes]);
    tMax = max([syncEphysTimes; syncSpikeTimes]);
    tLims = [tMin-tRng tMax+tRng];
    t = tLims(1) : 1/fs : tLims(2);
    
    spikeBins = histcounts(syncSpikeTimes, t);
    ephysBins = histcounts(syncEphysTimes, t);
    
    % cross correlate to align signals
    [r, lags] = xcorr(spikeBins, ephysBins);
    [~, maxInd] = max(r);
    lag = lags(maxInd)/fs;
    syncEphysTemp = syncEphysTimes + lag;
    syncSpikeTemp = syncSpikeTimes;
    
    
    % find matching events
    % --------------------
    maxDiff = .1;
    matchedInds = nan(2,0);  % first row spike, second row ephys
    
    while ~all(isnan(syncEphysTemp)) && ~all(isnan(syncSpikeTemp))
        
        diffs = abs(syncSpikeTimes - syncEphysTemp');  % abs(diffs) between each pair of events (spkInds X ephysInds)
        [minDiff, minInd] = min(diffs, [], 'all', 'linear');
        if minDiff < maxDiff
            [spikeInd, ephysInd] = ind2sub(size(diffs), minInd);
            syncSpikeTemp(spikeInd) = nan;
            syncEphysTemp(ephysInd) = nan;
            matchedInds(:,end+1) = [spikeInd; ephysInd];
        else
            break
        end
    end
    
    % plot
    % ----
    if s.plot
        figure('name', sprintf('%s: spike / openephys event alignment', session), ...
            'color', 'white', 'position', [90.00 654.00 1769.00 225.00]); hold on

        plot([syncSpikeTimes(matchedInds(1,:)), syncEphysTimes(matchedInds(2,:))+lag], ...
            [1 0], 'LineWidth', 1, 'color', [0 0 0 .4])  % lines connecting matched events
        scatter(syncSpikeTimes(matchedInds(1,:)), ones(1,size(matchedInds,2)), 50, [0 0.44 0.74], 'filled')
        scatter(syncEphysTimes(matchedInds(2,:))+lag, zeros(1,size(matchedInds,2)), 50, [.85 .32 .10], 'filled')

        spkUnmatchedInds = find(~ismember(1:length(syncSpikeTimes), matchedInds(1,:)));
        scatter(syncSpikeTimes(spkUnmatchedInds), ones(1,length(spkUnmatchedInds)), 100, 'red')
        ephysUnmatchedInds = find(~ismember(1:length(syncEphysTimes), matchedInds(2,:)));
        scatter(syncEphysTimes(ephysUnmatchedInds)+lag, zeros(1,length(ephysUnmatchedInds)), 100, 'red')

        set(gca, 'ytick', [0 1], 'YTickLabel', {'open ephys', 'spike'}, 'ylim', [-1 2])
        xlabel('spike times (s)')
        pause(.1)
    end
    
    % update times
    syncSpikeTimes = syncSpikeTimes(matchedInds(1,:));
    syncEphysTimes = syncEphysTimes(matchedInds(2,:));
end


% linear mapping from open ephys to spike event time
openEphysToSpikeMapping = polyfit(syncEphysTimes, syncSpikeTimes, 1); % get linear mapping from open ephys to spike
predictedEventSpikeTimes = polyval(openEphysToSpikeMapping, syncEphysTimes);

% check that predictions are accurate
<<<<<<< HEAD
predictedEventSpikeTimes = polyval(openEphysToSpikeMapping, syncEphysTimes);
if max(abs(predictedEventSpikeTimes - syncSpikeTimes)) > .002
    fprintf('%s: WARNING! Linear mapping from openephys to spike fails to fit all events!\n', session)
   
=======
thresh = .003;  % maximum acceptable difference between predicted and actual event times
if max(abs(predictedEventSpikeTimes - syncSpikeTimes)) > thresh
    fprintf('%s: WARNING! %i predicted event times are more than %i ms off! Mapping may have failed!\n', ...
        session, sum(abs(predictedEventSpikeTimes - syncSpikeTimes) > thresh), thresh*1000)
%     disp(predictedEventSpikeTimes - syncSpikeTimes)  % try the following line to see if the predicted times are really off or within an acceptible range
>>>>>>> 403084717706e379fe39f1524671ab0c3297bcb6
end
    

% get spike times for good units
[spkInds, unit_ids] = getGoodSpkInds(session);
[bestChannels, ~] = getBestChannels(session, 'returnPhysicalLayout', true);
cellData = readtable(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'cellData.csv'));
if ~isequal(cellData.unit_id(:), unit_ids(:)); disp('WARNING! cellData.csv unit_ids do not match those in ephysFolder'); keyboard; end
if ~isequal(length(unit_ids), length(bestChannels)); disp('WARNING! bestChannels do not match unit_ids'); keyboard; end


% restrict to good units
goodBins = cellData.include==1;
unit_ids = unit_ids(goodBins);
bestChannels = bestChannels(goodBins);
spkInds = spkInds(goodBins);
cellData = cellData(goodBins,:);

spkTimes = cell(1, length(unit_ids));
for i = 1:length(unit_ids)
    spkTimes{i} = polyval(openEphysToSpikeMapping, ephysInfo.timeStamps(spkInds{i}));
end


% convert to instantaneous firing rate
minTime = min(cellfun(@(x) x(1), spkTimes)); % latest spike across all neurons
maxTime = max(cellfun(@(x) x(end), spkTimes)); % latest spike across all neurons
[~, timeStamps] = getFiringRate(spkTimes{1}, 'tLims', [minTime maxTime], 'fs', s.spkRateFs, ...
    'kernel', s.kernel, 'kernelRise', s.kernelRise, 'kernelFall', s.kernelFall, 'sig', s.kernelSig);
spkRates = nan(length(spkTimes), length(timeStamps));

for i = 1:length(spkTimes)
    
    [spkRates(i,:), timeStamps] = getFiringRate(spkTimes{i}, 'tLims', [minTime maxTime], 'fs', s.spkRateFs, ...
        'kernel', s.kernel, 'kernelRise', s.kernelRise, 'kernelFall', s.kernelFall, 'sig', s.kernelSig);    
    
    % get min and max time for cell
    cellMinTime = polyval(openEphysToSpikeMapping, cellData.timeStart(i)*60);
    if strcmp(cellData.timeEnd(i), 'max')
        cellMaxTime = timeStamps(end);
    else
        if iscell(cellData.timeEnd(i)); timeEnd = str2double(cellData.timeEnd(i)); else; timeEnd = cellData.timeEnd(i); end
        cellMaxTime = polyval(openEphysToSpikeMapping, timeEnd*60);
    end
    
    % remove spikes that are out of min and max times
    spkRates(i, timeStamps<cellMinTime | timeStamps>cellMaxTime) = nan;
    spkTimes{i} = spkTimes{i}(spkTimes{i}>cellMinTime & spkTimes{i}<cellMaxTime);
end

settings = s;
save(s.outputFileName, 'spkRates', 'spkTimes', 'timeStamps', 'unit_ids', 'bestChannels', 'openEphysToSpikeMapping', 'settings')




