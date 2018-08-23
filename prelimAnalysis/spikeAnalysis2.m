function spikeAnalysis2(session, varsToOverWrite)

    % performs preliminary analyses on spike data and saves results in runAnalyzed.mat
    %
    % computes the following:
    %         reward times
    %         debounced touch signal and touch on/off times
    %         decoding stepper motor commands
    %         decoding obstacle position
    %         decoding wheel position
    %         getting obstacle on and off times
    %         getting obstacle light on and off times
    %         whether a trial has light on or not
    %         getting frame time stamps
    %         getting wisk frame time stamps
    %         getting webcam time stamps
    %         get position of tip of nose from bot view
    %         linear mapping between meters and pixels
    %         neural network classifier to determine whether paws are touching obs
    %         body angle
    %
    % for each session, loads existing runAnalyzed.mat
    % if a computed variable is not already stored in runAnalyzed.mat AND the files necessary to compute it exist, it computes the variable
    % if a variable name is included in cell array varsToOverWrite, it re-computes the variable even if it already exists, so long as
    % the necessary files exist in the directory to compute it
    %
    % input:     sessions          session to analyze
    %            varsToOverwrite   cell array of of variables that should be re-computed



    % settings
    targetFs = 1000; % frequency that positional data will be resampled to
    minRewardInteveral = 1;
    minObsLightInterval = .1;

    % rig characteristics
    whEncoderSteps = 2880; % 720cpr * 4
    wheelRad = 95.25; % mm
    obEncoderSteps = 1000; % 250cpr * 4
    obsRad = 96 / (2*pi); % radius of timing pulley driving belt of obstacles platform

    % if no variables to overwrite are specified, set to default
    if ~exist('varsToOverWrite', 'var')
        varsToOverWrite = {' '};
    end
    
    


    anythingAnalyzed = false; % results are only saved if something was found that wasn't already analyzed

    % load or initialize data structure
    sessionDir = [getenv('OBSDATADIR') 'sessions\' session '\'];

    if exist([sessionDir 'runAnalyzed.mat'], 'file')
        varStruct = load([sessionDir 'runAnalyzed.mat']);
    else
        varStruct = struct();
    end
    varNames = fieldnames(varStruct);


    
    
    % analyze reward times
    if analyzeVar({'rewardTimes'}, varNames, varsToOverWrite)

        fprintf('%s: getting reward times\n', session)
        load([sessionDir 'run.mat'], 'reward')

        % find reward times
        rewardInds = find(diff(reward.values>2)==1) + 1;
        rewardTimes = reward.times(rewardInds);

        % remove reward times occuring within minRewardInteveral seconds of eachother
        rewardTimes = rewardTimes(logical([1; diff(rewardTimes)>minRewardInteveral]));

        % save values
        varStruct.rewardTimes = rewardTimes;
        anythingAnalyzed = true;
    end




    % decode stepper motor commands
    if analyzeVar({'motorPositions', 'motorTimes'}, varNames, varsToOverWrite)

        load([sessionDir 'run.mat'], 'step', 'stepDir')

        % decode stepper motor
        if exist('stepDir', 'var') && ~isempty(stepDir.times)
            fprintf('%s: decoding stepper motor commands\n', session)
            [motorPositions, motorTimes] = motorDecoder(stepDir.level, stepDir.times, step.times, targetFs);
        else
            motorPositions = [];
            motorTimes = [];
        end

        % save values
        varStruct.motorPositions = motorPositions;
        varStruct.motorTimes = motorTimes;
        varStruct.targetFs = targetFs;
        anythingAnalyzed = true;
    end




    % decode obstacle position (based on obstacle track rotary encoder)
    if analyzeVar({'obsPositions', 'obsTimes'}, varNames, varsToOverWrite)

        load([sessionDir 'run.mat'], 'obEncodA', 'obEncodB')

        if exist('obEncodA', 'var') && ~isempty(obEncodA.times)
            fprintf('%s: decoding obstacle position\n', session)
            [obsPositions, obsTimes] = rotaryDecoder(obEncodA.times, obEncodA.level,...
                                                     obEncodB.times, obEncodB.level,...
                                                     obEncoderSteps, obsRad, targetFs, session);
        else
            obsPositions = [];
            obsTimes = [];
        end

        % save values
        varStruct.obsPositions = obsPositions;
        varStruct.obsTimes = obsTimes;
        varStruct.targetFs = targetFs;
        anythingAnalyzed = true;
    end




    % decode wheel position
    if analyzeVar({'wheelPositions', 'wheelTimes'}, varNames, varsToOverWrite)

        fprintf('%s: decoding wheel position\n', session)
        load([sessionDir 'run.mat'], 'whEncodA', 'whEncodB')

        [wheelPositions, wheelTimes] = rotaryDecoder(whEncodA.times, whEncodA.level,...
                                                     whEncodB.times, whEncodB.level,...
                                                     whEncoderSteps, wheelRad, targetFs, session);
        % save values
        varStruct.wheelPositions = wheelPositions;
        varStruct.wheelTimes = wheelTimes;
        varStruct.targetFs = targetFs;
        anythingAnalyzed = true;
    end




    % get obstacle on and off times
    % (ensuring that first event is obs turning ON and last is obs turning OFF)
    if analyzeVar({'obsOnTimes', 'obsOffTimes'}, varNames, varsToOverWrite)

        fprintf('%s: getting obstacle on and off times\n', session)
        load([sessionDir 'run.mat'], 'obsOn')

        if exist('obsOn', 'var')
            firstOnInd = find(obsOn.level, 1, 'first');
            lastOffInd = find(~obsOn.level, 1, 'last');

            obsOn.level = obsOn.level(firstOnInd:lastOffInd);
            obsOn.times = obsOn.times(firstOnInd:lastOffInd);

            obsOnTimes  =  obsOn.times(logical(obsOn.level));
            obsOffTimes = obsOn.times(logical(~obsOn.level));
        else
            obsOnTimes = [];
            obsOffTimes = [];
        end
        
        % get rid of really close obsOnTimes (debounce)
        validBins = (obsOffTimes-obsOnTimes) > .1; % not too close together
        obsOnTimes = obsOnTimes(validBins);
        obsOffTimes = obsOffTimes(validBins);
        

        % save values
        varStruct.obsOnTimes = obsOnTimes;
        varStruct.obsOffTimes = obsOffTimes; 
        anythingAnalyzed = true;
    end
    
    
    
% the following is commented out because i prefer using the obsHeights determined from the video // this code threw an error for session 180803_002 and i dont care to find out what that's about!    
%     % determine obstacle height for every trial
%     if analyzeVar({'obsHeights'}, varNames, varsToOverWrite) && ...
%        exist([sessionDir '\trialInfo.csv'], 'file') && ...
%        ~isempty(readtable([sessionDir 'trialInfo.csv']))
%        
%         fprintf('%s: getting obstacle heights\n', session)
%         obsHeightData = dlmread([sessionDir '\trialInfo.csv']); % columns: obsHeight (mm), timestamp (s), timestamps (ms)
%         obsTimesSeconds = obsHeightData(:,2);
%         validInds = [abs(diff(obsTimesSeconds))>0; true]; %if two times are very close to eachother only believe the second of the two times
%         obsHeights = obsHeightData(validInds,1);
%         try
%         obsHeights = obsHeights(1:length(varStruct.obsOnTimes)); % this gets rid of last entry, which we shouldn't need
%         catch; keyboard; end
%         
%         % there should be one more obsHeight than there all trials because an obs height is randomly chosen
%         if sum(validInds)-1 > length(obsHeights)
%             fprintf('%s: WARNING: problem assigning obstacle height metadata to correct trial\n', session)
%         end
% 
%         % save values
%         varStruct.obsHeights = obsHeights;
%         anythingAnalyzed = true;
%     end
    



    % get obstacle light on and off times
    % (ensuring that first event is obs turning ON and last is obs turning OFF)
    if analyzeVar({'obsLightOnTimes', 'obsLightOffTimes'}, varNames, varsToOverWrite)

        fprintf('%s: getting obstacle light on and off times\n', session)
        load([sessionDir 'run.mat'], 'obsLight')

        if exist('obsLight', 'var') && any(obsLight.values>2)

            % find reward times
            obsLightOnInds  = find(diff(obsLight.values>2)==1) + 1;
            obsLightOffInds = find(diff(obsLight.values>2)==-1) + 1;
            obsLightOnTimes = obsLight.times(obsLightOnInds);
            obsLightOffTimes = obsLight.times(obsLightOffInds);

            % remove reward times occuring within minRewardInteveral seconds of each other
            obsLightOnTimes  = obsLightOnTimes(logical([1; diff(obsLightOnTimes)>minObsLightInterval]));
            obsLightOffTimes = obsLightOffTimes(logical([1; diff(obsLightOffTimes)>minObsLightInterval]));

            % ensure first time is on and last time is off
            obsLightOnTimes =  obsLightOnTimes(obsLightOnTimes < obsLightOffTimes(end));
            obsLightOffTimes = obsLightOffTimes(obsLightOffTimes > obsLightOnTimes(1));

        else
            obsLightOnTimes = [];
            obsLightOffTimes = [];
        end

        % save values
        varStruct.obsLightOnTimes = obsLightOnTimes;
        varStruct.obsLightOffTimes = obsLightOffTimes; 
        anythingAnalyzed = true;
    end
    
    
    
    
    % determine whether light was on or off for every trial
    if analyzeVar({'isLightOn'}, varNames, varsToOverWrite)
        
        if isfield(varStruct, 'obsLightOnTimes') && isfield(varStruct, 'obsOnTimes')
            
            fprintf('%s: determing whether each trial is light on or light off\n', session)
            isLightOn = false(size(varStruct.obsOnTimes));

            if ~isempty(varStruct.obsLightOnTimes) 
                for i = 1:length(varStruct.obsOnTimes)
                    isLightOn(i) = min(abs(varStruct.obsOnTimes(i) - varStruct.obsLightOnTimes)) < 1; % did the light turn on near when the obstacle turned on
                end
            end
        else
            isLightOn = [];
        end

        % save values
        varStruct.isLightOn = isLightOn;
        anythingAnalyzed = true;
    end




    % get frame timeStamps
    if analyzeVar({'frameTimeStamps'}, varNames, varsToOverWrite)

        if exist([sessionDir 'run.csv'], 'file')

            fprintf('%s: getting frame time stamps\n', session)
            load([sessionDir '\run.mat'], 'exposure')

            % get camera metadata and spike timestamps
            camMetadata = dlmread([sessionDir '\run.csv']); % columns: bonsai timestamps, point grey counter, point grey timestamps (uninterpretted)
            frameCounts = camMetadata(:,2);
            timeStampsFlir = timeStampDecoderFLIR(camMetadata(:,3));

            if length(exposure.times) >= length(frameCounts)
                frameTimeStamps = getFrameTimes2(exposure.times, timeStampsFlir, frameCounts, session);
            else
                disp('  there are more frames than exposure TTLs... saving frameTimeStamps as empty vector')
                frameTimeStamps = [];
            end

            % save values
            varStruct.frameTimeStamps = frameTimeStamps;
            anythingAnalyzed = true;
        end
    end
    
    
    
    
    % get wisk frame timeStamps
    if analyzeVar({'frameTimeStampsWisk'}, varNames, varsToOverWrite)

        if exist([sessionDir 'wisk.csv'], 'file')
            
            fprintf('%s: getting wisk frame time stamps\n', session)
            load([sessionDir '\run.mat'], 'exposure')

            % get camera metadata and spike timestamps
            camMetadataWisk = dlmread([sessionDir '\wisk.csv']); % columns: bonsai timestamps, point grey counter, point grey timestamps (uninterpretted)
            frameCountsWisk = camMetadataWisk(:,1);
            timeStampsFlirWisk = timeStampDecoderFLIR(camMetadataWisk(:,2));

            if length(exposure.times) >= length(frameCountsWisk)
                frameTimeStampsWisk = getFrameTimes2(exposure.times, timeStampsFlirWisk, frameCountsWisk, session);
            else
                disp('  there are more frames than exposure TTLs... saving frameTimeStamps as empty vector')
                frameTimeStampsWisk = [];
            end

            % save values
            varStruct.frameTimeStampsWisk = frameTimeStampsWisk;
            anythingAnalyzed = true;
        end
    end




    % get webCam timeStamps if webCam data exist
    if analyzeVar({'webCamTimeStamps'}, varNames, varsToOverWrite)

        if exist([sessionDir 'webCam.csv'], 'file') &&...
           exist([sessionDir 'run.csv'], 'file') &&...
           any(strcmp(fieldnames(varStruct), 'frameTimeStamps'))

            fprintf('%s: getting webcam time stamps\n', session)

            % load data
            camMetadataWisk = dlmread([sessionDir '\wisk.csv']);
            camSysClock = camMetadataWisk(:,1) / 1000;
            camSpikeClock = varStruct.frameTimeStampsWisk; % !!! wh
            webCamSysClock = dlmread([sessionDir '\webCam.csv']) / 1000; % convert from ms to s

            % remove discontinuities
            webCamTimeSteps = cumsum([0; diff(webCamSysClock)<0]);
            webCamSysClock = webCamSysClock + webCamTimeSteps;
            webCamSysClock = webCamSysClock - webCamSysClock(1); % set first time to zero

            camTimeSteps = cumsum([0; diff(camSysClock)<0]);
            camSysClock = camSysClock + camTimeSteps;
            camSysClock = camSysClock - camSysClock(1); % set first time to zero

            % determine spike clock times from system clock times
            validInds = ~isnan(camSpikeClock);
            try
                sysToSpike = polyfit(camSysClock(validInds), camSpikeClock(validInds), 1);
                webCamSpikeClock = webCamSysClock * sysToSpike(1) + sysToSpike(2);

                % save
                varStruct.webCamTimeStamps = webCamSpikeClock;
                anythingAnalyzed = true;
            catch
                fprintf('%s: PROBLEM GETTING WEBCAM TIMESTAMPS\n', session)
            end
        end
    end
    
    
    
    
    % get nose position
    if analyzeVar({'nosePos'}, varNames, varsToOverWrite) && ...
       exist([sessionDir 'trackedFeaturesRaw.csv'], 'file')

        fprintf('%s: getting nose position\n', session)

        % load data
        locationsTable = readtable([sessionDir 'trackedFeaturesRaw.csv']); % get raw tracking data
        noseBotX = median(locationsTable.nose_bot);
        noseBotY = median(locationsTable.nose_bot_1);

        % save
        varStruct.nosePos = [noseBotX noseBotY];
        anythingAnalyzed = true;
    end
    
    
    
    % get mToPixMapping and obstacle pixel positions in bottom view
    if analyzeVar({'obsPixPositions', 'obsPixPositionsContinuous', 'mToPixMapping'}, varNames, varsToOverWrite) && ...
       exist([sessionDir 'trackedFeaturesRaw.csv'], 'file') && ...
       ~isempty(varStruct.obsOnTimes)

        fprintf('%s: tracking obstacles in bottom view\n', session)
        
        % load tracking data if not already open
        if ~exist('locationsTable', 'var'); locationsTable = readtable([sessionDir 'trackedFeaturesRaw.csv']); end
        
        % get obs pix positions
        obsHighX = locationsTable.obsHigh_bot;
        obsLowX = locationsTable.obsLow_bot;
        obsHighScores = locationsTable.obsHigh_bot_2;
        obsLowScores = locationsTable.obsLow_bot_2;
        
        % ensure that confidences are high for top and bottom points of obstacle, and ensure that both have x values that are close to one another
        validInds = abs(obsHighX - obsLowX) < 10 & ...
                    obsHighScores>0.99 & ...
                    obsLowScores>0.99;
        obsPixPositions = mean([obsHighX, obsLowX], 2);
        obsPixPositions(~validInds) = nan;
        obsPixPositionsUninterped = obsPixPositions; % these are the obsPixPositions wihtout any interpolation (only where the obs is in the frame and successfully tracked)
        obsPositionsInterp = interp1(varStruct.obsTimes, varStruct.obsPositions, varStruct.frameTimeStamps); % get position of obstacle for all frames
        wheelPositionsInterp = interp1(varStruct.wheelTimes, varStruct.wheelPositions, varStruct.frameTimeStamps); % get position of wheel for all frames
        
        % determine mappings between obs pix positions (x) and both wheel
        % positions and obs positions (both from independent rotary encoders)
        trialObsMappings = nan(length(varStruct.obsOnTimes), 2); % mapping between obs pix positions and obsPos from rotary encoder
        trialWheelMappings = nan(length(varStruct.obsOnTimes), 2); % mapping between obs pix positions and wheel pos from wheel rotary encoder
        for i = 1:length(varStruct.obsOnTimes)
            getMappingBins = varStruct.frameTimeStamps>varStruct.obsOnTimes(i) & ...
                             varStruct.frameTimeStamps<=varStruct.obsOffTimes(i) & ...
                             ~isnan(obsPixPositions);
            if any(getMappingBins)
                trialObsMappings(i,:) = polyfit(obsPositionsInterp(getMappingBins), obsPixPositions(getMappingBins), 1);
                trialWheelMappings(i,:) = polyfit(wheelPositionsInterp(getMappingBins), obsPixPositions(getMappingBins), 1);
            end          
        end
        
        % use obs position from rotary encoder to infer pix positions when obs is out of frame
        epochTimes = [varStruct.obsOnTimes; varStruct.frameTimeStamps(end)];
        for i = 1:(length(epochTimes)-1)
            epochBins = varStruct.frameTimeStamps>epochTimes(i) & ...
                        varStruct.frameTimeStamps<=epochTimes(i+1);
            interpBins =  epochBins & isnan(obsPixPositions); % bins that should be interpolated over
            if any(epochBins)
                obsPixPositions(interpBins) = obsPositionsInterp(interpBins)*trialObsMappings(i,1) + trialObsMappings(i,2);
            end
        end
        
        % use wheel position from rotary encoder to infer 'unraveled' obs
        % pix positions FOR EACH TRIAL
        %
        % obsPixPositionsContinuous has one obsPixPositions per trial,
        % where row is an 'individual obstacle'. This can be used to
        % 'unheadfix' the mouse later, by subtracting these obsPositions
        % from the x values of the paw on a trial by trial basis
        
        
        % obs
        obsPixPositionsContinuous = repmat(obsPixPositions', length(varStruct.obsOnTimes), 1);
        for i = 1:length(varStruct.obsOnTimes)
            % interp all values expect those where obs is tracked within the trial
            dontInterpBins =  varStruct.frameTimeStamps>varStruct.obsOnTimes(i) & ...
                              varStruct.frameTimeStamps<varStruct.obsOffTimes(i) & ...
                              epochBins & ~isnan(obsPixPositionsUninterped); % use obsPixPositions except when it is nan or it it out of frame // otherwise figure it out based on wheel encoder
            if any(~dontInterpBins)
                obsPixPositionsContinuous(i,~dontInterpBins) = wheelPositionsInterp(~dontInterpBins)*trialWheelMappings(i,1) + trialWheelMappings(i,2);
            end
        end

        % save
        varStruct.obsPixPositions = obsPixPositions';
        varStruct.obsPixPositionsContinuous = obsPixPositionsContinuous;
        varStruct.mToPixMapping = nanmedian(trialObsMappings,1);
        anythingAnalyzed = true;
    end
    
    
    
    
    % get wheel points
    if analyzeVar({'wheelCenter', 'wheelRadius'}, varNames, varsToOverWrite) & ...
       exist([sessionDir 'trackedFeaturesRaw.csv'], 'file')
        
        fprintf('%s: getting wheel center and radius\n', session)
        
        vidTop = VideoReader([sessionDir 'runTop.mp4']);
        wheelPoints = getWheelPoints(vidTop);
        [wheelRadius, wheelCenter] = fitCircle(wheelPoints);
        
        % save
        varStruct.wheelCenter = wheelCenter;
        varStruct.wheelRadius = wheelRadius;
        anythingAnalyzed = true;
    end
    
    
            
    
    % get body angle
    if analyzeVar({'bodyAngles'}, varNames, varsToOverWrite) && ...
       exist([sessionDir 'trackedFeaturesRaw.csv'], 'file')
        
        fprintf('%s: getting body angle\n', session)
        
        % load tracking data if not already open
        if ~exist('locationsTable', 'var'); locationsTable = readtable([sessionDir 'trackedFeaturesRaw.csv']); end
        bodyAngles = getSessionBodyAngles(locationsTable, varStruct.nosePos);
        
        % save
        varStruct.bodyAngles = bodyAngles;
        anythingAnalyzed = true;
    end
    
    
    
    
    % get height of obs for each trial
    if analyzeVar({'obsHeightsVid'}, varNames, varsToOverWrite) && ...
       any(strcmp(fieldnames(varStruct), 'obsPixPositions'))
        
        fprintf('%s: getting obstacle heights\n', session)
        
        % settings
        obsDiameter = 3.175; % (mm)
        
        % load tracking data if not already open
        if ~exist('locationsTable', 'var'); locationsTable = readtable([sessionDir 'trackedFeaturesRaw.csv']); end
        obsTopY = locationsTable.obs_top_1;
        obsTopScores = locationsTable.obs_top_2;
        
        obsHeightsVid = nan(1,length(varStruct.obsOnTimes));
        for i = 1:length(varStruct.obsOnTimes)
            trialBins = varStruct.frameTimeStamps>varStruct.obsOnTimes(i) & ...
                        varStruct.frameTimeStamps<varStruct.obsOffTimes(i) & ...
                        ~isnan(varStruct.obsPixPositions)' & ...
                        obsTopScores>.99;
            medianObsY = median(obsTopY(trialBins));
            obsHeightPix = varStruct.wheelCenter(2) - varStruct.wheelRadius - medianObsY;
            obsHeightsVid(i) = (obsHeightPix / abs(varStruct.mToPixMapping(1)))*1000 + (obsDiameter/2); % second term accounts for the fact that center of obs is tracked, but height is the topmost part of the obstacle
        end
        
        % save
        varStruct.obsHeightsVid = obsHeightsVid;
        anythingAnalyzed = true;
    end
    
    
    
    
    % neural network classifier to determine whether paw is touching obs
    if (analyzeVar({'touches', 'touchesPerPaw', 'touchConfidences', 'touchClassNames'}, varNames, varsToOverWrite) ...
            || ~exist([sessionDir 'pawAnalyzed.csv'], 'file') || isempty(readtable([sessionDir 'pawAnalyzed.csv']))) && ...
        exist([sessionDir 'trackedFeaturesRaw.csv'], 'file') && ...
        isfield(varStruct, 'obsPixPositions') && ...
        ~isempty(varStruct.obsOnTimes)
        
        fprintf('%s: getting paw contacts\n', session)
        
        % settings
        rerunClassifier = true; % if true, redoes the neural network classifier even when it has already been run // if false only runs the post-processing
        pythonPath = '\Users\rick\Anaconda3\envs\fastai\python.exe';
        confidenceThresh = .5;
        proximityThresh = 20;
        classesToAssignToPaw = {'fore_dorsal', 'fore_ventral', 'hind_dorsal', 'hind_ventral_low'};

        % run neural network classifier
        if ~exist([sessionDir 'pawAnalyzed.csv'], 'file') || (exist([sessionDir 'pawAnalyzed.csv'], 'file') && rerunClassifier) || isempty(readtable([sessionDir 'pawAnalyzed.csv']))
            fprintf('%s: running paw contact neural network\n', session)
            save([sessionDir 'runAnalyzed.mat'], '-struct', 'varStruct') % first save the file so analyzeVideo.py can access it
            [~, ~] = system([pythonPath ' tracking\pawContact\expandanalyze.py ' getenv('OBSDATADIR') 'sessions ' session]);
        end
        
        % get touch class for each frame
        pawAnalyzed = readtable([sessionDir 'pawAnalyzed.csv']);
        touchClassNames = pawAnalyzed.Properties.VariableNames(2:end); % first column is frame number
        allScores = table2array(pawAnalyzed(:,2:end));
        [touchConfidences, classInds] = max(allScores, [], 2);
        noTouchInd = find(strcmp(touchClassNames, 'no_touch'));
        classInds(touchConfidences<confidenceThresh) = noTouchInd;
        touches = ones(1,length(varStruct.frameTimeStamps))*noTouchInd;
        touches(pawAnalyzed.framenum) = classInds;
        
        
        % figure out which paws are touching obs in each touch frame
        
        % get xz positions for paws
        if ~exist('locationsTable', 'var'); locationsTable = readtable([sessionDir 'trackedFeaturesRaw.csv']); end
        [locations, features] = fixTrackingDLC(locationsTable, varStruct.frameTimeStamps);
        pawXZ = nan(size(locations,1), 2, 4);
        for i = 1:4
            pawXBin = contains(features, ['paw' num2str(i)]) & contains(features, '_bot');
            pawZBins = contains(features, ['paw' num2str(i)]) & contains(features, '_top');
            pawXZ(:,1,i) = locations(:,1,pawXBin);
            pawXZ(:,2,i) = locations(:,2,pawZBins);
        end

        % get obs height in pixels for each trial
        % (replace missing values with median of tracked values for each trial)
        obsBin = ismember(features, 'obs_top');
        obsHeights = nan(size(locations,1),1);
        for i = 1:length(varStruct.obsOnTimes)
            trialBins = varStruct.frameTimeStamps>varStruct.obsOnTimes(i) & ...
                        varStruct.frameTimeStamps<varStruct.obsOffTimes(i);
            medianHgt = nanmedian(locations(trialBins,2,obsBin));
            obsHeights(trialBins) = locations(trialBins,2,obsBin);
            obsHeights(trialBins & isnan(locations(:,2,obsBin))) = medianHgt;
        end
        obsHeights = medfilt1(obsHeights,5);

        % get xz distance of paws to obs at all times
        dx = squeeze(pawXZ(:,1,:)) - repmat(varStruct.obsPixPositions',1,4);
        dz = squeeze(pawXZ(:,2,:)) - repmat(obsHeights,1,4);
        pawDistances = sqrt(dx.^2 + dz.^2);

        % determine which paws are touching obs
        classesToAssignToPawInds = find(ismember(touchClassNames, classesToAssignToPaw));
        touchesToAssignToPaws = touches .* ismember(touches, classesToAssignToPawInds);
        touchesPerPaw = repmat(touchesToAssignToPaws',1,4) .* double(pawDistances<proximityThresh);
        
        % only only fore paw classes for forepaws annd hind paw classes for hind paws
        foreClassInds = find(contains(touchClassNames, 'fore'));
        hindClassInds = find(contains(touchClassNames, 'hind'));
        touchesPerPaw(:,[2,3]) = touchesPerPaw(:,[2,3]) .* double(ismember(touchesPerPaw(:,[2,3]), foreClassInds));
        touchesPerPaw(:,[1,4]) = touchesPerPaw(:,[1,4]) .* double(ismember(touchesPerPaw(:,[1,4]), hindClassInds));
        
        % touchConfidences are only for analyzed frames // asign confidence of 1 to unanalyzed frames
        temp = touchConfidences;
        touchConfidences = ones(1,length(varStruct.frameTimeStamps));
        touchConfidences(pawAnalyzed.framenum) = temp;
        
        
        % save
        varStruct.touches = touches;
        varStruct.touchesPerPaw = touchesPerPaw;
        varStruct.touchClassNames = touchClassNames;
        varStruct.touchConfidences = touchConfidences;
        anythingAnalyzed = true;
    end
    
    
    
    
    % run whisker contact network
    if analyzeVar('wiskContactFrames', varNames, varsToOverWrite) && ...
            ~isempty(varStruct.obsOnTimes) && ...
            exist([sessionDir 'runWisk.mp4'], 'file')
        
        fprintf('%s: running wisk contact network\n', session)
        pythonPath = 'C:\Users\rick\Anaconda3\envs\deepLabCut\python.exe';
        
        % run neural network classifier
        if anythingAnalyzed; save([sessionDir 'runAnalyzed.mat'], '-struct', 'varStruct'); end % first save the file so analyzeVideo.py can access it
        [~,~] = system([pythonPath ' tracking\whiskerContact\cropanalyzevideo.py ' getenv('OBSDATADIR') 'sessions ' session]);
        wiskContactData = readtable([sessionDir 'whiskerAnalyzed.csv']);
        
        % save
        varStruct.wiskContactFrames = wiskContactData.framenum;
        varStruct.wiskContactFramesConfidences = wiskContactData.confidence;
        anythingAnalyzed = true;
    end
    
    
    % save results
    if anythingAnalyzed
        save([sessionDir 'runAnalyzed.mat'], '-struct', 'varStruct')
        fprintf('%s: data analyzed and saved\n', session)
    end
    
    
    
    
    % ---------
    % FUNCTIONS
    % ---------
    
    function analyze = analyzeVar(vars, varNames, varsToOverWrite)
        if ~strcmp(varsToOverWrite,'all')
            analyze = any(~ismember(vars, varNames)) || any(ismember(varsToOverWrite, vars));
        else
            analyze = true;
        end
    end
end


