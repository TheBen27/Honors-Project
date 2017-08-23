function [ pitch, roll ] = feature_static_accel( accel, sample_rate, order, cutoff )
%FEATURE_STATIC_ACCEL Approximate orientation through accelerometry
% Static acceleration is derived by applying a lowpass filter to the data,
% leaving only the DC offset and gravity vector.
% We then derive pitch and roll through the equations at 
% https://theccontinuum.com/2012/09/24/arduino-imu-pitch-roll-from-accelerometer/
% with the right axes for our accelerometer.
%
% The input accel uses the same weird windowing setup as all the others:
% [M samples per window x 3 axes x N windows]. The resulting vectors are
% both [N x 1].

[low_b, low_a] = butter(order, cutoff / sample_rate);

% TODO Resize data so that it's all filtered instead of by windows
filtered = filter(low_b, low_a, accel, [], 1);
low_x = filtered(:, 1, :);
low_y = filtered(:, 2, :);
low_z = filtered(:, 3, :); % [M x 1 x N]
mean_x = mean(mean(accel(:,1,:), 3), 1);

all_pitches = asin(low_x - mean_x) * (180 / pi); % [M x 1 x N]
all_rolls = atan2(-low_z, low_y);

num_windows = size(accel, 3);
pitch = reshape(mean(all_pitches, 1), num_windows, 1, 1);
roll = reshape(mean(all_rolls, 1), num_windows, 1, 1);
% pitch = asin(lo_x - mu_x) * (180 / pi);
% roll = atan2(-lo_z, lo_y);

end

