function [timeDiff,params] = gen_ITD(low,high,numChan,fs,directions,savePath)
% [ild,params] = gen_ILD(low,high,numChan,fs,directions,savePath)

input_gain = 500;
if ~exist('directions','var')
    directions = [-90 -45 0 45 90];
end

for i = 1:length(directions)
    load(sprintf('HRTF\\kemar_small_horiz_%i_0.mat',directions(i)));
    [nf,cf,bw] = getFreqChanInfo('erb',numChan,low,high);
    fcoefs=MakeERBFilters(fs,cf,low);

%     bbnoise = randn(10000,1);
%     stim_l = conv(hrir_left,bbnoise);
%     stim_r = conv(hrir_right,bbnoise);
    rightFilt = ERBFilterBank(stim_r,fcoefs)*input_gain;
    leftFilt = ERBFilterBank(stim_l,fcoefs)*input_gain;

    %% calculate cross-correlation
    for j = 1:numChan
        [xLR,lag] = xcorr(leftFilt(j,:),rightFilt(j,:));
        [~,I] = max(abs(xLR));
        timeDiff(j,i) = lag(I);
    end
end
timeDiff = timeDiff/fs;

params.directions = directions;
params.fs = fs;

if exist('savePath','var')
    saveName = sprintf('%sILD_Kemar_%ich_low%i_high%i.mat',savePath,numChan,low,high);
    save(saveName,'ild','params')
end
