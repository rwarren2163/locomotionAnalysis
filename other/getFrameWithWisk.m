function [frame, yWiskPos, xWiskPos, wiskScaling, frameNumWisk] = ...
    getFrameWithWisk(vidRun, vidWisk, frameTimeStamps, frameTimeStampsWisk, frameNumRun, varargin)

% returns a frame with the whisker camera overlaid on the run camera //
% 'frame' is the desired frame in vidRun // automatically finds
% corresponding frame in vidWisk // if the user passes in yWiskPos, 
% xWiskPos, and wiskScaling, they don't have to be computed de novo

% settings
s.border = 5;  % border to add around the whiskers
s.yWiskPos = [];
s.xWiskPos = [];
s.wiskScaling = [];
s.wiskContrast = [.5 1];
s.runContrast = [0 1];
s.isPaddingWhite = false;  % otherwise padding is black
s.edgeFading = 50;  % (pixels) how much to fade out left and right side of frade


% initializations
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % reassign settings passed in varargin
[~, frameNumWisk] = min(abs(frameTimeStampsWisk - frameTimeStamps(frameNumRun)));
frameWisk = rgb2gray(read(vidWisk, frameNumWisk));
frameRun = rgb2gray(read(vidRun, frameNumRun));

% find wisk cam alignment if not provided
if isempty(s.yWiskPos) || isempty(s.xWiskPos) || isempty(s.wiskScaling)
    [s.yWiskPos, s.xWiskPos, s.wiskScaling] = getSubFramePosition(frameRun(1:round(size(frameRun,1)/2),:), frameWisk(:,:), .35:.005:.45);  % only use top half of frame run (assuming bottom half corresponds to bottom view)
end
yWiskPos = s.yWiskPos;
xWiskPos = s.xWiskPos;
wiskScaling = s.wiskScaling;

if s.edgeFading>0
    fade = repmat([linspace(0,1,s.edgeFading) ones(1,vidRun.Width-2*s.edgeFading) linspace(1,0,s.edgeFading)], vidRun.Height, 1);
    frameRun = uint8(double(frameRun) .* fade);
end

frameRun = imadjust(frameRun, s.runContrast, [0 1]);




% adjust wisk frame
frameWisk = imresize(frameWisk, s.wiskScaling);
frameWisk = imadjust(frameWisk, s.wiskContrast, [0 1]);
frameWisk = 255 - frameWisk;

% add border to frame
frameWisk([1:s.border, end-s.border:end], :) = 255;
frameWisk(:, [1:s.border, end-s.border:end]) = 255;

% add to run frame

% todo: currently assumes whisker frames is not HIGHER than run frame, and
% crops the top of whisker frame otherwise... there must be a nicer way of
% handling this...
rightPadding = (xWiskPos+size(frameWisk,2)) - size(frameRun, 2) - 1;  % how much to add to right of frame
frame = cat(2, frameRun, ones(size(frameRun,1), rightPadding)*255 * s.isPaddingWhite);

% crop top of wisk frame if it is too high
if yWiskPos<1
    frameWisk = frameWisk((-yWiskPos+2):end,:,:);
    yWiskPosTemp = 1;
else
    yWiskPosTemp = yWiskPos;
end

xInds = xWiskPos:xWiskPos+size(frameWisk,2)-1;
yInds = yWiskPosTemp:yWiskPosTemp+size(frameWisk,1)-1;
frame(yInds, xInds) =  frameWisk;

<<<<<<< HEAD
=======

>>>>>>> 403084717706e379fe39f1524671ab0c3297bcb6
