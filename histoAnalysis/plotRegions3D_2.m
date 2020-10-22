function plotRegions3D_2(labels, xyzCoords, varargin)


% settings
s.downSampling = 1;             % (int, >=1) downsample volumes to speed things up 
s.maxSmps = 5e6;                % if > s.maxSmps in volumes, automatically downsample to prevent crashing
s.surfArgs = {};                % args pass to trisurf function
s.apGrid = 1:size(labels,1);
s.mlGrid = 1:size(labels,3);
s.dvGrid = 1:size(labels,2);
s.method = 'boundary';          % using which function to plot the 3D structure
s.resolution = 2;
s.scaling = 0.2;
s.thickness = 50;

% inits
regionLabels = unique(labels(:));
regionLabels = regionLabels(regionLabels~=0)';
s.colors = lines(length(unique(labels(:)))-1);
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % reassign settings passed in varargin
hold on; axis equal

% check if there are too many samples\
smpNum = sum(labels(:)>0);
if smpNum > s.maxSmps
    newDownSampling = ceil(smpNum / s.maxSmps);
    if newDownSampling > s.downSampling
        s.downSampling = newDownSampling;
        fprintf('WARNING! Downsamping by %ix because too many samples detected...\n', s.downSampling);
    end
end

% downsample
if s.downSampling ~= 1
    ds = s.downSampling;
    s.apGrid = s.apGrid(1:ds:end);
    s.mlGrid = s.mlGrid(1:ds:end);
    s.dvGrid = s.dvGrid(1:ds:end);
    labels   = labels(1:ds:end, 1:ds:end, 1:ds:end);
end

for i = regionLabels
    [apInds, dvInds, mlInds] = ind2sub(size(labels), find(labels==i));
    ap = s.apGrid(apInds); ml = s.mlGrid(mlInds); dv = s.dvGrid(dvInds);
    if exist('xyzCoords', 'var')
        ml = double(xyzCoords(:, 1)');
        ap = double(xyzCoords(:, 2)');
        dv = double(xyzCoords(:, 3)');
    end
    
    if strcmp(s.method, 'boundary')
        k = boundary(ap', ml', dv');
    else
        k = convhull(ap, ml, dv, 'Simplify', true);
    end
    
    trisurf(k, ml, ap, dv, ...
        'FaceColor', s.colors(i,:), 'FaceAlpha', .4, 'EdgeColor', [.2 .2 .2], 'EdgeAlpha', .4, ...
        s.surfArgs{:});
end          

xlabel('ML'); ylabel('AP'); zlabel('DV');
set(gca, 'ZDir', 'reverse');
view(-45, 30)