function [ means ] = feature_accel(accel, times, col)
%FEATURE_ACCEL_Z Get mean Z acceleration of each window
% accel:  m x 3 x w
% times:  m x w
% means:  w x 1
windows = size(accel, 3);

accel_ws = accel(:,col,:);
means = mean(accel_ws, 1);
means = reshape(means, windows, 1, 1);
end