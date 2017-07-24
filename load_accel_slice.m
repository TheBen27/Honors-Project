function [ accel, times, label_times, label_names ] = load_accel_slice( slice )
%LOAD_ACCEL_SLICE_LABELE Convert a slice structure into real data.
% slice_struct is a struct defined in SLICES.MAT
load ACCEL.MAT
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

