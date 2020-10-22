function [tiffStack, xyzCoords] = importTiffStack_2(fileName, varargin)
% quickly load tiff stack for a single channel into an (imageNum X height X width matrix)

% code inspired by: https://www.mathworks.com/matlabcentral/answers/105739-how-to-show-tiff-stacks

% settings
s.scaling = 1;         % shrink images by setting < 1
s.dataType = 'uint8';  % images are rescaled to fit this target bit depth // set to 'logical' to binarize images
s.normalize = .999;    % rescales such that values of normalize*max(imgs-min(imgs)) are set to the highest value // set to false to avoid normalization
s.resolution = 2;      % 2 um per pixel (standard resolution after BrainJ) 
s.thickness = 50;      % section thickness

% initializations
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % reassign settings passed in varargin
warning('off', 'imageio:tiffmexutils:libtiffWarning') % Suppress all the tiff warnings
tiffObj  = Tiff(fileName);
metadata = imfinfo(fileName);
imgNum = length(metadata);
wid = metadata(1).Width;
hgt = metadata(1).Height;
bitDepth = double(metadata(1).BitsPerSample(1));  % bit depth for original image


% collect images
fprintf('loading %s with %.2f scaling, image number: 1 ', fileName, s.scaling)
temp = imresize(zeros(hgt, wid), s.scaling);  % for getting the size of scaled images
tiffStack = cast(zeros(imgNum, size(temp,1), size(temp,2)), s.dataType);
for i = 1:imgNum
    img = readImg();
    fprintf('%i ', i)
    tiffStack(i,:,:) = img(:,:,1);
end
fprintf('all done!\n')
warning('on', 'imageio:tiffmexutils:libtiffWarning')


% normalize
if s.normalize && ~strcmp(s.dataType, 'logical')
    tiffStack = tiffStack - min(tiffStack);
    clipVal = prctile(tiffStack(:), s.normalize*100);
    tiffStack(tiffStack>clipVal) = clipVal;
    tiffStack = tiffStack * (255 / double(max(tiffStack(:))));
end


% get the xyz coordinates (columns are ML, AP, DV) 
inds = find(tiffStack>0);
tiffStackSize = size(tiffStack);
[AP, DV, ML] = ind2sub(tiffStackSize, inds);
xyzCoords = [ML*s.resolution/s.scaling, AP*s.thickness, DV*s.resolution/s.scaling]; % covert pixel location into xyz coordinates (unit in microns)



% read next image from stack
function img = readImg()
    img = read(tiffObj);
    if strcmp(s.dataType, 'logical')
        img = img>0;
    else
        img = double(img) * (double(intmax(s.dataType)) / (2^bitDepth-1));  % rescale to new bit depth
        img = cast(img, s.dataType);
    end
    if s.scaling~=1; img = imresize(img, s.scaling); end
    if currentDirectory(tiffObj)<imgNum; tiffObj.nextDirectory(); end
end


end