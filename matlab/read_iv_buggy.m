clc;
clear;
close all;

%% Improved I-V processing script
% This script reads semiconductor I-V measurement text files, cleans invalid
% values (NaN/Inf), normalizes current, performs logarithmic fitting on
% IRF3710 data, compares multiple devices, and exports publication-style
% figures.

%% Resolve data folder robustly (works from any current working directory)
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
dataDirCandidates = {
    fullfile(repoRoot, 'data'), ...                    % expected layout
    repoRoot, ...                                      % current repo layout
    fullfile(repoRoot, 'codex-iv-debug-demo'), ...     % nested layout fallback
    scriptDir ...                                      % local fallback
    };

% Locate the directory that actually contains all required files.
requiredFiles = {'irf3710.txt', 'irf2804.txt', 'bd241c.txt'};
dataDir = '';
for i = 1:numel(dataDirCandidates)
    c = dataDirCandidates{i};
    if all(cellfun(@(f) isfile(fullfile(c, f)), requiredFiles))
        dataDir = c;
        break;
    end
end
if isempty(dataDir)
    error('Data files not found. Checked: %s', strjoin(dataDirCandidates, ', '));
end

%% Load data for each device
irf3710 = loadDeviceData(fullfile(dataDir, 'irf3710.txt'));
irf2804 = loadDeviceData(fullfile(dataDir, 'irf2804.txt'));
bd241c  = loadDeviceData(fullfile(dataDir, 'bd241c.txt'));

%% Figure 1: IRF3710 logarithmic fitting result
% Choose a representative gate-bias sweep (target ~100 from header row).
[targetVgLabel, idx3710] = pickClosestBias(irf3710.biases, 100);

I3710 = irf3710.current;
V3710 = irf3710.voltage(:, idx3710);

% Keep only finite and physically valid points for log fit (I > 0).
valid = isfinite(I3710) & isfinite(V3710) & (I3710 > 0);
I3710 = I3710(valid);
V3710 = V3710(valid);

% Normalize current for numerical stability and comparability.
I3710_norm = I3710 ./ max(I3710);

% Logarithmic fitting model: V = a*log(I_norm) + b
fitObj = fit(I3710_norm, V3710, 'a*log(x)+b', 'StartPoint', [0.1, mean(V3710)]);
V3710_fit = fitObj.a .* log(I3710_norm) + fitObj.b;

fig1 = figure('Color', 'w', 'Position', [100 100 850 550]);
semilogx(I3710_norm, V3710, 'o', 'MarkerSize', 5, 'LineWidth', 1.0, ...
    'DisplayName', 'Measured IRF3710');
hold on;
semilogx(I3710_norm, V3710_fit, '-', 'LineWidth', 2.2, 'Color', [0.85 0.2 0.2], ...
    'DisplayName', sprintf('Log fit: V = %.4f log(I_n) + %.4f', fitObj.a, fitObj.b));

grid on;
box on;
xlabel('Normalized Current, I_n = I / I_{max}', 'FontSize', 11);
ylabel('Voltage (V)', 'FontSize', 11);
title(sprintf('IRF3710 Logarithmic Fitting (Bias ~ %.0f)', targetVgLabel), 'FontSize', 12);
legend('Location', 'best');
set(gca, 'FontSize', 10, 'LineWidth', 1.0);

exportgraphics(fig1, fullfile(scriptDir, 'irf3710_log_fit.png'), 'Resolution', 300);

%% Figure 2: Multi-device I-V characteristics comparison
% For fair comparison, select the bias closest to 100 for each device.
[lab3710, i3710] = pickClosestBias(irf3710.biases, 100);
[lab2804, i2804] = pickClosestBias(irf2804.biases, 100);
[lab241c, i241c] = pickClosestBias(bd241c.biases, 100);

% Clean and normalize each device's current.
[I1n, V1] = cleanAndNormalize(irf3710.current, irf3710.voltage(:, i3710));
[I2n, V2] = cleanAndNormalize(irf2804.current, irf2804.voltage(:, i2804));
[I3n, V3] = cleanAndNormalize(bd241c.current,  bd241c.voltage(:,  i241c));

fig2 = figure('Color', 'w', 'Position', [120 120 900 560]);
semilogx(I1n, V1, 'LineWidth', 2.0, 'DisplayName', sprintf('IRF3710 (bias %.0f)', lab3710));
hold on;
semilogx(I2n, V2, 'LineWidth', 2.0, 'DisplayName', sprintf('IRF2804 (bias %.0f)', lab2804));
semilogx(I3n, V3, 'LineWidth', 2.0, 'DisplayName', sprintf('BD241C (bias %.0f)',  lab241c));

grid on;
box on;
xlabel('Normalized Current, I_n = I / I_{max}', 'FontSize', 11);
ylabel('Voltage (V)', 'FontSize', 11);
title('I-V Characteristics Comparison (Semilog Current Axis)', 'FontSize', 12);
legend('Location', 'best');
set(gca, 'FontSize', 10, 'LineWidth', 1.0);

exportgraphics(fig2, fullfile(scriptDir, 'iv_device_comparison.png'), 'Resolution', 300);

fprintf('Done. Figures exported to:\n  %s\n  %s\n', ...
    fullfile(scriptDir, 'irf3710_log_fit.png'), ...
    fullfile(scriptDir, 'iv_device_comparison.png'));

%% Local helper functions
function device = loadDeviceData(filePath)
% Read first row to get bias labels; read numeric body to get I-V matrix.
rawHeader = readcell(filePath, 'FileType', 'text');
headerRow = rawHeader(1, :);
biases = nan(1, numel(headerRow)-1);
for k = 2:numel(headerRow)
    biases(k-1) = str2double(string(headerRow{k}));
end

numericData = readmatrix(filePath, 'FileType', 'text', 'NumHeaderLines', 1);
current = numericData(:, 1);
voltage = numericData(:, 2:end);

device = struct('biases', biases, 'current', current, 'voltage', voltage);
end

function [label, idx] = pickClosestBias(biasList, target)
[~, idx] = min(abs(biasList - target));
label = biasList(idx);
end

function [Inorm, Vclean] = cleanAndNormalize(I, V)
valid = isfinite(I) & isfinite(V) & (I > 0);
Iclean = I(valid);
Vclean = V(valid);
Inorm = Iclean ./ max(Iclean);
end
