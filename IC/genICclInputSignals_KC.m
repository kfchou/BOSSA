function [S,Sx,Sz,sigild]=genICclInputSignals_KC(yL,yR,z,Xun,Ts,p,side,signal)

%[S,Sx,Sz]=genICclInputSignals(yL,yR,z,Xun,Ts,NP,side)
%This function gets the current inputs to the ICcl
%spiking LIF model over all frequency channels
%z = level difference
%Xun = cross correlation
%Ts = time step in ms
%NP = cell of NeuronParms at each frequency
%Assumes low pass filtering of inputs, 4ms 
%Side of the brain (-1 for left, 1 for right, 0 for both-(half and half))

NF = size(z,1); % number of frequency channels
Sx = Xun; %ITD input
Sz = zeros(size(z));
sigild = zeros(size(z));

%find ILD threshold frequency (0 Hz?)
[~,ix] = min(abs(signal.flist-0));
for n=1:NF
%% Get ILD Input
    if side==-1
    E = (yR(n,:));
    elseif side==1
    E = (yL(n,:));
    elseif side==0
    E = (yR(n,:));
    end
    
    f = signal.flist(n);
    if n<=ix %all freq before ILD threshold
        sigild(n,:) = sigILD(z(n,:),p(n,:),f,signal.az);
    else
        sigild(n,:) = sigILD(z(n,:),p(ix,:),f,signal.az);
    end
%     Sz(n,:) = E.*(sigILD(z(n,:),p(n,:))); % ILD - original equation
    Sz(n,:) = E.*sigild(n,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
end

%Transform the inputs so that values lie roughly between -50 and 50.
Sz=2*Sz-40;
Sx=200*Sx-60;
% max_sz = max(max(Sz));
% min_sz = min(min(Sz));
% Sz = (Sz-min_sz)/(max_sz-min_sz)*60-30;
% max_sx = max(max(Sx));
% min_sx = min(min(Sx));
% Sx = (Sx-min_sx)/(max_sx-min_sx)*60-30;

%Combine ITD (Sx) and ILD (Sz) inputs and filter
S=lowpass_firstorder(Sx+Sz,4,Ts);
% S = lowpass_firstorder(Sx,4,Ts); %ITD only
% S = lowpass_firstorder(Sz,4,Ts); %ILD only

