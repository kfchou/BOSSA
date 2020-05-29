function [spkTimes, firingrate] = ICmodel(s_filt,azList,optional)
% [spk, firingrate] = ICmodel(s_filt,azList,randomness)
% main function for calling Fischer's IC model
% Inpus:
%   s_filt.
%       .lowFreq
%       .highFreq
%       .nf
%       .fs
%   azList - location of model neurons, in degrees az.
%   optional
%       .randomness - noise in the IC model, 0 or 1
% 
% example:
%   ICmodel(s_filt,[-90,0,90]) runs the IC model with three model
%   neurons, with best ITD and ILDs correponding to -90, 0, and 90 deg az.
%   No random firing in the model.
%
% 2019-08-07-KFC: Changed output to spike-time cell array from spike-train
%                 matrix.

% path = [cd filesep]; %assuming current directory is set to the root directory of the project
if strcmp(getenv('computername'),'KENNY-PC')
    path = 'C:\Users\Kenny\Desktop\GitHub\BOSSA\';
else
    path = 'C:\Users\kfcho\Documents\GitHub\BOSSA\';
end

randomness = 0;
saveLoc = '';
if exist('optional','var')
    if isfield(optional,'rand'), randomness = optional.rand; end
    if isfield(optional,'saveLoc'), saveLoc = optional.saveLoc; end
end

nSpatialChan = length(azList);
nf = s_filt.nf;
n_signal = length(s_filt.sL);
% spk = zeros(n_signal, nf, nSpatialChan); %time x freq x neurons
spkTimes = cell(nf,nSpatialChan);
firingrate = zeros(nf, n_signal, nSpatialChan);

%load neuron parameters from Fischer's file (?)
load([path fullfile('IC','/ICcl_CF5300_N150.mat')],'NeuronParms')

% ------------------- Binaural cue Calculation ----------------------
% translate az from degrees to milliseconds 
a = 9.3395; % radius of KEMAR's head, cm
c = 34300; % speed of sound, cm/s
ITDs = -a/c*(azList*pi/180+sin(azList*pi/180)); %woodworth formula; negative sign is necessary
ITDs = ITDs*1000; %convert to ms
% ITDs = gen_ITD(s_filt.lowFreq,s_filt.highFreq,s_filt.nf,s_filt.fs,azList)*1000;
ILDs = gen_ILD(s_filt.lowFreq,s_filt.highFreq,s_filt.nf,s_filt.fs,azList,saveLoc,path);

% -------------------------- Run Model ----------------------------
for i = 1:length(azList) %for each az location
    ITD_az = ITDs(i);
    ILD_az = ILDs(:,i);
    s_filt.az = azList(i);
    
    % get corresponding parameters for ICcl neuron
    [np, side] = SetLocalizationParameters(ITD_az, ILD_az, nf, NeuronParms);
    
    % run model
    [spkTimes(:,i), firingrate(:, :, i), ~] = ICcl(s_filt,nf,ITD_az,np,side,randomness);
end