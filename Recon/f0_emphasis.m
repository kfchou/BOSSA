function recon = f0_emphasis(preprocessed_stim,fs,maskingParams,debugParam)
% recon = f0_emphasis(preprocessed_stim,fs,maskingParams)
%   f0 estimated from vocoded sounds appear discrete, and sounds unnatural.
%   this function smoothes the f0 estimates of the voiced regions, and
%   computes a mask to emphasize the harmonics of the smoothed f0.
%   will sound sound more natural?
% Inputs:
%   preprocessed_stim: stimulus to be processed
%   fs: sampling freq
%   maskingParams: define the following fields:
%       .nHarmonics - number of harmonics;
%       .smoothing - smoothing function, hamming(10) by default;
%       .attenuation - default is 0.00001;
%       .region - 'v' to mask only the voiced regions;
%       .fcutoff - for piecewise construction; defualt to 1500Hz
%
%

if ~isfield(maskingParams,'fcutoff'), maskingParams.fcutoff = 1500; end
if debugParam.plotting == 0, pefacPlotOption = []; end
%% f0 estimation first:
%1. PEFAC
p.flim = [60 350];
if debugParam.plotting == 1, figure; end
[f0x,tx,pv,fv,p]=fxpefac(preprocessed_stim,fs,1/fs*100,pefacPlotOption,p);
%tx = time at center of frames
%fx = corresponding pitch estimates

%2. Fit fx to normal distribution, calculate mu+/-1.96*sigma
if debugParam.plotting == 1
    figure;
    histfit(f0x,round(range(f0x))); %fit normal distribution to fx (visualize) 
end
pd = fitdist(f0x,'Normal');

%3. updated frequency range for PEFAC, and run PEFAC again
% p.flim = [pd.mu-pd.sigma*1.96 pd.mu+pd.sigma*1.96]; 
p.flim = [pd.mu-pd.sigma*1.5 pd.mu+pd.sigma*1.5]; 
if debugParam.plotting == 1, figure; end
[f0x,tx,pv,fv,p]=fxpefac(preprocessed_stim,fs,1/(4*mean(f0x)),pefacPlotOption,p);

thresh = 0.4;
mf0x = mean(f0x(pv>thresh));
f0x(f0x==0) = max(f0x);
%% find voiced regions
transitions = diff(pv>thresh);
[voicedEdges]=find(transitions);
if transitions(voicedEdges(1)) == -1
    voicedEdges = [1; voicedEdges];
end

% remove regions too short in length
truncatedVE = voicedEdges;
for i = 1:length(truncatedVE)-1
    if truncatedVE(i+1) - truncatedVE(i) < 20
        truncatedVE(i) = 0;
        truncatedVE(i+1) = 0;
        i = i+1;
    end
end
truncatedVE(truncatedVE==0) = [];
if transitions(truncatedVE(1))
    truncatedVE = [1; truncatedVE];
end

%% perform smoothing
f0xSmoothed = medfilt1(f0x,60);
% f0xSmoothed = smooth(f0xSmoothed,20);
if mod(length(truncatedVE),2)==1, truncatedVE = [truncatedVE; length(f0x)]; end
for i = 1:2:length(truncatedVE)
    f0xSmoothed(truncatedVE(i:i+1)) = smooth(f0x(truncatedVE(i:i+1)),30);
end

% plot
if debugParam.plotting
    figure;
    subplot(2,1,1);
    plot(tx(pv>thresh),f0x(pv>thresh),'o'); hold on;
    plot(tx(pv<thresh),f0x(pv<thresh),'o')
    title('pre-smoothing')

    subplot(2,1,2);
    plot(tx(pv>thresh),f0xSmoothed(pv>thresh),'o'); hold on;
    plot(tx(pv<thresh),f0xSmoothed(pv<thresh),'o')
    title('post-smoothing')

    % highlight voiced regions
    mf0x = max(f0x)+50;
    subplot(2,1,1)
    if mod(length(voicedEdges),2)==1, voicedEdges = [voicedEdges; length(f0x)]; end
    for i = 1:2:length(voicedEdges)
        harea = area(tx(voicedEdges(i:i+1)),[mf0x mf0x], 100,'LineStyle', 'none');
        set(harea, 'FaceColor', 'r')
        alpha(0.25)
    end

    subplot(2,1,2)
    if mod(length(truncatedVE),2)==1, truncatedVE = [truncatedVE; length(f0x)]; end
    for i = 1:2:length(truncatedVE)
        harea = area(tx(truncatedVE(i:i+1)),[mf0x mf0x], 100,'LineStyle', 'none');
        set(harea, 'FaceColor', 'r')
        alpha(0.25)
    end
