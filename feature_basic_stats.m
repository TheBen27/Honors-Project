function [stats] = feature_basic_stats(accel)
%FEATURE_BASIC_STATS Returns a bevy of stats from accelerometer data.
% Stat choices are from a paper on cow behavior detection with
% accelerometers (Martiskainen et al 2009)
%
% Output is a table with the following column names:
%  mean_x, mean_y, mean_z
%  std_x, std_y, std_z
%  skew_x, skew_y, skew_z
%  kurt_x, kurt_y, kurt_z
%  min_x, min_y, min_z,
%  min_ix, min_iy, min_iz,
%  max_x, max_y, max_z
%  max_ix, max_iy, max_iz
%  energy_x, energy_y, energy_z,
%  pearson_xy, pearson_xz, pearson_yz
%
% accel is an MxCxW matrix
% each output column is wx1
%   M - number of samples in a window
%   C - number of axes
%   W - number of windows

ap = permute(accel, [3, 2, 1]);
means = mean(ap, 3);
std_devs = std(ap, 0, 3);
skew = skewness(ap, 1, 3);
kurt = kurtosis(ap, 1, 3);
[minv, mini] = min(ap, [], 3);
[maxv, maxi] = max(ap, [], 3);
% from Ravi et al 2005
energy = sum(abs(ap) .^ 2, 3) / size(accel, 1);

% Pearson correlation coefficient r
dx = ap(:,1,:) - repmat(mean(ap(:,1,:), 3), 1, 1, size(ap, 3));
dy = ap(:,2,:) - repmat(mean(ap(:,2,:), 3), 1, 1, size(ap, 3));
dz = ap(:,3,:) - repmat(mean(ap(:,3,:), 3), 1, 1, size(ap, 3));
cor_xy = sum(dx .* dy, 3) ./ (sqrt(sum(dx .^ 2, 3)) .* sqrt(sum(dy .^ 2, 3)));
cor_xz = sum(dx .* dz, 3) ./ (sqrt(sum(dx .^ 2, 3)) .* sqrt(sum(dz .^ 2, 3)));
cor_yz = sum(dy .* dz, 3) ./ (sqrt(sum(dy .^ 2, 3)) .* sqrt(sum(dz .^ 2, 3)));

stats = table( ...
    means(:,1), means(:,2), means(:,3), ...
    std_devs(:,1), std_devs(:,2), std_devs(:,3), ...
    skew(:,1), skew(:,2), skew(:,3), ...
    kurt(:,1), kurt(:,2), kurt(:,3), ...
    minv(:,1), minv(:,2), minv(:,3), ...
    mini(:,1), mini(:,2), mini(:,3), ...
    maxv(:,1), maxv(:,2), maxv(:,3), ...
    maxi(:,1), maxi(:,2), maxi(:,3), ...
    energy(:,1), energy(:,2), energy(:,3), ...
    cor_xy, cor_xz, cor_yz ...
);

stats.Properties.VariableNames = {...
    'avg_x', 'avg_y', 'avg_z', ...
    'std_x', 'std_y', 'std_z', ...
    'skew_x', 'skew_y', 'skew_z', ...
    'kurt_x', 'kurt_y', 'kurt_z', ...
    'min_x', 'min_y', 'min_z', ...
    'min_ix', 'min_iy', 'min_iz', ...
    'max_x', 'max_y', 'max_z', ...
    'max_ix', 'max_iy', 'max_iz', ...
    'energy_x', 'energy_y', 'energy_z', ...
    'cor_xy', 'cor_xz', 'cor_yz' ...
};

end

