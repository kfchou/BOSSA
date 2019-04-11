function [spk, firingrate] = ICmodel(s_filt,randomness)
% main function for calling Fischer's IC model

% ------------------- initialize -------------------
% path = [cd filesep]; %assuming current directory is set to the root directory of the project
if strcmp(getenv('computername'),'KENNY-PC')
    path = 'C:\Users\Kenny\Desktop\GitHub\PISPA2.0\';
else
    path = 'C:\Users\kfcho\Documents\GitHub\PISPA2.0\';
end
% azList = -90:45:90; %neurons at these locations - subject to change
azList = [-90,-60,-45,-30,0,30,45,60,90];
nSpatialChan = length(azList);

nf = s_filt.nf;
n_signal = length(s_filt.sL);
spk = zeros(n_signal, nf, nSpatialChan); %time x freq x neurons
firingrate = zeros(nf, n_signal, nSpatialChan);

%load neuron parameters from Fischer's file (?)
load([path fullfile('IC','/ICcl_CF5300_N150.mat')],'NeuronParms')

% ------------------- ITDs -------------------------
% load([path fullfile('HRTF','ITD_Kemar_36ch.mat')])
% translate az from degrees to milliseconds
% Assume 90 deg = 0.7 ms and -90 deg = -0.7 ms for KEMAR HRTFs
a = 9.3395; % radius of KEMAR's head
c = 34300; % speed of sound, cm/s
ITDs = -a/c*(azList*pi/180+sin(azList*pi/180)); % woodworth formula; negative sign is necessary


% ------------------- ILDs -------------------------
ildFile = [path fullfile('HRTF',sprintf('ILD_Kemar_%ich_low%i_high%i.mat',nf,s_filt.lowFreq,s_filt.highFreq))];
if exist(ildFile, 'file') == 2
    fprintf('using precalculated ILD: low: %dhz, high: %dhz \n',s_filt.lowFreq,s_filt.highFreq)
    load(ildFile,'ild')
else
    disp('calculating ILD')
    ild = gen_ILD(s_filt.lowFreq,s_filt.highFreq,s_filt.nf,s_filt.fs,[path 'HRTF\']);
end

for i = 1:length(azList) %for each az location
    ITD_az = ITDs(i);
    ILD_az = ild(:,i);
    s_filt.az = azList(i);
    
    % get corresponding parameters for ICcl neuron
    [np, side] = SetLocalizationParameters(ITD_az, ILD_az, nf, NeuronParms);
    
    % run model
    [spk(:, :, i), firingrate(:, :, i), ~] = ICcl(s_filt,nf,ITD_az,np,side,randomness);
end