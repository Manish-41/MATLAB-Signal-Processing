clc;
clear;
close all;
% 1. LOAD ECG
recordName = '100';
[ecg, Fs, tm] = rdsamp(recordName, 1);
[ann,anntype]=rdann('100','atr');
wfdbdesc('100');
% First 10 seconds
N = 10 * Fs;
ecg = ecg(1:N);
tm = tm(1:N);
% Original ECG
figure;
plot(tm, ecg);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original ECG Signal - First 10 Seconds');
grid on;

% 2. NORMALIZE ECG
ecg_normalized = ecg - mean(ecg);
ecg_normalized = ecg_normalized / max(abs(ecg_normalized));
figure;
plot(tm, ecg_normalized);
xlabel('Time (s)');
ylabel('Amplitude');
title('Normalized ECG Signal');
grid on;

% 3. ADD NOISE
% Add white Gaussian noise
ecg_awgn = awgn(ecg_normalized, 10, 'measured');
% Add 50 Hz power-line interference
powerline = 0.2 * sin(2*pi*50*tm);
% Add baseline wander
baseline = 0.3 * sin(2*pi*0.5*tm);
% Combined noisy ECG
ecg_noisy = ecg_awgn + powerline + baseline;
figure;
plot(tm, ecg_noisy);
xlabel('Time (s)');
ylabel('Amplitude');
title('Noisy ECG Signal');
grid on;

% 4. DESIGN FILTERS
% 50 Hz Notch Filter
wo = 50 / (Fs/2);
bw = wo / 35;
[b_notch, a_notch] = iirnotch(wo, bw);
% 0.5 - 40 Hz Bandpass Filter
[b_bp, a_bp] = butter(4, [0.5 40] / (Fs/2), 'bandpass');

% 5. FILTER ECG
% Remove 50 Hz interference
ecg_notch = filtfilt(b_notch, a_notch, ecg_noisy);
% Remove unwanted frequencies
ecg_filtered = filtfilt(b_bp, a_bp, ecg_notch);

% 6. BEFORE AND AFTER FILTERING
figure;
subplot(2,1,1);
plot(tm, ecg_noisy);
xlabel('Time (s)');
ylabel('Amplitude');
title('ECG Before Filtering');
grid on;
subplot(2,1,2);
plot(tm, ecg_filtered);
xlabel('Time (s)');
ylabel('Amplitude');
title('ECG After Filtering');
grid on;

% 7. FFT ANALYSIS
L = length(ecg_noisy);
f = Fs * (0:floor(L/2)) / L;
% FFT before filtering
Y = fft(ecg_noisy);
P = abs(Y/L);
P = P(1:floor(L/2)+1);
P(2:end-1) = 2 * P(2:end-1);
% FFT after filtering
Y1 = fft(ecg_filtered);
Pf = abs(Y1/L);
Pf = Pf(1:floor(L/2)+1);
Pf(2:end-1) = 2 * Pf(2:end-1);
figure;
subplot(2,1,1);
plot(f, P);
xlim([0 100]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT Before Filtering');
grid on;
subplot(2,1,2);
plot(f, Pf);
xlim([0 100]);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('FFT After Filtering');
grid on;

% 8. R-PEAK DETECTION
% Differentiate
ecg_diff = diff(ecg_filtered);
% Square
ecg_squared = ecg_diff.^2;
% Moving-window integration
window = round(0.15 * Fs);
ecg_integrated = movmean(ecg_squared, window);
% Detect QRS peaks
threshold = 0.3 * max(ecg_integrated);
minDistance = round(0.25 * Fs);
[peak_values, qrs] = findpeaks(ecg_integrated, ...
    'MinPeakHeight', threshold, ...
    'MinPeakDistance', minDistance);
disp(peak_values);
disp(qrs);
% 9. FIND R-PEAK LOCATIONS
search = round(0.08 * Fs);
r_locations = zeros(1,length(qrs));
for k = 1:length(qrs)
    left = max(1, qrs(k) - search);
    right = min(length(ecg_filtered), qrs(k) + search);
    [~, index] = max(ecg_filtered(left:right));
    r_locations(k) =left + index - 1;
end
r_locations = unique(r_locations);
r_times = tm(r_locations);
r_peaks = ecg_filtered(r_locations);

% 10. R-PEAK DETECTION PLOT
figure;
plot(tm, ecg_filtered);
hold on;
plot(r_times, r_peaks, 'ro');
xlabel('Time (s)');
ylabel('Amplitude');
title('Filtered ECG with Detected R-Peaks');
legend('Filtered ECG', 'R-Peaks');
grid on;

% 11. HEART RATE
RR = diff(r_times);
if isempty(RR)
    average_RR = NaN;
    heartRate = NaN;
else
    average_RR = mean(RR);
    heartRate = 60 / average_RR;
end

% 12. PERFORMANCE EVALUATION
error = ecg_normalized - ecg_filtered;
% SNR
SNR = 10 * log10(sum(ecg_normalized.^2) / sum(error.^2));
% RMSE
RMSE = sqrt(mean(error.^2));
% Correlation
C = corrcoef(ecg_normalized, ecg_filtered);
correlation = C(1,2);

% 13. DISPLAY RESULTS
fprintf('       ECG PROJECT RESULTS\n');
fprintf('Sampling Frequency : %.0f Hz\n', Fs);
fprintf('Duration           : %.2f seconds\n', tm(end));
fprintf('\nR-PEAK RESULTS\n');
fprintf('Number of R-peaks  : %d\n', length(r_times));
fprintf('Average RR Interval: %.3f seconds\n', average_RR);
fprintf('Heart Rate         : %.2f BPM\n', heartRate);
fprintf('\nPERFORMANCE PARAMETERS\n');
fprintf('SNR                : %.2f dB\n', SNR);
fprintf('RMSE               : %.4f\n', RMSE);
fprintf('Correlation        : %.4f\n', correlation);
