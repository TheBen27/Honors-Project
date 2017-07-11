%% Check low-frequency Z acceleration for turning
% 
% When a shark turns, it gives the accelerometer a little bit of
% centripetal force - 0.1213 g's is a rough estimate. If we filter
% out any high-frequency data, break everything into overlapping windows,
% and plot the average Z value against its label, will we find anything?
%
% Our data set will be a mix of shark data from two times: Time Slice 2,
% without much turning, and Time Slice 4, with a lot of turning (see
% closeup.m). Both sets will be labeled through video observation.
%
% Note that a shark makes about 0.656 turns a minute. This isn't a lot,
% so we'll need a good method to weed out false positives, if we can
% find one
%% Configuration

% Window size, in samples
window_size = 25;

% Normalized filter cutoff for a 2nd-order butterworth lowpass.
% DC Offset will also be applied
filter_cutoff = 2 / 25;

%% Extract data and lables
[straight_accel, straight_time] = load_time_slice(datetime(2017, 6, 15, ... 
    12, 44, 49), datetime(2017, 6, 15, 14, 17, 03));
[curve_accel, curve_time] = load_time_slice(datetime(2017, 6, 15, ... 
    15, 45, 08), datetime(2017, 6, 15, 15, 48, 10));

accel = [straight_accel ; curve_accel];
times = [straight_time  ; curve_time];

[straight_inds, straight_names] = import_labels('Labels/slice-2.csv');
[curve_inds, curve_names]       = import_labels('Labels/slice-4.csv');

label_times = [ straight_inds ; curve_inds];
label_names = [straight_names ; curve_names];

%% Filter Z data
disp('STUB: accel_filt');
accel_filtz = accel(:, 3);
accel_filtz = accel_filtz - mean(accel_filtz);

[fb, fa] = butter(2, filter_cutoff);
accel_filtz = filter(fb, fa, accel_filtz);

%% Split data into labeled windows
window_means = [];
window_names = {};
for w=1:window_size:length(times)
    wend = min([w + window_size, length(times)]);
    window_means(end+1) = mean(accel_filtz(w:wend));
    % For now, we just take the last-used label to be the label for this
    % window (instead of the mode or something)
    window_names{end+1} = label_names(find(label_times <= times(w), 1, 'last'));
end

%% Plot labeled data
ws = string(window_names);
is_turning = ws == 'L-turn' | ws == 'R-turn';

turn_means = window_means(is_turning);
straight_means = window_means(~is_turning);

disp('Mean and std. dev. Z for straight windows:');
disp(mean(straight_means));
disp(std(straight_means));

disp('Mean and std. dev. Z acceleration for curved windows:');
disp(mean(turn_means));
disp(std(turn_means));

figure;
hold on
plot(turn_means, ones(sum(is_turning), 1), 'oy');
plot(straight_means, zeros(sum(~is_turning), 1), 'ob');
legend('Turning', 'Not Turning');