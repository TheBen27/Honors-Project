%% Initial Setup
% Converts the CSVs in Accelerometer into ACCEL.MAT for quick loading.
% Run this before doing anything else.

folders = dir('Accelerometer');
all_accel = struct();
all_times = struct();
for fi = 3:length(folders) % skip . and ..
    dirname = folders(fi).name;
    
    files = dir(strcat('Accelerometer/', dirname));
    accel = [];
    times = [];
    
    for fj=3:length(files)
        fname = files(fj,1).name;
        [new_accel, new_times] = import_data(strcat('Accelerometer/', dirname, '/', fname), true);
        accel = [accel ; new_accel];
        times = [times ; new_times];
    end
    
    all_accel.(dirname) = accel;
    all_times.(dirname) = times;
end

save('ACCEL.MAT', 'all_accel', 'all_times');
