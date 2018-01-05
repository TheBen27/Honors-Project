function [ means ] = feature_odba(dynamic_accel)
%FEATURE_ODBA Get mean windowed dynamic body acceleration.
% "The sum of the absolute values of the dynamic acceleration of the data"
% accel:  m x 3 x w
% means:  w x 1

instantaneous_means = sum(abs(dynamic_accel), 2);
windowed_means = mean(instantaneous_means, 1);
means = permute(windowed_means, [3, 2, 1]);

end
