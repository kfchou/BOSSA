function y=lowpass_firstorder(x,tau,Ts)

%y=lowpass_firstorder(x,tau,Ts)

L=size(x,2);
y=zeros(size(x));

eps=Ts/tau;
for n=2:L
    y(:,n)=y(:,n-1)+eps*(-y(:,n-1)+x(:,n-1));
end



