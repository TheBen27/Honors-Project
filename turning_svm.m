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
roc_thresholds = linspace(0, 1, 1500);

% Percent of data that goes to the training set; the rest goes to
% the test set.
training_set_portion = 0.7;

% Number of bootstrap classifiers to create
% Each classifier is made from a sample taken with replacement from the
% original training set, with majority classes undersampled until they
% match minority classes.
bootstrap_samples = 7;
bootstrap_ratio = 10.0;
bootstrap_classes = {'clockwise', 'anticlockwise'};

undersample_straight_swimming = true;

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

%% Make feature table
disp("Generating features...");

means = feature_means_extreme(accel);
odba = feature_odba(dynamic_accel);
[pitch, roll] = feature_pitch_and_roll(accel, static_accel);

[tail_distinct, tail_freq] = feature_tailbeat(accel, 25, 0.8, 1.6);

features = table(...
    means(:,1), ...
    means(:,2), ...
    means(:,3), ...
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

%% Split and Preprocess Data
disp("Generating sample sets...");
% Shuffle features/labels to randomize training set and test set
rand_inds = randperm(height(features));
r_features = features(rand_inds, :);
r_labels = label_names(rand_inds);

% Split into training set and test set
training_size = floor(length(label_names) * training_set_portion);
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

% Create bootstrap samples for classifiers
% Matlab does not support 3D tables, so we will use cell arrays instead
bootstrap_features = cell(bootstrap_samples, 1);
bootstrap_labels = cell(bootstrap_samples, 1);
for i=1:bootstrap_samples
   [bfs, bls] = ...
        make_bootstrap_sample(training_features, training_labels, ...
        bootstrap_ratio, bootstrap_classes);
   bootstrap_features{i} = bfs;
   bootstrap_labels{i} = bls;
end

disp("Bootstrap sample amounts:");
for ci=1:length(label_categories)
    cat = label_categories{ci};
    disp(cat + ": " + sum(bootstrap_labels{1} == cat));
end

%% Generate classifier
disp("Training classifiers...");

% Train and predict
svm_template = templateSVM('KernelFunction', 'Gaussian');

bootstrap_probabilities = zeros(height(test_features), ...
    length(label_categories), bootstrap_samples);
bootstrap_predictions = repmat(test_labels(1), height(test_features), bootstrap_samples);
for i=1:bootstrap_samples
   disp("Fitting bootstrap " + i + "...");
   trainer = fitcecoc(bootstrap_features{i}, bootstrap_labels{i}, ...
       'FitPosterior', 1, 'Learners', svm_template);
   [bootstrap_predictions(:,i), ~, ~, ...
       bootstrap_probabilities(:,:,i)] = predict(trainer, test_features);
end

%% Get general confusion matrix
% Use majority vote to make predictions
prediction_counts = zeros(length(bootstrap_predictions), length(label_categories));
for i=1:length(label_categories)
    prediction_counts(:,i) = sum(bootstrap_predictions == label_categories{i}, 2);
end
[~, predictions] = max(prediction_counts, [], 2);
predictions = categorical(label_categories(predictions));

% Find information about a class
true_pos_preds  = zeros(4, 1);
false_pos_preds = zeros(4, 1);
true_neg_preds  = zeros(4, 1);
false_neg_preds = zeros(4, 1);
for i=1:length(label_categories)
    cat = label_categories{i};
    disp(cat);
    disp("=======");
    true_pos_preds(i)  = sum(predictions == cat & test_labels == cat);
    false_pos_preds(i) = sum(predictions == cat & test_labels ~= cat);
    true_neg_preds(i)  = sum(predictions ~= cat & test_labels ~= cat);
    false_neg_preds(i) = sum(predictions ~= cat & test_labels == cat);
    
    total = length(test_labels);
    confusion_matrix = table(...
        [true_neg_preds(i); false_neg_preds(i)], ...
        [false_pos_preds(i); true_pos_preds(i)], ...
        'VariableNames', {'Not_Predicted', 'Predicted'}, ...
        'RowNames', {'Not_Actual', 'Actual'});
    disp(confusion_matrix);
    
    precision = true_pos_preds(i) / (true_pos_preds(i) + false_pos_preds(i));
    recall = true_pos_preds(i) / (true_pos_preds(i) + false_neg_preds(i));
    disp("Precision: " + precision);
    disp("Recall: " + recall);
    disp("");
end

%% Plot ROC Curves
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
full_thresh = repmat(full_thresh, [size(bootstrap_probabilities(:,:,1)), 1]);

% Generate predictions for each threshold by majority vote with bootstrap
% samples. The final array is (MxCxT), matching full_thresh
full_positives = zeros(size(full_thresh));
for i=1:bootstrap_samples
    probs = bootstrap_probabilities(:,:,i);
    full_probs = repmat(probs, 1, 1, length(roc_thresholds));
    full_positives = full_positives + (full_probs >= full_thresh);
end
full_positives = (full_positives > (bootstrap_samples / 2));
 
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

% TP Rate = recall
% Probability that the class is correctly detected out of the total number
% of positives detected
true_positive_rate = true_positives ./ (true_positives + false_negatives);
% FP Rate = fall-out, "probability of false alarm"
% Probability of a class incorrectly detected out of the total number of
% negatives detected
false_positive_rate = false_positives ./ (false_positives + true_negatives);

hold on
stairs(false_positive_rate, true_positive_rate, "-*");
plot([0,1], [0,1],'--');
legend(label_categories, 'Location', 'southeast');
xlabel("False Positive Rate");
ylabel("True Positive Rate");
hold off

%% Area Under Curve Calculations
% The area under the ROC curve represents "discrimination" - the chance
% that, given one random positive sample and random one negative sample,
% the positive sample will be higher rated than the negative one.
%
% As threshold increases, FP and TP rate both decrease, though at different
% rates. The area of a single bar between two thresholds is:
%
% (TP rate of current threshold) * (FP rate of current threshold - FP rate of next threshold)
next_fp = false_positive_rate(2:length(false_positive_rate), :);
next_fp(length(next_fp)+1, :) = 1;

auc = sum(true_positive_rate .* (false_positive_rate - next_fp));
disp("AUROCs");
disp("======");
for i=1:length(label_categories)
   cat = label_categories{i};
   disp(cat + ": " + auc(i));
end
