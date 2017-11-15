%% Simple SVM for Turning Detection
% A binary SVM for detecting turning.
%
% The data will be split into overlapping windows. The windows will
% then be sent through a series of functions to act as feature
% detectors, and the result put into a binary SVM. We'll then find
% the accuracy of the features we've put in and, well, hopefully they'll
% be better than that of a dice-throwing monkey.
%% Configuration

% Cell array of data slices to use. These should all be labeled.
slice_name = {'many-turns', 'medley-1'};

% Each window has (window_size + window_overlap) samples. Overlapping
% samples are shared with a window's neighbors.
%
% Data at the end of the set that does not fit squarely within a window is
% cut off.
window_size = 25 - 8;
window_overlap = 8;

% An experimental feature that ensures that all classes have approximately
% the same number of examples. The idea is that the SVM can no longer rely
% on the overwhelming likelihood of one class over another.
% cull_overly_frequent_classes = true;

%% Load and preprocess data
[accel, times, label_times, label_names] = ... 
    load_accel_slice_windowed(slice_name, window_size, window_overlap);

%% Make features
features = generate_features(accel, true);

% Normalize features to [-1, 1]
for col = 1:size(features, 2)
    feat = features{:, col};
    fmax = max(feat);
    fmin = min(feat);
    features{:, col} = 2 * (feat - fmin) / (fmax - fmin) - 1;
end

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

% Print precision, recall, and confusion matrix
% precision = P(is true | was thought to be true)
% recall = P(was thought to be true | is true)

