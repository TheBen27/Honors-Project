function [ accel, times, label_times, label_names, label_categories, raw_freqs, window_freqs ] = ...
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

[accel_r, times_r, label_times_r, label_names_r, raw_freqs] = load_accel_slice(slice_names);
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

parfor win=1:num_windows
    sind = (win - 1) * (window_overlap + window_size) + 1;
    eind = sind + total_window_size - 1;
    accel(:, :, win) = accel_r(sind:eind, :);
    times(:, win) = times_r(sind:eind);
    
    % Find the most prevalent label in this window. For example, if a
    % window consists of 0.5 seconds under label "A" and 0.2 seconds under
    % label "B", then we classify it as "A".
    start_time = times_r(sind);
    end_time = times_r(eind);
    between_window = find((label_times_r <= end_time) & ...
                          (label_times_r >= start_time));
    if isempty(between_window)
       window_times = [start_time, end_time]; 
    else
       window_times = [start_time, label_times_r(between_window)', end_time];
    end
    
    delta_times = window_times(2:end) - window_times(1:end-1);
    [~, time_ind] = max(delta_times);
    
    if time_ind == 1
       most_prevalent_ind = find(label_times_r <= start_time, 1, 'last');
    else
       most_prevalent_ind = between_window(time_ind - 1);
    end
    label_times(win) = label_times_r(most_prevalent_ind);
    label_names(win) = label_names_r(most_prevalent_ind);
end

% Give a summary of the base probabilities of each label
label_categories = categories(label_names);
window_freqs = zeros(length(label_categories), 1);
disp("");
disp("WINDOW FREQUENCIES");
for cat_i = 1:length(label_categories)
    cat = label_categories{cat_i};
    cat_pos = sum(label_names == cat);
    cat_perc = cat_pos / length(label_names);
    disp(cat + ": " + cat_pos + "/" + length(label_names) + ...
        " (" + cat_perc * 100 + "%)");
    window_freqs(cat_i) = cat_perc;
end

end

