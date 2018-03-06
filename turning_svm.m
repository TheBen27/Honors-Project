%% Simple SVM for Turning Detection
% A multiclass SVM for detecting turning.
% ... Well, it used to be simple, anyway.
%% Configuration

% Save the seed so we get consistent results
rng(3);

% Cell array of data slices to use. These should all be labeled.
slice_name = {...
    'many-turns', 'medley-1', 'medley-2', 'large-slice', 'small-slice', ...
    'rturn-fun', 'afternoon', 'precise', 'sb34-slice-1'...
};

sample_rate = 25;

% Each window has (window_size + window_overlap) samples. Overlapping
% samples are shared with a window's neighbors.
%
% Data at the end of the set that does not fit squarely within a window is
% cut off.
window_size = 20;
window_overlap = 16;

% Configuration of the butterworth filter dividing static and
% dynamic acceleration.
static_filter_order = 3;
static_filter_cutoff = 0.6;

% The cost of classifying a point into class j if its true class is i
classifier_cost = ones(4) - eye(4);
%~classifier_cost = ...
%~    ... L    R    A    C (Predicted class)
%~    [   0, 0.2,   5,   5; ... % L (Actual classs)
%~      0.2,   0,   5,   5; ... % R
%~        1,   1,   0, 0.2; ... % A
%~        1,   1, 0.2,   0];    % C

optimization_mode = 'none';

% Only include certain features
feature_whitelist = true;
included_features = {...
	'distinctiveness_y', ...
	'std_x', ...
	'std_y', ...
	'min_x', ...
	'max_z', ...
	'energy_x', ...
	'cor_xy', ...
	'min_y', ...
	'frequency_y' ...
};


% SVM Learning template
svm_template = templateSVM('KernelFunction', 'Gaussian');

% Thresholds for the ROC curve to check.
% Should be a row vector.
roc_thresholds = linspace(0, 1, 1500);

% Percent of data that goes to the training set; the rest goes to
% the test set.
training_set_portion = 0.8;

% Whether to use Principal Component Analysis, which converts
% the feature set such that certain features are known to have higher
% variance than others.
use_pca = false;
pca_threshold = 0.05;

% Number of bootstrap classifiers to create
% Each classifier is made from a sample taken with replacement from the
% original training set, with majority classes undersampled until they
% match minority classes.
resampling_method = 'resample'; % resample, bootstrap, none

% General params
bootstrap_samples = 11;

% Bootstrap params
bootstrap_ratio = 2.0;
bootstrap_majority_classes = {'clockwise', 'anticlockwise'};

% Resample parameters
bootstrap_minority_classes = {'L-turn', 'R-turn'};
smote_k = 6;
smote_amt = 3;
minor_ratio = 0.8;
major_ratio = 1.0;

if strcmp(resampling_method, 'none')
   bootstrap_samples = 1; 
end

undersample_straight_swimming = true;


%% Load and preprocess data
[accel, times, label_times, label_names, label_categories] = ... 
    load_accel_slice_windowed(slice_name, window_size, window_overlap);

raw_features = build_feature_table(accel, sample_rate, ...
    static_filter_order, static_filter_cutoff);

writetable([raw_features, table(label_names)], "Features/features-raw.csv");

features = table();

if feature_whitelist
    for wi=1:length(included_features)
       inc_feat = included_features{wi};
       features.(inc_feat) = raw_features.(inc_feat);
   end
else
   features = raw_features;
end

% PCA
if use_pca
   features_arr = table2array(features);
   [coeff, score, latent] = pca(features_arr);
   nfeats = find(latent < pca_threshold, 1) - 1;
   features = array2table(features_arr * coeff(:, 1:nfeats));
   disp("After PCA, has " + nfeats + " features");
end

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
if ~strcmp(resampling_method, 'none')
    bootstrap_features = cell(bootstrap_samples, 1);
    bootstrap_labels = cell(bootstrap_samples, 1);
    
    for bs=1:bootstrap_samples
        if strcmp(resampling_method, 'resample')
           [bootstrap_features{bs}, bootstrap_labels{bs}] = ...
                resample_feature_table(training_features, training_labels, ...
                bootstrap_minority_classes, smote_amt, smote_k, ...
                minor_ratio, major_ratio); 
        elseif strcmp(resampling_method, 'bootstrap')
           [bootstrap_features{bs}, bootstrap_labels{bs}] = ...
               make_bootstrap_sample(training_features, training_labels, ...
               bootstrap_ratio, bootstrap_majority_classes);
        else
            error(['Invalid resample method: ' resample_method]);
        end
    end
