function out = cost(theta0,inputs,wavs,params)
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
    [out(j,:),rstim1o(j).wav,rstim2o(j).wav,rstim3o(j).wav] = recon_eval(spk,wavs(j).tgt,wavs(j).tgtLR,wavs(j).mix,params);
end