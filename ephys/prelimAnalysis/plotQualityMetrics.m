function plotQualityMetrics(session, varargin)

% displays and save a several plots to assess the quality of 'good' units

% SETTINGS
% general
spkWindow = [-.3 .75]; % ms pre and post spike time to plot
spkNum = 5000; % take this many of all spikes to analyze (to save system resources)
showFigures = 'on';
s.unitsToPlot = [];  % if provided, only plot cells in unit_ids
s.fastLoad = false;  % if true loads from .cont instead of .dat file, which is faster but lacks common reference subtraction
s.showChannelsOverTime = true;  % whether to also call showChannelsOverTime()

% SNR settings
snrYLims = [0 20];
snrDt = 1; % (s)
snrWindow = 30; % (s)

% probe view settings
traceWidth = 25;  % (microns) width of trace
traceHeight = .1;  % (micron / microvolt) scaling factor for height of traces
timeBinNum = 4;  % show spike waveforms over this amout of time
minFiringRate = 0.5; % (hz) time bins with firing rate less than minFr will not display average trace

% spike trace settings
sampleTraceLength = .15;
verticalSpacing = 200;
traceTimeBins = 6;

% firing rate settings
frWindow = 30; % seconds

% false positive settings
fpTimeBinNum = 200;
fpBinSize = 5*60; % s
refractoryPeriod = .002;
censoredPeriod = .001;

% autocorrelogram
xcorrBinWidth = .001;
xcorrWidth = .04;



% COLLECT SESSION DATA
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % reassign settings passed in varargin
fprintf('%s: collecting data... \n', session)
info = getSessionEphysInfo(session);
spkWindowInds = int64((spkWindow(1)/1000*info.fs) : (spkWindow(2)/1000*info.fs));
load(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', [info.mapFile '.mat']), ...
    'xcoords', 'ycoords', 'channelNum_OpenEphys', 'kcoords')
[allSpkInds, unit_ids] = getGoodSpkInds(session); % get spike times for good units
bestChannels = getBestChannels(session); % Best channels are returned in ChannelNum used in kilosort and phy (intan+1);


% plotting all channels
folder = fullfile(getenv('OBSDATADIR'), 'figures', 'ephys', 'qualityMetrics');  % figures will be saved here
if s.showChannelsOverTime
    showChannelsOverTime(session, 'timeBinNum', 5, 'showSortedSpikes', true, ...
        'figureName', fullfile(folder, [session 'allUnits.png']), 'bestChannels', bestChannels);
    pause(.1)
end


% function to extract voltage from binary file
getVoltage = @(data, channel, inds) ...
    double(data.Data.Data(channel,inds))*info.bitVolts; % extract voltage from memmapfile, converting to votlage, and only return specific channel

% load data
data = memmapfile(fullfile(getenv('OBSDATADIR'), 'sessions', session, info.ephysFolder, [info.fileNameBase '_CHs.dat']), ...
    'Format', {'int16', [info.channelNum, info.smps], 'Data'}, 'Writable', false);


cellColors = hsv(length(unit_ids))*.8;
getColors = @(length, color) interp2(1:3, [1:2]', cat(1,[0 0 0], color), 1:3, linspace(1,2,length)'); % creates gradient from black to color
if isempty(s.unitsToPlot); s.unitsToPlot = unit_ids; end
unitInds = find(ismember(unit_ids, s.unitsToPlot))';

