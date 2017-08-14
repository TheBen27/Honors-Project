function [ accel, times, label_times, label_names ] = load_accel_slice( slice_name )
%LOAD_ACCEL_SLICE Convert a slice structure into accelerometer and labeling
%data.
load('ACCEL.MAT', 'accel', 'times');
load('SLICES.MAT', 'TIME_SLICES');

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

disp(slice.description);

start_time = slice.start_time;
end_time   = slice.end_time;

if isempty(slice.labels_file)
    label_times = [];
    label_names = {};
else
   [label_times, label_names] = import_labels(slice.labels_file);
end

in_frame = find((times < start_time) + (times > end_time));
accel(in_frame,:) = [];
times(in_frame) = [];

end

