%% test functions for decision making plots


%% load sensory dependence data
fprintf('loading... '); load(fullfile(getenv('OBSDATADIR'), 'matlabData', 'sensoryDependence_data.mat'), 'data'); disp('sensoryDependence data loaded!')
condition = 'sensoryCondition';
levels = {'WL', 'W', 'L', '-'};

%% load muscimol data
fprintf('loading... '); load(fullfile(getenv('OBSDATADIR'), 'matlabData', 'mtc_muscimol_data.mat'), 'data'); disp('sensoryDependence data loaded!')
condition = 'condition';
levels = {'saline', 'muscimol'};

%% heatmaps

plotDecisionHeatmaps(data, 'condition', condition, 'levels', levels, ...
    'successOnly', false, 'modPawOnlySwing', false, 'lightOffOnly', false, ...
    'avgMice', true, 'plotMice', true);

%% trials scatters

plotDecisionTrials(data, 'condition', condition, 'levels', levels, ...
    'successOnly', false, 'modPawOnlySwing', true, 'lightOffOnly', false);

%% model accuracies

plotModelAccuracies(data, 'condition', condition, 'levels', levels, ...
    'successOnly', false, 'modPawOnlySwing', true, 'lightOffOnly', false);

%% decision threshold

plotDecisionThresholds(data, 'condition', condition, 'levels', levels, ...
    'successOnly', false, 'modPawOnlySwing', true, 'lightOffOnly', false);






