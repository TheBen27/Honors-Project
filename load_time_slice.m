function [accel, times] = load_time_slice(start_time, end_time)
% LOAD_TIME_SLICE Import a section of ACCEL.MAT

load ACCEL.MAT % Not to worry, this loads accel and time!
in_frame = find((times < start_time) + (times > end_time));
accel(in_frame,:) = [];
times(in_frame) = [];

end