function [ accel_out, times_out, label_times, label_names ] = ...
    load_accel_slice( slice_names )
%LOAD_ACCEL_SLICE Convert a slice structure into accelerometer and labeling
%data. slice_names is a cell array containing the names of the slices you
%want (or just a string)
load('ACCEL.MAT', 'all_accel', 'all_times');
load('SLICES.MAT', 'TIME_SLICES');

if ~iscell(slice_names)
   slice_names = {slice_names}; 
end

% average turn duration:
%   - mean = 2.1s
%   - std  = 0.8s

accel_out = [];
times_out = [];
label_times = [];
label_names = {};

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
    end
    
    data_set = slice.data_set;
    accel = all_accel.(data_set);
    times = all_times.(data_set);
    
    in_frame = (times >= start_time) & (times <= end_time);
    new_accel = accel(in_frame, :);
    new_times = times(in_frame, :);
    
    accel_out = [accel_out ; new_accel];
    times_out = [times_out ; new_times];
end

end

