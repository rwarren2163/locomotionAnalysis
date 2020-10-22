
folder = uigetdir();
files = dir(fullfile(folder, '*.tif'));

% Right Side
RightDentate = reformatTiffStack(fullfile(folder, 'DentateRight.tif'));
RightInt = reformatTiffStack(fullfile(folder, 'InterpositusRight.tif'));
RightProbe = reformatTiffStack(fullfile(folder, 'ProbeRight_1.tif'));
RightPCLayer = reformatTiffStack(fullfile(folder, 'PCLayerRight.tif'));
RightBrainSurface = reformatTiffStack(fullfile(folder, 'BrainSurfaceRight.tif'));

% Left Side
LeftInt = reformatTiffStack(fullfile(folder, 'InterpositusLeft.tif'));
LeftDentate = reformatTiffStack(fullfile(folder, 'DentateLeft.tif'));

LeftProbe_1L = reformatTiffStack(fullfile(folder, 'ProbeLeft_1_1L.tif'));
LeftProbe_1R = reformatTiffStack(fullfile(folder, 'ProbeLeft_1_1R.tif'));
LeftProbe_2 = reformatTiffStack(fullfile(folder, 'ProbeLeft_2.tif'));
LeftProbe_3 = reformatTiffStack(fullfile(folder, 'ProbeLeft_3.tif'));

LeftPCLayer = reformatTiffStack(fullfile(folder, 'PCLayerLeft.tif'));

LeftBrainSurface = reformatTiffStack(fullfile(folder, 'BrainSurfaceLeft.tif'));


%% Get xyzCoords 

RDCoords = getCoordinates(RightDentate);
RICoords = getCoordinates(RightInt);
RPCoords = getCoordinates(RightProbe);
RPCLCoords = getCoordinates(RightPCLayer);
RBSCoords = getCoordinates(RightBrainSurface);

LICoords = getCoordinates(LeftInt);
LDCoords = getCoordinates(LeftDentate);
LPCoords_1L = getCoordinates(LeftProbe_1L);
LPCoords_1R = getCoordinates(LeftProbe_1R);
LPCoords_2 = getCoordinates(LeftProbe_2);
LPCoords_3 = getCoordinates(LeftProbe_3);
LPCLCoords = getCoordinates(LeftPCLayer);
LBSCoords = getCoordinates(LeftBrainSurface);

%% Plot brain regions + probe traces

figure;
xrange = size(LeftDentate, 2);
yrange = max(LDCoords(:, 3))+60; % +60 just for visualizing purposes
% 
PlotRegions3D(LDCoords, 20, [0.3176, 0.8314, 0.9608], xrange, yrange);
% hold on;
% PlotRegions3D(LICoords, 20, [1, 0.74, 0.35], xrange, yrange);

hold on;
PlotRegions3D(LPCLCoords, 10, [0.82, 0.56, 0.97], xrange, yrange);
hold on;
PlotRegions3D(LBSCoords, 10, [0.8 0.8 0.8], xrange, yrange);

hold on;
PlotRegions3D(LPCoords_1L, 10, [1.0, 0.43, 0.54], xrange, yrange);
hold on;
PlotRegions3D(LPCoords_1R, 10, [1.0, 0.43, 0.54], xrange, yrange);
% hold on;
% PlotRegions3D(LPCoords_2, 10, [1.0, 0.43, 0.54], xrange, yrange);
% hold on;
% PlotRegions3D(LPCoords_3, 10, [1.0, 0.43, 0.54], xrange, yrange);


% PlotRegions3D(RDCoords, 20, [0.3176, 0.8314, 0.9608], xrange, yrange);
% hold on;
% PlotRegions3D(RICoords, 20, [1, 0.74, 0.35], xrange, yrange);
% hold on;
% PlotRegions3D(RPCLCoords, 10, [0.82, 0.56, 0.97], xrange, yrange);
% hold on;
% PlotRegions3D(RBSCoords, 10, [0.8 0.8 0.8], xrange, yrange);
% hold on;
% PlotRegions3D(RPCoords, 10, [1.0, 0.43, 0.54], xrange, yrange);
% 

%% fit a line for the probe 

