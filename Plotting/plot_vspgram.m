function [Braw, tx, h] = plot_vspgram(waveform,fs,p,newFig)
%% mask to highlight f0 and harmonics, using the smoothed f0
% returns:
%   h = figure handle

if ~exist('p','var'); p = struct(); end
if ~isfield(p,'fstep'); p.fstep=5; end      % frequency resolution of initial spectrogram (Hz)
if ~isfield(p,'tinc'); p.tinc = 0.01; end   % maximum frequency of initial spectrogram (Hz)
if ~isfield(p,'fmax'); p.fmax=8000; end     % default frame increment (s)
if ~isfield(p,'fmin'); p.fmin=0; end     % default frame increment (s)
if ~exist('newFig','var'), newFig = 0; end

% spectrogram       
fres = 20; %bandwidth, from fxpefac
fmin = p.fmin;
faxis_spec = [fmin p.fstep p.fmax];
[tx,F,B,~,Brawfilt,spec] = spgrambw(waveform,fs,fres,faxis_spec,[],p.tinc); %run this line to extract some parameters

% Voicebox Spectrogram
[sf,~]=enframe(waveform,spec.win,spec.ninc);
frameLen = length(spec.win);
Braw=rfft(sf,frameLen,2);
Braw = Braw';
Bmag = abs(Braw);
fxraw = [0:frameLen-1]/frameLen*fs;
fxraw = fxraw(1:frameLen/2);

if newFig,  h = figure; end
imagesc(tx,fxraw,20*log(Bmag));
set(gca,'ydir','normal')
ylim([0,8000])
title('magnitude')
hold on;
