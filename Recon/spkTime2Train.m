function spks = spkTime2Train(spkTime,fs,timeLen)
% Converts cell array of spike times into a matrix of spike trains
%
% inputs:
%   spkTime = cell array of spike times. One cell for each freq channel
%   fs      = sampling freq
%   timeLen = length of time vector, taps. Optional

if ~exist('timeLen','var')
    temp = spkTime;
    temp = temp(~cellfun('isempty',temp));
    nTime = ceil(max(max(cellfun(@max,temp)))*fs); %find max time vector length
else
    nTime = timeLen;
end

spks = zeros(nTime,size(spkTime,1),size(spkTime,2));
for i = 1:size(spkTime,1)
    for j = 1:size(spkTime,2)
        spks(round(spkTime{i,j}*fs),i,j) = 1;
    end
end