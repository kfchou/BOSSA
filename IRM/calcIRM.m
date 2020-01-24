function [signal_out,IRM,IBM] = calcIRM(target,mixture,lc)
% Calculate IRM
% Inputs: filterbank-filtered sounds: Target and Mixture (Target + Noise)
%   lc: local criterion for IBM calculation (in dB)
% Outputs: IRM-filtered signal, and the IRM itself
%
% Based on Deliang Wang's ideal binary mask implementation:
% http://web.cse.ohio-state.edu/~wang.77/pnl/shareware/cochleagram/
% Kenny F Chou, October 2018, Boston Univ.

% Inputs: ERB-filtered target and mixture
if ~exist('lc','var'), lc = 0; end
if length(target) ~= length(mixture), error('signal length mismatch'); end

sigLength = length(target);
winLength = 320; %default window length.

% cochleargram = divide into frames, gives energy per TF tile
[ctarget,~,~] = cochleagram(target,winLength);
[cnoise,~,~] = cochleagram(mixture-target,winLength);
[cmixture,winShift,increment] = cochleagram(mixture,winLength);
[numChan,numFrame] = size(ctarget);     % number of channels and time frames

% Mask calculations
if isinf(-lc)
    IBM = ones(numChan,numFrame);  % give an all-one mask with lc = -inf
else
    IBM = ctarget >= cmixture*10^(lc/10);
    IRM = (ctarget ./ (ctarget+cnoise)).^0.5;
end    
mask = IRM;

% ==================== Synthesize Filtered Waveform ===================== %
r = zeros(1,sigLength);
temp1 = mixture;

% calculate a raised cosine window
coswin = zeros(1,winLength);
for i = 1:winLength
    coswin(i) = (1 + cos(2*pi*(i-1)/winLength - pi))/2;
end

% Overlap-add
for c = 1:numChan    
    weight = zeros(1, sigLength);       % calculate weighting
    for m = 1:numFrame-increment/2+1      % mask value can be binary or rational           
        startpoint = (m-1)*winShift;
        if m <= increment/2                % shorter frame lengths for beginning frames or zero padding
%             weight(1:startpoint+winLength/2) = weight(1:startpoint+winLength/2) + IBM(c,m)*coswin(winLength/2-startpoint+1:end);
            weight(1:startpoint+winLength/2) = weight(1:startpoint+winLength/2) + IRM(c,m)*coswin(winLength/2-startpoint+1:end);
        else 
%             weight(startpoint-winLength/2+1:startpoint+winLength/2) = weight(startpoint-winLength/2+1:startpoint+winLength/2) + IBM(c,m)*coswin;
            weight(startpoint-winLength/2+1:startpoint+winLength/2) = weight(startpoint-winLength/2+1:startpoint+winLength/2) + IRM(c,m)*coswin;
        end
    end
    r = r + temp1(c,:).*weight;
end
signal_out = r;