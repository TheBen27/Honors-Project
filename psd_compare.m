
[accel_straight] = load_accel_slice('one-revolution');
[accel_turn] = load_accel_slice('rturn-2');

asz = accel_straight(:,3);
atz = accel_turn(:,3);

arr_length = max([length(asz), length(atz)]);
asz = padarray(asz, max(0, arr_length - length(asz)), 'post');
atz = padarray(atz, max(0, arr_length - length(atz)), 'post');
hann = hanning(arr_length);
nfft = [];
sample_rate = 25;

hold on
periodogram([asz, atz], hann, nfft, sample_rate);
legend('Clockwise', 'Right Turn');
title('Power Spectral Density of Two Behaviors');
hold off