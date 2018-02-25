function [ pitch, roll ] = feature_pitch_and_roll( accel, static_accel )
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

low_x = static_accel(:, 1, :);
low_y = static_accel(:, 2, :);
low_z = static_accel(:, 3, :); % [M x 1 x N]
mean_x = mean(mean(accel(:,1,:), 3), 1);

all_pitches = asin(low_x - mean_x) * (180 / pi); % [M x 1 x N]
all_rolls = atan(-low_z ./ low_y);

% Beginning to think this whole "windowed" thing has led to entirely too
% much permuting and cache thrashing
num_windows = size(accel, 3);
pitch = permute(mean(all_pitches, 1), [3, 1, 2]);
roll = permute(mean(all_rolls, 1), [3, 1, 2]);

end

