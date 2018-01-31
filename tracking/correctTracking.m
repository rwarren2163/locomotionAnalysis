function correctTracking(outputFile, vid, locations, frameInds, vidDelay, anchorPts, lineLocations)


% settings
circSize = 200;
vidSizeScaling = 1.5;
colors = hsv(4);


% initializations
playing = true;
paused = false;
frameUpdating = true;
currentFrameInd = frameInds(1);
sampleFrame = rgb2gray(read(vid,currentFrameInd));



% initialize fields for manual corrections (if they do not already exist)
if ~isfield(locations, 'locationCorrections'); locations.locationCorrections = nan(size(locations.locationsRaw)); end
if ~isfield(locations, 'locationsCorrected'); locations.locationsCorrected = nan(size(locations.locationsRaw)); end
if ~isfield(locations, 'isCorrected'); locations.isCorrected = false(length(locations.isAnalyzed),1); end
if ~isfield(locations, 'isInterped'); locations.isInterped = false(length(locations.isAnalyzed),1); end

% initialize corrected data (for every trial, replace x and y entries with non-nan entries in xCorrections and yCorrections // then interpolate on a trial by trial basis)
for i = unique(locations.trialIdentities(~isnan(locations.trialIdentities)))'
    mergeCorrectionsAndInterpolate(i, 1:4);
end



% prepare figure
close all;
fig = figure('units', 'pixels', 'position', [600 400 vid.Width*vidSizeScaling vid.Height*vidSizeScaling],...
    'menubar', 'none', 'color', 'black', 'keypressfcn', @changeFrames);

colormap gray
preview = image(sampleFrame, 'CDataMapping', 'scaled'); hold on;
rawAxis = gca;
set(rawAxis, 'visible', 'off', 'units', 'pixels',...
    'position', [0 0 vid.Width*vidSizeScaling vid.Height*vidSizeScaling]);
circSizes = circSize * ones(1,length(anchorPts));


% prepare lines showing x locations of bottom tracked paws
lines = cell(4,1);
if exist('lineLocations', 'var')
    for i = 1:4
        lines{i} = line([0 0], [vid.Height vid.Height-50], 'color', colors(i,:));
    end
end


% prepare circles showing locationsRaw
scatterRaw = scatter(rawAxis, zeros(1,length(anchorPts)), zeros(1,length(anchorPts)),...
    circSizes, colors, 'linewidth', 2.5); hold on


% prepare colored circles in the corner to tell you which paw goes where
hold on; scatter(rawAxis, [anchorPts{1}(1) anchorPts{2}(1) anchorPts{3}(1) anchorPts{4}(1)] .* (vid.Width-1) + 1,...
                 [anchorPts{1}(2) anchorPts{2}(2) anchorPts{3}(2) anchorPts{4}(2)] .* (vid.Height-1) + 1,...
                 circSizes, colors, 'filled', 'linewidth', 3);     % show anchor points

% prepare impoints, draggable markers used to show / adjust tracking
for i = 1:4
    impoints{i} = impoint(gca, [10 10]*i);
    setColor(impoints{i}, colors(i,:));
    addNewPositionCallback(impoints{i}, @(x) dispYaYaYa(i));
end


% main loop
while playing
    while paused; pause(.001); end
    updateFrame(1);
end
close(fig)


% ---------
% FUNCTIONS
% ---------

% keypress controls
function changeFrames(~,~)
    
    key = double(get(fig, 'currentcharacter'));
    
    if ~isempty(key) && isnumeric(key)
        
        if key==28                      % LEFT: move frame backward
            pause(.001);
            paused = true;
            updateFrame(-1);
        
        elseif key==29                  % RIGHT: move frame forward
            pause(.001);
            paused = true;
            updateFrame(1);
        
        elseif key==102                  % 'f': select frame
            pause(.001);
            paused = true;
            input = inputdlg('enter frame number');
            currentFrameInd = find(frameInds == str2double(input{1}));
            updateFrame(1);
        
        elseif key==27                  % ESCAPE: close window
            playing = false;
            paused = false;
            
        elseif key==115                 % 's': save current progress
            save(outputFile, 'locations')
        
        else                            % OTHERWISE: close window
            paused = ~paused;
        end
    end
end



% update frame preview
function updateFrame(frameStep)
    
    currentFrameInd = currentFrameInd + frameStep;
    if currentFrameInd > length(frameInds); currentFrameInd = 1;
    elseif currentFrameInd < 1; currentFrameInd = length(frameInds); end
    
    % record that this frame has been corrected (somebody looked at it and verified it was correct or corrected it manually)
    locations.isCorrected(frameInds(currentFrameInd)) = true;
    
    % get frame and sub-frames
    frame = rgb2gray(read(vid, frameInds(currentFrameInd)));
    
    
    % add vertical lines
    if exist('lineLocations', 'var')
        inds = lineLocations.x(frameInds(currentFrameInd),:);
        for j = 1:4
            set(lines{j}, 'XData', [inds(j) inds(j)])
        end
    end
    
    
    % add frame number
    frame = insertText(frame, [size(frame,2) size(frame,1)], ...
        sprintf('trial %i, frame %i', locations.trialIdentities(frameInds(currentFrameInd)), frameInds(currentFrameInd)),...
	    'BoxColor', 'black', 'AnchorPoint', 'RightBottom', 'TextColor', 'white');
    
    % update figure
    set(preview, 'CData', frame);
    
    
    % update point locations to locationsCorrected
    frameUpdating = true;
    for j = 1:4
        setPosition(impoints{j}, locations.locationsCorrected(frameInds(currentFrameInd),1,j), ...
            locations.locationsCorrected(frameInds(currentFrameInd),2,j));
    end
    frameUpdating = false;
    
    % update circles to locationsRaw
    frameLocations = locations.locationsRaw(frameInds(currentFrameInd),:,:);
    frameLocationsCorrected = locations.locationsCorrected(frameInds(currentFrameInd),:,:);
    correctedBins = ~isnan(frameLocationsCorrected);
    frameLocations(correctedBins) = frameLocationsCorrected(correctedBins);
    frameLocations = squeeze(frameLocations);
    
    set(scatterRaw, 'XData', frameLocations(1,:), 'YData', frameLocations(2,:), 'visible', 'on');
    
    % pause to reflcet on the little things...
    pause(vidDelay);
end





% adds corrected values to raw values for a trial, and interpolates missing values
function mergeCorrectionsAndInterpolate(trial, paws)
    
    trialInds = ([locations.trialIdentities]==trial);
    
    for dimension = 1:2
        for paw = paws
            
            % extract locations for a single trial, paw, and dimension (x, y, or z)
            trialLocations = squeeze(locations.locationsRaw(trialInds, dimension, paw));
            trialCorrections = squeeze(locations.locationCorrections(trialInds, dimension, paw));
            
            % if there are any manually corrected values, incorporate them
            correctedInds = ~isnan(trialCorrections);
            if ~isempty(correctedInds); trialLocations(correctedInds) = trialCorrections(correctedInds); end
            
            % fill in missing values and store in locationsCorrected field
            trialLocations = fillmissing(trialLocations, 'linear', 'endvalues', 'extrap');
            locations.locationsCorrected(trialInds, dimension, paw) = trialLocations;
        end
    end
end


function dispYaYaYa(paw)
    
    if ~frameUpdating
        trial = locations.trialIdentities(frameInds(currentFrameInd));
        locations.locationCorrections(frameInds(currentFrameInd), :, paw) = getPosition(impoints{paw});
        mergeCorrectionsAndInterpolate(trial, paw);
    end
end
    
    
end













