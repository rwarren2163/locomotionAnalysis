function obsAvoidanceLearningSummary(mice)

% shows obstacle avoidance for all mice over time, with and without wheel break...
% assumes at least noBrSessions have been collected... otherwise will behave incorrectly
%
% input         mice:      name of mice to analyze


% user settings
minTouchTime = .05; % only touches count that are >= minTouchTime
conditionYAxes = {'(light)', '(no light)'};
experimentNames = {'obsNoBr', 'obsBr'};
frameEdges = [.336 .415]; % (m) % [(pos at which obs enters frame) (pos at which obs clears hind paws (this is to avoid including tail contacts))]
noBrSessions = 3; % uses the most recent noBrSessions 
brSessions = 7; % uses the first (oldest) brSessions
mouseScatSize = 25;
meanScatSize = 100;

% initializations
xInds = 1:(noBrSessions + brSessions);
sessionInfo = readtable([getenv('OBSDATADIR') 'sessions\sessionInfo.xlsx']);

sessionBins = ismember(sessionInfo.mouse, mice) &...
              ismember(sessionInfo.experiment, experimentNames) &...
              sessionInfo.include;
sessions = sessionInfo(sessionBins, :);

data = struct(); % stores trial data for all sessions

cmap = winter(length(mice));



% collect data
for i = 1:size(sessions,1)

    % load session data
    load([getenv('OBSDATADIR') 'sessions\' sessions.session{i} '\runAnalyzed.mat'],...
            'obsPositions', 'obsTimes',...
            'obsOnTimes', 'obsOffTimes',...
            'obsLightOnTimes', 'obsLightOffTimes',...
            'touchOnTimes', 'touchOffTimes', 'touchSig');
    load([getenv('OBSDATADIR') 'sessions\' sessions.session{i} '\run.mat'], 'breaks', 'touch');
    
    obsPositions = fixObsPositions(obsPositions, obsTimes, obsOnTimes);
    
    
    % remove brief touches
    validLengthInds = (touchOffTimes - touchOnTimes) >= minTouchTime;
    touchOnTimes = touchOnTimes(validLengthInds);
    touchOffTimes = touchOffTimes(validLengthInds);
    
    
    % get touch positions and ensure all touches fall within frame
    touchPositions = interp1(obsTimes, obsPositions, touchOnTimes, 'linear');
    validPosInds = touchPositions>frameEdges(1) & touchPositions<frameEdges(2);
    touchOnTimes = touchOnTimes(validPosInds);
    touchOffTimes = touchOffTimes(validPosInds);
           
    
    
    isAvoided = nan(length(obsOnTimes), 1);
    isLightOn = false(length(obsOnTimes), 1);
    
    % iterate over all trials
    for j = 1:length(obsOnTimes)
        
        % find whether and where obstacle was toucheed
%         isAvoided(j) = ~any(touchOnTimes>obsOnTimes(j) & touchOnTimes<obsOffTimes(j));
        isAvoided(j) = ~any(touchOnTimes>obsOnTimes(j) & touchOnTimes<obsOffTimes(j)) &&...
                       ~any(breaks.times>obsOnTimes(j) & breaks.times<obsOffTimes(j));
        
        % find whether light was on
        isLightOn(j) = min(abs(obsOnTimes(j) - obsLightOnTimes)) < 1; % did the light turn on near whether the obstacle turned on
                
    end
    
    data(i).mouse = sessions.mouse{i};
    data(i).lightOnAvoidance = sum(isAvoided(isLightOn)) / sum(isLightOn);
    data(i).lightOffAvoidance = sum(isAvoided(~isLightOn)) / sum(~isLightOn);
    data(i).isWheelBreak = strcmp(sessions.experiment{i}, 'obsBr');
    
end


% determine which sessions to include (get last noBrSessions without wheel break and first brSessions with wheel break)
for i = 1:length(mice)
    
    % get no break session nums
    indsNoBr = find(strcmp(mice{i}, {data.mouse}) & ~[data.isWheelBreak], noBrSessions, 'last');
    indsBr = find(strcmp(mice{i}, {data.mouse}) & [data.isWheelBreak], brSessions, 'first');
    temp = num2cell(ones(1,length([indsNoBr indsBr])));
    [data([indsNoBr indsBr]).includeSessions] = temp{:};
    
end


% plot everything

% prepare figure
figure('name', 'obsAvoidanceLearningSummary', 'menubar', 'none', 'units', 'pixels', 'position', [500 200 750 500], 'color', [1 1 1]);
fields = {'lightOnAvoidance', 'lightOffAvoidance'};

% plot light on and light off avoidance for each mouse

allAvoidanceData = nan(length(mice), (noBrSessions+brSessions), 2); % (mice, session, isLightOn)

for i = 1:2
    
    subplot(2,1,i)
    
    for j = 1:length(mice)
        
        bins = strcmp(mice{j}, {data.mouse}) & [data.includeSessions];
        
        plot(xInds(1:sum(bins)), [data(bins).(fields{i})], 'color', cmap(j,:)); hold on
        scatter(xInds(1:sum(bins)), [data(bins).(fields{i})], mouseScatSize, cmap(j,:), 'filled')
        
        allAvoidanceData(j, 1:sum(bins), i) = [data(bins).(fields{i})];
        
    end
    
    % pimp fig
    set(gca, 'box', 'off', 'xtick', xInds, 'xlim', [xInds(1)-.5 xInds(end)], 'ylim', [0 1])
    if i==2; xlabel('session', 'fontweight', 'bold'); end
    ylabel({'fraction avoided', conditionYAxes{i}}, 'fontweight', 'bold')
    line([noBrSessions+.5 noBrSessions+.5], [0 1], 'lineWidth', 3, 'color', get(gca, 'xcolor'))
    
end

% plot means
for i = 1:2
    
    subplot(2,1,i)
    meanAvoidance = nanmean(squeeze(allAvoidanceData(:,:,i)),1);
    plot(xInds, meanAvoidance, 'lineWidth', 3, 'color', get(gca, 'xcolor'))
    scatter(xInds, meanAvoidance, meanScatSize, get(gca, 'xcolor'), 'filled')
    
end


% save fig
savefig([getenv('OBSDATADIR') 'figures\obsAvoidanceLearningSummary.fig'])
