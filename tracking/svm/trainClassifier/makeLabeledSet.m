function makeLabeledSet(className, labeledDataFile, vidFile, obsPixPositions, posEgs, negEgsPerEg)

% !!! need to document


% settings
dataDir = 'C:\Users\LindseyBuckingham\Google Drive\columbia\obstacleData\svm\trainingData\';
subFrameSize = [50 50]; % y,x
maxOverlap = .25;


% initializations
load(labeledDataFile, 'locations', 'locationFrameInds');
nanInds = isnan(locationFrameInds);
locations = locations(:,~nanInds,:);
locationFrameInds = locationFrameInds(~nanInds);
centPad = floor(subFrameSize / 2); % y,x
posEgsCount = 0;

% sort chronologically (this may make reading video frames faster)
[locationFrameInds, sortInds] = sort(locationFrameInds);
locations = locations(:, sortInds, :);

egsPerFrame = size(locations,3);
imNumberInd = 1;
pixPerSub = prod(subFrameSize);

% load video and sample frame
vid = VideoReader(vidFile);
bg = getBgImage(vid, 1000, false);


% iterate through frames of all examples (locations)

features = nan(pixPerSub, size(locations,2));
labels = nan(1, size(locations,2));

for i = randperm(length(locations))
    
    % get frame
    frame = rgb2gray(read(vid, locationFrameInds(i)));
    frame = frame - bg;
    
    % mask obstacle
    if ~isnan(obsPixPositions(locationFrameInds(i)))
        frame = maskObs(frame, obsPixPositions(locationFrameInds(i)));
    end
        
    % create mask of locations of positive examples
    egsMask = zeros(size(frame,1), size(frame,2));

    for j = 1:egsPerFrame
        xy = round(locations(1:2, i, j));
        imgInds = {xy(2)-centPad(1):xy(2)+centPad(1), xy(1)-centPad(2):xy(1)+centPad(2)}; % would be smarter to have binary vector keeping track of whether imgInds are valid (if example is too close to edge), so I don't need to compute imgInds multiple times, etc
        imgInds{1}(imgInds{1}<1)=1; imgInds{1}(imgInds{1}>vid.Height)=vid.Height;
        imgInds{2}(imgInds{2}<1)=1; imgInds{2}(imgInds{2}>vid.Width)=vid.Height;
        egsMask(imgInds{1}, imgInds{2}) = 1;
    end


    % save positive and create negative examples
    for j = 1:egsPerFrame
        
        if posEgsCount < posEgs
            
            xy = round(locations(1:2, i, j));
            imgInds = {xy(2)-centPad(1):xy(2)+centPad(1)-1, xy(1)-centPad(2):xy(1)+centPad(2)-1};

            if ~any(imgInds{1}<1 | imgInds{1}>vid.Height) && ~any(imgInds{2}<1 | imgInds{2}>vid.Width)

                img = frame(imgInds{1}, imgInds{2});
                features(:, imNumberInd) = img(:);
                labels(imNumberInd) = 1;
                imNumberInd = imNumberInd+1;
                posEgsCount = posEgsCount+1;
                fprintf('positive eg #%i\n', posEgsCount);

                % create/save negative examples for every positive example
                for k = 1:negEgsPerEg

                    % find a frame that doesn't overlap with positive examples
                    acceptableImage = false;

                    while ~acceptableImage 

                        pos = [randi([centPad(1)+1 size(frame,1)-centPad(1)-1])...
                               randi([centPad(2)+1 size(frame,2)-centPad(2)-1])]; % y,x
                        temp = egsMask(pos(1)-centPad(1):pos(1)+centPad(1)-1, pos(2)-centPad(2):pos(2)+centPad(2)-1);
                        pixelsOverlap = sum(temp(:));
                        img = frame(pos(1)-centPad(1):pos(1)+centPad(1)-1, pos(2)-centPad(2):pos(2)+centPad(2)-1);

                        if (pixelsOverlap/pixPerSub)<maxOverlap && mean(img(:))>mean(frame(:))
                            acceptableImage = true;
                        end
                    end

                    % store negative example
                    features(:, imNumberInd) = img(:);
                    labels(imNumberInd) = 2;
                    imNumberInd = imNumberInd+1;
                end    
            end
        end
    end
    
    if posEgsCount==posEgs
        break;
    end
end

% remove nan values
validInds = ~isnan(labels);
features = features(:,validInds,:);
labels = labels(validInds);


save([dataDir className '\labeledFeatures.mat'], 'features', 'labels', 'subFrameSize')









