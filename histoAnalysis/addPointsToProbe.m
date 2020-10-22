function [BS_crossPoint, PC_crossPoint, goodChannelPoint, GCUnitInds] = addPointsToProbe(session, LM, BSCoords, shankNum, opts)


if ~exist('shankNum', 'var'); shankNum = 1; end

% settings
s.showPCPoints = true;
s.showGCPoints = true;
s.noDiIMode = false;

% reassign settings contained in opts
if exist('opts', 'var'); for i = 1:2:length(opts); s.(opts{i}) = opts{i+1}; end; end
if strcmp(session, '000000_000'); s.showGCPoints = false; end

% initialization
PC_crossPoint = []; 
goodChannelPoint = [];
GCUnitInds = [];


% ------------- strat processing -----------------------------------------
disp(['processing ' session ', shank = ' num2str(shankNum)]);

% get probe mapping file
ephysHistoInfo = getEphysSessionHistoInfo(session);

% load ephysChannelsInfo spreadsheet
warning('off')
ephysChannelsInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysChannelsInfo.xlsx'), 'Sheet', 'EphysChannelsInfo');
warning('on')

probeName = char(unique(ephysChannelsInfo.probeName(strcmp(session, ephysChannelsInfo.session))))

% automatically figure out offset if users didn't assign any values for it
if any(ephysChannelsInfo.Offset(strcmp(session, ephysChannelsInfo.session)& ephysChannelsInfo.PCShankNum == shankNum)) & (~exist('offset', 'var'))
    offset = unique(ephysChannelsInfo.Offset(strcmp(session, ephysChannelsInfo.session) & ephysChannelsInfo.PCShankNum == shankNum));
    disp(['offset = ', num2str(offset)]);
    if length(offset) ~= 1
        warning('Multiple offsets detected for the same probe trace! Offset will be temporarily set to 0!')
        offset = 0;
    end
    
elseif any(ephysChannelsInfo.Offset(strcmp(session, ephysChannelsInfo.session))) & ~any(strcmp(session, ephysChannelsInfo.session)& ephysChannelsInfo.PCShankNum == shankNum)
    offset = unique(ephysChannelsInfo.Offset(strcmp(session, ephysChannelsInfo.session)));
    disp(['offset = ', num2str(offset)]);    
    
else
    offset = 0;
    disp('set offset = 0');
end



disp('adding points...');
% ----------------------- plot brain surface cross point ------------------
if ~s.noDiIMode
    
    % the code below deals with the reconstruction of dii-coated probe traces    
    % get avg point and direction vector from the linear model
    avg = LM.avg;
    dirV = LM.dirVect;
    if dirV(1, 3) < 0
        dirV = -dirV; % make sure that the direction vector is pointing downward
    end
    
%     % (optional) plotting the avg point
%     hold on
%     plot3(avg(:, 1), avg(:, 2), avg(:, 3), '.b', 'MarkerSize', 30)
    

    % coarsely determine the location of the brain surface cross point
    MLCoord = avg(1, 1);
    BS_MLCoords = unique(BSCoords(:, 1));
    MLCoord = BS_MLCoords(knnsearch(BS_MLCoords, MLCoord), 1);
    avgDVCoord = mean(BSCoords(BSCoords(:, 1) == MLCoord, 3));
    tempDistance = (avg(1, 3) - avgDVCoord)/dirV(1, 3); % a hacky way of moving the avg point to where near the brain surface
    if tempDistance > 0; tempDistance = -tempDistance; end
    tempBS_crossPoint = avg + dirV * tempDistance;
    