LM_Left_1L = LinearFit(LPCoords_1L);
LM_Left_1R = LinearFit(LPCoords_1R);
LM_Left_2 = LinearFit(LPCoords_2);
LM_Left_3 = LinearFit(LPCoords_3);
LM_Right_1 = LinearFit(RPCoords);




%% Add points for Probe Left 1L

% BS crossPoint
avg = LM_Left_1L.avg;
dirV = LM_Left_1L.dirVect;
plot3(avg(:, 1), avg(:, 3), avg(:, 2), '.b', 'MarkerSize', 30)

d_BS = -171;
BS_crossPoint_left1L = (d_BS)*dirV + avg;
hold on
plot3(BS_crossPoint_left1L(:, 1), BS_crossPoint_left1L(:, 3), BS_crossPoint_left1L(:, 2), '.k', 'MarkerSize', 30)
points = [BS_crossPoint_left1L ; avg];
plot3(points(:,1),points(:,3),points(:,2),'-k','LineWidth',3) 


% PC crossPoint
PC_crossPoint = [382.5 373 127.5];
d_PC = getDistance(PC_crossPoint, LM_Left_1L.avg);
d_PC = 95;
crossPoint = (d_PC)*dirV + avg;
hold on
plot3(crossPoint(:, 1), crossPoint(:, 3), crossPoint(:, 2), '.r', 'MarkerSize', 30)


% Start Channel Point
d_startPoint = distanceConverter(140, 1, 0.3);
startPoint = (d_startPoint+d_PC)*dirV + avg;
hold on
plot3(startPoint(:, 1), startPoint(:, 3), startPoint(:, 2), '.m', 'MarkerSize', 20)


% End Channel Point
d_endPoint = distanceConverter(790, 1, 0.3);
endPoint = (d_PC + d_startPoint + d_endPoint) * dirV + avg;
hold on
points = [startPoint ; endPoint];
plot3(points(:,1),points(:,3),points(:,2),'-m','LineWidth',3) 
plot3(endPoint(:, 1), endPoint(:, 3), endPoint(:, 2), '.m', 'MarkerSize', 20)


% Good Channel Point
goodChannelNum = [63, 58, 61, 49, 47];
d_channels =  (goodChannelNum-32).*25;
d_channels = distanceConverter(d_channels, 1, 0.3);
for i = 1:length(goodChannelNum)
    channelPoint = (d_channels(i) + d_PC + d_startPoint)*dirV + avg; 
    hold on
    plot3(channelPoint(:, 1), channelPoint(:, 3), channelPoint(:, 2), '.c', 'Markersize', 30);
end


%% Add points for Probe Left 2


% BS crossPoint
avg = LM_Left_2.avg;
dirV = LM_Left_2.dirVect;
plot3(avg(:, 1), avg(:, 3), avg(:, 2), '.b', 'MarkerSize', 30)

d_BS = -117;
BS_crossPoint_left2 = (d_BS)*dirV + avg;
hold on
plot3(BS_crossPoint_left2(:, 1), BS_crossPoint_left2(:, 3), BS_crossPoint_left2(:, 2), '.k', 'MarkerSize', 30)
points = [BS_crossPoint_left2 ; avg];
plot3(points(:,1),points(:,3),points(:,2),'-k','LineWidth',3) 


% end of the probe
d_endPoint = distanceConverter(2560, 1, 0.3);
d_endPoint = d_BS + d_endPoint; % reference to the avg point
endPoint = (d_endPoint)*dirV + avg;
plot3(endPoint(:, 1), endPoint(:, 3), endPoint(:, 2), '.m', 'MarkerSize', 20)

% start of the probe
d_startPoint = distanceConverter(790, 0.9, 0.3);
d_startPoint = d_endPoint - d_startPoint; % reference to the avg point
startPoint = (d_startPoint)*dirV + avg;
points = [startPoint; endPoint];
plot3(startPoint(:, 1), startPoint(:, 3), startPoint(:, 2), '.m', 'MarkerSize', 20)
plot3(points(:, 1), points(:, 3), points(:, 2), '-m')

% good channels
goodChannelNum = [21 22];
d_channels =  (goodChannelNum - 1).*25;
d_channels = distanceConverter(d_channels, 0.9, 0.3);
for i = 1:length(goodChannelNum)
    channelPoint = (d_channels(i) + d_startPoint)*dirV + avg; 
    hold on
    plot3(channelPoint(:, 1), channelPoint(:, 3), channelPoint(:, 2), '.c', 'Markersize', 30);
