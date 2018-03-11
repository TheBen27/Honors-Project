function [new_features] = smote(features, k, n)
% features is MxN array
% k is # nearest neighbors
% n is oversampling degree (n <= k)

% Convert table to matrix and save variable names
var_names = features.Properties.VariableNames;
features = table2array(features);

all_neighbors = knnsearch(features, features, 'K', k+1); % S x (k+1)
select_neighbors = zeros(length(all_neighbors), n);      % S x N
for r=1:length(all_neighbors)
   select_neighbors(r,:) = all_neighbors(r, randperm(k, n)+1); 
end

% Linearly interpolate between the originals and each neighbor
a = repmat(features, 1, 1, n); % S samples x C classes x N neighbors

% Expand the neighbor indices into neighbor elements
b = zeros(size(features, 1), size(features, 2), n);
for r=1:size(b, 1)
   b(r,:,:) = permute(features(select_neighbors(1,:),:), [3, 2, 1]); 
end

% c is the interpolating value between the two
c = repmat(rand(size(a, 1), 1, size(a, 3)), 1, size(a, 2), 1);

new_features = a + (b - a) .* c;
new_features = reshape(new_features, size(new_features, 3) * size(new_features, 1), size(new_features, 2), 1);
new_features = array2table(new_features, 'VariableNames', var_names);

end

