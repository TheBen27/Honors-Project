% Demonstrates FFT computation for peak detection
% 3Hz sine wave
sample_rate = 20;

t = linspace(0, 1-(1/sample_rate), sample_rate);
x = sin(t * 2 * pi)...           % 2pi rads/second
  + 0.5 * sin(5 * t * 2 * pi)... % 10pi rads/second
  + 0.3 * rand(size(t));

figure;
plot(t, x);
title("Regular Plot");

%% First FFT
% fft, given a vector of N samples, returns
% a vector of N samples. Weirdly, the FFT
% loops back on itself every 2*pi/sample_rate
% seconds, which is why we don't just see one
% peak.
X = fft(x);
figure;
plot(abs(X));
title("FFT");

%% Symmetrical
% The part of the FFT function in the range [pi/sample_rate,
% 2*pi/sample_rate] is the negative part of the function, and is
% symmetrical, so we want to plot it in the range [-pi/sample_rate,
% pi/sample_rate] instead.
%
% We also want to finally get some real frequency numbers on our plot.
N = length(x);
ws = 2 * pi / N;
wnorm = -pi:ws:pi;
wnorm = wnorm(1:N); % Lops off the last value
w = wnorm * sample_rate;

FX = fftshift(X);

figure;
plot(w, abs(FX));
title("Symmetric FFT");
xlabel("Frequency (rads/sec)");
ylabel("Bigness?");

%% Remove Negative Half
% The negative half is redundant for real-numbered values.
negative = (w < 0);
FX(negative) = 0;
w(negative) = 0;

figure;
plot(w, abs(FX));
title("Positive FFT");
xlabel("Frequency (rads/sec)");
ylabel("Bigness?");

%% Peak Estimation
% Finds the two highest peaks in the signal and reports their
% frequency and amplitudes. For more realistic data, we will need to
% use better peak detection.
%
% Getting the amplitude is as simple as multiplying by 2/N
[vals, inds] = sort(FX, 'descend');
peaks = abs(vals(1:2)) * 2 / N;
freqs = w(inds(1:2));
disp(peaks)
disp(freqs)

% This method works perfectly for frequency and is within 0.01 for
% amplitude, at least with our data.