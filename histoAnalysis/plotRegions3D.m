function plotRegions3D(xyzCoords, varargin)

% This function is to plot the 3-dimension logical matrix (created by
% reformatTiffStack function and getCoordinates function) in 3-d space.

% INPUT: 

% settings
s.markerSize = 10;            
s.color = [1 0.42 0.53];      
s.xrange = [];
s.yrange = [];
s.transparency = .2;

s.selected = [false, false, false];
s.selectedInds = [1, size(xyzCoords, 1)];

if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % reassign settings passed in varargin
hold on; 

if ~any(s.selected)
    h = scatter3(xyzCoords(:, 1), xyzCoords(:, 2), xyzCoords(:, 3), s.markerSize, s.color, 'filled');
else
    temp = find(s.selected);
    inds = xyzCoords(:, temp) >= s.selectedInds(1) & xyzCoords(:, temp) <= s.selectedInds(2);
    h = scatter3(xyzCoords(inds, 1), xyzCoords(inds, 2), xyzCoords(inds, 3), s.markerSize, s.color, 'filled');
end

set(h, 'MarkerEdgeAlpha', s.transparency, 'MarkerFaceAlpha', s.transparency);

if ~isempty(s.xrange); xlim([s.xrange(1), s.xrange(2)]); end
if ~isempty(s.yrange); ylim([s.yrange(1), s.yrange(2)]); end
set( gca, 'ZDir', 'reverse' );
set(gca, 'XDir', 'normal');
set(gca, 'YDir', 'normal');
xlabel('ML axis (in micron)')
ylabel('AP axis (in micron)')
zlabel('DV axis (in micron)')

end