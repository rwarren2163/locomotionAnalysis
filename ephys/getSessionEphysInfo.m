function sessionEphysInfo = getSessionEphysInfo(session)


% gets ephys folder name, base name for recording, number of channels,
% sampling frequency, number of samples, bitvols conversion factor

% get name of ephys folder
files = dir(fullfile(getenv('OBSDATADIR'), 'sessions', session));
sessionEphysInfo.ephysFolder = files([files.isdir] & contains({files.name}, 'ephys_')).name;

% get source name (e.g. 100, 107) and number of chhannels
contFiles = dir(fullfile(getenv('OBSDATADIR'), 'sessions', session, sessionEphysInfo.ephysFolder, '*.continuous'));
contFiles = contFiles(~contains({contFiles.name}, 'AUX')); % remove AUX channels
sessionEphysInfo.channelNum = length(contFiles);
sessionEphysInfo.fileNameBase = contFiles(1).name(1:3);

% get probe mapping file
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'sessions', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo');
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')
sessionEphysInfo.mapFile = ephysInfo.map{strcmp(session, ephysInfo.session)};

% get fs, microvolts conversion factor, and number of samples
addpath(fullfile(getenv('GITDIR'), 'analysis-tools'))
[~, sessionEphysInfo.timeStamps, info] = load_open_ephys_data_faster(...
    fullfile(getenv('OBSDATADIR'), 'sessions', session, sessionEphysInfo.ephysFolder, contFiles(end).name)); % for some reason taking the first contFiles failed on one session...
sessionEphysInfo.fs = info.header.sampleRate;
sessionEphysInfo.bitVolts = info.header.bitVolts;

% get number of samples
file = fullfile(getenv('OBSDATADIR'), 'sessions', session, sessionEphysInfo.ephysFolder, [sessionEphysInfo.fileNameBase '_CHs.dat']);
temp = dir(file);
sessionEphysInfo.smps = temp.bytes/2/sessionEphysInfo.channelNum; % 2 bytes per sample












