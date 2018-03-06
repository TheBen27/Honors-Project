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

dpitch = all_pitches(:);
dpitch(1) = 0;
dpitch(2:end) = dpitch(2:end) - dpitch(1:(end-1));
dpitch = reshape(dpitch, size(all_pitches));

droll = all_rolls(:);
droll(1) = 0;
droll(2:end) = droll(2:end) - droll(1:(end-1));
droll = reshape(droll, size(all_rolls));

ap = permute(all_pitches, [3, 1, 2]); %[n x m]
pitch_mean = mean(ap, 2);
pitch_std = std(ap, [], 2);
pitch_max = max(ap, [], 2);
pitch_min = min(ap, [], 2);
pitch_pp = pitch_max - pitch_min;

ar = permute(all_rolls, [3, 1, 2]);
roll_mean = mean(ar, 2);
roll_std = std(ar, [], 2);
roll_max = max(ar, [], 2);
roll_min = min(ar, [], 2);
roll_pp = roll_max - roll_min;

adp = permute(dpitch, [3, 1, 2]);
dpitch_mean = mean(adp, 2);
dpitch_max  = max(adp, [], 2);
dpitch_min  = min(adp, [], 2);
dpitch_skew = skewness(adp, [], 2);

adr = permute(droll, [3, 1, 2]);
droll_mean =  mean(adr, 2);
droll_max  =  max(adr, [], 2);
droll_min  =  min(adr, [], 2);
droll_skew =  skewness(adr, [], 2);

out_table = table(pitch_mean, pitch_std, pitch_max, pitch_min, pitch_pp, ...
    roll_mean, roll_std, roll_max, roll_min, roll_pp, ...
    dpitch_mean, dpitch_max, dpitch_min, dpitch_skew, ...
    droll_mean, droll_max, droll_min, droll_skew);

end

