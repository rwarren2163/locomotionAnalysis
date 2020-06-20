%% find out which sessions have 'originalDimensions' files

files = dir(fullfile(getenv('OBSDATADIR'), 'sessions'));
sessions = {files([files.isdir]).name};
origSessions = {};

fileExists = false(1,length(sessions));
fprintf('\n\n--------------------looking for originalDimensions--------------------\n')
for i = 1:length(sessions)
    dirSub = dir(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, '*.mp4'));
    bins = contains({dirSub.name}, 'originalDimensions');
    if any(bins)
        fprintf('%s: ', sessions{i})
        fprintf('%s ', dirSub(bins).name)
        fprintf('\n')
        origSessions{end+1} = sessions{i};
    end
end
disp('all done!')

%% find ephysSessions

ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'));
ephysSessions = ephysInfo.session(ephysInfo.include==1);
clear ephysInfo


%% reanalyze everything for ephys sessions

problemSessions = {};
% ephysSessions = {'180917_002', '200130_000'};  % temp

for i = 1:length(ephysSessions)
    fprintf('\n___________%i/%i___________\n', i, length(ephysSessions))
    
    % concat top and bot if necessary
    folder = fullfile(getenv('OBSDATADIR'), 'sessions', ephysSessions{i});
    if ~exist(fullfile(folder, 'run.mp4')); concatTopBotVids(ephysSessions{i}); end
    
    try
        analyzeSession(ephysSessions{i}, ...
            'overwriteVars', 'all', ...
            'verbose', true, ...
            'superVerbose', false, ...
            'rerunRunNetwork', true, ...
            'rerunWiskNetwork', true, ...
            'rerunPawContactNetwork', true, ...
            'rerunWiskContactNetwork', true);
    catch
        fprintf('%s: problem with analysis!\n', ephysSessions{i})
        problemSessions{end+1} = ephysSessions{i};
    end
end
disp('all done!')


%% reanalyze single field in ephysSessions

% settings
close all
skipSessions = {};
vars = {'whiskerAngle'};
args = {'showLickFig', true};  % passed to analyzeSession

fprintf('\n_____ reanalyzing: '); fprintf('%s ', vars{:}); fprintf('_____\n')
sessions = ephysSessions(~ismember(ephysSessions, skipSessions));
for i = 1:length(sessions)
    analyzeSession(sessions{i}, 'overwriteVars', vars, 'verbose', true, args{:});
    fprintf('\n')
end
disp('all done!')

%% show tracking with continuous signal

session = ephysSessions{1};

locationsWisk = readtable(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'trackedFeaturesRaw_wisk.csv'));
load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runAnalyzed.mat'), 'frameTimeStampsWisk')

showTracking(session, 'sig', locationsWisk.tongue_1, 'sigTimes', frameTimeStampsWisk)


%% reanalyze single sessions
analyzeSession('999999_999', ...
            'overwriteVars', 'all', ...
            'verbose', true, ...
            'superVerbose', false, ...
            'rerunRunNetwork', true, ...
            'rerunWiskNetwork', true, ...
            'rerunPawContactNetwork', true, ...
            'rerunWiskContactNetwork', true);

%% recover broken session

session = '200118_001'; % '200118_001', '191009_003'

% figure out if any frames lost at the beginning of session
load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runAnalyzed.mat'), 'ledInds', 'ledIndsWisk', 'rewardTimes')
load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'run.mat'), 'exposure')
firstLedTtl = find(exposure.times > rewardTimes(1), 1, 'first');

if firstLedTtl==ledInds(1) && firstLedTtl==ledIndsWisk(1)
    disp('no frames lost at beginning')
else
    fprintf('%i frames unaccounted for in run camera\n', firstLedTtl-ledInds(1))
    fprintf('%i frames unaccounted for in wisk camera\n', firstLedTtl-ledIndsWisk(1))
end

