function cat_durations = get_behavior_freqs(label_times, label_names)

    durations = label_times(2:end) - label_times(1:(end-1));
    duration_names = categorical(label_names(1:(end-1)));
    
    cats = unique(label_names);
    cat_durations = repmat(duration(), length(cats), 1);
    for ci=1:length(cats)
        cat = cats{ci};
        cat_durations(ci) = ...
            cat_durations(ci) + sum(durations(cat == duration_names));
    end
    
end