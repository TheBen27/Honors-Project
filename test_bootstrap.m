feats = table((1:4)');
labels = categorical({'a', 'b', 'c', 'd'})';

[~, no_undersample] = make_bootstrap_sample(feats, labels, 2000.0, []);
[~, undersample] = make_bootstrap_sample(feats, labels, 2000.0, categorical({'a','b','c'})');

no_under_as = sum(no_undersample == 'a') / length(no_undersample);
under_as = sum(undersample == 'a') / length(undersample);
disp("A | No undersampling: " + 100 * no_under_as + "%");
disp("  | Undersampling: " + 100 * under_as + "%");
disp("-----");

no_under_bs = sum(no_undersample == 'b') / length(no_undersample);
under_bs = sum(undersample == 'b') / length(undersample);
disp("B | No undersampling: " + 100 * no_under_bs + "%");
disp("  | Undersampling: " + 100 * under_bs + "%");
disp("-----");

no_under_cs = sum(no_undersample == 'c') / length(no_undersample);
under_cs = sum(undersample == 'c') / length(undersample);
disp("C | No undersampling: " + 100 * no_under_cs + "%");
disp("  | Undersampling: " + 100 * under_cs + "%");
disp("-----");

no_under_ds = sum(no_undersample == 'd') / length(no_undersample);
under_ds = sum(undersample == 'd') / length(undersample);
disp("D | No undersampling: " + 100 * no_under_ds + "%");
disp("  | Undersampling: " + 100 * under_ds + "%");
