function [ accel_out, times_out, label_times, label_names, cat_freqs ] = ...
    load_accel_slice( slice_names )
%LOAD_ACCEL_SLICE Convert a slice structure into accelerometer and labeling
%data. slice_names is a cell array containing the names of the slices you
%want (or just a string)
load('ACCEL.MAT', 'all_accel', 'all_times');
load('SLICES.MAT', 'TIME_SLICES');

if ~iscell(slice_names)
   slice_names = {slice_names}; 
end

accel_out = [];
times_out = [];
label_times = [];
label_names = {};

label_durations = containers.Map();

for slice_i = 1:length(slice_names)
    slice_name = slice_names{slice_i}; 
    
    % lookup the slice_name within TIME_SLICES
    slice = [];
    for i=1:length(TIME_SLICES)
        s = TIME_SLICES(i);
        name = s.name;
        if isequal(name, slice_name)
            slice = s;
            break;
        end
    end

    if isempty(slice)
        error(['Could not find data slice ' slice_name]);
    end

    disp('');
    disp(slice.description);

    start_time = slice.start_time;
    end_time   = slice.end_time;
    
    if ~isempty(slice.labels_file)
       [new_label_times, new_label_names] = import_labels(slice.labels_file);
       label_times = [label_times ; new_label_times];
       label_names = [label_names ; new_label_names];
       
       % We calculate the frequency of each time slice individually.
       % This eliminates issues with gaps between slices, among other
       % things
       new_label_durations = new_label_times(2:end) - new_label_times(1:end-1);
       assert(all(new_label_durations >= duration));
       
       new_duration_names = categorical(new_label_names(1:(end-1)));
       new_cats = categories(new_duration_names);
       for ci=1:length(new_cats)
          cat = new_cats{ci};
          cat_duration = sum(new_label_durations(new_duration_names == cat));
          if isKey(label_durations, cat)
              label_durations(cat) = label_durations(cat) + cat_duration;
          else
              label_durations(cat) = cat_duration;
          end
       end
    end
    
    data_set = slice.data_set;
    accel = all_accel.(data_set);
    times = all_times.(data_set);
    
    in_frame = (times >= start_time) & (times <= end_time);
    new_accel = accel(in_frame, :);
    new_times = times(in_frame, :);
    
    accel_out = [accel_out ; new_accel];
    times_out = [times_out ; new_times];
    
    if isempty(new_accel)
        error(['No accelerometer data loaded from ' slice.description]);
    end
    
end


total_duration = duration();
durs = label_durations.values; % cell array of duration arrays
for vi=1:length(durs)
    total_duration = total_duration + durs{vi}(1);
end

ks = label_durations.keys;
for ki=1:length(ks)
    k = ks{ki};
    dur = label_durations(k);
    disp([k, ': ', char(dur), ' (', num2str(100 * dur / total_duration), '%)']);
end

cat_freqs_cell = label_durations.values;
cat_freqs = repmat(duration, length(cat_freqs_cell), 1);
for ci=1:length(cat_freqs_cell)
    cat_freqs(ci) = cat_freqs_cell{ci};
end

end

