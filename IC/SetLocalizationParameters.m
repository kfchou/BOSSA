function [np, side] = SetLocalizationParameters(preferredITD,ild,nf,NeuronParms)
% Retrieve localization parameters for ICcl neuron, given the desired azimuth
% Inputs:
%   AZ: Azmuth, in degrees. Supports az in the range of [-90:5:90]
%   NF: number of frequency bands
% Outputs:
%   PREFERREDITD: ITDs, milliseconds
%   NP: Neuron Parameters, saved previously
%   SIDE: Left (-1), Right (1), or middle (0)
% Assuming freq channels from 100 to 8k hz
%
% 2018-11-10: moved ITD and ILD calculation to the parent file - KFC


% combine with previous neuron parameters
np = NeuronParms(1,:);
np = ones(nf,1)*np;
% move sigmoid horizontally
np(:,10) = -np(1,6) + ild;
np(:,6) = np(1,6) + ild;
% sharpen ILD tuning slope on right side
np(:,11) = -ones(nf,1)*.002;
np(:,7) = ones(nf,1)*.002;

% np(10) = np(10);
% np(6) = np(6);% change p depending on preferred ILD
np(:,3) = ones(nf,1); % gain  on Voltage

%% Side
if preferredITD < 0
    side = -1;
elseif preferredITD > 0
    side = 1;
else
    side = 0;
end
% side = 0;