%     % (optional) plot the tempBS_crossPoint, just for quality checking
%     hold on
%     plot3(tempBS_crossPoint(:, 1), tempBS_crossPoint(:, 2), tempBS_crossPoint(:, 3), '.k', 'MarkerSize', 30)
%     points = [tempBS_crossPoint ; avg];
%     plot3(points(:,1),points(:,2),points(:,3),'-g','LineWidth',3)
%     
    
    % fine tune the DV coordinates for the brain surface cross point by
    % using the info from only the adjacent brain sections
    APCoord = tempBS_crossPoint(1, 2);
    if APCoord < 0;
        adjacentAPCoord = min(BSCoords(:, 2));
    else
        adjacentAPCoord = [BSCoords(find(BSCoords(:, 2) < APCoord, 1, 'last'), 2), BSCoords(find(BSCoords(:, 2) > APCoord, 1, 'first'), 2)];
    end
    
    MLCoord =  tempBS_crossPoint(1, 1);
    MLCoord = BSCoords(find(BSCoords(:, 1) > round(MLCoord), 1));
   
    % dealing with the situation if there is only one adjacent brain section (most anterior or posterior)
    if length(adjacentAPCoord) == 1 
        DVCoords = BSCoords((BSCoords(: , 1) == MLCoord) & (BSCoords(:, 2) == adjacentAPCoord), 3);
    else
        DVCoords1 = BSCoords((BSCoords(: , 1) == MLCoord) & (BSCoords(:, 2) == adjacentAPCoord(1)), 3);
        DVCoords2 = BSCoords((BSCoords(:, 1) == MLCoord) & (BSCoords(:, 2) == adjacentAPCoord(2)), 3);
        DVCoords = cat(1, DVCoords1, DVCoords2);
    end
    
    DVCoord = mean(DVCoords);
    BS_distance = (avg(1, 3) - DVCoord)/dirV(1, 3);
    if BS_distance > 0; BS_distance = -BS_distance; end
    BS_crossPoint = avg + dirV * BS_distance;
    clear DVCoords MLCoord
    
    if length(adjacentAPCoord) ~= 1
        APCoord = BS_crossPoint(1, 2);
        adjacentAPCoord = [BSCoords(find(BSCoords(:, 2) < APCoord, 1, 'last'), 2), BSCoords(find(BSCoords(:, 2) > APCoord, 1, 'first'), 2)];
        weights = [abs(APCoord - adjacentAPCoord(1))/abs(diff(adjacentAPCoord)), abs(APCoord - adjacentAPCoord(2))/abs(diff(adjacentAPCoord)) ];
        DVCoord = mean(DVCoords1)*weights(2) + mean(DVCoords2)*weights(1);
        BS_distance = (avg(1, 3) - DVCoord)/dirV(1, 3);
        if BS_distance > 0; BS_distance = -BS_distance; end
        BS_crossPoint = avg + dirV * BS_distance;

        clear weights APCoord DVCoord distance DVCoords1 DVCoords2 DVCoord
    end
    
else
    
    % the code below applies for reconstructing no dii traces only
    tempBS_crossPoint = LM.BS_crossPoints;
    dirV = LM.dirV;
    if dirV(1, 3)<0; dirV = -dirV; end
    APCoord = tempBS_crossPoint(1, 2);
    adjacentAPCoord = [BSCoords(find(BSCoords(:, 2) < APCoord, 1, 'last'), 2), BSCoords(find(BSCoords(:, 2) > APCoord, 1, 'first'), 2)];
    adjacentAPCoord = double(adjacentAPCoord);
    
    MLCoord = tempBS_crossPoint(1, 1);
    MLCoord = double(BSCoords(find(BSCoords(:, 1) > round(MLCoord), 1)));
    
    DVCoords1 = double(BSCoords((BSCoords(:, 1) == MLCoord) & (BSCoords(:, 2) == adjacentAPCoord(1)), 3));
    DVCoords2 = double(BSCoords((BSCoords(:, 1) == MLCoord) & (BSCoords(:, 2) == adjacentAPCoord(2)), 3));
    weights = [abs(APCoord - adjacentAPCoord(1))/abs(diff(adjacentAPCoord)), abs(APCoord - adjacentAPCoord(2))/abs(diff(adjacentAPCoord)) ];
    DVCoord = mean(DVCoords1)*weights(2) + mean(DVCoords2)*weights(1);
    
    BS_crossPoint = [tempBS_crossPoint(1, :), DVCoord];
    BS_crossPoint = double(BS_crossPoint);
    BS_distance = 2000;
    fakePoints = BS_crossPoint + dirV * BS_distance;
end

% plot brain surface cross point

if ~s.noDiIMode
    plot3(BS_crossPoint(:, 1), BS_crossPoint(:, 2), BS_crossPoint(:, 3), '.k', 'MarkerSize', 30);
    points = [BS_crossPoint ; avg]; 
    plot3(points(:,1), points(:,2), points(:,3),'-g','LineWidth',3);
    text(BS_crossPoint(1,1), BS_crossPoint(1,2), BS_crossPoint(1,3)-20, probeName,'FontSize',15);
else
    plot3(BS_crossPoint(:, 1), BS_crossPoint(:, 2), BS_crossPoint(:, 3), '.', 'Color',[0.4940 0.1840 0.5560], 'MarkerSize', 30);
    points = [BS_crossPoint ; fakePoints]; 
    plot3(points(:,1), points(:,2), points(:,3),'-y','LineWidth',3);
    text(BS_crossPoint(1,1), BS_crossPoint(1,2), BS_crossPoint(1,3)-20, probeName, 'FontSize', 12);
