%% New Classification Code
% This is a revision of the old classification code that replaces
% most of the home-grown solutions with built-in MATLAB code.
% This will likely make the code more correct and easier to
% expand.

%% Hackish feature import
% For now, just take the test/training set csvs and concatenate them
% Later, we will move some of the code from turning_svm.m into a separate
% function entirely
features = [readtable('Features/test-standard.csv') ; ...
    readtable('Features/training-standard.csv')];
labels_copy = features{:, width(features)};
pos_classes = {'L-turn', 'R-turn'};
neg_classes = {'clockwise', 'anticlockwise'};
%% Classification training and performance estimate

% Find weights to downsample or upsample different rows?
% Not QUITE sure what I'm doing here, which is never good.
%
% Apparently, weighting a CLASS makes the model more sensitive to that
% class, which is good. But we're weighting individual samples...
% I'm sure nothing bad will come of this.
cat_labels = categorical(features.training_labels);
minority_samples = cat_labels == 'L-turn' | cat_labels == 'R-turn';
majority_samples = ~minority_samples;
weights = ones(size(labels_copy));
weights(minority_samples) = (sum(majority_samples) / sum(minority_samples));

% Splits the data into K non-overlapping "folds". Each fold is
% used as the test set and the others as the training set
cp = classperf(labels_copy, 'Positive', pos_classes, 'Negative', neg_classes);
cross_inds = crossvalind('kfold', 1:height(features), 5);
for i=1:5
   test_inds = cross_inds == i;
   train_inds = ~test_inds;
   classifier = TreeBagger(64, features(train_inds,:), 'training_labels', 'Weights', weights(train_inds));
   preds = predict(classifier, features(test_inds,:));
   classperf(cp, preds, test_inds);
end

disp("Class labels: " + cp.ClassLabels)
disp("Sample distribution by class: " + cp.SampleDistributionByClass)
disp("Sensitivity: " + cp.Sensitivity)
disp("Specificity: " + cp.Specificity)