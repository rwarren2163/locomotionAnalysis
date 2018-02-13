% function getObsTrajectories(sessions)

% temp
sessions = {'180122_001', '180122_002', '180122_003'};%, ...
%             '180123_001', '180123_002', '180123_003', ...
%             '180124_001', '180124_002', '180124_003'}; ...
%             '180125_001', '180125_002', '180125_003'};

% settings
obsPos = -.0073;
speedTime = .02; % compute velocity over this interval
controlSteps = 2;

% initializations
sessionInfo = readtable([getenv('OBSDATADIR') 'sessions\sessionInfo.xlsx']);
data = struct();
dataInd = 1;

for i = 1:length(sessions)
    
    % report progress
    fprintf('%s: collecting data\n', sessions{i});
    
    % load session data
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\runAnalyzed.mat'],...
            'obsPositions', 'obsTimes', 'obsPixPositions', 'frameTimeStamps', ...
            'obsOnTimes', 'obsOffTimes', 'nosePos', 'targetFs', 'wheelPositions', 'wheelTimes');
    obsPositions = fixObsPositions(obsPositions, obsTimes, obsPixPositions, frameTimeStamps, obsOnTimes, obsOffTimes, nosePos(1));
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\tracking\locationsBotCorrected.mat'], 'locations')
    locations = locations.locationsCorrected;
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\tracking\stanceBins.mat'], 'stanceBins')
    
    % get velocities for all trials in session
    sessionVels = getTrialSpeedsAtObsPos(obsPos, wheelPositions, wheelTimes, obsPositions, obsTimes, obsOnTimes, speedTime, targetFs);
    
    % normalize y values
    locations(:,2,:) = locations(:,2,:) - nosePos(2); % subtract midline from all y values
    
    % get stance identities
    swingBins = ~stanceBins;
    swingIdentities = nan(size(swingBins));
    for j = 1:4
        swingStartBins = [0; diff(swingBins(:,j))==1]';
        swingIdentities(:,j) = cumsum(swingStartBins);
    end
    swingIdentities(stanceBins | isnan(squeeze(locations(:,1,:)))) = nan;
    
    
    for j = 1:length(obsOnTimes)
        
        % get frame ind at which obs reaches obsPos
        obsPosTime = obsTimes(find(obsPositions>=obsPos & obsTimes>obsOnTimes(j), 1, 'first'));
        obsPosInd = knnsearch(frameTimeStamps, obsPosTime);
        
        % get trial swing identities and define control and modified steps
        controlStepIdentities = nan(size(swingIdentities));
        modifiedStepIdentities = nan(size(swingIdentities));
        
        for k = 1:4
            overObsInd = find(locations(:,1,k)>obsPixPositions' & frameTimeStamps>obsOnTimes(j), 1, 'first');
            swingOverObsIdentity = swingIdentities(overObsInd, k);
            firstModifiedIdentitiy = swingIdentities(obsPosInd, k);
            
            modifiedBins = (trialSwingIdentities(:,k) >= firstModifiedIdentitiy) & (trialSwingIdentities(:,k) <= swingOverObsIdentity);
            controlBins = (trialSwingIdentities(:,k) >= (firstModifiedIdentitiy-controlSteps)) & (trialSwingIdentities(:,k) < firstModifiedIdentitiy);
            
            controlStepIdentities = swingIdentities
            
            trialSwingIdentities(:,k) = swingIdentities(:,k) - swingOverObsIdentity;
        end
        
        
        
        % define control and modified swings (modified swings are those that occur during or after the frame at which obs reaches obsPos)
        for k = 1:4
            
        end
        
        
        
        % get swing identities
        
        
        
        
        % store results
        sessionInfoBin = find(strcmp(sessionInfo.session, sessions{i}));
        data(dataInd).mouse = sessionInfo.mouse{sessionInfoBin};
        data(dataInd).session = sessions{i};
        data(dataInd).vel = sessionVels(j);
        data(dataInd).obsPosInd = obsPosInd;
        dataInd = dataInd + 1;
        
    end
end

fprintf('--- done collecting data ---\n', sessions{i});









