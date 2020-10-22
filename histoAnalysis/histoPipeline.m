%% import tiff stack mask files
mouseID = 'cer11';
folder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'TiffStack');
files = dir(fullfile(folder, '*.tif'));

downsampleRate = 0.2;
thickness = 60;

includeDentate = true;
includeInt = true;
includeFastigial = true;
includePCL_and_BS = true;

saveFiles = true;

% brain regions
if includeInt
    disp('Reformatting Int...');
    [brainRegions.RI, brainXYZCoords.RICoords] = importTiffStack_2(fullfile(folder, 'InterpositusRight.tif'), 'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [brainRegions.LI, brainXYZCoords.LICoords] = importTiffStack_2(fullfile(folder, 'InterpositusLeft.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
end

if includeDentate
    disp('Reformatting Dentate...');
    [brainRegions.LD, brainXYZCoords.LDCoords] = importTiffStack_2(fullfile(folder, 'DentateLeft.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [brainRegions.RD, brainXYZCoords.RDCoords] = importTiffStack_2(fullfile(folder, 'DentateRight.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
end

if includeFastigial
    disp('Reformatting Fastigial...');
    [brainRegions.LF, brainXYZCoords.LFCoords] = importTiffStack_2(fullfile(folder, 'FastigialLeft.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [brainRegions.RF, brainXYZCoords.RFCoords] = importTiffStack_2(fullfile(folder, 'FastigialRight.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
end

if includePCL_and_BS
    disp('Reformatting PC Layer and Brain Surface...');
    [~, brainXYZCoords.RPCLCoords] = importTiffStack_2(fullfile(folder, 'PCLayerRight.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [~, brainXYZCoords.RBSCoords] = importTiffStack_2(fullfile(folder, 'BrainSurfaceRight.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [~, brainXYZCoords.LPCLCoords] = importTiffStack_2(fullfile(folder, 'PCLayerLeft.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
    [~, brainXYZCoords.LBSCoords] = importTiffStack_2(fullfile(folder, 'BrainSurfaceLeft.tif'),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');
end

% turn brain structure to unsigned int 32, in order to save more space, and
% potentially faster to plot.
fn = fieldnames(brainXYZCoords);
for k=1:numel(fn)
    if( isnumeric(brainXYZCoords.(fn{k})) )
        brainXYZCoords.(fn{k}) = uint32(brainXYZCoords.(fn{k}));   
    end
end


% probes
disp('Reformatting probe traces...');

probeFiles = files(contains({files.name}, 'Probe'));
probe = struct();

for i = 1:length(probeFiles)
    probe(i).name = probeFiles(i).name(1:end-4);
    [probe(i).traces, probe(i).coords] = importTiffStack_2(fullfile(folder, probeFiles(i).name),  'scaling', downsampleRate, 'thickness', thickness, 'dataType', 'logical');   
    probe(i).isDiI = 1;
    
    if contains(probe(i).name, 'ProbeLeft')
        probe(i).side = 'left';
    else
        probe(i).side = 'right';    
    end
end


resultsFolder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'Reconstruction');
if saveFiles
    save(fullfile(resultsFolder, 'brainXYZCoords.mat' ), 'brainXYZCoords');
    save(fullfile(resultsFolder, 'brainRegions.mat' ), 'brainRegions');
    save(fullfile(resultsFolder, 'probe.mat' ), 'probe');
    disp('File Saved!');
end
disp('All Done!');



%% Plot brain regions + probe traces
mouseID = 'cer11';
resultsFolder = fullfile('Z:\obstacleData\histology', mouseID, 'Reconstruction');
load(fullfile(resultsFolder, 'brainXYZCoords.mat'));
load(fullfile(resultsFolder, 'brainRegions.mat'));
load(fullfile(resultsFolder, 'probe.mat'));

%% Plot!!

figure('Color', 'white', 'position', get(0,'ScreenSize'));

plot_PC_BS = true;

sideToShow = 'both';

regionFn = fieldnames(brainRegions);
coordsFn = fieldnames(brainXYZCoords);
switch sideToShow
    case 'left'
        inds = find(contains(regionFn, 'L'));
        for i = 1:length(inds)
            plotRegions3D_2(brainRegions.(regionFn{inds(i)}), brainXYZCoords.(coordsFn{inds(i)}), 'method', 'convhull'); hold on;
        end
        
%         inds = find(strcmp({probe.side}, 'left'));
%         for i = 1:length(inds)
%             plotRegions3D_2(probe(inds(i)).traces, probe(inds(i)).coords); hold on
%         end
        
    case 'right'
        inds = find(contains(regionFn, 'R'));
        for i = 1:length(inds)
            plotRegions3D_2(brainRegions.(regionFn{inds(i)}), brainXYZCoords.(coordsFn{inds(i)}), 'method', 'convhull'); hold on;
        end   
        
%         inds = find(strcmp({probe.side}, 'right'));
%         for i = 1:length(inds)
%             plotRegions3D_2(probe(inds(i)).traces, probe(inds(i)).coords); hold on
%         end
        
    case 'both'
        for i = 1:length(regionFn)
            plotRegions3D_2(brainRegions.(regionFn{i}), brainXYZCoords.(coordsFn{i}),'method', 'convhull'); hold on;
        end
        
%         for i = 1:size(probe, 2)
%             plotRegions3D_2(probe(i).traces, probe(i).coords); hold on
%         end
end

PCL_color = [0.82, 0.56, 0.97];
BS_color = [0.8 0.8 0.8];
if plot_PC_BS
    switch sideToShow
        case 'left'
            plotRegions3D(brainXYZCoords.LPCLCoords, 'color', PCL_color, 'selected', [false, true, false], 'selectedInds', [600, 1200]);
            %  'selected', [false, true, false], 'selectedInds', [700, 1400]
            plotRegions3D(brainXYZCoords.LBSCoords, 'color', BS_color);
        case 'right'
            plotRegions3D(brainXYZCoords.RPCLCoords, 'color', PCL_color,  'selected', [false, true, false], 'selectedInds', [800, 1500]);
            plotRegions3D(brainXYZCoords.RBSCoords, 'color', BS_color);
        case 'both'
            plotRegions3D(brainXYZCoords.LPCLCoords, 'color', PCL_color,  'selected', [false, true, false], 'selectedInds', [200, 1200]);
            plotRegions3D(brainXYZCoords.LBSCoords, 'color', BS_color);
            plotRegions3D(brainXYZCoords.RPCLCoords, 'color', PCL_color,  'selected', [false, true, false], 'selectedInds', [200, 1200]);
            plotRegions3D(brainXYZCoords.RBSCoords, 'color', BS_color);
    end
end
            

title('3D Plot of Traced Brain Features');
daspect([1, 1, 1]);
grid on

%% fit a line for the probe traces


switch sideToShow
    case 'left'
        diI_inds = find([probe.isDiI] & strcmp({probe.side}, 'left'));       
    case 'right'
        diI_inds = find([probe.isDiI] & strcmp({probe.side}, 'right'));
    case 'both'
        diI_inds = find([probe.isDiI]);
end
        


for i = 1:length(diI_inds)
    probe(diI_inds(i)).LM = LinearFit(probe(diI_inds(i)).coords);
    if contains(probe(diI_inds(i)).name, 'ProbeLeft')
        probe(diI_inds(i)).side = 'left';
    else
        probe(diI_inds(i)).side = 'right';
    end
    
    switch probe(diI_inds(i)).name(end)
        case 'L'
            probe(diI_inds(i)).shankNum = 1;
        case 'R'
            probe(diI_inds(i)).shankNum = 2;
        case 'M'
            probe(diI_inds(i)).shankNum = 3;
    end
end




%% AddPoints: For probes with DiI, calculate brain surface cross points and PC layer cross points
%  For probes with DiI, add good channel points 


disp('getting sessions for the mouse...');
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo');
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')

mouse.sessions = {ephysInfo.session{strcmp(mouseID, ephysInfo.mouse) & (ephysInfo.DiI == 1)}};
mouse.DiINotes = {ephysInfo.DiINotes{strcmp(mouseID, ephysInfo.mouse) & (ephysInfo.DiI == 1)}};

% find session number associated with each probe traces
for i = 1:length(diI_inds)
    probe(diI_inds(i)).session = mouse.sessions{contains(mouse.DiINotes, probe(diI_inds(i)).name(1:end-1))}; 
end

% plot BS_crossPoints, GC_crossPoints and good channels on the 3D map
% temporarily use 
switch sideToShow
    case 'left'
        diI_inds = find([probe.isDiI] & strcmp({probe.side}, 'left'));
    case 'righ'
        diI_inds = find([probe.isDiI] & strcmp({probe.side}, 'right'));
    case 'both'
        diI_inds = find([probe.isDiI]);
end
        


for i = 1:length(diI_inds)
    
    if strcmp(probe(diI_inds(i)).side, 'left')
        [probe(diI_inds(i)).BS_crossPoints, probe(diI_inds(i)).PC_crossPoints, probe(diI_inds(i)).GC_points, probe(diI_inds(i)).GC_ids] = ...
            addPointsToProbe(probe(diI_inds(i)).session, probe(diI_inds(i)).LM, double(brainXYZCoords.LBSCoords), probe(diI_inds(i)).shankNum);
    elseif strcmp(probe(diI_inds(i)).side, 'right')
        [probe(diI_inds(i)).BS_crossPoints, probe(diI_inds(i)).PC_crossPoints, probe(diI_inds(i)).GC_points, probe(diI_inds(i)).GC_ids] = ...
            addPointsToProbe(probe(diI_inds(i)).session, probe(diI_inds(i)).LM, double(brainXYZCoords.RBSCoords), probe(diI_inds(i)).shankNum);
    end

end



%% Save the current probe files

resultsFolder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'Reconstruction');

save(fullfile(resultsFolder, 'brainXYZCoords.mat' ), 'brainXYZCoords');
save(fullfile(resultsFolder, 'brainRegions.mat' ), 'brainRegions');
save(fullfile(resultsFolder, 'probe.mat' ), 'probe');

disp('File Saved!');



%% for no dii tracks, building linear models for locating the entry points

% ------------------------- settings -------------------------------------
% HistoCoords DiI (get from probe structure)
temp = struct2table(probe(logical([probe.isDiI])));
histoPoints = table(temp.name, temp.BS_crossPoints(:, 1:2), temp.shankNum, 'VariableNames', {'HistoProbeNames', 'HistoCoords', 'shank'}); 

% ManipulatorCoords (get from ephysInfo spreadsheet)
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo');
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')

ManipuProbeNames = ephysInfo.DiINotes((strcmp(mouseID, ephysInfo.mouse)));
ManipuCoords = [ephysInfo.locationML( (strcmp(mouseID, ephysInfo.mouse))), ephysInfo.locationAP( (strcmp(mouseID, ephysInfo.mouse)))];
manipuPoints = table(ManipuProbeNames, ManipuCoords, 'VariableNames', {'ManipuProbeNames', 'ManipuCoords'});

%% Save histoPoints and manipuPoints
% Please review and modify these coordinates manually! Then SAVE IT!
saveFiles = true;
resultsFolder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'Reconstruction');
if saveFiles
    save(fullfile(resultsFolder, 'histoPoints.mat' ), 'histoPoints');
    save(fullfile(resultsFolder, 'manipuPoints.mat' ), 'manipuPoints');
end
disp('File saved!');

%% Load histoPoints and manipuPoints

resultsFolder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'Reconstruction');

load(fullfile(resultsFolder, 'histoPoints.mat'));
load(fullfile(resultsFolder, 'manipuPoints.mat'));


%%
% --------------------------- processing ----------------------------------
% plot to verify the histo info


% !!! Manul work needed before running the code below
% !!! Organize the manipuPoints first
noDiI_inds = contains(manipuPoints.ManipuProbeNames, 'noDiI');
diI_inds = contains(manipuPoints.ManipuProbeNames, 'Probe');
manipuPoints_LM = manipuPoints(diI_inds, :);
histoPoints_LM = table();
for i = 1:size(manipuPoints(diI_inds, :), 1)
    temp = manipuPoints_LM.ManipuProbeNames(i);
    histoPoints_LM(i, :) = histoPoints(strcmp(histoPoints.HistoProbeNames, temp), :);    
end



figure('Color', 'white', 'position', get(0,'ScreenSize'));
plot(manipuPoints.ManipuCoords(diI_inds, 1), manipuPoints.ManipuCoords(diI_inds, 2), '.r', 'MarkerSize', 10);
hold on
plot(manipuPoints.ManipuCoords(noDiI_inds, 1), manipuPoints.ManipuCoords(noDiI_inds, 2), '.m', 'MarkerSize', 10);
plot(histoPoints.HistoCoords(:, 1), histoPoints.HistoCoords(:, 2), '.b', 'MarkerSize', 20);


mdlML_test = fitlm(manipuPoints_LM.ManipuCoords(:, 1), histoPoints_LM.HistoCoords(:, 1))
mdlAP_test = fitlm(manipuPoints_LM.ManipuCoords(:, 2), histoPoints_LM.HistoCoords(:, 2))


fittedML_nodii = predict(mdlML_test, manipuPoints.ManipuCoords(noDiI_inds, 1));
fittedAP_nodii = predict(mdlAP_test, manipuPoints.ManipuCoords(noDiI_inds, 2));

% plot the fitted entry points for ni dii tracks
hold on
plot(fittedML_nodii, fittedAP_nodii, '.', 'MarkerSize', 20, 'Color', [1 0.74 0.35])
legend('manipulator coordinates (DiI)', 'manipulator coordinates (noDiI)', 'histo points (DiI)', 'predicted no DiI points');
xlabel('ML axis');
ylabel('AP axis');

%% for ni dii tracks, reconstructing no-dii probe traces in 3d view

dirV = nan(sum([probe.isDiI]), 3);
diI_inds = find([probe.isDiI]);
for i = 1:length(dirV)
    dirV(i, :) = probe(diI_inds(i)).LM.dirVect;
    if dirV(i, 3) < 0; dirV(i, :) = -dirV(i, :); end
end
nodiiLM.dirV = mean(dirV);

% Before running the code below, please double check that the noDiI entries
% in the manipuPoints have been splitted into the left and right traces.

noDiI_inds = find(contains(manipuPoints.ManipuProbeNames, 'noDiI'));
L = sum([probe.isDiI]);
for i = 1:length(noDiI_inds)
    tempName = char(manipuPoints.ManipuProbeNames(noDiI_inds(i)));
    probe(L+i).name = tempName;
    probe(L+i).session = ephysInfo.session{contains(ephysInfo.DiINotes, tempName(1:end-1)) & strcmp(ephysInfo.mouse, mouseID)};
    probe(L+i).side = ephysInfo.side{contains(ephysInfo.DiINotes, tempName(1:end-1))};
    probe(L+i).isDiI = 0;
    probe(L+i).coords = nan;
    probe(L+i).PC_crossPoints = [];
    probe(L+i).GC_points = [];
    
    tempLM = struct();
    tempLM.BS_crossPoints = [fittedML_nodii(i), fittedAP_nodii(i)];
    tempLM.dirV = mean(dirV);
    probe(L+i).LM = tempLM;
    
    
    switch tempName(end)
        case 'L'
            probe(L+i).shankNum = 1;
        case 'R'
            probe(L+i).shankNum = 2;
        case 'M'
            probe(L+i).shankNum = 3;
    end
    
   
end

noDiI_inds = find([probe.isDiI] == 0);
for i = 1:2
    
    if strcmp(probe(noDiI_inds(i)).side, 'right')
        [probe(noDiI_inds(i)).BS_crossPoints, probe(noDiI_inds(i)).PC_crossPoints, probe(noDiI_inds(i)).GC_points, probe(noDiI_inds(i)).GC_ids] = ...
            addPointsToProbe(probe(noDiI_inds(i)).session, probe(noDiI_inds(i)).LM, brainXYZCoords.RBSCoords, probe(noDiI_inds(i)).shankNum,...
            {'noDiIMode', true, 'showGCPoints', true});
    elseif strcmp(probe(noDiI_inds(i)).side, 'left')
         [probe(noDiI_inds(i)).BS_crossPoints, probe(noDiI_inds(i)).PC_crossPoints, probe(noDiI_inds(i)).GC_points, probe(noDiI_inds(i)).GC_ids] = ...
            addPointsToProbe(probe(noDiI_inds(i)).session, probe(noDiI_inds(i)).LM, brainXYZCoords.LBSCoords, probe(noDiI_inds(i)).shankNum,...
            {'noDiIMode', true, 'showGCPoints', true});       
    end
    
end

%% save probe.mat (final version, containing both DiI and no DiI info)
resultsFolder = fullfile(getenv('OBSDATADIR'), 'histology', mouseID, 'Reconstruction');
saveFiles = true;
if saveFiles
    save(fullfile(resultsFolder, 'probe_final.mat' ), 'probe');
end
disp('probe_final.mat saved!');


temp = struct2table(probe);

newEphysHistoTable = table();
newEphysHistoTable.session = temp.session;
newEphysHistoTable.mouseID(:) = {mouseID};
newEphysHistoTable.side = temp.side;
newEphysHistoTable.probeName = temp.name;
newEphysHistoTable.isDiI = temp.isDiI;
for i = 1:height(newEphysHistoTable)
    newEphysHistoTable.probeMap(i) = ephysInfo.map(strcmp(ephysInfo.session, temp.session(i)) &...
                                                   strcmp(ephysInfo.mouse, mouseID));
end
newEphysHistoTable.shankNum = temp.shankNum;
newEphysHistoTable.BS_crossPoints = temp.BS_crossPoints;
newEphysHistoTable.PC_crossPoints = temp.PC_crossPoints;
newEphysHistoTable.GC_Points = temp.GC_points;
newEphysHistoTable.GC_ids = temp.GC_ids;


% check to update and save ephysHistoData
fileName = fullfile(getenv('OBSDATADIR'), 'histology', '0_ephysHistoData', 'ephysHistoTable.mat');
ephysHistoFolder = fullfile(getenv('OBSDATADIR'), 'histology', '0_ephysHistoData');
if ~exist(fileName, 'file')
    ephysHistoTable = newEphysHistoTable;
    save(fileName, 'ephysHistoTable');
else
    old = load(fullfile(ephysHistoFolder, 'ephysHistoTable.mat'));
    old = old.ephysHistoTable;
    new = newEphysHistoTable;
    deleteInds = [];
    for i = 1:height(new)
        overlapInd = find(strcmp(old.session, new.session(i)) & strcmp(old.probeName, new.probeName(i)));
        if any(overlapInd) && length(overlapInd) == 1
            old(overlapInd, :) = new(i, :);
            deleteInds = [deleteInds, i];
        end
    end
    
    if any(length(deleteInds))
        new(deleteInds, :) = [];
    end
        
    if any(height(new))
        ephysHistoTable = [old; new];
    else
        ephysHistoTable = old;
    end  
    save(fileName, 'ephysHistoTable');
end

