end


%% Add points for Probe Left 3



% BS crossPoint
avg = LM_Left_3.avg;
dirV = LM_Left_3.dirVect;
plot3(avg(:, 1), avg(:, 3), avg(:, 2), '.b', 'MarkerSize', 30)

d_BS = -165;
BS_crossPoint_left3 = (d_BS)*dirV + avg;
hold on
plot3(BS_crossPoint_left3(:, 1), BS_crossPoint_left3(:, 3), BS_crossPoint_left3(:, 2), '.k', 'MarkerSize', 30)
points = [BS_crossPoint_left3 ; avg];
plot3(points(:,1),points(:,3),points(:,2),'-k','LineWidth',3) 


% end of the probe
d_endPoint = distanceConverter(2732, 0.9, 0.3);
d_endPoint = d_BS + d_endPoint; % reference to the avg point
endPoint = (d_endPoint)*dirV + avg;
plot3(endPoint(:, 1), endPoint(:, 3), endPoint(:, 2), '.m', 'MarkerSize', 20)

% start of the probe
d_startPoint = distanceConverter(790, 0.9, 0.3);
d_startPoint = d_endPoint - d_startPoint; % reference to the avg point
startPoint = (d_startPoint)*dirV + avg;
points = [startPoint; endPoint];
plot3(startPoint(:, 1), startPoint(:, 3), startPoint(:, 2), '.m', 'MarkerSize', 20)
plot3(points(:, 1), points(:, 3), points(:, 2), '-m')

% good channels
goodChannelNum = [26 27];
d_channels =  (goodChannelNum - 1).*25;
d_channels = distanceConverter(d_channels, 0.9, 0.3);
for i = 1:length(goodChannelNum)
    channelPoint = (d_channels(i) + d_startPoint)*dirV + avg; 
    hold on
    plot3(channelPoint(:, 1), channelPoint(:, 3), channelPoint(:, 2), '.c', 'Markersize', 30);
end


%% Add points for Probe Right 1

% BS crossPoint
avg = LM_Right_1.avg;
dirV = LM_Right_1.dirVect;
plot3(avg(:, 1), avg(:, 3), avg(:, 2), '.b', 'MarkerSize', 30)

d_BS = -90;
BS_crossPoint_right1 = (d_BS)*dirV + avg;
hold on
plot3(BS_crossPoint_right1(:, 1), BS_crossPoint_right1(:, 3), BS_crossPoint_right1(:, 2), '.k', 'MarkerSize', 30)
points = [BS_crossPoint_right1 ; avg];
plot3(points(:,1),points(:,3),points(:,2),'-k','LineWidth',3) 



% PC crossPoint
PC_crossPoint = [1055 411 165];
d_PC = getDistance(PC_crossPoint, avg);
% d_PC = 100;
crossPoint = (d_PC)*dirV + avg;
hold on
plot3(crossPoint(:, 1), crossPoint(:, 3), crossPoint(:, 2), '.r', 'MarkerSize', 30)


% end of the probe (only for PC recording)
temp = (32 - 24)* 25;
d_diff = distanceConverter(temp, 0.9, 0.3); % unit in um
d_end = d_PC + d_diff; % reference to avg point
endPoint = d_end*dirV + avg;
plot3(endPoint(:, 1), endPoint(:, 3), endPoint(:, 2), '.m', 'MarkerSize', 20)


%% Try to get the relationship between MATLAB measured coords and modulator coords

% measured coordinates in MATLAB 3d plots
histoCoords = [BS_crossPoint_left1L; BS_crossPoint_left2; BS_crossPoint_left3; BS_crossPoint_right1];
histoCoords = [histoCoords(:, 1) histoCoords(:, 3)];


% manipulator coordinates (converted with 0.9 tissue shrinkage and 0.3
% image downsample rate)
convertedCoords = nan(4,2);
convertedCoords(1,:) = [380, 108];
convertedCoords(2,:) = [492.6, 129.6];
convertedCoords(3,:) = [503.4, 155];
convertedCoords(4,:) = [1007, 133.65];


