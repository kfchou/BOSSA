function spks = spkTime2Train(spkTime,fs,timeLen)
% Converts cell array of spike times into a matrix of spike trains
%
% inputs:
%   spkTime = cell array of spike times. One cell for each freq channel
%   fs      = sampling freq
%   timeLen = length of time vector. Optional

if ~exist('timeLen','var')
    nTime = max(cellfun(@max,spkTime))*fs; %find max time vector length
else
    nTime = timeLen;
end

spks = zeros(nTime,length(spkTime));
for i = 1:length(spkTime)
    spks(round(spkTime{i}*fs),i) = 1;
end