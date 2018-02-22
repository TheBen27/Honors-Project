[~, ~, label_times, label_names] = load_accel_slice('medley-2');

label_names = categorical(label_names);
cats = categories(label_names);
% durations = repmat(duration(), length(cats), 1);
for ti=2:length(label_times)
  diff = label_times(ti) - label_times(ti-1);
  cat = label_names(ti-1);
  durations(cat) = durations(cat) + diff;
end

total_time = sum(durations);
for ci=1:length(cats)
   disp(cats(ci) + ": " + char(durations(ci)) + ...
       " (" + durations(ci) / total_time * 100 + "%)");
end