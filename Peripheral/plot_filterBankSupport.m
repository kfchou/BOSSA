function [f,out]=plot_filterBankSupport(fcoefs,ncf,options)
% [f,out] = plot_filterBankSupport(fcoefs,ncf,options)
% ncf = center frequency index (integer), optional
% if passed in, code will highlight a filter at that center frequency
if nargin < 1
    error('not enough input arguments, missing fceofs')
end

delta = [zeros(100000,1)];
delta(50) = 1;
sup = ERBFilterBank(delta,fcoefs);
% figure;plot(sup); %filter in the time domain
SUP = fft(sup');
f = linspace(0,1,100000)*40000;
figure; hold on;
if exist('ncf','var')
    for i = 1:size(SUP,2)
        if i==ncf
            colormap = [28,97,206]; %blue
        else
            colormap = [208,216,229]; %bluish grey
        end
        plot(f,abs(SUP(:,i)),'color',colormap/255);
    end
else
    plot(f,abs(SUP));
end
plot(f,sum(abs(SUP),2))
xlim([0 8000]);
title('ERB filter support')
xlabel('frequency (Hz)')
ylabel('fft magnitude')

if exist('options','var')
    if strcmp(options,'log')
            set(gca,'xscale','log');
    end
end


out = abs(SUP);
