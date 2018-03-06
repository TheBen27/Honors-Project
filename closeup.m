%% Closeup
% Looks at a small slice of animal data in accelerometry, FFT, and
% peaking terms, among other things.
%% Configuration

% Name of the slice from SLICES.MAT
slice_name = 'rturn-2';

% Turning these off might result in faster processing.
plot_raw_accel = false;
plot_psds = false;
plot_spectrograms = false; % Won't work on smaller segments
plot_orientation = false;
plot_delta_orientation = true;

if (~(plot_raw_accel || plot_psds || plot_spectrograms || ...
        plot_orientation || plot_delta_orientation))
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
psd_maxFreq = 8.0;

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
    window_starts = [];
    window_ends = [];
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
    figure;
    labels = {'X', 'Y', 'Z'};
    for i=1:3
        subplot(3, 1, i);
        periodogram(accel(:, i), hanning(length(accel)), [], 25);
        ylim([-100, 5]);
        title(['Power Spectral Density ', labels{i}]);
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
if plot_orientation || plot_delta_orientation
    [low_b, low_a] = butter(3, 15 / sample_rate);
    static_accel = filter(low_b, low_a, accel, [], 1);
    dynamic_accel = accel - static_accel;

    low_x = static_accel(:, 1);
    low_y = static_accel(:, 2);
    low_z = static_accel(:, 3);
    mean_x = mean(accel(:,1));

    all_pitches = asin(low_x - mean_x) * (180 / pi);
    all_rolls = atan(-low_z ./ low_y) * (180 / pi);
end

if plot_orientation
    % Centered vertically with a little leeway
    extent_y = max(abs([all_pitches ; all_rolls]));
    extent_y = ceil(extent_y / 45) * 45;
    
    figure;
    raw_xlims = [times(1), times(end)]; 
    raw_ylims = [-extent_y, extent_y];
    subplot(2,1,1);
    hold on
    plot(times, all_pitches);
    title('Pitch');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("Pitch (Degrees)");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, cellstr(window_names), 'Green');
    plot_labels(window_ends, {}, 'Red');
    hold off
    
    subplot(2,1,2);
    hold on
    plot(times, all_rolls);
    title('Roll');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("Roll (Degrees)");
    plot_labels(label_times, label_names);
    plot_labels(window_starts, cellstr(window_names), 'Green');
    plot_labels(window_ends, {}, 'Red');
    hold off
end

if plot_delta_orientation
   delta_pitch = (all_pitches(2:end) - all_pitches(1:(end-1))) * sample_rate;
   delta_roll = (all_rolls(2:end) - all_rolls(1:(end-1))) * sample_rate;
   new_times = times(2:end);
   
   extent = max(abs([delta_pitch ; delta_roll]));
   extent = ceil(extent / 45) * 45;
   
   subplot(2,1,1);
   hold on
   plot(new_times, delta_pitch);
   title('Angular Velocity (Pitch)');
   ylim([-extent, extent]);
   xlabel('Time (s)');
   ylabel('Angular Velocity (°/s)');
   hold off
   
   subplot(2, 1, 2);
   hold on
   plot(new_times, delta_roll);
   title('Angular Velocity (Roll)');
   ylim([-extent, extent]);
   xlabel('Time (s)');
   ylabel('Angular Velocity (°/s)');
   hold off
end