% My attempt at making sense of fft

amp = 1; %V
freq = 10; %hz
sampleRate = 30*10; % oversampling factor of 30

t = 0:(1/sampleRate):(1/freq);
x = sin(2*pi*freq*t);

NFFT = 1024;
nf = (-NFFT/2 : NFFT/2-1) * sampleRate / NFFT;
fx = abs(fftshift(fft(x,NFFT)));
pfx = fx .* conj(fx) / (NFFT * length(x));
% Remove the negative frequencies
negs = nf < 0;
nf(negs) = [];
fx(negs) = [];
pfx(negs) = [];

% Plot sine wave and frequency vs. magnitude
figure;
subplot(3,1,1);
plot(t,x);
title("sine(t)");
xlabel("time");
ylabel("amplitude");

subplot(3,1,2);
plot(nf,fx);
title("fft");
xlabel("frequency");
ylabel("amplitude");

subplot(3, 1, 3);
plot(nf, pfx);
title("power fft");
xlabel("frequency");
ylabel("power");