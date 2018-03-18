%% Find good window size via grid search
slice_name = {...
    'many-turns', 'medley-1', 'medley-2', 'large-slice', 'small-slice', ...
    'rturn-fun', 'afternoon', 'precise', 'sb34-slice-1'...
};
window_sizes = 12:6:48;
window_overlaps = 12:4:24;

ss_error = zeros(length(window_sizes), length(window_overlaps));
for ws=1:length(window_sizes)
    for wo=1:length(window_overlaps)
        [~, ~, ~, ~, ~, raw_freqs, window_freqs ] = ...
            load_accel_slice_windowed(slice_name, window_sizes(ws), window_overlaps(wo));
        percent_diff = abs(raw_freqs - window_freqs) ./ raw_freqs;
        ss_error(ws, wo) = mean(percent_diff);
    end
end

[error, ind] = min(ss_error(:));
[best_size_ind, best_overlap_ind] = ind2sub(size(ss_error), ind);

disp("Best window overlap: " + window_overlaps(best_overlap_ind));
disp("Best window size: " + window_sizes(best_size_ind));
disp("Mean % Error: " + ss_error(best_size_ind, best_overlap_ind));