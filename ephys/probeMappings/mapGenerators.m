%% GENERATE MAPS FOR KILOSORT

% The whole point of making channel maps is to link each channel in the
% physical layout of one probe to its corresponding CH_*.continous files 
% saved by openEphys software.

% siteLocations is the xy coordinates of recording channels ordered in 
% the probe physical layout. 
% channelNum_OpenEphys reflets the mapping relationship b/w the channel 
% number ordered in the probe physical layout and the channel number 
% ordered in openEphys software. 

% In the plot of each probe map, the circles reflect the physical layout of
% channels on the probe. The number associated with each circle is the
% channel number ordered in the probe physical map, whereas the number in
% the bracket is the corresponding channel number used in the names of
% the openEphys continuous files.
% Eg: for NeuronexusA4x16-Poly2, channel 1 in the probe physical layout 
% corresponds to 107_CH42.continuous in the openEphys files.

% After figuring out the mapping relationship b/w the probe physical layout and
% corresponding channel number used in openEphys, we generate parameters
% for kilosort. 

% xcoords and ycoords are the x and y coordinates for each channel in 
% the openEphys order.  
% kcoords is the shank number for each channel in the openEphys order.
% Eg: for NeuronexusA4x16-Poly2, channel 1 (107_CH1.continuous) in the
% openEphys corresponds to channel 33 in the physical layout, so xcoords(1)
% and ycoords(1) relefts the x and y coordinates for channel 33 in the
% physical map.

% QZ, July 05, 2020.


%% NeuronexusA4x16-Poly2, intan
channelNum_OpenEphys = [42, 35, 33, 46, 54, 48, 34, 44, 52, 43, 36, 40, 50, 39, 37, 38, 57, 63, 59, 55, 41, 49, 47, 56, 45, 51, 60, 58, 62, 53, 64, 61, 1, 7, 9, 5, 15, 23, 10, 17, 13, 19, 8, 6, 11, 4, 3, 2, 29, 24, 20, 31, 18, 12, 22, 32, 21, 14, 26, 30, 25, 16, 28, 27];

% get probe physical layout
shankSeparation = 200;
siteLocations = nan(16, 2); % start with one shank, then replicate after
siteLocations(2:2:16,:) = cat(2, zeros(8,1), (0:46:46*7)'+23); % first column of leftmost shank
siteLocations(1:2:15,:) = cat(2, ones(8,1)*30, (0:46:46*7)'); % second column of leftmost shank

siteLocations = repmat(siteLocations,4,1);
siteLocations(:,1) = siteLocations(:,1) + repelem(1:4,16)'.*shankSeparation;

% plot the probe channel map
figure;
scatter(siteLocations(:,1), siteLocations(:,2))
for i = 1:size(siteLocations,1)
    text(siteLocations(i,1), siteLocations(i,2), [num2str(i) ' (' num2str(channelNum_OpenEphys(i)) ')']) 
end


% save the channel map for kilosort
Nchannels = 64; 
connected = true(Nchannels, 1); 
chanMap = 1:Nchannels; 
chanMap0ind = chanMap - 1; 

[~, sortInds] = sort(channelNum_OpenEphys);
kcoords = repelem(1:4, 16)';
kcoords = kcoords(sortInds);
xcoords = siteLocations(sortInds, 1);
ycoords = siteLocations(sortInds, 2);

fs = 30000; % sampling frequency


% probe BDFD // original mapping
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'BDFD.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs');

% probe BDFD // after right most shank broken
connected([27 16 30 14 32 12 31 24 28 25 26 21 22 18 20 29]) = false;
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'BDFD2.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs');

%% old
xcoords = nan(Nchannels, 1);
ycoords = nan(Nchannels, 1);
kcoords = nan(Nchannels, 1);

for i = 1:Nchannels
    temp = find(channelNum_OpenEphys == i);
    xcoords(i) = siteLocations(temp, 1);
    ycoords(i) = siteLocations(temp, 2);
    
    if temp <= 16
        kcoords(i, 1) = 1;
    elseif temp <= 32
        kcoords(i, 1) = 2;
    elseif temp <= 48
        kcoords(i, 1) = 3;
    else
        kcoords(i, 1) = 4;    
    end
