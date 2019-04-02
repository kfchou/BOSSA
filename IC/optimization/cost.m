function out = cost(theta0,inputs,wavs,params)
% cost function: out = cost(theta0,inputs,wavs,params)
% Using some inputs, generate spikes with different IC
% parameters, THETA. Reconstruct and calculate STOI w/ recon_eval().
% WAVS: Reference waveforms
% PARAMS: params for recon_eval
%
% by Kenny Chou
% 2019-03-29
sigmoid = inputs;
slope = theta0(1);
center = theta0(2);
thresh = theta0(3);
fs = 40000;
nf = 64;
randomness = 0;

for j = 1:5
    % 1. FR
    fr = genSigmoidActivities(params.nparams(1,:),sigmoid(j).S,slope,center,thresh);

    % 2. spikes from FR
    spike_times = cell(nf,1);
    time = 0:1/fs:(size(sigmoid(j).S,2)-1)/fs;
    n_time = length(time);
    spk = zeros(n_time,nf);
    for i=1:nf 
        [spk(:,i),spike_times{i,1}] = spike_generator_kc(fr(i,:),time,randomness);
    end

    % 3. Reconstruction
    params.fs = fs;
    [out(j,:),rstim] = recon_eval(spk,wavs(j).tgt,wavs(j).tgtLR,wavs(j).mix,params);
end