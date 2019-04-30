function [st,rstim] = recon_eval(data,target_wav,target_spatialized,mix_wav,params)
% performs stimulus reconstruction and objective intelligibility assessment on a set of spike trains
% out = recon_eval(data,target_wav,target_spatialized,mix_wav,params)
% Inputs:
%	data: a set of spike trains (from the IC for example)
%	target_wav_loc: full path to target.wav (str), or its waveform vector
%	target_spatialized_loc: full path to target_conv.wav, or its waveform
%	mix_wav_loc: full path to mixed.wav, or its waveform vector
%   params: structure with fields
%       .fs - mandatory
%       .tau - mask computation kernel time constant
%       .spatialChan - spatial channel to be reconstructed
%       -------- option 1: ------
%       .cf,
%       .coefs, or
%       -------- option 2: ------
%       .frgain
%       .low_freq
%       .high_freq
%       .numChannel
%       ----- other options -----
%       .maskRatio
%       .cond: an array containing the reconstruction conditions
%              see outputs -> rstim for a list of conditions
% Outputs:
%	out: STOI scores of three reconstruction methods
%       ['filt' 'env' 'voc' 'mix' 'mix+pp']
%   rstim: a structure of reconstructed stimuli, with the following fields
%       fields returned depends on the conditions (x) given in the input
%       (1) .r1d = rstim1dual; FRmask
%       (1) .r1m = rstim1mono;
%       (2) .r2d = rstim2dual; FRmask + tone vocode
%       (2) .r2m = rstim2mono;
%       (3) .r3 = rstim3;      Mixed - Vocoded Mask
%       (4) .r4d = rstim4dual; FRmask + mixed vocode
%       (4) .r4m = rstim4mono;
%       (4) .r4pp = rstim4pp; (post-processed)
%
%
% @Kenny Chou
% 2019-04-30
% Boston University
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
masks = calcSpkMask(data,fs,'alpha',params.tau);
masksNorm = zeros(size(masks));
if ndims(masks) == 3
    % normalize masks
    for i = 1:size(masks,3)
        masksNorm(:,:,i) = masks(:,:,i)/max(max(masks(:,:,i)));
    end
    
    % remove side channels
    centerM = masksNorm(:,:,3);
    rightM1 = masksNorm(:,:,5);
    rightM2 = masksNorm(:,:,4);
    leftM1 = masksNorm(:,:,1);
    leftM2 = masksNorm(:,:,2);
    if params.spatialChan == 3
        spkMask = centerM-params.maskRatio.*(rightM1+leftM1+leftM2+rightM2);
        spkMask(spkMask<0)=0;
    else
        error('only the mask for the center spatial channel is implemented');
    end
else
    spkMask = masks;
end

rstim = struct();
st = struct();
if ismember(1,params.cond)
    % mixture carrier reconstruction
    [rstim1dual, rstim1mono] = applyMask(spkMask,mixedFiltL,mixedFiltR,frgain,'filt');
    st1 = runStoi(rstim1mono,targetLRmono,fs,fs);
    
    rstim.r1d = rstim1dual;
    rstim.r1m = rstim1mono;
    st.r1 = st1;
end

if ismember(2,params.cond)
    %apply to envelope of filtered mixture
    [rstim2dual, rstim2mono] = applyMask(spkMask,mixedEnvL,mixedEnvR,frgain,'env',cf);
    st2 = runStoi(rstim2mono,targetLRmono,fs,fs);
    
    rstim.r2d = rstim2dual;
    rstim.r2m = rstim2mono;
    st.r2 = st2;
end

if ismember(3,params.cond)
     % Vocoded-SpikeMask
    fcutoff = 2000;
    rstim3t = vocode(spkMask,cf,'tone');
    rstim3n = vocode(spkMask,cf,'noise',fs);
    rstim3 = rstim3t;
    rstim3(cf>fcutoff,:) = rstim3n(cf>fcutoff,:);
    st3 = runStoi(rstim3,target,fs,fs);
    
    rstim.r3 = rstim3;
    st.r3 = st3;
end

if ismember(4,params.cond)
    % mixed vocoding of filtered mixture envelope
    [rstim4dual, rstim4mono] = applyMask(spkMask,mixedEnvL,mixedEnvR,frgain,'mixed',cf);
    st4 = runStoi(rstim4mono,targetLRmono,fs,fs);

    rstim4pp = runF0(rstim4dual,fs);
    st4pp = runStoi(rstim4pp,targetLRmono,fs,fs);
    
    rstim.r4d = rstim4dual;
    rstim.r4m = rstim4mono;
    rstim.r4pp = rstim4pp;
    st.r4 = st4;
    st.r4pp = st4pp;
end

disp('eval complete')