% check length of videos
vid = VideoReader(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'run.mp4'));
vidWisk = VideoReader(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runWisk.mp4'));
fprintf('%i run frames, %i whisker frames\n', vid.NumberOfFrames, vidWisk.NumberOfFrames)

% check if there are skipped frames
runCamMeta = dlmread(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'run.csv')); % columns: bonsai timestamps, point grey counter, point grey timestamps (uninterpretted)
wiskCamMeta = dlmread(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'wisk.csv')); % columns: bonsai timestamps, point grey counter, point grey timestamps (uninterpretted)
deltaFramesRun = diff(runCamMeta(:,2));
deltaFramesWisk = diff(wiskCamMeta(:,1));

if any(deltaFramesRun>1) || any(deltaFramesWisk>1)
    disp('frames were skipped!')
else
    disp('no skipped frames')
end

% save data assuming no frames lost at beginning
data = load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runAnalyzed.mat'));

data.frameTimeStamps = nan(length(runCamMeta),1);
data.frameTimeStampsWisk = nan(length(wiskCamMeta),1);
data.frameTimeStamps(1:length(exposure.times)) = exposure.times;
data.frameTimeStampsWisk(1:length(exposure.times)) = exposure.times;

save(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'runAnalyzed.mat'), '-struct', 'data')
disp('data saved')


%% to clear up disk space we could:


% get rid of runTop, runBot when run exists

% get rid of originalDimensions for old sessions OR ...

% get rid of cropped for old sessions and reanalyze: could potentially
% analyze on cropped vids with old network, then shift the coordinates to
% accomodate the cropping, and throw away cropped vid, performing the rest
% of the analysis on the uncropped video // alternatively, see if old DLC
% can handle uncropped vids, and reanalyze like that...

%% load lick time diffs for all sessions

d = cell(1, length(ephysSessions));
for i = 1:length(ephysSessions)
    load(fullfile(getenv('OBSDATADIR'), 'sessions', ephysSessions{i}, 'runAnalyzed.mat'), 'lickTimes')
    d{i} = diff(lickTimes);
end
disp('all done!')


close all;
diffs = cat(1,d{:});
figure; histogram(diffs(diffs<1)*250,100)

%% check confidence statistics for new and old sessions

new = readtable('Z:\loco\obstacleData\sessions\200311_000\trackedFeaturesRaw.csv');
old = readtable('Z:\loco\obstacleData\sessions\200310_001\trackedFeaturesRaw.csv');

newConf = table2array(new(:,contains(new.Properties.VariableNames, '_2')));
oldConf = table2array(old(:,contains(old.Properties.VariableNames, '_2')));

bins = 100;
close all; figure; histogram(newConf(:),bins); hold on; histogram(oldConf(:),bins)

%% copy metadata to all ephysSessions

files = {'trackedFeaturesRaw_metadata.mat', 'trackedFeaturesRaw_wisk_metadata.mat'};
srcDir = 'C:\Users\rick\Desktop\';

for i = 1:length(ephysSessions)
    for j = 1:length(files)
        copyfile(fullfile(srcDir, files{j}), ...
            fullfile(getenv('OBSDATADIR'), 'sessions', ephysSessions{i}, files{j}));
    end
end
disp('all done!')


%% find grooming by plotting wheel vel and vertical paw position

close all
sessions = ephysSessions(1:14);

for i = 1:length(sessions)
    load(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, 'runAnalyzed.mat'), ...
        'wheelPositions', 'wheelTimes', 'rewardTimes', 'frameTimeStamps');
    locations = readtable(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, 'trackedFeaturesRaw.csv'));
    rf_z = -locations.paw3RF_top_1;
    rf_conf = locations.paw3RF_top_2;
    rf_z(rf_conf<.8) = nan;
    wheelVel = getVelocity(wheelPositions, .1, 1/nanmedian(diff(wheelTimes)));

    figure('name', sessions{i}, 'color', 'white', 'Position', [30.00 772.00 1781.00 176.00]); hold on
%     yyaxis left
%     plot(wheelTimes, wheelVel)
%     yyaxis right
    plot(frameTimeStamps, rf_z)
    set(gca, 'ylim', [-140 0])
    pause(.1)
end
disp('all done!')
