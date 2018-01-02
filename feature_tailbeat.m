function [ distinctiveness, frequency ] = feature_tailbeat( ...
    accel, nfft, sample_rate, high_pass, low_pass)
%FEATURE_TAILBEAT Try to estimate the tailbeat frequency of a window of data.
%
% accel is organized in windows (m entries/window x 3 columns x n windows).
% both outputs are (n x 1) vectors.
%
% distinctiveness is a twofold measure. It scores very low if the closest
% thing we could find to a "tailbeat" is too fast or slow to be reasonable.
% It also scores low if it's not much higher than the other frequencies
% (e.g. it might just be noise).

% Get PSD and filter frequencies via brickwall
accel_fft = fftshift(fft(accel,  nfft, 1));
accel_pow = accel_fft .* conj(accel_fft) / (nfft * size(accel, 1));

freqs = sample_rate * (-nfft/2:nfft/2-1)/nfft;
filt_inds = (freqs > high_pass) & (freqs < low_pass);

accel_pow(filt_inds, :, :) = [];
freqs(filt_inds) = [];
[tail_amp, tail_ind] = max(accel_pow, [], 1);

frequency = freqs(tail_ind);

% TODO get energy from each window?
energy = mean(accel_pow, 1);
distinctiveness = tail_amp ./ energy;

num_windows = size(distinctiveness, 3);
num_axes = size(distinctiveness, 2);
distinctiveness = reshape(distinctiveness, num_windows, num_axes, 1);
frequency = reshape(frequency, num_windows, num_axes, 1);

end

