%% Closeup
% Looks at a small slice of animal data in accelerometry, FFT, and
% peaking terms, among other things.
%
% 14:07:05 - 14:07:26 (2017-06-15)
% Shark swims at a constant speed on the outer rim of the pool.
% By the end of the time frame, it has completed one full revolution.
%
% 12:44:49 - 14:17:03 (2017-06-15)
% Mostly constant swimming with occasional turns and bumps.
%
% 16:51:26 - 16:51:31 (2016-06-15)
% A single, clean 180-degree left turn (doesn't hit the wall).
%
% 15:45:08-15:48:10 (2016-06-15)
% A lot of turning right after the shark was poked.
%% Configuration

TIME_SLICES = [
    % Short-term (1 rotation around tank)
    datetime(2017, 6, 15, 14, 7, 5), datetime(2017, 6, 15, 14, 7, 26);
    % Long-term view (couple of hours of mostly constant swimming)
    datetime(2017, 6, 15, 12, 44, 49), datetime(2017, 6, 15, 14, 17, 03);
    % Single clean turn
    datetime(2017, 6, 15, 16, 51, 26), datetime(2017, 6, 15, 16, 51, 31);
    % Lots of turns
    datetime(2017, 6, 15, 15, 45, 08), datetime(2017, 6, 15, 15, 48, 10)
];

TIME_SLICE = 4;

plot_raw_accel = true;
plot_psds = true;
plot_spectrograms = true; % Won't work on smaller segments

% General Settings
sample_rate = 25;

% Power Spectral Distribution Settings
psd_nfft = 2048;
psd_maxFreq = 2.0;

% Spectral window settings
spectral_window = sample_rate * 3;

%% Loading and Preprocessing
start_time = TIME_SLICES(TIME_SLICE, 1);
end_time   = TIME_SLICES(TIME_SLICE, 2);

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

%% Get Power Spectral Distributions

% Subtract mean to remove DC offset and center signal
% TODO Figure out if that idea is at all sensible
accel_high = accel - repmat(mean(accel),size(accel,1),1);

sample_rate = 25;
accel_fft = fftshift(fft(accel_high, psd_nfft, 1));
accel_power = accel_fft .* conj(accel_fft) / (psd_nfft * size(accel,1));

f = sample_rate * (-psd_nfft/2:psd_nfft/2-1)/psd_nfft;

% Remove all negative frequencies
neg_fs = f < 0;
f(neg_fs) = [];
accel_fft(neg_fs,:) = [];
accel_power(neg_fs,:) = [];

%% Plotting PSDs
if plot_psds
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
