function [new_features, new_labels] = make_bootstrap_sample(...
    features, labels, ratio, majority_classes)
%MAKE_BOOTSTRAP_SAMPLE Take n times samples with replacement
% Majority classes is a category array of classes that will be
% undersampled until they match the number of "minority classes".

% Generate new sample with replacement
n_samples = floor(height(features) * ratio);
new_inds = 1 + floor(rand(n_samples, 1) * height(features));
new_features = features(new_inds, :);
new_labels = labels(new_inds);

if ~isempty(majority_classes)
    % Undersample majority class.
    % The undersample ratio is the total number of majority class samples over
    % the total number of minority samples.
    major_samples = ismember(new_labels, majority_classes);
    undersample_ratio = (length(new_labels) - sum(major_samples)) / sum(major_samples);
    if undersample_ratio > 1.0
       error("Your majority classes are outweighed by your minority" + ...
           "classes. There's no need to undersample them."); 
    else
        % Get the indices of the majority class, undersample that array by
        % (1 - ratio), then delete remaining indices from the original array.

        major_inds = find(major_samples);
        major_inds(randperm(length(major_inds))) = major_inds;
        to_preserve = floor(length(major_inds) * undersample_ratio);
        major_inds(1:to_preserve) = [];

        new_features(major_inds, :) = [];
        new_labels(major_inds) = []; 
    end
end