function spkMasks = calcSpkMask(spks,fs,param)
% masks = calcSpkMask(spks,fs,param)
%
% Estimates spike-masks by convolving SPKS with a kernel (see below)
% SPKS is assumed to have the dimensions [time x freq x neurons]
%
% param: parameter structure, containing
%   .kernel - 'alpha','hamming','rect','tukey'
%   .tau (optional) - 0.01 by default, seconds
%   .delay (optional) - 0 by default, steps
%
% output is [freq x time]. Dimensions are swapped for easy plotting
%   .FR - FR-mask
%   .xMask - cross-spatial inhibition mask: center - (R-L) - (L-R)
%   ..diffMask - difference mask: center - scale*sum(sides)
% Kenny F Chou
% updated 2018/9/18
% 2019-07-26 KFC added delay parameter to calcSpkMask
%                changed varargin to param structure
% 2020-05-25 KFC added diffmask calculation

if isfield(param,'tau'), tau = param.tau; else, tau = 0.01; end
if isfield(param,'delay'), delayLen = param.delay; else, delayLen = 0; end
if isfield(param,'maxKernelLen'), kernelLen = param.maxKernelLen; else, kernelLen = 0.1; end

numTaps = tau*fs;
switch param.kernel
    case 'alpha'
        t = 0:1/fs:kernelLen;
        A = t.*exp(-t/tau);
    case 'hamming'
        A = hamming(numTaps);
    case 'rect'
        A = ones(1,numTaps);
    case 'tukey'
        A = tukeywin(numTaps,0.35);
end

if delayLen > 0 
    A = [zeros(1,delayLen) A];
elseif delayLen < 0
    A = [A zeros(1,abs(delayLen))];
end

numNeurons = size(spks,3);
tempc = zeros(size(spks));
for n = 1:numNeurons
    tempc(:,:,n) = conv2(spks(:,:,n),A','same');
end
masks = permute(tempc,[2 1 3]);
spkMasks.FR = masks; %FRMasks

% 2nd & 3rd layer operations, assuming there are 5 channels
if ndims(masks) == 3 && size(masks,3) == 5
    % normalize masks
    for i = 1:size(masks,3)
        masksNorm(:,:,i) = masks(:,:,i)/max(max(masks(:,:,i)));
    end
    centerM = masksNorm(:,:,3);
    rightM1 = masksNorm(:,:,5);
    rightM2 = masksNorm(:,:,4);
    leftM1 = masksNorm(:,:,1);
    leftM2 = masksNorm(:,:,2);

    %cross-hemisphere inhibition
    mask1 = max(rightM1-leftM1,0);
    mask2 = max(leftM1-rightM1,0);
    mask3 = max(rightM2-leftM2,0);
    mask4 = max(leftM2-rightM2,0);
    xMask = max(centerM-mask1-mask2-mask3-mask4,0.001);
    xMask = xMask./max(max(abs(xMask)));  %normalize to [0,1]
    spkMasks.xMask = xMask;
    
    %difference mask, center - scale*sum(sides)
    diffMask = centerM-params.maskRatio.*(rightM1+leftM1+leftM2+rightM2);
    diffMask(diffMask<0)=0;
    diffMask = diffMask./max(max(abs(diffMask)));  %normalize to [0,1]
    spkMasks.diffMask = diffMask;
else
    warning('undefined SPKS dimensions')
end
