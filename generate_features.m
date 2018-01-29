function [feature_table] = generate_features(accel, save_csv)

means = feature_means(accel);
means_x = means(:,1);
means_y = means(:,2);
means_z = means(:,3);

means_extreme = feature_means_extreme(accel);
means_ex_x = means_extreme(:,1);
means_ex_y = means_extreme(:,2);
means_ex_z = means_extreme(:,3);

[pitch, roll] = feature_static_accel(accel, 25, 3, 0.6);
tails = feature_tailbeat(accel, 1024, 25, 0.8, 1.6);

feature_table = table(means_x, means_y, means_z, ...
    means_ex_x, means_ex_y, means_ex_z, ...
    tails(:, 1), tails(:, 2), tails(:, 3), pitch, roll);

if save_csv == true
    writetable(feature_table, "features.csv");
end

end

