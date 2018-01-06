% A series of quasi-unit tests for the tailbeat frequency/distinctiveness
% feature.

sample_rate = 20;
window_size = 20;
nfft = 1024;
high_pass = 0.0;
low_pass = 999.9;

% 10 seconds worth of sample read times organized into second-long windows
% and repmatted across three axes. For example, if the sample rate were 2,
% then it would look like:
%
% times(:,:,1) = [0.0, 0.0, 0.0 ; 0.5, 0.5, 0.5]
% times(:,:,2) = [1.0, 1.0, 1.0 ; 1.5, 1.5, 1.5]
times = linspace(0, window_size - (1 / sample_rate), sample_rate * window_size);
times = reshape(times, sample_rate, 1, window_size);
times = repmat(times, 1, 3, 1);

%% Single 1Hz sine wave, no noise
data = sin(1 * times * 2 * pi);
[distinct, freq] = feature_tailbeat(data, nfft, sample_rate, high_pass, low_pass);
if all(all(abs(freq - 1) >= 0.02))
    disp("FAILED: single 1hz sine wave, no noise");
end