% plot the AP and ML coordinates of probe entry point 
% compare the manipulator coords and MATLAB measured coords
figure;
plot(histoCoords(:, 1), histoCoords(:, 2), '.b', 'MarkerSize', 20);
hold on
plot(convertedCoords(:, 1), convertedCoords(:, 2), '.r', 'MarkerSize', 20);


distance = nan(4,1);

% plot a line connecting each pair (MATLAB measured and manipulator) and
% measure the distance for each pair
for i = 1:4
    
    x = [histoCoords(i, 1), convertedCoords(i, 1)];
    y = [histoCoords(i, 2), convertedCoords(i, 2)];
    hold on
    plot(x, y, '-c', 'LineWidth', 2)
    
    distance(i, 1) = sqrt((x(2) - x(1))^2 + (y(2) - y(1))^2);
    
end

legend('MATLAB Measured Coords', 'Modulator Coords')


% build a linear model between x value (ML coordinates) and distance
% between MATLAB measured coords and manipulator coords
figure;
plot(convertedCoords(:, 1), distance, '.b', 'MarkerSize', 20);
mdl = fitlm(convertedCoords(:, 1), distance)
slope = table2array(mdl.Coefficients(2, 1));
intercept = table2array(mdl.Coefficients(1,1));
fitted = convertedCoords(:, 1).*slope + intercept;
hold on
plot(histoCoords(:, 1), fitted, '-m', 'LineWidth', 2);


% calculate the distance along the direction vector based on the x value (ML axis),
% for probe trails without DiI
convertedCoordsFake = [916.5 108; 943.5 108; 998.85 122.85; 1032.6 122.85];
hold on
plot(convertedCoordsFake(:, 1), convertedCoordsFake(:, 2), '.', 'Color', [1, 0.43, 0.55], 'MarkerSize', 20);



distance_rightFake1L = convertedCoordsFake(1, 1)*slope + intercept;
distance_rightFake1R = convertedCoordsFake(2, 1)*slope + intercept;
distance_rightFake2L = convertedCoordsFake(3, 1)*slope + intercept;
distance_rightFake2R = convertedCoordsFake(4, 1)*slope + intercept;


% get direction vector for each pair (converted pointing to original) and
% calculate a mean direction vector
diff = histoCoords - convertedCoords;
dirV = diff./distance;
avg_dirV = mean(dirV, 1);

%
histoCoordsFake = nan(4, 2);
histoCoordsFake(1, :) = convertedCoordsFake(1, :) + dirV(4, :) * distance_rightFake1L;
histoCoordsFake(2, :) = convertedCoordsFake(2, :) + dirV(4, :) * distance_rightFake1R;
histoCoordsFake(3, :) = convertedCoordsFake(3, :) + dirV(4, :) * distance_rightFake2L;
histoCoordsFake(4, :) = convertedCoordsFake(4, :) + dirV(4, :) * distance_rightFake2R;


hold on
plot(histoCoordsFake(:, 1), histoCoordsFake(:, 2), '.', 'Color', [0.49, 0.84, 0.97], 'MarkerSize', 20)

for i = 1:4
    
    x = [histoCoordsFake(i, 1) convertedCoordsFake(i, 1)];
    y = [histoCoordsFake(i, 2) convertedCoordsFake(i, 2)];
    hold on
    plot(x, y, '-', 'Color', [1 0.74, 0.35], 'LineWidth', 2);
    
    
end



%% play with linear models (keep 3, test the last 1)

histoCoords = [BS_crossPoint_left1L; BS_crossPoint_left2; BS_crossPoint_left3; BS_crossPoint_right1];
histoCoords = [histoCoords(:, 1) histoCoords(:, 3)];


% manipulator coordinates (converted with 0.9 tissue shrinkage and 0.3
% image downsample rate)
convertedCoords = nan(4,2);
convertedCoords(1,:) = [380, 108];
convertedCoords(2,:) = [492.6, 129.6];
convertedCoords(3,:) = [503.4, 155];
convertedCoords(4,:) = [1007, 133.65];


distance = nan(4,1);
for i = 1:4
    x = [histoCoords(i, 1), convertedCoords(i, 1)];
    y = [histoCoords(i, 2), convertedCoords(i, 2)];
    distance(i, 1) = sqrt((x(2) - x(1))^2 + (y(2) - y(1))^2);
