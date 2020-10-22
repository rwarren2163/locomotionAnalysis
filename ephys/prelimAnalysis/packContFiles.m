function packContFiles(sessions, varargin)

% wrapper function that calls python pack_2 script

% settings
s.pythonPath = 'C:\Anaconda3\envs\phy2\python.exe';
<<<<<<< HEAD
s.highPassFreq = 0; % 0 to skip highpass
s.referencing = 'ave';  % 'ave' 'med' or 'none'
s.verbose = true;
=======
s.highPassFreq = 0;         % 0 to skip highpass
s.referencing = 'med';      % 'ave' 'med' or 'none'
s.verbose = false;
>>>>>>> 403084717706e379fe39f1524671ab0c3297bcb6


% initializations
if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end  % parse name-value pairs
if isstr(sessions); sessions = {sessions}; end
addpath(fullfile(getenv('GITDIR'), 'analysis-tools'))


for i = 1:length(sessions)
    
    % get session data
    files = dir(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}));
    ephysFolder = files([files.isdir] & contains({files.name}, 'ephys_')).name;
    contFiles = dir(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, ephysFolder, '*.continuous'));
    contFiles = contFiles(~contains({contFiles.name}, 'AUX')); % remove AUX channels
    fileNameBase = contFiles(1).name(1:3);
    [~, ~, info] = load_open_ephys_data_faster(fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, ephysFolder, [fileNameBase '_CH1.continuous']));
    fs = info.header.sampleRate;
    
    % get channel mapping
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames')
    ephysInfo = readtable(fullfile(getenv('OBSDATADIR'), 'spreadSheets', 'ephysInfo.xlsx'), 'Sheet', 'ephysInfo');
    warning('on', 'MATLAB:table:ModifiedAndSavedVarnames')
    mapFile = ephysInfo.map{strcmp(sessions{i}, ephysInfo.session)};
    load(fullfile(getenv('OBSDATADIR'), 'ephys', 'channelMaps', 'kilosort', [mapFile '.mat']), 'connected')
    connected = [num2str(connected)]'; % string containing binary vector

    % run pack_2
    fprintf('%s: running pack_2... ', sessions{i})
    fileName = fullfile(getenv('OBSDATADIR'), 'sessions', sessions{i}, ephysFolder);
    pythonFile = fullfile(getenv('GITDIR'), 'locomotionAnalysis', 'ephys', 'prelimAnalysis', 'packContFiles.py');
    commandStr = [s.pythonPath ' ' pythonFile ' ', ...
        fileName ' ' fileNameBase ' ' num2str(fs) ' ' num2str(s.highPassFreq) ' ' s.referencing ' ' connected];

    tic; 
    if s.verbose
        system(commandStr);
    else
        [~,~] = system(commandStr);
    end
    fprintf('created .dat file in %.1f minutes\n', toc/60)
end



