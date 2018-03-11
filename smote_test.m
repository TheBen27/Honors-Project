%% Test of Borderline SMOTE
% Tests what portion of minority samples would be considered as
% "dangerous" by the borderline-SMOTE test.
%
% Borderline-SMOTE only oversamples samples on the border between
% minority and majority samples. If all of a sample's neighbors are
% in the majority class, then it is noise; if it has more than half
% majority neighbors, it is considered "dangerous" and is oversampled.
% If it has fewer, it is not oversample.

% assume accel, label_names, label_times already exist
minority_classes = {'L-turn', 'R-turn'};
k = 5;

minority_inds = zeros(size(label_names));
for ci=1:length(minority_classes)
   c = minority_classes{ci};
   minority_inds = minority_inds | (label_names == c);
end

% The first neighbor found is always the sample itself
minority_neighbors = knnsearch(features{:,:}, features{minority_inds,:}, 'K', 1 + k);
minority_neighbors = minority_neighbors(:, 2:end);

n_majority_neighbors = sum(~minority_inds(minority_neighbors), 2);
hold on
histogram(n_majority_neighbors, k, 'BinWidth', 1);
xlim([0, k]);
hold off