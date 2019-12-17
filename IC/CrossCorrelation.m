function X=CrossCorrelation(vL,vR,Ts,DT)
% Calculates xcorr for all time delays
%X=CrossCorrelationwGainControl(vL,vR,Ts,sig_noise)
%There are many fixed parameters in this function
%so check it out if you want to change them.
%Not all are constrained by data.
%
% KFC 2019-12-16 changed ITD step size to 10/1000 ms from 1/1000 ms
%%%%%%%%%%%%%%%Initialize%%%%%%%%%%%%%%%%%%%

%%%%%%Fixed parameters%%%%%
%Maximum internal interaural time difference (ms)
%Desired size of internal ITD steps (ms)
ITD_StepSize=10/1000; % ms
%Time constant of gain control on input signals (ms)
tau_InputGain=2;
%Constant for gain control on input signal
const_InputGain=100;
%Time constant of running cross-correlation (ms)
tau_CC=5;
%Constant bias on cross-correlation
const_CC=0;
%Time constant of gain control on cross-correlation (ms)
tau_CCGain=3;
%Constant bias for gain control on cross-correlation
const_CCGainBias=15;
%Constant scale for gain control on cross-correlation
const_CCGainScale=2.65;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%You don't have to do anything below this point if you don't want.

%%%%%%Derived parameters%%%%%
%Number of frequency channels (NF) and length of time vector (Lt)
[NF,Lt]=size(vL);
%Upsample rate required to produce desired ITD steps
Ns=ceil(Ts/ITD_StepSize);    


%Length of upsampled vectors
L=Lt*Ns;
%Index for downsampling
ind=1:Ns:L;
%Filter parameters for input gain control
eps=(1-Ts/tau_InputGain);
eps2=Ts;
%Filter parameters for cross-correlation 
CCeps=(1-Ts/tau_CC);
CCeps2=Ts;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%Initialize vectors%%%%%
%Gain on input signals
gL=zeros(size(vL));
gR=gL;
%Upsampled input signals
vLup=zeros(NF,L);
vRup=vLup;
%Cross-correlation
X=zeros(NF,Lt);
%Delayed input signals
UL=X;
UR=X;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Run the cross-correlation with gain control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Gain control on input signals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%Low pass filter%%%%%%%%%%%%%%%%
for k=2:Lt
    gL(:,k)=eps*gL(:,k-1)+eps2*vL(:,k-1).^2; % energy equation: P2 upper right corner?? 
    gR(:,k)=eps*gR(:,k-1)+eps2*vR(:,k-1).^2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%Gain%%%%%%%%%%%%%%%%%%%%%%%%%
GL=sqrt(const_InputGain+gL);  %const_InputGain is gamma
GR=sqrt(const_InputGain+gR);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%Apply Gain%%%%%%%%%%%%%%%%%%%
uL=vL./GL;
uR=vR./GR;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%Add noise%%%%%%%%%%%%%%%%%%%
% uL=uL.*(1+randn(size(uL))*sig_noise);
% uR=uR.*(1+randn(size(uR))*sig_noise);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Perform function of delay lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%Upsample for delay lines%%%%%%%%%%%%%
for n=1:NF
    vLup(n,:)=interp(uL(n,:),Ns);
    vRup(n,:)=interp(uR(n,:),Ns);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Delay time converted from ms to delay steps
DS=round(DT/Ts*Ns); 

%Delay on left signal    
dL=max([DS 0]);   
%Initialize 
temp=zeros(NF,L);
%Delay the signal
temp(:,dL+1:L)=vLup(:,1:L-dL);
%Get the delayed signal and downsample
UL=temp(:,ind);

%Delay on right signal
dR=max([-DS 0]);
%Initialize 
temp=zeros(NF,L);
%Delay the signal
temp(:,dR+1:L)=vRup(:,1:L-dR);
%Get the delayed signal and downsample
UR=temp(:,ind);
%done with delays

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Compute gain for cross-correlation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Gain Q(t;fk) in text
%Lowpass-filter magnitude of signals on left and right and add them.
G=lowpass_firstorder(sqrt(uL.^2),tau_CCGain,Ts)+lowpass_firstorder(sqrt(uR.^2),tau_CCGain,Ts);
%Compute a quadratic function of this value.  This is the gain.
G=const_CCGainScale*G.^2+const_CCGainBias;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Run the cross-correlation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% testing
% figure
% subplot(2,1,1)
% plot(0:Ts:(length(vL)-1)*Ts,vL(1,:));hold on;plot(0:Ts:(length(vL)-1)*Ts,vR(1,:),'g')
% xlim([10 20])
% subplot(2,1,2)
% plot(0:Ts:(length(UL)-1)*Ts,UL(1,:));hold on;plot(0:Ts:(length(UL)-1)*Ts,UR(1,:),'g')
% xlim([10 20])

%%
for j=2:Lt %time
    
    X(:,j)=CCeps*X(:,j-1)+CCeps2*(UL(:,j-1)+UR(:,j-1)+const_CC).^2;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Apply the gain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for n=1:NF  %For each frequency channel
    %Get cross-correlation in this channel
    x=X(n,:);
    %Apply the gain
    X(n,:)=x./G(n,:);
end

%%%%%%%%%%%%%%Add noise%%%%%%%%%%%%%%%%%%%
% X=X.*(1+randn(size(X))*sig_noise);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Done