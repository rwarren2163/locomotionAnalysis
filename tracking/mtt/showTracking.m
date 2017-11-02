function showTracking(vid, locations, labels, gridPts, vidDelay, paws)
    

currentFrame = 1;
sampleFrame = rgb2gray(read(vid,currentFrame));
totalFrames = vid.NumberOfFrames;
cmap = winter(length(paws));

% prepare figure
close all;
fig = figure('position', [567 383 698 400], 'color', 'black', 'keypressfcn', @changeFrames);
colormap gray


rawIm = image(sampleFrame, 'CDataMapping', 'scaled');
rawAxis = gca;
set(rawAxis, 'visible', 'off')
hold on;
scatterPts =    scatter(rawAxis, zeros(1,length(paws)), zeros(1,length(paws)), 200, cmap, 'filled'); hold on
scatterPtsAll = scatter(rawAxis, 0, 0, 200, 'green', 'linewidth', 2);

playing = true;
paused = false;


% main loop
while playing
    while paused; pause(.001); end
    updateFrame(1);
end

% keypress controls
function changeFrames(~,~)
    
    key = double(get(fig, 'currentcharacter'));
    
    if ~isempty(key) && isnumeric(key)
        
        if key==28                      % LEFT: move frame backward
            paused = true;
            updateFrame(-1);
        
        elseif key==29                  % RIGHT: move frame forward
            paused = true;
            updateFrame(1);
        
        elseif key==27                  % ESCAPE: close window
            playing = false;
            close(fig)
        else                            % OTHERWISE: close window
            paused = ~paused;
        end
    end
end

% update frame preview
function updateFrame(frameStep)
    
    currentFrame = currentFrame + frameStep;
    
    % get frame and sub-frames
    frame = rgb2gray(read(vid,currentFrame));
    frame = getFeatures(frame);
    
    % update figure
    set(rawIm, 'CData', frame);
    
%     xs = [locations(currentFrame).x; gridPts(:,1)];
%     ys = [locations(currentFrame).y; gridPts(:,2)];
    xs = [locations(currentFrame).x; zeros(size(gridPts,1),1)];
    ys = [locations(currentFrame).y; zeros(size(gridPts,1),1)];

    inds = labels(currentFrame,paws);
    
    set(scatterPts, 'XData', xs(inds), 'YData', ys(inds), 'visible', 'on');
%     set(scatterPtsAll, 'XData', locations(currentFrame).x, 'YData', locations(currentFrame).y);
    
    % pause to reflcet on the little things...
    pause(vidDelay);
    if currentFrame==totalFrames; currentFrame = 0; end
end


end