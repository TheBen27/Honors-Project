function [accel, times, start_time] = import_data(filename, add_start_time)
  % First, read the metadata to figure out what the start time is.
  % This is on the third line of the file:
  % ;Start_time, 2017-06-15, 09:00:06.461
  fid = fopen(filename);
  if fid == -1
      printf(['Error: could not read ' filename '\n']);
  end
  fgetl(fid);
  fgetl(fid);
  matches = ...
    regexp(fgetl(fid), ';Start_time, ([0-9\-]*, [0-9:\.]*)', 'tokens');
  start_time = datetime(matches{1}, 'InputFormat', 'yyyy-MM-dd, HH:mm:ss.SSS');
  fclose(fid);
  
  %options = detectImportOptions(filename, 'CommentStyle', ';');
  data = readtable(filename, 'CommentStyle', ';');
  times = seconds(data.Var1);
  if add_start_time
      times = start_time + seconds(data.Var1);
  end
  
  accel = [data.Var2 , data.Var3 , data.Var4];
end