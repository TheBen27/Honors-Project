%% Closeup
% Looks at a small slice of animal data in accelerometry, FFT, and
% peaking terms, among other things.
%% Configuration

TIME_SLICES_S = [ ...
    struct( ...
        'description', '1 full constant-speed revolution around tank, no turning', ...
         'start_time', datetime(2017, 6, 15, 14, 7, 5), ...
           'end_time', datetime(2017, 6, 15, 14, 7, 26), ...
        'labels_file', '' ...
    ), ...
    struct( ...
        'description', 'Mostly constant swimming', ...
         'start_time', datetime(2017, 6, 15, 12, 44, 49), ...
           'end_time', datetime(2017, 6, 15, 14, 17, 03), ...
        'labels_file', '' ...
    ), ...
    struct( ...
        'description', 'Single clean 180-degree left turn', ...
         'start_time', datetime(2017, 6, 15, 16, 51, 26), ...
           'end_time', datetime(2017, 6, 15, 16, 51, 31), ...
        'labels_file', '' ...
    ), ...
    struct( ...
        'description', 'A lot of turning after the shark was poked', ...
         'start_time', datetime(2017, 6, 15, 15, 45, 08), ...
           'end_time', datetime(2017, 6, 15, 15, 48, 10), ...
        'labels_file', 'Labels/slice-4.csv' ...
    ) ...
];

TIME_SLICE = 4;

% Turning these off might result in faster processing.
plot_raw_accel = false;
plot_psds = false;
plot_spectrograms = true; % Won't work on smaller segments

% Sample rate of the input data. It should really stay on 25 unless you're
% using another tag.
sample_rate = 25;

% Precision of the PSD and the spectrograms. For spectrograms, this
% controls the vertical precision; higher values take more CPu.
psd_nfft = 2048;

% Essentially the horizontal precision of the spectrogram. Too high and
% you'll lose detail; too low and you'll start getting weird artifacts.
% sample_rate is, I think, a good minimum.
spectral_window = sample_rate * 3;

% Controls the maximum frequency plotted in the PSDs.
psd_maxFreq = 2.0;

%% Loading and Preprocessing
disp(TIME_SLICES_S(TIME_SLICE).description);
start_time = TIME_SLICES_S(TIME_SLICE).start_time;
end_time   = TIME_SLICES_S(TIME_SLICE).end_time;

load ACCEL.MAT

in_frame = find((times < start_time) + (times > end_time));
accel(in_frame,:) = [];
times(in_frame) = [];

%% Plotting Raw Acceleration
if plot_raw_accel
    raw_xlims = [times(1), times(end)]; 
    raw_ylims = [-1.3, 1.3];
    figure;
    subplot(3,1,1);
    plot(times,accel(:,1));
    title('X Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");

    subplot(3,1,2);
    plot(times,accel(:,2));
    title('Y Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");

    subplot(3,1,3);
    plot(times,accel(:,3));
    title('Z Acceleration');
    xlim(raw_xlims);
    ylim(raw_ylims);
    xlabel('Time');
    ylabel("g's");
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
