%% get all the sessions that use the H2 probe

ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo');
allSessions = {ephysInfo.session{strcmp('ASSY77_H2Probe_HH', ephysInfo.map) & ephysInfo.include == 1}};

%% move the original cellData.csv into a new subfolder, then rename it

for i = 1:length(allSessions) 
    
    session = allSessions{i};
    sessionMainFolder = fullfile(getenv('OBSDATADIR'), 'sessions', session);
    mkdir(sessionMainFolder, 'cellDataBackup');
    copyfile([sessionMainFolder, '\cellData.csv'], [sessionMainFolder, '\cellDataBackup\cellDataCopy_', date(), '.csv']);
    
      
end

%% re-run the plotQualityMetrics function for all (include == 1) sessions that using the H2 probe 
for i = 1:length(allSessions) 
    
    session = allSessions{i};
    plotQualityMetrics(session);
    
end
