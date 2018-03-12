%% Box-And-Whiskers + Correlation Feature Analysis
% Analyze a single feature to determine the extent to which it has a
% statistically significant effect on the data.
%
% Each window will be applied to a feature; windows will be grouped by
% label and then tested for significant difference in mean via ANOVA.
%
% We will then draw a box-and-whiskers chart to show in more detail
% what this means.

slice_name = {...
    'many-turns', 'medley-1', 'medley-2', 'large-slice', 'small-slice', ...
    'rturn-fun', 'afternoon', 'precise', 'sb34-slice-1'...
};
window_size = 30;
window_overlap = 15;

histogram_title = 'Lateral Acceleration Histogram';
histogram_xlabel = 'Acceleration (g''s)';
histogram_ylabel = '# Occurrences';
histogram_bin_width = 0.01;

[accel, times, label_times, label_names] = ...
    load_accel_slice_windowed(slice_name, window_size, ...
    window_overlap);

processed = feature_means_extreme(accel);
processed = processed(:,3);

cats = categories(label_names);

% Basics
for ci=1:length(cats)
   cat = cats{ci};
   disp(cat + " mean: " + mean(processed(label_names == cat)));
   disp(cat + " std-dev: " + std(processed(label_names == cat)));
end

% Turning
% f = figure;
% histogram(processed(label_names == 'L-turn'), 20, ...
%     'Normalization', 'count', 'BinWidth', histogram_bin_width);
% hold on;
% histogram(processed(label_names == 'R-turn'), 20, ...
%     'Normalization', 'count', 'BinWidth', histogram_bin_width);
% title('');
% legend({'L-Turn', 'R-Turn'});
% xlabel(histogram_xlabel);
% ylabel(histogram_ylabel);
% title([histogram_title ' - Turning Behaviors']);
% saveas(f, 'histogram-turning.svg');
% hold off;

% Clockwise/Anticlockwise
f = figure;
hold on;

[c_bins, edges] = histcounts(processed(label_names == 'clockwise'), 60);
[a_bins] = histcounts(processed(label_names == 'anticlockwise'), 60);
line(edges(1:end-1), [c_bins ; a_bins]);
title(histogram_title);
legend({'Counterclockwise', 'Clockwise'});
xlabel(histogram_xlabel);
ylabel(histogram_ylabel);
title([histogram_title ' - Non-Turning Behaviors']);
hold off;

% ANOVA and Box-and-Whiskers
figure;
anova1(processed, label_names);
title(histogram_title)
xlabel('Class');
ylabel('ODBA (g''s)');