fprintf('%s: plotting cell ', session)
for c = unitInds

    fprintf('%i ', unit_ids(c))
    figure('Name', sprintf('%s cell %i', session, unit_ids(c)), 'Visible', showFigures, ...
        'Color', 'white', 'units', 'normalized', 'Position', [.1 .1 .8 .8]); hold on
    spkInds = allSpkInds{c};

    
    % EXTRACT WAVEFORM ACROSS CHANNELS
    spkIndsSub = spkInds(round(linspace(2, length(spkInds), spkNum))); % get subpopulation of spikes evenly spaced out
    spkIndsSubAll = uint64(repmat(spkWindowInds,1,length(spkIndsSub)) + int64(repelem(spkIndsSub, length(spkWindowInds)))');

    allWaveforms = getVoltage(data, 1:info.channelNum, spkIndsSubAll);
    if s.fastLoad
        channelFile = fullfile(getenv('OBSDATADIR'), 'sessions', session, info.ephysFolder, ...
            sprintf('%s_CH%i.continuous', info.fileNameBase, bestChannels(c)));
        channelData = load_open_ephys_data(channelFile);
    else
        channelData = getVoltage(data, bestChannels(c), 1:info.smps);
    end
    allWaveforms = reshape(allWaveforms, info.channelNum, length(spkWindowInds), []);
    allWaveforms = permute(allWaveforms, [3 1 2]);
    
    

    % PLOT SPIKE SHAPES ON PROBE
    subplot(4,4,[1 5 9]); hold on
    timeBins = discretize(double(spkIndsSub), timeBinNum);
    colors = getColors(timeBinNum, cellColors(c,:));
    traceX = double(spkWindowInds) * (traceWidth/range(double(spkWindowInds)));
    
    shankNum = kcoords(bestChannels(c));
    shankInds = find(kcoords==shankNum)';  % inds for channels on same shank as best channel
%     shankInds = find(abs(xcoords-xcoords(bestChannels(c))) < 50)';  % temporary hack until kcoords is accurate
    
    for j = shankInds
        for i = 1:timeBinNum
            firingRate = sum(timeBins==i) / (range(info.timeStamps)/timeBinNum);
            if firingRate>minFiringRate % don't plot average trace if rate of spikes in bin is too low, which happens when the unit is lost
                trace = squeeze(mean(allWaveforms(timeBins==i,j,:),1));
                plot(xcoords(j) + traceX, ...
                    ycoords(j) + trace*traceHeight, ...
                    'Color', colors(i,:), 'LineWidth', 2)
            end
        end
        if j==bestChannels(c); textColor='red'; else; textColor='black'; end
        text(double(xcoords(j) + traceX(1)), ycoords(j), ...
                num2str(find(channelNum_OpenEphys==j)), 'Color', textColor, ...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle')
    end
    text(mean(xcoords(shankInds)) + mean(traceX), max(ycoords)+25, ...
        sprintf('SHANK %i/%i', shankNum, length(unique(kcoords))), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')

    xLims = [min(xcoords(shankInds)) + traceX(1) - .5*range(traceX), ...
             max(xcoords(shankInds)) + traceX(end) + .5*range(traceX)];
    set(gca, 'visible', 'off', 'xlim', xLims)


    % PLOT SAMPLE TRACES
    subplot(4,4,14:16)
    colors = getColors(traceTimeBins, cellColors(c,:));

    traceTimes = linspace(info.timeStamps(1), info.timeStamps(end), traceTimeBins+1);
    for i = 1:traceTimeBins

        % plot raw trace
        traceBins = info.timeStamps>=traceTimes(i) & info.timeStamps<traceTimes(i)+sampleTraceLength;
        times = info.timeStamps(traceBins);
        trace = channelData(traceBins);
        plot(times-times(1), trace + (traceTimeBins-i)*verticalSpacing, 'Color', [.5 .5 .5], 'LineWidth', 0.5); hold on % plot raw trace

        % overlay spikes
        traceSpkInds = spkInds(info.timeStamps(spkInds)>=traceTimes(i) & info.timeStamps(spkInds)<traceTimes(i)+sampleTraceLength);
        spkBins = repmat(spkWindowInds,length(traceSpkInds),1) + int64(traceSpkInds); % matrix where each row is inds for given spike
        for j = 1:length(traceSpkInds)
            plot(info.timeStamps(spkBins(j,:))-times(1), channelData(spkBins(j,:)) + (traceTimeBins-i)*verticalSpacing, ...
                'Color', colors(i,:), 'LineWidth', 2); % overlay spikes!
        end
    end
    set(gca, 'visible', 'off', 'XLim', [0 range(times)])


    % AMP OVER TIME
    subplot(4,4,2:4)
    xLims = [min(info.timeStamps) max(info.timeStamps)]/60;

    amplitudes = peak2peak(squeeze(allWaveforms(:,bestChannels(c),:)),2);
    stdev = std(channelData);
    
    scatter(info.timeStamps(spkIndsSub)/60, amplitudes/stdev, ...
        20, getColors(length(spkIndsSub), cellColors(c,:)), 'MarkerEdgeAlpha', .4);
    set(gca, 'XLim', xLims, 'YLim', snrYLims, 'XColor', get(gcf, 'color'))
    ylabel(sprintf('channel %i SNR', bestChannels(c)))
    xlabel('time (min)')


    % FIRING RATE OVER TIME
    subplot(4,4,6:8)
    [counts, edges] = histcounts(info.timeStamps(spkInds), min(info.timeStamps):1:max(info.timeStamps));
    binWidth = median(diff(edges));
    spkRates = counts / binWidth;
    spkRates = smooth(spkRates, frWindow/binWidth);
    minutes = (edges(1:end-1) + .5*binWidth) / 60; % get bin centers and convert from seconds to minutes
    plot(minutes, spkRates, 'LineWidth', 2, 'Color', cellColors(c,:))
    ylabel('firing rate (Hz)')
    set(gca, 'Box', 'off', 'XLim', xLims, 'XColor', get(gcf, 'color'))


    % FALSE POSITIVE RATE
    subplot(4,4,10:12)
    yyaxis right
    fpRates = nan(1,fpTimeBinNum);
    centers = linspace(0, info.timeStamps(spkInds(end)), fpTimeBinNum);

    for i = 1:fpTimeBinNum

        binMin = max(0, centers(i)-.5*fpBinSize);
        binMax = min(info.timeStamps(spkInds(end)), centers(i)+.5*fpBinSize);

        spkBins = info.timeStamps(spkInds)>=binMin & info.timeStamps(spkInds)<binMax;
        violations = sum(diff(info.timeStamps(spkInds(spkBins)))<refractoryPeriod);
        if violations>0
            rhs = 2 * (refractoryPeriod-censoredPeriod) * sum(spkBins)^2 / violations / (binMax-binMin); % !!! should check this math is correct
            fpRates(i) = .5 - .5*sqrt((rhs-4)/rhs);
        else
            fpRates(i) = 0;
        end
        fpRates(i) = violations/sum(spkBins);
    end

    plot(centers/60, fpRates, 'LineWidth', 2, 'Color', 'black')
    set(gca, 'box', 'off', 'XLim', xLims, 'YLim', [0 .05], 'YColor', 'black');
    ylabel('false positive rate')
    xlabel('time (min)')
    
    
    % 5th percentile SNR
    times = min(info.timeStamps):snrDt:max(info.timeStamps);
    percentiles = nan(1,length(times));
    for i = 1:length(times)
        spkBins = info.timeStamps(spkIndsSub)>times(i)-snrWindow*.5 & info.timeStamps(spkIndsSub)<=times(i)+snrWindow*.5;
        binSnrs = amplitudes(spkBins) / stdev; % !!! change to bin std, not global std?
        if sum(spkBins)/snrWindow > minFiringRate
            percentiles(i) = prctile(binSnrs, 5);
        end
    end
    yyaxis left
    plot(times/60, percentiles, 'LineWidth', 2, 'Color', cellColors(c,:))
    ylabel('5th percentile SNR')
    set(gca, 'YColor', cellColors(c,:), 'YLim', snrYLims*.5, 'Box', 'off');


    % AUTOCORRELOGRAM
    subplot(4,4,13)
    spksBinary = histcounts(info.timeStamps(spkInds), 0:xcorrBinWidth:info.timeStamps(end));
    autocorr = xcorr(spksBinary, round(xcorrWidth/2/xcorrBinWidth), 'coeff');
    autocorr(autocorr==1) = nan;
    bar(autocorr, 'BarWidth', 1, 'EdgeColor', 'none', 'FaceColor', cellColors(c,:))
    set(gca, 'visible', 'off')
    
    
    % save figures
    saveas(gcf, fullfile(folder, [session 'cell' num2str(unit_ids(c)) '.png']))
    pause(.01)
end

disp('all done!')