end



%% NeuronexusA1x32Poly3, intan

channelNum_OpenEphys = [1, 17, 8, 24, 16, 2, 29, 32, 7, 26, 3, 15, 21, 19, 11, 23, 14, 12, 28, 30, 6, 18, 9, 13, 22, 25, 5, 27, 10, 4, 31, 20];

% get probe physical layout
siteLocations = nan(32, 2);
siteLocations(4:3:31, :) = cat(2, ones(10,1)*-18, fliplr(12.5 : 25 : (12.5+25*9))'); % xy values for left column
siteLocations([1 2:3:32], :) = cat(2, zeros(12,1), fliplr(0 : 25 : (25*11))'); % xy values for right column
siteLocations(3:3:30, :) = cat(2, ones(10,1)*18, fliplr(12.5 : 25 : (12.5+25*9))'); % xy values for right column

% plot the probe channel map
figure;
scatter(siteLocations(:,1), siteLocations(:,2))
for i = 1:size(siteLocations,1)
    text(siteLocations(i,1), siteLocations(i,2), [num2str(i) ' (' num2str(channelNum_OpenEphys(i)) ')']) 
end

% save the channel map for kilosort
kcoords = ones(32, 1); % dim: Nchannels * 1; 
Nchannels = 32; 
connected = true(Nchannels, 1); 
chanMap = 1:Nchannels; 
chanMap0ind = chanMap - 1; 

xcoords = nan(Nchannels, 1);
ycoords = nan(Nchannels, 1);
for i = 1:Nchannels
    temp = find(channelNum_OpenEphys == i);
    xcoords(i) = siteLocations(temp, 1);
    ycoords(i) = siteLocations(temp, 2);
end
fs = 30000; % sampling frequency

% save the probe map for probe C6CE
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'C6CE.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs');

% save the probe map for probe D55F // nine sites defective?
connected([18 28 14 9 10 2 7 15 11]) = false;
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'D55F.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs');


%% openEphys_nonlinear32_poly2_neuronexus_mapping C858
 
channelNum_OpenEphys = [8, 24, 2, 29, 7, 26, 15, 21, 11, 23, 12, 28, 6, 18, 13, 22, 5, 27, 4, 31, 10, 20, 9, 25, 14, 30, 3, 19, 16, 32, 1, 17];

% get probe physical layout
y = [775+75:-25:75];

siteLocations = nan(32, 2);
for i = 1:32
    if mod(i, 2) == 1
        siteLocations(i, 1) = 43.3;
        siteLocations(i, 2) = y(i);
    else
        siteLocations(i, 1) = 0;
        siteLocations(i, 2) = y(i);
    end
end
        
% plot the probe channel map
figure;
scatter(siteLocations(:,1), siteLocations(:,2))
for i = 1:size(siteLocations,1)
    text(siteLocations(i,1), siteLocations(i,2), [num2str(i) ' (' num2str(channelNum_OpenEphys(i)) ')']) 
end

% save the channel map for kilosort
kcoords = ones(32, 1); % dim: Nchannels * 1; 
Nchannels = 32; 
connected = true(Nchannels, 1); 
chanMap = 1:Nchannels; 
chanMap0ind = chanMap - 1; 

xcoords = nan(Nchannels, 1);
ycoords = nan(Nchannels, 1);
for i = 1:Nchannels
    temp = find(channelNum_OpenEphys == i);
    xcoords(i) = siteLocations(temp, 1);
    ycoords(i) = siteLocations(temp, 2);
end
fs = 30000; % sampling frequency

% save the probe map for ASSY77 H2 probe
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'C858.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')


%% NeuroCambridge ASSY-H2 (32 channel per shank*2)

