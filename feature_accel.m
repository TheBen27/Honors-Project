function [ means ] = feature_accel(accel, col, maxes)
%FEATURE_ACCEL_Z Get mean Z acceleration of top 6 points of each window
% accel:  m x 3 x w
% times:  m x w
% means:  w x 1

windows = size(accel, 3);
means = zeros(windows, 1);

assert(maxes < size(accel, 1));

% Probably not the fastest way to do this, not that I really care
for w=1:windows
    % get window
    % flatten it
    % sort it
    % get first N elements
    % get mean of those
    % add to means
    window = sort(accel(:, col, w), 'descend');
    means(w) = mean(window(1:maxes));
end

%means = mean(accel_ws, 1);
%means = reshape(means, windows, 1, 1);
end