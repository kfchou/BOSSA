function [ild,params] = gen_ILD(low,high,numChan,fs,directions,savePath)

input_gain = 500;
if ~exist('directions','var')
    directions = [-90 -45 0 45 90];
end

for i = 1:length(directions)
    load(sprintf('HRTF\\kemar_small_horiz_%i_0.mat',directions(i)));
    [nf,cf,bw] = getFreqChanInfo('erb',numChan,low,high);
    fcoefs=MakeERBFilters(fs,cf,low);

    bbnoise = randn(10000,1);
    stim_l = conv(hrir_left,bbnoise);
    stim_r = conv(hrir_right,bbnoise);
    rightFilt = ERBFilterBank(stim_r,fcoefs)*input_gain;
    leftFilt = ERBFilterBank(stim_l,fcoefs)*input_gain;

    [yL,yR,z] = EnergyEnvelopeandDifference(leftFilt,rightFilt,1000/fs,0);

    amp_l = zeros(nf,1);
    amp_r = zeros(nf,1);
    amp_z = zeros(nf,1);

    for j = 1:nf
        amp_l(j) = rms(yL(j,150:end));
        amp_r(j) = rms(yR(j,150:end));
        amp_z(j) = mean(z(j,150:end));
    end
    ild(:,i) = amp_z;
end

params.directions = directions;
params.fs = fs;

if exist('savePath','var')
    saveName = sprintf('%sILD_Kemar_%ich_low%i_high%i.mat',savePath,numChan,low,high);
    save(saveName,'ild','params')
end