end


if strcmp(session, '000000_000')
    return
end


% ------------------ plot PC layer cross points ---------------------------
if s.showPCPoints
    
    % get PC channel info of the recording session
    PCShankNum =  ephysChannelsInfo.PCShankNum(strcmp(session, ephysChannelsInfo.session));
    PCProbeDepth = ephysChannelsInfo.PCProbeDepth(strcmp(session, ephysChannelsInfo.session));
    PCChannels = ephysChannelsInfo.PCChannels(strcmp(session, ephysChannelsInfo.session));
    
    PCShankNum = PCShankNum(~isnan(PCShankNum));
    PCProbeDepth = PCProbeDepth(~isnan(PCProbeDepth)); % probeDepth: the manipulator readings at where I see PC signals, indicating the most ventral point of the probe
    PCChannels = PCChannels(~isnan(PCChannels));
    
    PCDepth = PCProbeDepth - [ephysHistoInfo.channelDepth(PCChannels)]'; % PCDepth: the actual depth of the channels on which I see PC signals
    
    PC_inds = find(PCShankNum == shankNum);
    PCChannels = PCChannels(PC_inds);
    PCDepth = PCDepth(PC_inds);
     
    PC_crossPoint = nan(length(PCDepth), 3);
    if dirV(1, 3) < 0; dirV = -dirV; end
    for i = 1:length(PCDepth)
        PC_crossPoint(i, :) = (PCDepth(i) + offset).*dirV + BS_crossPoint;
        hold on
        plot3(PC_crossPoint(i, 1), PC_crossPoint(i, 2), PC_crossPoint(i, 3), '.r', 'MarkerSize', 30)   
        points = [PC_crossPoint(i, :); BS_crossPoint];
        if ~s.noDiIMode
            plot3(points(:,1),points(:,2),points(:,3),'-g','LineWidth',3)
            text(points(1,1)+20, points(1,2), points(1,3), num2str(PCDepth(i)+offset),'FontSize',12)
        else
            plot3(points(:,1),points(:,2),points(:,3),'-y','LineWidth',3)
            text(points(1,1)+20, points(1,2), points(1,3), num2str(PCDepth(i)+offset),'FontSize',12)
        end
    end
  
end


% ------------------- plot good channel points ----------------------------
if s.showGCPoints
    
    % get good channels info of the recording session
    load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'neuralData.mat'), 'bestChannels', 'unit_ids');
    if ~exist('bestChannels', 'var')
        disp('bestChannels not found; format ephysData again to include bestChannels...');
        formatEphysData(session);
        load(fullfile(getenv('OBSDATADIR'), 'sessions', session, 'neuralData.mat'), 'bestChannels', 'unit_ids');
    end
    GCChannels = bestChannels; clear bestChannels;
    GCShankNum = ephysHistoInfo.shankNum(GCChannels);
    GCDepth = ephysHistoInfo.probeFinalDepth * 1000 - ephysHistoInfo.channelDepth(GCChannels); % GCDepth: the actual depth of the channels on which there are good (single) unit signals after spike sorting
   
    inds = find(GCShankNum == shankNum);
    GCChannels = GCChannels(inds);
    GCUnitInds = unit_ids(inds);
    GCDepth = GCDepth(inds);

    
    goodChannelPoint = nan(length(GCDepth), 3);
    if dirV(1, 3) < 0; dirV = -dirV; end
    for i = 1:length(GCDepth)        
        goodChannelPoint(i, :) = (GCDepth(i) + offset).*dirV + BS_crossPoint;
        hold on
        plot3(goodChannelPoint(i, 1), goodChannelPoint(i, 2), goodChannelPoint(i, 3), '.c', 'Markersize', 30);
        points = [goodChannelPoint(i, :); BS_crossPoint];
        if ~s.noDiIMode
            plot3(points(:,1),points(:,2),points(:,3),'-g','LineWidth',3);
            text(points(1,1)+20, points(1,2), points(1,3),...
                ['unit ', num2str(GCUnitInds(i)), ' ', num2str(GCDepth(i)+offset)], 'FontSize',12);
        else
            plot3(points(:,1),points(:,2),points(:,3),'-y','LineWidth',3); 
            text(points(1,1)+20, points(1,2), points(1,3),...
                ['unit ', num2str(GCUnitInds(i)), ' ', num2str(GCDepth(i)+offset)], 'FontSize',12);
        end
    end    
end

disp('Done');

end