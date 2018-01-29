function [means] = feature_means_extreme(accel)
%FEATURE_MEANS_EXTREME Accentuate the turning factor here
%
% Basically, figure out if most of the samples are above or below 0.
% Then get the mean of the samples with the dominant sign.
% accel:  m [samples per window] x 3 [axes] x w [number of windows]
% times:  m x w
% means:  w x 1

% positives >= negatives
% total = positives + negatives
% negatives = total - positives
% positives >= total - positives
% 2 * positives >= total
positives = sum(accel > 0);
positives = permute(positives, [3, 2, 1]);
totals = size(accel,1);

has_more_positives = positives * 2 >= totals;
means = zeros(size(accel, 3), size(accel, 2));
for w=1:size(accel,3)
   win = accel(:,:,w);
   has_pos = has_more_positives(w,:);
   more_pos = mean(win(win>0));
   more_neg = mean(win(win<=0));
   % Ugly, but it works
   % Remember that mean([]) == NaN
   more_pos(isnan(more_pos)) = 0.0;
   more_neg(isnan(more_neg)) = 0.0;
   means(w,:) = (more_pos * has_pos) + (more_neg * ~has_pos);
end

end

