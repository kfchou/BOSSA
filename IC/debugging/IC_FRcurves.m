% Sigmoidal FR curve
sigmoid = @(x,max,k,x0) max./(1+exp(-k.*(x-x0)));

x = -150:100; %membrane potential range
L = 150; %max firing rate
k = 0.4122;
x0 = 56;

fischer = sigmoid(x,L,k,-x0);

%%
kk = 0.2:-0.01:.01;
% kk = [0.04,0.4];
clear sig
for i = 1:length(kk)
    sig(:,i) = sigmoid(x,L,kk(i),40);
end

sig = [fischer' sig];
colormap = [208,216,229]; %all grey to start
figure;
plot(x,sig,'color',colormap/255)
title('IC FR decision curve')
xlabel('input membrane potential')
ylabel('firing rate')

%% set individual line colors
hline = findobj(gcf,'type','line');
set(hline(end),'color',[28,97,206]/255,'linewidth',2);
set(hline(4),'color',[227,74,51]/255,'linewidth',2);

%legend
temp = cell(1,length(kk)+1);
temp(2:end) = cellstr(num2str((kk)'));
temp(1) = cellstr('fischer');
legend([hline(end) hline(4)],'Fischer, x_0 = -56','0.04, x_0 = 40')

%% Natural Log - like FR curve
lnx = @(x,a,b,x0) a*log(x-x0)+b;

x = -150:150; %membrane potential range
plot(x,lnx(x,30,-10,45));