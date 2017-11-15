function [ means ] = feature_means(accel)
% FEATURE_MEAN Get mean of each window's column
% accel:  m x 3 x w
% times:  m x w
% means:  w x 1

means = mean(accel, 1);
means = reshape(means, size(accel,3), 3, 1);
end