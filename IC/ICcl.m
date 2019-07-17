function [spike_train,fr,signal]=ICcl(signal,nf,DT,np,side,randomness)
% A complete MSO/NL neuron, cross-correlator of binaural inputs
% Inputs
%   [signal]: input binaural waveform, frequency filtered
%       .sL/sR
%       .fs      sample rate in Hz
%   [fcoefs]: specifies Gammatone filterbank,should be designed with
%             MakeERBFilters function. Sampling rate of signal is included
%   [DT]: delay time of the model neuron in ms
%         +, left delay
%         -, right delay
%   [np]: neuron parameters, calculated with SetLocalizationParameters()
%   [side]: calculated with SetLocalizationParameters()
%   [randomness]: noise in the spike generator: 1 or 0.

Ts=1000/signal.fs; % time step in ms

%% Compute cues
% Energy Envelope and Diff
noise_level = 0;
[yL,yR,z] = EnergyEnvelopeandDifference(signal.sL,signal.sR,Ts,noise_level);
% CrossCorrelation
x = CrossCorrelation(signal.sL,signal.sR,Ts,DT);
%% Get input to neurons
% S = genICclInputSignals_JD_testITDonly(yL,yR,z,x,Ts,np(:,5:end),side);
[S,Sx,Sz,sigild] = genICclInputSignals_KC(yL,yR,z,x,Ts,np(:,5:end),side,signal); %raw spike rate?

%% Spiking LIF model
% Get spiking probabilities
fr = genSigmoidActivities(np(1,:),S);  % firing rate

% %% Poisson spiking model
% spike_train = poissrnd(fr*Ts);
% %% Old method (take CC output directly as spike rate)

% Poisson spiking model
spike_times = cell(nf,1);
time = 0:1/signal.fs:(length(signal.sL)-1)/signal.fs;
n_time = length(time);
spike_train = zeros(n_time,nf);
for i=1:nf
%     [spike_train(:,i),spike_times{i,1}] = spike_generator_kc(fr(i,:),time,randomness);
    [spike_train(:,i),~] = spike_generator_kc(fr(i,:),time,randomness);
end

% ------------------------ plots for debugging ------------------------
% figure;
% subplot(2,2,1);imagesc(time,1:64,z)
% colorbar;
% title('Energy Envelope Difference')
% ylabel('freq chan #')
% xlabel('time (s)')
% 
% subplot(2,2,2);imagesc(time,1:64,x)
% title('Cross-Correlation output')
% colorbar;
% ylabel('freq chan #')
% xlabel('time (s)')
% 
% subplot(2,2,3);imagesc(time,1:64,sigild)
% title('ILD response')
% colorbar;
% ylabel('freq chan #')
% xlabel('time (s)')
% 
% subplot(2,2,4);imagesc(time,1:64,S)
% title('filtered (ITD response + envelope*ILD response)')
% colorbar;
% ylabel('freq chan #')
% xlabel('time (s)')
% 
% set(gcf, 'Position',  [100, 100, 800, 700])
% suptitle([num2str(signal.az) 'deg cell'])

