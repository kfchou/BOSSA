function [yL,yR,z]=EnergyEnvelopeandDifference(vL,vR,Ts,noiseLev)

%[yL,yR,z]=EnergyEnvelopeandDifference(vL,vR,Ts,sig)
% LPF and take log transform of L and R signals vL and vR
% Computes energy envelope difference of the result.
%
% vL,vR are outputs of the filterbank
% Ts is the time step in msec, 1000/fs
% noiseLev is noise level

%Fixed parameters
%time constant of the low pass filter in msec
tau=1;

%%%%%%%%%%%%%%%Initialize%%%%%%%%%%%%%%%%%%%
%Length of time vector
Lt=size(vL,2);
%Initialize y
yL=zeros(size(vL));%yL(freq channels,time)?
yR=yL;
%Filter parameter
eps=(1-Ts/tau);
eps2=Ts*100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%Low pass filter%%%%%%%%%%%%%%%%
% g(t;fk,tau) =10^ y(t;fk)(freq and time switched)
for k=2:Lt
    yL(:,k)=eps*yL(:,k-1)+eps2*vL(:,k-1).^2;
    yR(:,k)=eps*yR(:,k-1)+eps2*vR(:,k-1).^2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%Log transform%%%%%%%%%%%%%%%%%%%

yL(yL<1)=0;
yR(yR<1)=0;

yL(yL>1)=log10(yL(yL>1))/10;
yR(yR>1)=log10(yR(yR>1))/10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%Noise%%%%%%%%%%%%%%%%%%%%%%%%

yL=yL.*(1+randn(size(yL))*noiseLev);
yR=yR.*(1+randn(size(yR))*noiseLev);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%Interaural Energy Envelope Difference%

z=yR-yL;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



