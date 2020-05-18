%%% This script contains a very basic demo of the DBSTOI/MBSTOI/NI-STOI 
%%% code. It takes a few minutes to run.

%% Generate some audio samples
% Clear
clear;
clc;

% Parameters
T = 2;              % Length of simulation. [s]
f_mod = 4;          % Modulation frequency of speech (see below). [Hz]
fs = 20000;         % Sampling rate. [Hz]
snrs = -30:3:30;    % SNR values at which to simulate. [dB]

% Use a square wave modulated noise as a crude approximation of speech
s = randn(1,T*fs) .* (0.1+(mod(0:1/fs:T-1/fs,1/f_mod)>0.5/f_mod));

% Generate two uncorrelated noises
n1 = randn(1,T*fs);
n2 = randn(1,T*fs);

%% DBSTOI/MBSTOI
corr_dbstoi = zeros(length(snrs),1);
corr_mbstoi = zeros(length(snrs),1);
uncorr_dbstoi = zeros(length(snrs),1);
uncorr_mbstoi = zeros(length(snrs),1);
for i=1:length(snrs)
   % Correlated speech
   xl = s;
   xr = s;
   
   % Correlated noise plus correlated speech
   yl = s + 10^(-snrs(i)/20) * n1;
   yr = s + 10^(-snrs(i)/20) * n1;
   corr_dbstoi(i) = dbstoi(xl,xr,yl,yr,fs);
   corr_mbstoi(i) = mbstoi(xl,xr,yl,yr,fs);
   
   % Uncorrelated noise plus correlated speech
   yl = s + 10^(-snrs(i)/20) * n1;
   yr = s + 10^(-snrs(i)/20) * n2;
   uncorr_dbstoi(i) = dbstoi(xl,xr,yl,yr,fs);
   uncorr_mbstoi(i) = mbstoi(xl,xr,yl,yr,fs);
end

% Plot results
figure();
plot(snrs,[corr_dbstoi,corr_mbstoi,uncorr_dbstoi,uncorr_mbstoi]);
title('DBSTOI/MBSTOI');
legend({'DBSTOI(corr)','MBSTOI(corr)','DBSTOI(uncorr)','MBSTOI(uncorr)'},...
       'location', 'northwest');
xlabel('SNR [dB]');
ylabel('SIP score')

%% NI-STOI
nistoi_wvad = zeros(length(snrs),1);
nistoi_nvad = zeros(length(snrs),1);
for i=1:length(snrs)
    nistoi_wvad(i) = nistoi(s,s+n1*10^(-snrs(i)/20),fs);
    nistoi_nvad(i) = nistoi_novad(s+n1*10^(-snrs(i)/20),fs);
end

% Plot results
figure();
plot(snrs,[nistoi_wvad,nistoi_nvad]);
title('NI-STOI');
legend({'NI-STOI','NI-STOI (no VAD)'},'location','northwest');
xlabel('SNR [dB]');
ylabel('SIP score');
