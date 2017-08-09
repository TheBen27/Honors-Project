%% Simple SVM for Turning Detection
% A binary SVM for detecting turning.
%
% The data will be split into overlapping windows. The windows will
% then be sent through a series of functions to act as feature
% detectors, and the result put into a binary SVM. We'll then find
% the accuracy of the features we've put in and, well, hopefully they'll
% be better than that of a dice-throwing monkey.
%% Configuration

% Load the needed data and labels here.
load('SLICES.MAT'); % loads TIME_SLICES

% Index of the data slice in SLICES.MAT to use
accel_slice = 5;

% Each window has (window_size + window_overlap) samples. Overlapping
% samples are shared with a window's neighbors.
%
% Data at the end of the set that does not fit squarely within a window is
% cut off.
window_size = 25 - 16;
window_overlap = 8;

%% Split and label data
[accel, times, label_times, label_names] = ... 
    load_accel_slice_windowed(TIME_SLICES(accel_slice), window_size, window_overlap);

%% Make features
means_x = feature_accel(accel, times, 1);
means_y = feature_accel(accel, times, 1);
means_z = feature_accel(accel, times, 1);

features = table(means_x, means_y, means_z);

%% Get Accuracy

% Shuffle features/labels to randomize training set and test set
rand_inds = randperm(height(features));
r_features = features(rand_inds, :);
r_labels = label_names(rand_inds);

% Split into training set and test set
training_size = floor(length(label_names) * 0.8);
training_features = r_features(1:training_size, :);
training_labels   = r_labels(1:training_size, :);
test_features = r_features((1 + training_size):length(label_names), :);
test_labels   = r_labels((1 + training_size):length(label_names), :);

assert(height(training_features) + height(test_features) == length(label_names));

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
disp("Accuracy of a dice-throwing monkey: " + 1 / length(categories(label_names)));

% Gory details
fprintf("\nGORY DETAILS\n\n");
cats = categories(label_names);
for i=1:length(cats)
    cat = string(cats{i});
    actual_hits = sum(cat == test_predictions);
    expected_hits = sum(cat == test_labels);
    disp("Number of hits for " + cats{i} + ": " + actual_hits ...
        + " (Expected " + expected_hits + ")");
end