else
    bootstrap_features = {training_features};
    bootstrap_labels = {training_labels};
end

disp("Bootstrap sample amounts:");
for ci=1:length(label_categories)
    cat = label_categories{ci};
    disp(cat + ": " + sum(bootstrap_labels{1} == cat));
end

%% Generate classifier
disp("Training classifiers...");

bootstrap_probabilities = zeros(height(test_features), ...
    length(label_categories), bootstrap_samples);
bootstrap_predictions = repmat(test_labels(1), height(test_features), bootstrap_samples);
trainers = {};
for i=1:bootstrap_samples
   disp("Fitting bootstrap " + i + "...");
   trainer = fitcecoc(bootstrap_features{i}, bootstrap_labels{i}, ...
       'FitPosterior', 1, 'Learners', svm_template, ...
       'OptimizeHyperparameters', optimization_mode, ...
       'Cost', classifier_cost);
   trainers = [trainers, {trainer}];
   [bootstrap_predictions(:,i), ~, ~, ...
       bootstrap_probabilities(:,:,i)] = predict(trainer, test_features);
end

%% Get confusion matrix, simple predictive measures
% Make predictions from majority vote of bootstrap samples
prediction_counts = zeros(length(bootstrap_predictions), length(label_categories));
for i=1:length(label_categories)
    prediction_counts(:,i) = sum(bootstrap_predictions == label_categories{i}, 2);
end
[~, predictions] = max(prediction_counts, [], 2);
predictions = categorical(label_categories(predictions));

% We need to sanitize the class names so that they look like variables
% Not really comprehensive, but good enough for our purposes
san_label_categories = cell(size(label_categories));
for i=1:length(label_categories)
    name = label_categories{i};
    if isvarname(name)
        san_label_categories{i} = name;
    else
        name(name=='-' | name==' ') = '_';
        san_label_categories{i} = name;
    end
end

sa = zeros(length(label_categories), 1);
confusion_matrix = table(sa, sa, sa, sa, ...
    'VariableNames', san_label_categories, ...
    'RowNames', san_label_categories ...
);
for actual_i=1:length(label_categories)
   actual = label_categories{actual_i};
   for predicted_i=1:length(label_categories)
       predicted = label_categories{predicted_i};
       % Find the number of samples with the label {actual}
       % that were classified as {predicted} by the classifier
       actual_obvs = (test_labels == actual);
       predicted_obvs = (predictions == predicted);
       matches = sum(actual_obvs & predicted_obvs);
       confusion_matrix{actual_i,predicted_i} = matches;
   end
end
disp('Columns are predicted, rows actual');
disp(confusion_matrix);

precision = 0.0;
recall = 0.0;
accuracy = 0.0;
for i=1:length(label_categories)
    tps = confusion_matrix{i,i};
    tps_and_fps = sum(confusion_matrix{:,i});
    tps_and_fns = sum(confusion_matrix{i,:});
    precision = precision + tps / tps_and_fps;
    recall = recall + tps / tps_and_fns;
    %accuracy = (TP + TN) / (P + N)
    % TP = confusion_matrix{i,i};
    % TN = confusion_matrix{all but i, :} = length(test_labels) - tps_and_fns
    % P = sum(confusion_matrix{i, :}) == tps_and_fns
    % N = length(test_labels) - P
    tp = confusion_matrix{i,i};
    tn = length(test_labels) - tps_and_fns;
    p = tps_and_fns;
    n = length(test_labels) - p;
    accuracy = accuracy + (tp + tn) / (p + n);
end
precision = precision / length(label_categories);
recall = recall / length(label_categories);
accuracy = accuracy / length(label_categories);

disp("Macro-Averages");
disp("Precision: " + precision);
disp("Recall: " + recall);
disp("Accuracy: " + accuracy);

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

% Plot individual ROC Curves
hold on
stairs(false_positive_rate, true_positive_rate);
plot([0,1], [0,1],'--');
legend(label_categories, 'Location', 'southeast');
xlabel("False Positive Rate");
ylabel("True Positive Rate");
hold off

% Plot macro-average ROC curve
mean_false_positive_rate = mean(false_positive_rate, 2);
mean_true_positive_rate = mean(true_positive_rate, 2);
hold on
stairs(mean_false_positive_rate, mean_true_positive_rate);
plot([0,1], [0,1], '--');
title("Macro-Average ROC");
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
