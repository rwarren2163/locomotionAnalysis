function getWiskContactTimes(sessions, thresh, showFrames)

% settings
rows = 5;
cols = 8;



for i = 1:length(sessions)
    
    fprintf('analyzing session %s\n', sessions{i})
    
    vid = VideoReader([getenv('OBSDATADIR') 'sessions\' sessions{i} '\runWisk.mp4']);
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\runAnalyzed.mat'], ...
        'wiskTouchSignal', 'obsOnTimes', 'obsOffTimes', 'frameTimeStampsWisk');
    
    % convert wisk contacts to z scores
    realInds = ~isnan(wiskTouchSignal);
    normedReal = zscore(wiskTouchSignal(realInds));
    wiskTouchSignal = nan(size(wiskTouchSignal));
    wiskTouchSignal(realInds) = normedReal;
    
    % find first contact time for each trial and get sample frames
    wiskContactTimes = nan(1, length(obsOnTimes));
    preContactFrames = nan(vid.Height, vid.Width, length(obsOnTimes));
    contactFrames = nan(vid.Height, vid.Width, length(obsOnTimes));
        
    for j = 1:length(obsOnTimes)
        indStart = find(frameTimeStampsWisk>obsOnTimes(j) & frameTimeStampsWisk<obsOffTimes(j) & wiskTouchSignal>=thresh, 1, 'first');
        
        if ~isempty(indStart)
            try
                wiskContactTimes(j) = interp1(wiskTouchSignal(indStart-1:indStart), frameTimeStampsWisk(indStart-1:indStart), thresh);
                if abs(wiskContactTimes(j)-frameTimeStampsWisk(indStart-1)) < abs(wiskContactTimes(j)-frameTimeStampsWisk(indStart))
                    indStart = indStart-1;
                end
                preContactFrames(:,:,j) = rgb2gray(read(vid, indStart-1));
                contactFrames(:,:,j) = rgb2gray(read(vid, indStart));
            catch
                fprintf('%s: error processing trial %i\n', sessions{i}, j);
            end
        end
    end
    
    
    % show preContact contact frames
    preContactPreview = nan(rows*vid.Height, cols*vid.Width);
    contactPreview = nan(rows*vid.Height, cols*vid.Width);
    imInds = randperm(size(contactFrames,3), rows*cols);
    imInd = 1;

    for j = 1:rows
        for k = 1:cols
            y = (j-1)*vid.Height + 1;
            x = (k-1)*vid.Width + 1;
            preContactPreview(y:y+vid.Height-1, x:x+vid.Width-1) = preContactFrames(:,:,imInds(imInd));
            contactPreview(y:y+vid.Height-1, x:x+vid.Width-1) = contactFrames(:,:,imInds(imInd));
            imInd = imInd+1;
        end
    end

    if showFrames
        figure('name', [sessions{i} ' preContact']);
        imshow(uint8(preContactPreview)); pimpFig
        figure('name', [sessions{i} ' contact']);
        imshow(uint8(contactPreview)); pimpFig
    end
    
    save([getenv('OBSDATADIR') 'sessions\' sessions{i} '\wiskContactTimes.mat'], 'wiskContactTimes', 'preContactFrames', 'contactFrames', 'thresh');
end



