% ILD
numChan = 64
low = 200
high = 8000
fs = 44100;
[nf,cf,bw] = getFreqChanInfo('erb',numChan,low,high);
ild = gen_ILD(low,high,numChan,fs);
itd = gen_ITD(low,high,numChan,fs);

figure;
plot(cf,ild,'LineWidth',2)
az = -90:45:90;
legend(cellstr(num2str(az')));
title(sprintf('ILD: %d to %d Hz, %d channels, gain = 500',low,high,numChan));
xlabel('CF')
ylabel('ILD')
set(gca,'xscale','log')
xticks([200, 500, 1000, 5000])
