% Import all accelerometer CSVs into one .mat file
files = dir('Accelerometer');
files = files(3:end); % skips . and ..
accel = []; % n x 3
times = []; % n x 1
for fi=1:size(files,1)
  fname = files(fi,1).name;
  [new_accel, new_times] = import_data(['Accelerometer/' fname], true);
  accel = [accel ; new_accel];
  times = [times ; new_times];
end
save('ACCEL.MAT', 'accel', 'times');
