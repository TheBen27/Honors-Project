%% Closeup
% Looks at a small slice of animal data in accelerometry, FFT, and
% peaking terms, among other things.
%% Configuration

% Name of the slice from SLICES.MAT
slice_name = 'rturn-only';

% Turning these off might result in faster processing.
plot_raw_accel = true;
plot_psds = true;
plot_spectrograms = false; % Won't work on smaller segments
plot_orientation = true;

if (~(plot_raw_accel || plot_psds || plot_spectrograms || plot_orientation))
    error(['Script is configured to not plot anything. ' ...
           'Go to closeup.m''s configuration section to change this']);
end

% Sample rate of the input data. It should really stay on 25 unless you're
% using another tag.
sample_rate = 25;

% Plot the positions of each window given some size and overlap.
% Green lines mark the beginning of a window, red lines the end
plot_windows = false;
window_size = 26;
window_overlap = 12;

% Highpass and lowpass filter controls (for raw accel only)
accel_filter = false;
if accel_filter
   accel_lowpass  = butter(2, (24 / 25), 'low');
   accel_highpass = butter(2, (1 / 25), 'high'); 
end

% Precision of the PSD and the spectrograms. For spectrograms, this
% controls the vertical precision; higher values take more CPu.
psd_nfft = 57;

% Essentially the horizontal precision of the spectrogram. Too high and
% you'll lose detail; too low and you'll start getting weird artifacts.
% sample_rate is, I think, a good minimum.
spectral_window = sample_rate * 3;

% Controls the maximum frequency plotted in the PSDs.
psd_maxFreq = 2.0;

%% Loading and Preprocessing
[accel, times, label_times, label_names] = load_accel_slice(slice_name);
if plot_windows
    [~, ~, ~, window_names] = load_accel_slice_windowed(slice_name, window_size, window_overlap);
else
    window_names = categorical([]);
end

% Get windows
if plot_windows
    num_windows = floor((length(accel) - window_overlap) / ...
        (window_overlap + window_size));
    windows = 1:num_windows;
    window_starts_is = (windows - 1) * (window_overlap + window_size) + 1;
    window_ends_is = window_starts_is + (window_size + window_overlap * 2) - 1;

    start_time = times(1);
    window_starts = start_time + seconds(window_starts_is / sample_rate);
    window_ends = start_time + seconds(window_ends_is / sample_rate);
else
    window_starts = []
    window_ends = []
end

%% Plotting Raw Acceleration
if plot_raw_accel
    % Filter data
    if accel_filter
      accel_filtered = filter(accel_lowpass(1), accel_lowpass(2), ...
            filter(accel_highpass(1), accel_highpass(2), accel));
    else
      accel_filtered = accel;
    end
    % Individual subplots
    raw_xlims = [times(1), times(end)]; 
    raw_ylims = [-1.3, 1.3];
    subplot(3,1,1);
    plot(times,accel_filtered(:,1));
    title('X Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, cellstr(window_names), 'Green');
    plot_labels(window_ends, {}, 'Red');
    
    subplot(3,1,2);
    plot(times,accel_filtered(:,2));
    title('Y Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, {}, 'Green');
    plot_labels(window_ends, {}, 'Red');

    subplot(3,1,3);
    plot(times,accel_filtered(:,3));
    title('Z Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, {}, 'Green');
    plot_labels(window_ends, {}, 'Red');
end

% Subtract mean to remove DC offset and center signal
% TODO Figure out if that idea is at all sensible
accel_high = accel - repmat(mean(accel),size(accel,1),1);


%% Get Power Spectral Distributions
if plot_psds
    sample_rate = 25;
    accel_fft = fftshift(fft(accel_high, psd_nfft, 1));
    accel_power = accel_fft .* conj(accel_fft) / (psd_nfft * size(accel,1));

    f = sample_rate * (-psd_nfft/2:psd_nfft/2-1)/psd_nfft;

    % Remove all negative frequencies
    neg_fs = f < 0;
    f(neg_fs) = [];
    accel_fft(neg_fs,:) = [];
    accel_power(neg_fs,:) = [];

    figure;
    psd_axes = [0, psd_maxFreq, 0, max(max(accel_power))];
    psd_labels = {'X','Y','Z'};
    for i=1:3
        subplot(3, 1, i);
        plot(f,accel_power(:,i));
        title(['Power Spectral Distribution (', psd_labels{i}, ')']);
        xlabel('Frequency (Hz)');
        ylabel('Power (???)');
        axis(psd_axes);
    end
end

%% Plotting Spectrograms
if plot_spectrograms
   figure;
    spectrogram(accel_high(:,1), spectral_window, sample_rate, ... 
        psd_nfft, sample_rate, 'yaxis');
    title('Spectrogram (X Axis)');

    figure;
    spectrogram(accel_high(:,2), spectral_window, sample_rate, ... 
        psd_nfft, sample_rate, 'yaxis');
    title('Spectrogram (Y Axis)');

    figure;
    spectrogram(accel_high(:,3), spectral_window, sample_rate, ... 
        psd_nfft, sample_rate, 'yaxis');
    title('Spectrogram (Z Axis)'); 
end


%% Plot pitch and roll
if plot_orientation
    [low_b, low_a] = butter(3, 15 / sample_rate);
    static_accel = filter(low_b, low_a, accel, [], 1);
    dynamic_accel = accel - static_accel;

    low_x = static_accel(:, 1);
    low_y = static_accel(:, 2);
    low_z = static_accel(:, 3);
    mean_x = mean(accel(:,1));

    all_pitches = asin(low_x - mean_x) * (180 / pi);
    all_rolls = atan(-low_z / low_y) * (180 / pi);
    
    % We need to expand rolls to avoid wraparound problems?
    
    figure;
    raw_xlims = [times(1), times(end)]; 
    raw_ylims = [-180, 180];
    subplot(2,1,1);
    plot(times, all_pitches);
    title('Pitch');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("Pitch (Degrees)");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, cellstr(window_names), 'Green');
    plot_labels(window_ends, {}, 'Red');
    
    subplot(2,1,2);
    plot(times, all_rolls);
    title('Roll');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("Roll (Degrees)");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, cellstr(window_names), 'Green');
    plot_labels(window_ends, {}, 'Red');
end