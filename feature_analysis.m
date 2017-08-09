%% Box-And-Whiskers + Correlation Feature Analysis
% Analyze a single feature to determine the extent to which it has a
% statistically significant effect on the data.
%
% Each window will be applied to a feature; windows will be grouped by
% label and then tested for significant difference in mean via ANOVA.
%
% We will then draw a box-and-whiskers chart to show in more detail
% what this means.

load('SLICES.MAT'); % loads TIME_SLICES

accel_slice = 5;
window_size = 24;
window_overlap = 8;

feature = @(acc) feature_accel(acc, [], 1);

[accel, times, label_times, label_names] = ...
    load_accel_slice_windowed(TIME_SLICES(accel_slice), window_size, ...
    window_overlap);

processed = feature(accel);

anova1(processed, label_names);