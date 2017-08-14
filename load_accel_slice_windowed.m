function [ accel, times, label_times, label_names ] = ...
    load_accel_slice_windowed( slice_names, window_size, window_overlap )
% LOAD_ACCEL_SLICE_WINDOWED Convert a slice of accelerometer data and split
% it into overlapping windows.
%
% accel is organized into a 3D matrix of (#entries per window X 3 axes X #windows).
% Each window will have (window_size + 2 * window_overlap) entries in it.
% times is (#entries per window X #windows).
% label_times and label_names are (#windows x 1) vectors.
%
% Any data at the end of the slice that doesn't cleanly fit into a window
% will be lopped off.

[accel_r, times_r, label_times_r, label_names_r] = load_accel_slice(slice_names);
label_names_r = categorical(label_names_r);
% Get number of windows and window size
total_window_size = window_size + 2 * window_overlap;
num_windows = floor((length(accel_r) - window_overlap) / ...
    (window_overlap + window_size));
% Set up accel, times, and labeling
accel = zeros(total_window_size, 3, num_windows);
times = repmat(datetime(0,0,0,0,0,0), total_window_size, num_windows);
label_times = repmat(datetime(0,0,0,0,0,0), num_windows, 1);
label_names = repmat(label_names_r(1), num_windows, 1);
for win=1:num_windows
    sind = (win - 1) * (window_overlap + window_size) + 1;
    eind = sind + total_window_size - 1;
    accel(:, :, win) = accel_r(sind:eind, :);
    times(:, win) = times_r(sind:eind);
    % For now, just get the closest label
    closest_time = times_r(sind);
    closest_ind = find(label_times_r < closest_time, 1, 'last');
    label_times(win) = label_times_r(closest_ind);
    label_names(win) = label_names_r(closest_ind);
end

end

