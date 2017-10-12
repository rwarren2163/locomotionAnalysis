
% plot baseline data

% user settings
dataDir = 'C:\Users\Rick\Google Drive\columbia\obstacleData\';
mouse = 'run5';
rewardRotations = 8;
wheelDiam = 0.1905; % m


% initializations
load([dataDir 'sessions\171010_000\runAnalyzed.mat'], 'wheelPositions', 'wheelTimes', 'rewardTimes', 'targetFs')
maxPosit = pi * wheelDiam * rewardRotations;
positsInterp = 0 : (1/targetFs) : maxPosit;



%!!! iterate over sessions

% compute velocity
vel = getVelocity(wheelPositions, .5, targetFs);

% get per trial velocity and positions (cell arrays with one trial per entry)
vel = splitByRewards(vel, wheelTimes, rewardTimes, false);
posits = splitByRewards(wheelPositions, wheelTimes, rewardTimes, true);

% interpolate velocities over evenly spaced positional values
velInterp = nan(length(rewardTimes), length(positsInterp));

close all; figure;
cmap = copper(length(rewardTimes));

for j = 1:length(rewardTimes)
    
    % remove duplicate positional values
    [posits{j}, uniqueInds] = unique(posits{j}, 'stable');
    vel{j} = vel{j}(uniqueInds);
    
    velInterp(j,:) = interp1(posits{j}, vel{j}, positsInterp, 'linear');
    plot(positsInterp, velInterp(j,:), 'color', cmap(j,:)); hold on
    
end

% compute average
sessionMean = nanmean(velInterp, 1);
plot(positsInterp, sessionMean, 'linewidth', 5, 'color', [0 0 0])

pimpFig;
% velInterp = 