channelNum_OpenEphys = [28 26 24 19 21 15 32 30 18 29 31 22 20 23 25 27 1 3 6 8 10 12 14 16 17 13 11 9 7 5 4 2 63 61 60 58 56 54 52 50 47 51 53 55 57 59 62 64 38 40 42 45 43 49 34 36 48 35 33 44 46 41 39 37];  


% get probe physical layout
shankSeparation = 250; % The left shank and right shank are separated by 250um.
y = [775:-25:0]'; % y coordinates for both shanks.
x = [ones(32, 1), repmat(1 + shankSeparation, 32, 1)]; % x coordinates for left shank and right shank.
sitaLocations_shank1 = [x(:, 1) y];
siteLocations_shank2 = [x(:, 2) y];
siteLocations = [sitaLocations_shank1; siteLocations_shank2]; % xy coordinates for both shanks. dim: Nchannels*Nshank

% plot the probe channel map
figure;
scatter(siteLocations(:,1), siteLocations(:,2))
for i = 1:size(siteLocations,1)
    text(siteLocations(i,1), siteLocations(i,2), [num2str(i) ' (' num2str(channelNum_OpenEphys(i)-1) ')']) 
end

% save the channel map for kilosort
kcoords = [ones(32, 1); repmat(2, 32, 1)]; % dim: Nchannels * 1; 
Nchannels = 64; 
connected = true(Nchannels, 1); 
chanMap = 1:Nchannels; 
chanMap0ind = chanMap - 1; 

xcoords = nan(Nchannels, 1);
ycoords = nan(Nchannels, 1);
for i = 1:Nchannels
    temp = find(channelNum_OpenEphys == i);
    xcoords(i) = siteLocations(temp, 1);
    ycoords(i) = siteLocations(temp, 2);
end
fs = 30000; % sampling frequency


% save the probe map for ASSY77 H2 probe
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'ASSY77_H2Probe.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')

%% NeuroCambridge ASSY-H2-QianyunVersion (32 channel per shank*2)

channelNum_OpenEphys = [38 40 42 45 43 49 34 36 48 35 33 44 46 41 39 37 63 61 60 58 56 54 52 50 47 51 53 55 57 59 62 64 1 3 6 8 10 12 14 16 17 13 11 9 7 5 4 2 28 26 24 19 21 15 32 30 18 29 31 22 20 23 25 27];  


% get probe physical layout
shankSeparation = 250; % The left shank and right shank are separated by 250um.
y = [775:-25:0]'; % y coordinates for both shanks.
x = [ones(32, 1), repmat(1 + shankSeparation, 32, 1)]; % x coordinates for left shank and right shank.
sitaLocations_shank1 = [x(:, 1) y];
siteLocations_shank2 = [x(:, 2) y];
siteLocations = [sitaLocations_shank1; siteLocations_shank2]; % xy coordinates for both shanks. dim: Nchannels*Nshank

% plot the probe channel map
figure;
scatter(siteLocations(:,1), siteLocations(:,2))
for i = 1:size(siteLocations,1)
    text(siteLocations(i,1), siteLocations(i,2), [num2str(i) ' (' num2str(channelNum_OpenEphys(i)-1) ')']) 
end

% save the channel map for kilosort
kcoords = [repmat(2, 32, 1); ones(32, 1)]; % dim: Nchannels * 1; 
Nchannels = 64; 
connected = true(Nchannels, 1); 
chanMap = 1:Nchannels; 
chanMap0ind = chanMap - 1; 

xcoords = nan(Nchannels, 1);
ycoords = nan(Nchannels, 1);
for i = 1:Nchannels
    temp = find(channelNum_OpenEphys == i);
    xcoords(i) = siteLocations(temp, 1);
    ycoords(i) = siteLocations(temp, 2);
end
fs = 30000; % sampling frequency


% save the probe map for ASSY77 H2 probe
save(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', 'ASSY77_H2Probe_QZ.mat'), ...
    'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')


% % save the probe map for ASSY77 H2 probe
% save(fullfile('D:\DCN_project\Ephys\ASSY_KS1ConfigFile', 'ASSY77_H2.mat'), ...
%     'chanMap','channelNum_OpenEphys','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')
% 

