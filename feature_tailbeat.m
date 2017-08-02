function [ freqs, amps ] = feature_tailbeat( accel )
%FEATURE_TAILBEAT Try to estimate the tailbeat frequency of a window of data.
%
% accel is organized in windows (m entries/window x 3 columns x n windows).
% freqs and amps will both be (n x 1) vectors.
%
% As far as I can tell, tailbeat frequency shows up strongly in the X axis
% of the tag. On a PSD, this manifests in the form of a peak around
% 1Hz - but since this is dependent somewhat on the shark's speed,
% we can vary it between about 1 and 2 Hz.
%
% For the sake of completeness, we're also going to return the
% second-biggest peak in this range along with the amplitudes of each peak.
% (TODO)

% ORIGINAL CODE
% psd_nfft = 1024
% sample_rate = 25;
% accel_fft = fftshift(fft(accel_high, psd_nfft, 1));
% accel_power = accel_fft .* conj(accel_fft) / (psd_nfft * size(accel,1));
% 
% f = sample_rate * (-psd_nfft/2:psd_nfft/2-1)/psd_nfft;
% 
% % Remove all negative frequencies
% neg_fs = f < 0;
% f(neg_fs) = [];
% accel_fft(neg_fs,:) = [];
% accel_power(neg_fs,:) = [];
end

