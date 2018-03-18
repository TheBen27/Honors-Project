%% Compute label times for each shark
% Doesn't check for redundant or test slices

%load('SLICES.MAT', 'TIME_SLICES')
slices = struct2table(TIME_SLICES);

slices.durations = slices.end_time - slices.start_time;
sets = unique(slices.data_set);

for si=1:length(sets)
    s = sets{si};
    in_set = all(char(slices.data_set) == s, 2);
    total_duration = sum(slices.durations(in_set));
    disp(s + ": " + char(total_duration));
end