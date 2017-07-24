function [ means ] = feature_accel_z(accel, times)
%FEATURE_ACCEL_Z Get mean Z acceleration of each window
% accel:  m x 3 x w
% times:  m x w
% means:  w x 1
windows = size(accel, 3);

accel_zs = accel(:,3,:);
means = mean(accel_zs, 1);
means = reshape(means, windows, 1, 1);
end