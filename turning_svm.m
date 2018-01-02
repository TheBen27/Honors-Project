%% Simple SVM for Turning Detection
% A binary SVM for detecting turning.
%
% The data will be split into overlapping windows. The windows will
% then be sent through a series of functions to act as feature
% detectors, and the result put into a binary SVM. We'll then find
% the accuracy of the features we've put in and, well, hopefully they'll
% be better than that of a dice-throwing monkey.
%% Configuration

% Save the seed so we get consistent results
rng(3);

% Cell array of data slices to use. These should all be labeled.
slice_name = {'many-turns', 'medley-1', 'medley-2'};

sample_rate = 20;

% Each window has (window_size + window_overlap) samples. Overlapping
% samples are shared with a window's neighbors.
%
% Data at the end of the set that does not fit squarely within a window is
% cut off.
window_size = 20;
window_overlap = 20;

% Configuration of the butterworth filter dividing static and
% dynamic acceleration.
static_filter_order = 3;
static_filter_cutoff = 0.6;

%% Load and preprocess data
[accel, times, label_times, label_names] = ... 
    load_accel_slice_windowed(slice_name, window_size, window_overlap);

%% Generate data to use in features
[low_b, low_a] = butter(static_filter_order, static_filter_cutoff / sample_rate);
static_accel = filter(low_b, low_a, accel, [], 1);
dynamic_accel = accel - static_accel;

%% Make and Process features
means_x = feature_accel(accel, 1, 3);
means_y = feature_accel(accel, 2, 3);
means_z = feature_accel(accel, 3, 3);
odba = feature_odba(dynamic_accel);
[pitch, roll] = feature_pitch_and_roll(accel, static_accel);

[tail_distinct, tail_freq] = feature_tailbeat(accel, 1024, 25, 0.8, 1.6);

features = table(...
    means_x, means_y, means_z, ...
    odba(:, 1), ...
    odba(:, 2), ...
    odba(:, 3), ...
    tail_distinct(:, 1), ...
    tail_distinct(:, 2), ...
    tail_distinct(:, 3), ...
    tail_freq(:, 1), ....
    tail_freq(:, 2), ....
    tail_freq(:, 3), ....
    pitch, roll...
);

% Shuffle features/labels to randomize training set and test set
rand_inds = randperm(height(features));
r_features = features(rand_inds, :);tail_freq(:, 1), ...
r_labels = label_names(rand_inds);

%% Get Accuracy

% Split into training set and test set
training_size = floor(length(label_names) * 0.8);
training_features = r_features(1:training_size, :);
training_labels   = r_labels(1:training_size, :);
test_features = r_features((1 + training_size):length(label_names), :);
test_labels   = r_labels((1 + training_size):length(label_names), :);

assert(height(training_features) + height(test_features) == length(label_names));

% Standardize variables - use Training Set's mean and std. dev.
training_mean = mean(training_features{:,:});
training_std = std(training_features{:,:});

training_features{:,:} = (training_features{:,:} - training_mean) ./ training_std;
test_features{:,:} = (test_features{:,:} - training_mean) ./ training_std;

% Save features before we oversample them
writetable([training_features, table(training_labels)], ...
            "Features/training-standard.csv");
writetable([test_features, table(test_labels, ...
            'VariableNames', {'training_labels'})], ...
            "Features/test-standard.csv");
% Oversample less common classes in training set only
dupe_features = table();
dupe_labels = [];
for wi = 1:length(weight_map)tail_freq(:, 1), ...
   label = weight_map(wi, 1);
   freq = weight_map{wi, 2} - 1;
   if freq > 0
       inds = (training_labels == label);
       dupe_features = [dupe_features ; repmat(training_features(inds,:), freq, 1)];
       dupe_labels = [dupe_labels ; repmat(training_labels(inds), freq, 1)]; 
   end
end

training_features = [features ; dupe_features];
training_labels = [label_names ; dupe_labels];

% Train and predict
svm_template = templateSVM('KernelFunction', 'Gaussian');

svm_trainer = fitcecoc(training_features, training_labels, 'Learners', svm_template);
training_predictions = predict(svm_trainer, training_features);
test_predictions = predict(svm_trainer, test_features);

% Accuracy
fprintf("\nACCURACY\n\n");
test_accuracy = sum(test_labels == test_predictions) ...
    / length(test_predictions);
training_accuracy = sum(training_labels == training_predictions) ...
    / length(training_predictions);

disp("Test accuracy: " + test_accuracy);
disp("Training accuracy: " + training_accuracy);

% Gory details
fprintf("\nGORY DETAILS\n\n");
cats = categories(label_names);
precisions = zeros(size(cats));
recalls = zeros(size(cats));

for i=1:length(cats)
    cat = string(cats{i});
    actual   = (cat == test_predictions);
    expected = (cat == test_labels);
    
    true_positives  = sum(actual & expected);
    false_positives = sum(actual & ~expected);
    false_negatives = sum(expected & ~actual);
    
    % Precision is a measure of quality - if the machine thought it
    % was this class, was it right?
    precisions(i) = true_positives / (true_positives + false_positives);
    % Recall is a measurement of quantity - if an example was of this
    % class, did the machine pick it?
    recalls(i)    = true_positives / (true_positives + false_negatives);
end

results = table(cats, precisions, recalls);
results.Properties.VariableNames = {'Classes', 'Precision', 'Recall'};
disp(results);
