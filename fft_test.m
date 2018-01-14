% Demonstrates FFT computation for peak detection
% 3Hz sine wave
sample_rate = 20;
rng(5);

% X Axis of Real Data
[x, t, ~, ~] = load_accel_slice('one-revolution');
% x = x(:, 1);

% Simulated sine waves
% t = linspace(0, 1-(1/sample_rate), sample_rate);
% x = sin(t * 2 * pi)...             % 2pi rads/second
%   + 0.5 * sin(5 * t * 2 * pi)...   % 10pi rads/second
%   + 0.3 * (2 * rand(size(t)) - 1); % Noise

low_pass = 3 * pi;
high_pass = 0.01 * pi;

% Using a power of 2 is ideal, but changing the nfft has an odd side
% effect of throwing off the frequency and introducing ringing
nfft = length(x); %2 ^ nextpow2(length(x) * 8);

figure;
plot(t, x);
title("Regular Plot");

%% First FFT
% fft, given a vector of N samples, returns
% a vector of N samples. Weirdly, the FFT
% loops back on itself every 2*pi/sample_rate
% seconds, which is why we don't just see one
% peak.
X = fft(x, nfft);

% figure;
% plot(abs(X));
% title("FFT");

%% Symmetrical
% The part of the FFT function in the range [pi/sample_rate,
% 2*pi/sample_rate] is the negative part of the function, and is
% symmetrical, so we want to plot it in the range [-pi/sample_rate,
% pi/sample_rate] instead.
%
% We also want to finally get some real frequency numbers on our plot.
N = length(X);
ws = 2 * pi / N;
wnorm = -pi:ws:pi;
wnorm = wnorm(1:N); % Lops off the last value
w = wnorm * sample_rate;

FX = fftshift(X);

% figure;
% plot(w, abs(FX));
% title("Symmetric FFT");
% xlabel("Frequency (rads/sec)");
% ylabel("Bigness?");

%% Brickwall Filters
% We remove all frequencies outside of a certain range.
out_of_range = (w > low_pass | w < high_pass);
FX(out_of_range, :) = [];
w(out_of_range) = [];

figure;
plot(w, abs(FX));
title("Filtered FFT");
xlabel("Frequency (rads/sec)");
ylabel("Bigness?");

%% Peak Estimation
% Finds the two highest peaks in the signal and reports their
% frequency and amplitudes.
%
% Getting the amplitude is as simple as multiplying by 2/length(x)
[vals, inds] = findpeaks(abs(FX(:, 1)), 'SortStr', 'descend');

peaks = vals * 2 / length(x);
freqs = w(inds);
disp 'Peak amplitudes'
disp(peaks)
disp 'Peak frequencies (rads)'
disp(freqs)

% This method works perfectly for frequency and is within 0.01 for
% amplitude, at least with our data.