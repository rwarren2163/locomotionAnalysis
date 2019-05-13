%% load experiment data
fprintf('loading... '); load(fullfile(getenv('OBSDATADIR'), 'matlabData', 'baseline_data.mat'), 'data'); disp('baseline data loaded!')

% global settings



% global initializations
mice = {data.data.mouse};


%% ----------
% PLOT THINGS
%  ----------

%% GET DISTANCE AND TIME TO CONTACT DATA

% settings
trialSmps = 100;

% initializations
[distances, times] = deal(cell(1,length(mice)));

for i = 1:length(mice)
    
    fprintf('%s: collectin data, ya heard...\n', mice{i})
    sessions = {data.data(i).sessions.session}; % sessions for mouse
    
    for j = 1:length(sessions)
        
        % load session data
        load(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{j}, 'kinData.mat'), 'kinData')
        load(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{j}, 'runAnalyzed.mat'), 'frameTimeStamps');
        secondsPerFrame = nanmedian(diff(frameTimeStamps)); % seconds per frame
        
        [distances{i}, times{i}] = deal([]);
        for k = find([kinData.isTrialAnalyzed])
            
            % get distance of leading paw at contact
            contactInd = find(frameTimeStamps(kinData(k).trialInds) >= kinData(k).wiskContactTimes, 1, 'first'); % ind in trial at which contact occurs
            distances{i}(end+1) = abs(max([kinData(k).locations(contactInd,1,:)]))*1000;
            
            trialX = max(kinData(k).locations(contactInd-trialSmps+1:contactInd,1,:), [], 3);
            linFit = polyfit(trialX', 1:trialSmps, 1);
            predictedAtObsInd = polyval(linFit, 0);
            times{i}(end+1) = abs((predictedAtObsInd-trialSmps) * secondsPerFrame)*1000; % frame until contact * (seconds/frame)
            
        end
        clear kinData frameTimeStamps
    end
end


%% PLOT DISTANCE AND TIME TO CONTACT

% settings
xLims = [15 50];
yLims = [0 150];
scatAlpha = .08;
mouseColors = true;
scatPlotSize = .7;
border = .15;


% initializations
xGrid = linspace(xLims(1), xLims(2), 200);
yGrid = linspace(yLims(1), yLims(2), 200);
d = abs(cat(2, distances{:}));
t = abs(cat(2, times{:}));
mouseIds = repelem(1:length(mice), cellfun(@length, distances));
medDistances = cellfun(@nanmedian, distances);
medTimes = cellfun(@nanmedian, times);

% plot that shit
figure('Color', 'white', 'Position', [2000 400 450 350], 'MenuBar', 'none');
scatterHistoRick(d,t, ...
    {'groupId', mouseIds, 'colors', 'lines', ...
    'xlabel', 'distance to contact (mm)', 'ylabel', 'time to contact (ms)', ...
    'xLims', xLims, 'yLims', yLims, 'showCrossHairs', false});


% save
file = fullfile(getenv('OBSDATADIR'), 'papers', 'paper1', 'figures', 'matlabFigs', ...
        'baseline_distanceTimeToContact');
fprintf('writing %s to disk...\n', file)
saveas(gcf, file, 'svg');

%% SCATTER VEL AND BODY ANGLE AT CONTACT

flat = flattenData(data, {'mouse', 'session', 'trial', 'velAtWiskContact', 'angleAtWiskContact'});
[~,~,mouseIds] = unique({flat.mouse});

% settings
xLims = [0 1];
yLims = [-30 30];

% initializations
close all;
figure('Color', 'white', 'Position', [2000 400 450 350], 'MenuBar', 'none');
scatterHistoRick([flat.velAtWiskContact], [flat.angleAtWiskContact], ...
    {'groupId', mouseIds, 'colors', 'lines', ...
    'xlabel', 'velocity (m/s)', 'ylabel', ['body angle (' char(176) ')'], ...
    'xLims', xLims, 'yLims', yLims, 'showCrossHairs', false});

% save
file = fullfile(getenv('OBSDATADIR'), 'papers', 'paper1', 'figures', 'matlabFigs', ...
        'baseline_phaseVelVariability');
fprintf('writing %s to disk...\n', file)
saveas(gcf, file, 'svg');


%% OVERLAY IMAGES

% settings
session = '180628_004';
trialsToOverlay = 10;

vidTop = VideoReader(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runTop.mp4'));
vidBot = VideoReader(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runBot.mp4'));
load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runAnalyzed.mat'), ...
    'frameTimeStamps', 'obsOnTimes', 'wiskContactTimes');
wiskContactTimes = wiskContactTimes(~isnan(wiskContactTimes));
frameTimes = sort(wiskContactTimes(randperm(length(wiskContactTimes), trialsToOverlay)));

imgs = uint8(zeros(vidTop.Height+vidBot.Height, vid.Width, trialsToOverlay));

for i = 1:trialsToOverlay
    top = rgb2gray(read(vidTop, knnsearch(frameTimeStamps, frameTimes(i))));
    bot = rgb2gray(read(vidBot, knnsearch(frameTimeStamps, frameTimes(i))));
    frame = cat(1, top, bot);
    imgs(:,:,i) = frame;
end

overlay = overlayImgs(imgs, {'colors', 'lines', 'contrastLims', [.3 .75], 'cutoff', 100, 'projection', 'mean'});
% overlay = flip(permute(overlay, [2 1 3]),1); % rotate image so it is vertical
imshow(overlay); pimpFig


% write image to desk
file = fullfile(getenv('OBSDATADIR'), 'papers', 'paper1', 'figures', 'imgs', ...
        'variability_omg.png');
fprintf('writing %s to disk...\n', file)
imwrite(overlay, file);

%% KINEMATICS WITH LANDING POSITION DISTRIBUTIONS

% settings
trialsToShow = 50;
xLims = [-.1 .07];
colors = lines(2);
ctlColor = [.2 .2 .2];
histoFillAlpha = .2;

close all;


% initializations
% flat = flattenData(data, {'mouse', 'session', 'trial', 'modPawKinInterp', 'preModPawKinInterp', 'obsHgt'});
[~,~,mouseIds] = unique({flat.mouse});
kinData = permute(cat(3, flat.modPawKinInterp), [3,1,2]);
kinDataCtl = permute(cat(3, flat.preModPawKinInterp), [3,1,2]);
kinDataCtl(:,1,:) = kinDataCtl(:,1,:) - kinDataCtl(:,1,1) + kinData(:,1,1);
condition = ones(1, length(kinData))*2;
condition(kinData(:,1,end)>0) = 1;
figure('Color', 'white', 'Position', [2000 400 900 250], 'MenuBar', 'none');




% plot kinematics
subplot(2,1,1)
plotKinematics(kinData(:,[1 3],:), [flat.obsHgt], condition, ...
    {'colors', colors, 'trialsToOverlay', trialsToShow, 'trialAlpha', .4, 'lineAlpha', 0})
plotKinematics(kinDataCtl(:,[1 3],:), [flat.obsHgt], ones(1,length(flat)), ...
    {'colors', [.2 .2 .2], 'lineWidth', 5})
set(gca, 'XLim', xLims)


subplot(2,1,2); hold on;
% esimate pdfs
xGrid = linspace(xLims(1), xLims(2), 500);
kdCtl = ksdensity(kinDataCtl(:,1,end), xGrid);
kdLong = ksdensity(kinData(condition==1,1,end), xGrid);
kdShort = ksdensity(kinData(condition==2,1,end), xGrid);

% plot that shit
fill([xGrid xGrid(1)], [kdCtl kdCtl(1)], ctlColor, 'FaceAlpha', histoFillAlpha)
plot(xGrid, kdCtl, 'Color', ctlColor, 'LineWidth', 3)

fill([xGrid xGrid(1)], [kdLong kdLong(1)], colors(1,:), 'FaceAlpha', histoFillAlpha)
plot(xGrid, kdLong, 'Color', colors(1,:), 'LineWidth', 3)

fill([xGrid xGrid(1)], [kdShort kdShort(1)], colors(2,:), 'FaceAlpha', histoFillAlpha)
plot(xGrid, kdShort, 'Color', colors(2,:), 'LineWidth', 3)

set(gca, 'XLim', xLims, 'YDir', 'reverse', 'Visible', 'off')



% save
file = fullfile(getenv('OBSDATADIR'), 'papers', 'paper1', 'figures', 'matlabFigs', ...
        'baseline_modStepVariability');
fprintf('writing %s to disk...\n', file)
saveas(gcf, file, 'svg');












