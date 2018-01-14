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

% Thresholds for the ROC curve to check.
% Should be a row vector.
roc_thresholds = linspace(0, 1, 30);

%% Load and preprocess data
[accel, times, label_times, label_names] = ... 
    load_accel_slice_windowed(slice_name, window_size, window_overlap);

label_categories = categories(label_names);

% Give a summary of the base probabilities of each label
disp("");
disp("BASE FREQUENCIES");
for cat_i = 1:length(label_categories)
    cat = label_categories{cat_i};
    cat_pos = sum(label_names == cat);
    cat_perc = cat_pos / length(label_names);
    disp(cat + ": " + cat_pos + "/" + length(label_names) + ...
        " (" + cat_perc * 100 + "%)");
end

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

[tail_distinct, tail_freq] = feature_tailbeat(accel, 25, 0.8, 1.6);

features = table(...
    means_x, means_y, means_z, ...
    odba,...
    tail_distinct(:, 1), ...
    tail_distinct(:, 2), ...
    tail_distinct(:, 3), ...
    tail_freq(:, 1), ....
    tail_freq(:, 2), ....
    tail_freq(:, 3), ....
    pitch, roll...
);
features.Properties.VariableNames = {...
    'means_x', 'means_y', 'means_z', ...
    'odba', ...
    'distinctiveness_x', 'distinctiveness_y', 'distinctiveness_z', ...
    'frequency_x', 'frequency_y', 'frequency_z', ...
    'pitch', 'roll'
};

% Shuffle features/labels to randomize training set and test set
rand_inds = randperm(height(features));
r_features = features(rand_inds, :);
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

% If the standard deviation of any column is 0, we get zerodiv errors
if any(training_std == 0)
    warning("One of your features has a standard deviation of 0. Standardizing to 0...");
    training_features{:, training_std == 0} = 0;
    test_features{:, training_std == 0} = 0;
end

% Save features
writetable([training_features, table(training_labels)], ...
            "Features/training-standard.csv");
writetable([test_features, table(test_labels, ...
            'VariableNames', {'training_labels'})], ...
            "Features/test-standard.csv");

% Train and predict
svm_template = templateSVM('KernelFunction', 'Gaussian');

svm_trainer = fitcecoc(training_features, training_labels, 'FitPosterior', 1, 'Learners', svm_template);
[training_predictions, ~, ~, training_probabilities] = ...
    predict(svm_trainer, training_features);
[test_predictions, ~, ~, test_probabilities] = ...
    predict(svm_trainer, test_features);

% ROC Curves
% An ROC curve for a given class plots TP rate against FP rate for various
% thresholds between 0 and 1. A perfect ROC curve will go straight up
% the Y axis and along the X axis; a perfectly awful ROC curve will
% sit on the diagonal.
%
% In this case, TP rate is TP / (TP + FN)
% FP rate is FP / (FP + TN)
% 
% We can use this to select a model that maximizes TP and minimizes FP.
% In our case, we want a high true positive rate for turning and a low
% FP rate for straight swimming.
% 
% The classifier's general performance is its AUC - area under the curve.
% The AUC of a coin-flipping monkey is 0.5, so if your AUC is under 0.5
% it's possible that the classifier is finding a relationship that is
% the opposite of what is expected.

% M = number of test examples
% C = number of classes
% T = number of thresholds

% full_thresh is (MxCxT)
% roc_thresholds is (1xT)
full_thresh = permute(roc_thresholds, [1, 3, 2]);
full_thresh = repmat(full_thresh, [size(test_probabilities), 1]);

% full_probs is (MxCxT)
% test_probabilities is (MxC)
full_probs = repmat(test_probabilities, 1, 1, length(roc_thresholds));
full_positives = (full_probs >= full_thresh);

% Now we want to expand each test_label from a categorical array into a 
% full array.
test_positives = false(size(full_positives));
for i = 1:length(label_categories)
    col = (test_labels == label_categories{i});
    test_positives(:,i,:) = repmat(col, 1, 1, length(roc_thresholds));
end


full_positives = permute(full_positives, [3, 2, 1]);
test_positives = permute(test_positives, [3, 2, 1]);

true_positives = sum(full_positives & test_positives, 3);
false_positives = sum(full_positives & ~test_positives, 3);
true_negatives = sum(~full_positives & ~test_positives, 3);
false_negatives = sum(~full_positives & test_positives, 3);

true_positive_rate = true_positives ./ (true_positives + false_negatives);
false_positive_rate = false_positives ./ (false_positives + true_negatives);

plot(true_positive_rate, false_positive_rate);
legend(label_categories);
xlabel("True Positive Ratio");
ylabel("False Positive Ratio");

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
precisions = zeros(size(label_categories));
recalls = zeros(size(label_categories));

for i=1:length(label_categories)
    cat = string(label_categories{i});
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

results = table(label_categories, precisions, recalls);
results.Properties.VariableNames = {'Classes', 'Precision', 'Recall'};
disp(results);
