function plot_labels( inds, names )
%PLOT_LABELS Draw vertical lines + names on the current figure
% If names's length is less than inds's, it's okays's's
if isempty(inds)
   return 
elseif (size(inds, 2) == 1) % column vector
    xs = [inds' ; inds'];
else % row vector
    xs = [inds ; inds];
end

f = gcf();
y = f.CurrentAxes.YLim';
ys = repmat(y, 1, length(inds));

line(xs, ys, 'Color', 'Yellow');

txs = xs(1, 1:length(names));
tys = ys(2, 1:length(names));
text(txs, tys, names);

end

