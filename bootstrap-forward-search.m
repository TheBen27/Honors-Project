% Special use of custom data

training_data = readtable('Features/training-standard.csv');
%test_data = readtable('Features/test-standard.csv');

% As stupid as it is, we need to convert from tables to arrays and back
% to use sequentialfs
training_features = table2array(training_data(:,1:(end-1)));
training_labels = categorical(training_data{:,end});

%test_features = table2array(test_data(:,1:(end-1)));
%test_labels = categorical(test_data{:,end});

c = cvpartition(training_labels,'k',5);
opts = statset('display','iter');

[a, b] = sequentialfs(@get_criterion, training_features, ...
    training_labels, 'cv', c, 'options', opts)

function crit = get_criterion(train_f, train_l, test_f, test_l)
    
    train_f = array2table(train_f);
    test_f = array2table(test_f, 'VariableNames', train_f.Properties.VariableNames);

    [cm, ~, ~] = turning_svm(...
        'show_plots', false, ...
        'feature_whitelist', false, ...
        'use_custom_data', true, ...
        'training_features', train_f, ...
        'training_labels', train_l, ...
        'test_features', test_f, ...
        'test_labels', test_l...
    );
    
    cm = table2array(cm);
    tps = sum(diag(cm));
    crit = sum(cm(:)) - tps;
end