function [out,rstim] = recon_eval(data,target_wav,target_spatialized,mix_wav,params)
% performs stimulus reconstruction and objective intelligibility assessment on a set of spike trains
% out = recon_eval(data,target_wav,target_spatialized,mix_wav,params)
% Inputs:
%	data: a set of spike trains (from the IC for example)
%	target_wav_loc: full path to target.wav (str), or its waveform vector
%	target_spatialized_loc: full path to target_conv.wav, or its waveform
%	mix_wav_loc: full path to mixed.wav, or its waveform vector
%   params: structure with fields
%       .fs - mandatory, and either
%       -------- option 1: ------
%       .cf,
%       .coefs, or
%       -------- option 2: ------
%       .frgain
%       .low_freq
%       .high_freq
%       .numChannel
% Outputs:
%	out: STOI scores of three reconstruction methods
%   rstim: a structure of reconstructed stimuli, with fields
%       .r1d = rstim1dual;
%       .r1m = rstim1mono;
%       .r2d = rstim2dual;
%       .r2m = rstim2mono;
%       .r3 = rstim3;
%       .r4d = rstim4dual;
%       .r4m = rstim4mono;
%       .mask = spkMask;

temp = data;

%% set up reference
if isa(target_wav,'char')
    target = audioread(target_wav);
    targetLR = audioread(target_spatialized);
    mixed = audioread(mix_wav);
else
    target = target_wav;
    targetLR = target_spatialized;
    mixed = mix_wav;
end
target = target/max(abs(target));
targetLRmono = targetLR(:,1) + targetLR(:,2);
targetLRmono = targetLRmono/abs(max(targetLRmono));

%frequency-filtered target & mixtures
if ~isfield(params,'fcoefs')
    fs = params.fs;
    frgain = params.frgain;
    low_freq = params.low_freq; %min freq of the filter
    high_freq = params.high_freq;
    numChannel = params.numChannel;
    [nf,cf,~] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
    fcoefs=MakeERBFilters(fs,cf,low_freq);
else
    fcoefs = params.fcoefs;
    cf = params.cf;
    nf = length(cf);
    fs = params.fs;
    frgain = 1;
end

targetFiltmono = ERBFilterBank(target,fcoefs);
mixedFiltL = ERBFilterBank(mixed(:,1),fcoefs);
mixedFiltR = ERBFilterBank(mixed(:,2),fcoefs);

clear mixedEnvL mixedEnvR targetEnv targetConvEnv
for i = 1:nf
    mixedEnvL(i,:)= envelope(mixedFiltL(i,:)); %envlope of mixture
    mixedEnvR(i,:)= envelope(mixedFiltR(i,:)); %envlope of mixture
    targetEnv(i,:) = envelope(targetFiltmono(i,:)); %envelope of target
end

%% reconstruction
spkMask = calcSpkMask(temp,fs,'alpha',params.tau);

% mixture carrier reconstruction
[rstim1dual, rstim1mono] = applyMask(spkMask,mixedFiltL,mixedFiltR,frgain,'filt');
st1 = runStoi(rstim1mono,targetLRmono,fs,fs);
%apply to envelope of filtered mixture
[rstim2dual, rstim2mono] = applyMask(spkMask,mixedEnvL,mixedEnvR,frgain,'env',cf);
st2 = runStoi(rstim2mono,targetLRmono,fs,fs);

[rstim4dual, rstim4mono] = applyMask(spkMask,mixedEnvL,mixedEnvR,frgain,'mixed',cf);
st4 = runStoi(rstim4mono,targetLRmono,fs,fs);

% Vocoded-SpikeMask
rstim3 = vocode(spkMask,cf,'tone');
st3 = runStoi(rstim3,target,fs,fs);

rstim.r1d = rstim1dual;
rstim.r1m = rstim1mono;
rstim.r2d = rstim2dual;
rstim.r2m = rstim2mono;
rstim.r3 = rstim3;
rstim.r4d = rstim4dual;
rstim.r4m = rstim4mono;
rstim.mask = spkMask;
out = [st1 st2 st3 st4];