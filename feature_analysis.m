%% Box-And-Whiskers + Correlation Feature Analysis
% Analyze a single feature to determine the extent to which it has a
% statistically significant effect on the data.
%
% Each window will be applied to a feature; windows will be grouped by
% label and then tested for significant difference in mean via ANOVA.
%
% We will then draw a box-and-whiskers chart to show in more detail
% what this means.

slice_name = {'many-turns', 'medley-1', 'medley-2', 'large-slice', 'small-slice'};
window_size = 50 - 24;
window_overlap = 12;

histogram_title = 'ODBA';
histogram_bin_width = 0.02;

[accel, times, label_times, label_names] = ...
    load_accel_slice_windowed(slice_name, window_size, ...
    window_overlap);

processed = feature_odba(accel);

cats = categories(label_names);

% Basics
for ci=1:length(cats)
   cat = cats{ci};
   disp(cat + " mean: " + mean(processed(label_names == cat)));
   disp(cat + " std-dev: " + std(processed(label_names == cat)));
end

% Turning
f = figure;
histogram(processed(label_names == 'L-turn'), 20, ...
    'Normalization', 'probability', 'BinWidth', histogram_bin_width);
hold on;
histogram(processed(label_names == 'R-turn'), 20, ...
    'Normalization', 'probability', 'BinWidth', histogram_bin_width);
legend({'L-turn', 'R-turn'});
xlabel('Acceleration (g''s)');
ylabel('Probability');
title([histogram_title ' - Turning Behaviors']);
saveas(f, 'histogram-turning.svg');
hold off;

% Clockwise/Anticlockwise
f = figure;
histogram(processed(label_names == 'anticlockwise'), 20, ...
    'Normalization', 'probability', 'BinWidth', histogram_bin_width);
hold on;
histogram(processed(label_names == 'clockwise'), 20, ...
    'Normalization', 'probability', 'BinWidth', histogram_bin_width);
title('');
legend({'Counterclockwise', 'Clockwise'});
xlabel('Acceleration (g''s)');
ylabel('Probability');
title([histogram_title ' - Non-Turning Behaviors']);
saveas(f, 'histogram-straight.svg');
hold off;

% ANOVA and Box-and-Whiskers
figure;
anova1(processed, label_names);
title(histogram_title)
xlabel('Class');
ylabel('ODBA (g''s)');