function [new_features, new_labels] = make_bootstrap_sample(...
    features, labels, ratio, majority_classes)
%MAKE_BOOTSTRAP_SAMPLE Take n times samples with replacement
% Majority classes is a cell array of classes that will be
% undersampled until they match the average size of the "minority classes"

% Generate new sample with replacement
n_samples = floor(height(features) * ratio);
new_inds = 1 + floor(rand(n_samples, 1) * height(features));
new_features = features(new_inds, :);
new_labels = labels(new_inds);

% Amount of samples to get for each class =
%  X
% For each class:
%   Find the samples matching the class
%   Select N of those
%   Only return those

if ~isempty(majority_classes)
    % Figure out how many samples to get for each class.
    minority_classes = setdiff(categories(new_labels), majority_classes);
    minority_samples = 0;
    for ci=1:length(minority_classes)
       minority_samples = minority_samples + sum(new_labels == minority_classes{ci}); 
    end
    minority_samples = floor(minority_samples / length(minority_classes));
    
    % Undersample majority classes
    inds_to_delete = [];
    for ci=1:length(majority_classes)
        klass = majority_classes{ci};
        majority_samples = find(new_labels == klass);
        to_delete = length(majority_samples) - minority_samples;
        inds_to_delete = [inds_to_delete ; majority_samples(1:to_delete)];
    end
    
    new_features(inds_to_delete, :) = [];
    new_labels(inds_to_delete, :) = [];
end