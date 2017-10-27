
% USER SETTINGS

% settings
vidFile = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\testVideo\botTest.mp4';
classifier = 'C:\Users\rick\Google Drive\columbia\obstacleData\svm\classifiers\classifier_pawBot_26-Oct-2017';
startFrame = 1;
thresh = 1;
boxSize = [36 36];
overlapThresh = .2;

% load sample frame and sample sub-frame
vid = VideoReader(vidFile);
sampleFrame = rgb2gray(read(vid,startFrame));
frmHgt = size(sampleFrame,1);
frmWid = size(sampleFrame,2);

% load classifier
load(classifier)

%% prepare figure
close all; figure('position', [680 144 698 834]); colormap gray

rawAxis = subaxis(2,1,1, 'spacing', 0.01, 'margin', .01);
rawIm = image(sampleFrame, 'parent', rawAxis, 'CDataMapping', 'scaled');
hold on; scatterPts = scatter(rawAxis, 0, 0, 200, 'filled');

predictAxis = subaxis(2,1,2, 'spacing', 0.01, 'margin', .01);
predictIm = image(sampleFrame, 'parent', predictAxis, 'CDataMapping', 'scaled');

%
for i = startFrame:vid.numberofframes
    
    % get frame and sub-frames
    frame = rgb2gray(read(vid,i));
    
    % filter with svm
    frameFiltered = - (conv2(frame, reshape(model.w, boxSize(1), boxSize(2)), 'same') - model.rho);
    [trackedPts, ~] = nonMaximumSupress(frameFiltered, boxSize, overlapThresh);
    frameFiltered(frameFiltered<0) = 0;
    
    % update figure
    set(rawIm, 'CData', frame);
    set(predictIm, 'CData', frameFiltered)
    set(scatterPts, 'XData', trackedPts(2,:), 'YData', trackedPts(1,:));

    % pause to reflcet on the little things...
    pause(.05);
end





