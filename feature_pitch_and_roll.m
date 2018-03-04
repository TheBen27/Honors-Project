function [ out_table ] = ...
    feature_pitch_and_roll( accel, static_accel )
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

% TODO Don't reshape? Premute better?
dpitch = all_pitches(:);
dpitch(1) = 0;
dpitch(2:end) = dpitch(2:end) - dpitch(1:(end-1));
dpitch = reshape(dpitch, size(all_pitches));

droll = all_rolls(:);
droll(1) = 0;
droll(2:end) = droll(2:end) - droll(1:(end-1));
droll = reshape(droll, size(all_rolls));

% TODO Don't do all this needless permutation
pitch_mean = permute(mean(all_pitches, 1), [3, 1, 2]);
pitch_std = permute(std(all_pitches, [], 1), [3, 1, 2]);
pitch_max = permute(std(all_pitches, [], 1), [3, 1, 2]);
pitch_min = permute(max(all_pitches, [], 1), [3, 1, 2]);

roll_mean = permute(mean(all_rolls, 1), [3, 1, 2]);
roll_std = permute(std(all_rolls, [], 1), [3, 1, 2]);
roll_max = permute(max(all_rolls, [], 1), [3, 1, 2]);
roll_min = permute(min(all_rolls, [], 1), [3, 1, 2]);

dpitch_mean = permute(mean(dpitch, 1), [3, 1, 2]);
dpitch_max  = permute(max(dpitch,  [], 1), [3, 1, 2]);
dpitch_min  = permute(min(dpitch, [], 1), [3, 1, 2]);
dpitch_skew = permute(skewness(dpitch, [], 1), [3, 1, 2]);

droll_mean = permute(mean(droll, 1), [3, 1, 2]);
droll_max  = permute(max(droll,  [], 1), [3, 1, 2]);
droll_min  = permute(min(droll, [], 1), [3, 1, 2]);
droll_skew = permute(skewness(droll, [], 1), [3, 1, 2]);

out_table = table(pitch_mean, pitch_std, pitch_max, pitch_min, ...
    roll_mean, roll_std, roll_max, roll_min, ...
    dpitch_mean, dpitch_max, dpitch_min, dpitch_skew, ...
    droll_mean, droll_max, droll_min, droll_skew);

end