end
%% fit the voiced regions to a polynomial?
% voicedIdx = zeros(size(f0x));
% f0xFitted = zeros(size(f0x));
% 
% for i = 1:2:length(truncatedVE)-1
%     currentIdx = truncatedVE(i):truncatedVE(i+1);
% %     voicedIdx(currentIdx) = 1;
%     pp = polyfit(tx(currentIdx),f0x(currentIdx),4);
%     f0xFitted(currentIdx) = polyval(pp,tx(currentIdx));
% end
% 
% hold on;
% plot(tx,f0xFitted,'linewidth',2);
%% mask to highlight f0 and harmonics, using the smoothed f0

% spectrogram
p.fstep=5;              % frequency resolution of initial spectrogram (Hz)
p.fmax=8000;            % maximum frequency of initial spectrogram (Hz)
fres = 20; %bandwidth, from fxpefac
fmin = 0;
faxis_spec = [fmin p.fstep p.fmax];
[tx,F,B,~,Brawfilt,spec] = spgrambw(preprocessed_stim,fs,fres,faxis_spec,[],p.tinc); %run this line to extract some parameters

% Voicebox Spectrogram
[sf,~]=enframe(preprocessed_stim,spec.win,spec.ninc);
frameLen = length(spec.win);
Braw=rfft(sf,frameLen,2);
Braw = Braw';
Bmag = abs(Braw);
fxraw = [0:frameLen-1]/frameLen*fs;
fxraw = fxraw(1:frameLen/2);
    
if debugParam.plotting
    figure;
    imagesc(tx,fxraw,20*log(Bmag));
    set(gca,'ydir','normal')
    ylim([0,8000])
    title('magnitude')
    hold on;
    plot(tx(pv>thresh),f0xSmoothed(pv>thresh),'o');
    plot(tx(pv<thresh),f0xSmoothed(pv<thresh),'o');
end
%% highlight energy at f0x, with a hamming window decay along frequency
temp = ones(size(Braw))*maskingParams.attenuation;
h = 1:maskingParams.nHarmonics;
blur = maskingParams.smoothing;
for i = 1:length(tx)
    [~,idx] = min(abs(fxraw-f0xSmoothed(i))); %use estimated f0
%     [~,idx] = min(abs(fxraw-f0xFitted(i))); %use fitted f0
    temp(idx*h,i) = 1;
end
temp1 = conv2(temp,blur,'same');
% temp2 = conv2(temp,hamming(50),'same');
% temp2 = temp2./max(max(temp2)).*max(max(temp1));
f0Mask = temp1;
if strcmp(maskingParams.region,'v')
    f0Mask(:,pv<thresh) = 1; %unvoiced -> no suppression
end
f0Mask(fxraw>maskingParams.fcutoff,:) = 1;

% apply mask to spectrogram
BmagThresh = Bmag;
Bmagf0 = BmagThresh.*f0Mask;

% re-synthesize
phi = angle(Braw);
s_n = Bmagf0.*exp(1j*phi);
temp = irfft(s_n',frameLen,2);
recon = overlapadd(temp,spec.win,spec.ninc);
recon = recon/max(abs(recon));

if debugParam.plotting
    figure; 
    imagesc(tx,fxraw,f0Mask);
    set(gca,'ydir','normal')
    ylim([0,8000])

    figure; imagesc(tx,fxraw,20*log(Bmagf0))
    set(gca,'ydir','normal')
    ylim([0,8000])
    title('f0mask emphasized')

    figure;imagesc(tx,fxraw,unwrap(phi,[],2))
    set(gca,'ydir','normal')
    title('unwrapped phase')
    ylim([0,8000])
end
disp('f0_emphasis complete')
%% score
% runStoi(preprocessed_stim,target,fs,fs)
% runStoi(recon,target,fs,fs)
% audiowrite('tmp1.wav',target,fs);
% audiowrite('tmp2.wav',preprocessed_stim,fs);
% audiowrite('tmp3.wav',recon/max(abs(recon)),fs);
% pq1 = pesqmain('+16000','tmp1.wav','tmp2.wav')
% pq2 = pesqmain('+16000','tmp1.wav','tmp3.wav')
