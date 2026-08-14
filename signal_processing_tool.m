function signal_processing_tool

    % Create GUI window
    fig = uifigure('Name', 'Simple Signal Processing Tool', ...
                   'Position', [300 100 900 650]);


    % Title
    uilabel(fig, ...
        'Text', 'Simple Signal Processing Tool', ...
        'Position', [270 600 400 30], ...
        'FontSize', 22, ...
        'FontWeight', 'bold');


    % Frequency 1
    uilabel(fig, ...
        'Text', 'Useful Frequency (Hz):', ...
        'Position', [40 550 160 25], ...
        'FontSize', 13);

    freq1 = uieditfield(fig, 'numeric', ...
        'Position', [200 550 80 25], ...
        'Value', 5);


    % Frequency 2
    uilabel(fig, ...
        'Text', 'Noise Frequency (Hz):', ...
        'Position', [310 550 160 25], ...
        'FontSize', 13);

    freq2 = uieditfield(fig, 'numeric', ...
        'Position', [470 550 80 25], ...
        'Value', 50);


    % Noise level
    uilabel(fig, ...
        'Text', 'Noise Level:', ...
        'Position', [580 550 100 25], ...
        'FontSize', 13);

    noiseLevel = uieditfield(fig, 'numeric', ...
        'Position', [680 550 80 25], ...
        'Value', 0.3);


    % Axes
    ax1 = uiaxes(fig, ...
        'Position', [50 320 380 200]);

    title(ax1, 'Original Signal');


    ax2 = uiaxes(fig, ...
        'Position', [470 320 380 200]);

    title(ax2, 'Noisy Signal');


    % Generate button
    uibutton(fig, 'push', ...
        'Text', 'Generate Signal', ...
        'Position', [70 250 160 40], ...
        'FontSize', 13, ...
        'ButtonPushedFcn', @generateSignal);


    % Filter button
    uibutton(fig, 'push', ...
        'Text', 'Filter Noise', ...
        'Position', [260 250 160 40], ...
        'FontSize', 13, ...
        'ButtonPushedFcn', @filterSignal);


    % FFT button
    uibutton(fig, 'push', ...
        'Text', 'FFT Analysis', ...
        'Position', [450 250 160 40], ...
        'FontSize', 13, ...
        'ButtonPushedFcn', @fftAnalysis);


    % Reset button
    uibutton(fig, 'push', ...
        'Text', 'Reset', ...
        'Position', [640 250 160 40], ...
        'FontSize', 13, ...
        'ButtonPushedFcn', @resetTool);


    % Status
    status = uilabel(fig, ...
        'Text', 'Click Generate Signal to begin.', ...
        'Position', [200 190 500 30], ...
        'FontSize', 14, ...
        'HorizontalAlignment', 'center');


    % Variables
    t = [];
    cleanSignal = [];
    noisySignal = [];
    % Generate Signal
    function generateSignal(~, ~)

        % Sampling frequency
        Fs = 1000;

        % Time vector
        t = 0:1/Fs:2;

        % Read user values
        f1 = freq1.Value;
        f2 = freq2.Value;
        noise = noiseLevel.Value;

        % Generate useful signal
        cleanSignal = sin(2*pi*f1*t);

        % Generate unwanted high-frequency signal
        highFrequencyNoise = noise * sin(2*pi*f2*t);

        % Generate random noise
        randomNoise = noise * randn(size(t));

        % Create noisy signal
        noisySignal = cleanSignal + ...
                      highFrequencyNoise + ...
                      randomNoise;

        % Display clean signal
        plot(ax1, t, cleanSignal);

        xlabel(ax1, 'Time (seconds)');
        ylabel(ax1, 'Amplitude');
        title(ax1, 'Original Signal');
        grid(ax1, 'on');

        % Display noisy signal
        plot(ax2, t, noisySignal);

        xlabel(ax2, 'Time (seconds)');
        ylabel(ax2, 'Amplitude');
        title(ax2, 'Noisy Signal');
        grid(ax2, 'on');

        status.Text = 'Signal generated successfully.';

    end
    % Filter Signal
    function filterSignal(~, ~)

        if isempty(noisySignal)

            status.Text = 'Please generate a signal first.';
            return;

        end

        % Sampling frequency
        Fs = 1000;

        % Low-pass filter
        filteredSignal = lowpass(noisySignal, 10, Fs);

        % Display filtered signal
        plot(ax2, t, filteredSignal);

        xlabel(ax2, 'Time (seconds)');
        ylabel(ax2, 'Amplitude');
        title(ax2, 'Filtered Signal');
        grid(ax2, 'on');

        status.Text = 'Noise filtered successfully.';

    end
    % FFT Analysis
   
    function fftAnalysis(~, ~)

        if isempty(noisySignal)

            status.Text = 'Please generate a signal first.';
            return;

        end

        % Sampling frequency
        Fs = 1000;

        % Number of samples
        N = length(noisySignal);

        % Perform FFT
        Y = fft(noisySignal);

        % Calculate frequency vector
        f = (0:N-1)*(Fs/N);

        % Calculate magnitude
        magnitude = abs(Y)/N;

        % Create new figure
        figure;

        plot(f(1:floor(N/2)), ...
             2*magnitude(1:floor(N/2)));

        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        title('Frequency Spectrum using FFT');
        grid on;

        % Find dominant frequency
        [~, index] = max(magnitude(1:floor(N/2)));

        dominantFrequency = f(index);

        status.Text = sprintf( ...
            'Dominant frequency: %.2f Hz', ...
            dominantFrequency);

    end



    % Reset
  
    function resetTool(~, ~)

        cla(ax1);
        cla(ax2);

        title(ax1, 'Original Signal');
        title(ax2, 'Noisy Signal');

        t = [];
        cleanSignal = [];
        noisySignal = [];

        status.Text = 'Tool reset successfully.';

    end

end
