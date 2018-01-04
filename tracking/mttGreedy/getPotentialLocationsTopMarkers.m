% function getPotentialLocationsTopMarkers(vid, frameInds, thresh, showTracking)


% !!! need to document

% temp
vid = VideoReader('C:\Users\rick\Google Drive\columbia\obstacleData\sessions\markerTest1\runTop.mp4');
thresh = 120;
showTracking = true;

% settings
circRoiPts = [36 172; 224 122; 386 157];
minBlobArea = 30;


% initializations
sampleFrame = rgb2gray(read(vid,1));
totalFrames = vid.NumberOfFrames;
wheelMask = getWheelMask(circRoiPts, [vid.Height vid.Width]);
bg = getBgImage(vid, 1000, 120, 2*10e-4, false);

%%


% prepare figure
if showTracking

    figure('menubar', 'none', 'color', 'white'); colormap gray

    rawAxis = subaxis(2,1,1, 'spacing', 0, 'margin', 0);
    rawIm = image(sampleFrame, 'parent', rawAxis, 'CDataMapping', 'scaled');
    set(gca, 'visible', 'off');
    hold on; scatterPtsAll = scatter(rawAxis, 0, 0, 100, 'filled', 'red');
    
    threshAxis = subaxis(2,1,2, 'spacing', 0, 'margin', 0);
    treshIm = image(sampleFrame, 'parent', threshAxis, 'CDataMapping', 'scaled');
    set(gca, 'visible', 'off');
    
    set(gcf, 'position', [680 144 vid.Width*2 vid.Height*4])
    
end

%%
potentialLocationsTop = struct();

for i = frameInds
    
    disp(i/totalFrames)
    
    % get frame and subframes
    frame = rgb2gray(read(vid,i));
    frame = frame - bg;
    frameMasked = frame .* wheelMask; % mask wheel
    frameThreshed = frameMasked > thresh;
    
    
    % blob analysis
    blobInfo = regionprops(frameThreshed, 'Area', 'Centroid');
    
        
    
    % store data
    potentialLocationsTop(i).x = x;
    potentialLocationsTop(i).y = y;
    potentialLocationsTop(i).scores = scores;
    
    
    if showTracking
        
        % put lines in top frame
        for j = paws%1:4
            if locationsBot.x(i,j)>0 && locationsBot.x(i,j)<vid.Width
                frame(:,locationsBot.x(i,j)) = 255;
            end
        end
        
        % update figure
        set(rawIm, 'CData', frame);
        set(treshIm, 'CData', frameMasked);
        set(predictIm, 'CData', frameFiltered)
        set(scatterPtsAll, 'XData', x, 'YData', y);
        
        % pause to reflcet on the little things...
        pause(.2);
%         keyboard
    end
end

close all