end


% build a linear model between x value (ML coordinates) and distance
% between MATLAB measured coords and manipulator coords
figure;
plot(convertedCoords(:, 1), distance, '.b', 'MarkerSize', 20);
mdl = fitlm(convertedCoords(:, 1), distance)
slope = table2array(mdl.Coefficients(2, 1));
intercept = table2array(mdl.Coefficients(1,1));
fitted = convertedCoords(:, 1).*slope + intercept;
hold on
plot(histoCoords(:, 1), fitted, '-m', 'LineWidth', 2);


i = 4;

figure;
plot(convertedCoords(i, 1), convertedCoords(i, 2), '.r', 'MarkerSize', 20);
xlim([300, 1100]);
ylim([100, 200])
tempConverted = convertedCoords;
tempDistance = distance;
tempHisto = histoCoords;
tempConverted(i, :) = [];
tempDistance(i, :) = [];
tempHisto(i, :) = [];
hold on
plot(tempConverted(:, 1), tempConverted(:, 2), '.b', 'MarkerSize', 20);
hold on
plot(histoCoords(:, 1), histoCoords(:, 2), '.', 'MarkerSize', 20, 'Color', [0.49, 0.84, 0.97]);

for i = 1:3
    x = [tempHisto(i, 1), tempConverted(i, 1)];
    y = [tempHisto(i, 2), tempConverted(i, 2)];
    hold on
    plot(x, y, '-c', 'LineWidth', 2)
end


i = 4;
mdl = fitlm(tempConverted(:, 1), tempDistance);
slope = table2array(mdl.Coefficients(2, 1));
intercept = table2array(mdl.Coefficients(1,1));
fittedPointDistance = convertedCoords(i, 1) * slope + intercept;


diff = histoCoords - convertedCoords;
dirV = diff./distance;
avg_dirV = mean(dirV, 1);

tempDir = mean(dirV(2:3, :));
fittedPoint = convertedCoords(i, :) + fittedPointDistance*tempDir;
hold on
plot(fittedPoint(1), fittedPoint(2), '.', 'MarkerSize', 20, 'Color', [0.84 0.55 0.73]);












%% create fake probe traces for no dii trails

figure;
xrange = size(LeftDentate, 2);
yrange = max(LDCoords(:, 3))+60; % +60 just for visualizing purposes
% 
PlotRegions3D(LDCoords, 20, [0.3176, 0.8314, 0.9608], xrange, yrange);
hold on;
PlotRegions3D(LICoords, 20, [1, 0.74, 0.35], xrange, yrange);

hold on;
PlotRegions3D(LPCLCoords, 10, [0.82, 0.56, 0.97], xrange, yrange);
hold on;
PlotRegions3D(LBSCoords, 10, [0.8 0.8 0.8], xrange, yrange);

hold on;
PlotRegions3D(LPCoords_1L, 10, [1.0, 0.43, 0.54], xrange, yrange);
hold on;
PlotRegions3D(LPCoords_1R, 10, [1.0, 0.43, 0.54], xrange, yrange);
hold on;
PlotRegions3D(LPCoords_2, 10, [1.0, 0.43, 0.54], xrange, yrange);
hold on;
PlotRegions3D(LPCoords_3, 10, [1.0, 0.43, 0.54], xrange, yrange);


PlotRegions3D(RDCoords, 20, [0.3176, 0.8314, 0.9608], xrange, yrange);
hold on;
PlotRegions3D(RICoords, 20, [1, 0.74, 0.35], xrange, yrange);
hold on;
PlotRegions3D(RPCLCoords, 10, [0.82, 0.56, 0.97], xrange, yrange);
hold on;
PlotRegions3D(RBSCoords, 10, [0.8 0.8 0.8], xrange, yrange);
hold on;
PlotRegions3D(RPCoords, 10, [1.0, 0.43, 0.54], xrange, yrange);



%% running plotting function on GPU

fn = fieldnames(brain);
for k=1:numel(fn)
    if( isnumeric(brain.(fn{k})) )
        brain.(fn{k}) = uint32(brain.(fn{k}));
        
    end
end












