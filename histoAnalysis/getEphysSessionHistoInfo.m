function [ephysHistoInfo] = getEphysSessionHistoInfo(session)

% Generate ephysHistoInfo structure of each session, for the convenience of subsequent histo analyses

warning('off')
ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo'); 
warning('on')

% get general session info
ephysHistoInfo.session = session;
ephysHistoInfo.mouseID = ephysInfo.mouse{strcmp(ephysInfo.session, session)};
ephysHistoInfo.probeFinalDepth = ephysInfo.depth(strcmp(ephysInfo.session, session));
ephysHistoInfo.mapFile = ephysInfo.map{strcmp(ephysInfo.session, session)};
ephysHistoInfo.mapFilePath = fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', [ephysHistoInfo.mapFile, '.mat']);

% get probe info of the session
load(ephysHistoInfo.mapFilePath);
ephysHistoInfo.channelNum_openEphys = channelNum_OpenEphys;
ephysHistoInfo.channelNum = length(channelNum_OpenEphys(connected));
ephysHistoInfo.shankNum = nan(1, length(ephysHistoInfo.channelNum));
ephysHistoInfo.channelDepth = nan(1, length(ephysHistoInfo.channelNum));
for i = 1:ephysHistoInfo.channelNum
    ephysHistoInfo.shankNum(1, i) = kcoords(channelNum_OpenEphys(i)); % channel number order matches probe physcial layout
    ephysHistoInfo.channelDepth(1, i) = ycoords(channelNum_OpenEphys(i)); % channel number order matches probe physical layout
end

end

