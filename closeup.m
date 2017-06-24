%% Closeup
% Looks at a small slice of animal data in accelerometry, FFT, and
% peaking terms, among other things.
%
% 14:07:05 - 14:07:26 (2017-06-15)
% Shark swims at a constant speed on the outer rim of the pool.
% By the end of the time frame, it has completed one full revolution.
%% Config

% Short-term view (one revolution around the tank)
% start_time = datetime(2017, 6, 15, 14, 7, 5);
% end_time   = datetime(2017, 6, 15, 14, 7, 26);

% Long-term view (a couple of hours of mostly constant swimming)
start_time = datetime(2017, 6, 15, 12, 44, 49);
end_time   = datetime(2017, 6, 15, 14, 17, 03);

freq_axes = [0,4,0,70];

nfft = 256;

%% Loading and Preprocessing

load ACCEL.MAT

in_frame = find((times < start_time) + (times > end_time));
accel(in_frame,:) = [];
times(in_frame) = [];

%% FFT - frequency

% Subtract mean to remove DC offset and center signal
% TODO Figure out if that idea is at all sensible
accel_high = accel - repmat(mean(accel),size(accel,1),1);

sample_rate = 25;
accel_fft = fftshift(fft(accel_high, nfft, 1));
accel_power = accel_fft .* conj(accel_fft) / (nfft * size(accel,1));

f = sample_rate * (-nfft/2:nfft/2-1)/nfft;

% Remove all negative frequencies
neg_fs = f < 0;
f(neg_fs) = [];
accel_fft(neg_fs,:) = [];
accel_power(neg_fs,:) = [];

%% Plotting Raw Acceleration
figure;
subplot(3,1,1);
plot(times,accel(:,1));
title('X Acceleration');
xlabel('Time');
ylabel("g's");

subplot(3,1,2);
plot(times,accel(:,2));
title('Y Acceleration');
xlabel('Time');
ylabel("g's");

subplot(3,1,3);
plot(times,accel(:,3));
title('Z Acceleration');
xlabel('Time');
ylabel("g's");

%% Plotting PSDs
figure;
plot(f,accel_power);
title("Power Spectral Distributions");
xlabel('Frequency (Hz)');
ylabel('Power (???)');


%% Plotting Spectrograms
figure;
spectrogram(accel(:,1), sample_rate * 2, floor(sample_rate / 3), ... 
    nfft, sample_rate, 'yaxis');
title('Spectrogram (X Axis)');
