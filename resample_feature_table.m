function [new_features, new_labels] = resample_feature_table(...
    features, labels, minority_classes, ...
    smote_amt, smote_k, minor_ratio, major_ratio, ...
    balance_minor, balance_major)
% New resampling technique combining bootstrap sampling and SMOTE
%
% minor_ratio% of minority classes are sampled without replacement,
% avoiding duplicates; minor_ratio should be less than or equal to 1
%
% minority classes are then smote'd to generate smote_amt new samples
% for each existing sample
%
% we then pull n majority class samples from features with replacement
% in accordance with traditional bootstrap sampling

assert(minor_ratio <= 1.0);
assert(smote_amt <= smote_k);

% Separate features/labels into minority and majority classes
in_minority = zeros(size(labels));
for ci=1:length(minority_classes)
    in_minority = in_minority | (labels == minority_classes{ci});
end

% Pull out a subset of minority samples
% We shuffle the samples we pull out to avoid taking certain time frames
n_minors = max(1, floor(sum(in_minority) * minor_ratio));
minor_inds = find(in_minority);
minor_inds = minor_inds(randperm(length(minor_inds), n_minors));

minor_features = features(minor_inds, :);
minor_labels = labels(minor_inds);

% Smote each minority class separately
for ci=1:length(minority_classes)
   c = minority_classes{ci};
   cf = features(minor_labels == c, :);
   new_features = smote(cf, smote_k, smote_amt);
   minor_features = [minor_features ; new_features];
   
   new_labels = categorical(repmat(cellstr(c), height(new_features), 1));
   minor_labels = [minor_labels ; new_labels];
end

if balance_minor
    % Downsample minority classes to smallest class size
    min_minority_samples = 2^64;
    for ci=1:length(minority_classes)
        s = sum(minority_classes{ci} == minor_labels);
        min_minority_samples = min(min_minority_samples, s);
    end

    % TODO Add shuffling?
    to_remove = [];
    for ci=1:length(minority_classes)
       in_c = find(minority_classes{ci} == minor_labels);
       % this form of indexing takes away smoted samples first
       in_c = in_c((min_minority_samples+1):end);
       to_remove = [to_remove ; in_c];
    end
    minor_features(to_remove, :) = [];
    minor_labels(to_remove, :) = [];
end

% Pull majority samples with replacement, ensuring balance
major_features = [];
major_labels = [];
majority_classes = setdiff(categories(labels), minor_labels);
class_size = length(minor_labels) / length(minority_classes);
for ci=1:length(majority_classes)
   c = majority_classes(ci);
   in_c = find(labels == c);
   in_c = in_c(1:class_size);
   major_features = [major_features ; features(in_c, :)];
   major_labels = [major_labels ; labels(in_c)];
end

% Make the shuffled concatenation of majority and minority inds
new_features = [major_features ; minor_features];
new_labels = [major_labels ; minor_labels];
shuffled = randperm(length(new_labels));
new_features = new_features(shuffled, :);
new_labels = new_labels(shuffled);

% Debug prints
disp("Total sample size: " + height(new_features));
disp("Majority samples: " + height(major_features));
disp("Minority samples: " + height(minor_features));

label_cats = categories(labels);
for ci=1:length(label_cats)
    disp(label_cats{ci} + ": " + sum(label_cats{ci} == new_labels));
end

assert(height(major_features) == length(major_labels));
assert(height(minor_features) == length(minor_labels));

end