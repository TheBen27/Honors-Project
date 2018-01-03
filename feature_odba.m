function [ means ] = feature_odba(dynamic_accel)
%FEATURE_ODBA Get overall dynamic body acceleration.
% "The sum of the absolute values of the dynamic acceleration of the data"
% accel:  m x 3 x w
% means:  w x 1
num_windows = size(dynamic_accel,3);
means = reshape(sum(abs(dynamic_accel)), num_windows, 3, 1);

end