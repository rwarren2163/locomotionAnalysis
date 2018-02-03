function preparePoseRegressionData(sessions, totalEgs)

% % temp
% sessions = {'180122_000', '180122_001', '180122_002'};
% totalEgs = 500;

% settings
writeDir = 'C:\Users\rick\Desktop\trainingExamples\poseRegression\';
targetSize = [227 227];

% initializations
if ~exist(writeDir, 'dir'); mkdir(writeDir); end
if ~exist([writeDir '\imgs'], 'dir'); mkdir([writeDir '\imgs']); end
lastSessionInd = 0;
imgInd = 1;



% concatinate all labeled data sets
sessionInds = []; % stores the session identity for each saved location
sessionFrameInds = []; % stores the frame inds
locationsAll = [];

for i = 1:length(sessions)
    
    % get labeled locations for single session
    load([getenv('OBSDATADIR') 'sessions\' sessions{i} '\tracking\locationsBotCorrected.mat'], 'locations');
    
    % remove nan entries
    frameInds = find(~isnan(sum(squeeze(locations.locationsCorrected(:,1,:)),2)))'; % only keep locations where all paws have a non-nan entry
    locations = locations.locationsCorrected(frameInds,:,:);
    
    % store
    locationsAll = cat(1, locationsAll, locations);
    sessionInds = [sessionInds i*ones(1,size(locationsAll,1))];
    sessionFrameInds = [sessionFrameInds frameInds];
    
end


% select random frames
locationInds = randperm(size(locationsAll,1), totalEgs);
locationInds = sort(locationInds);

% restructure locations into feature matrix, and normalize range
locations = locationsAll(locationInds,:,:);
locations = reshape(locations, totalEgs, 8);


for i = locationInds
    
    % load new video if you have reached the next session
    if sessionInds(i) ~= lastSessionInd
        fprintf('loading session %s', sessions{sessionInds(i)})
        vid = VideoReader([getenv('OBSDATADIR') 'sessions\' sessions{sessionInds(i)} '\runBot.mp4']);
        bg = getBgImage(vid, 1000, 120, 2*10e-4, false);
        load([getenv('OBSDATADIR') 'sessions\' sessions{sessionInds(i)} '\runAnalyzed.mat'], 'obsPixPositions')
        lastSessionInd = sessionInds(i);
    end
    
    % get frame
    frame = rgb2gray(read(vid, sessionFrameInds(i)));
    frame = frame - bg;
    
    % mask obstacle
    if ~isnan(obsPixPositions(sessionFrameInds(i)))
        frame = maskObs(frame, obsPixPositions(sessionFrameInds(i)));
    end
    
    % save image
%     imwrite(frame, [writeDir 'imgs\img' num2str(imgInd) '.tif'])
    img = uint8(imresize(frame, 'outputsize', targetSize));
    img = repmat(img, 1, 1, 3);
    imwrite(img, [writeDir 'imgs\img' num2str(imgInd) '.tif'])
    
    % report progress
    disp(imgInd/totalEgs)
    imgInd = imgInd +  1;
end

% store data in features table
imgNames = cell(totalEgs,1);
for i = 1:totalEgs; imgNames{i} = [writeDir 'imgs\img' num2str(i) '.tif']; end
x1 = nan(totalEgs,1); y1 = nan(totalEgs,1);
x2 = nan(totalEgs,1); y2 = nan(totalEgs,1);
x3 = nan(totalEgs,1); y3 = nan(totalEgs,1);
x4 = nan(totalEgs,1); y4 = nan(totalEgs,1);
features = table(imgNames, x1,y1,x2,y2,x3,y3,x4,y4);

% normalize feature range
locations(:,[1 3 5 7]) = locations(:,[1 3 5 7]) / size(frame,2);
locations(:,[2 4 6 8]) = locations(:,[2 4 6 8]) / size(frame,1);
for i = 1:8; features(:,i+1) = mat2cell(locations(:,i), ones(1,totalEgs), 1); end


% save results
save([writeDir 'pawLocations.mat'], 'features', 'locations', 'sessions', 'sessionFrameInds', 'sessionInds')
csvwrite([writeDir 'locations.csv'], locations)




% % sanity check pltting to see ifthings worked correctly
% ind = 100;
% ind = locationInds(ind);
% 
% vid = VideoReader([getenv('OBSDATADIR') 'sessions\' sessions{sessionInds(ind)} '\runBot.mp4']);
% frame = rgb2gray(read(vid, sessionFrameInds(ind)));
% close all; figure;
% imshow(frame);
% hold on; scatter(locationsAll(ind,[1 3 5 7]), locationsAll(ind,[2 4 6 8]))








