function [ ideal_mask] = calcIdealMasks(voice_sig, noise_sig, NUMBER_CHANNEL,fs,is_wiener_mask, db)
% [ ideal_mask] = calcIdealMasks(voice_sig, noise_sig, NUMBER_CHANNEL,fs,is_wiener_mask, db)
% Inputs:
%   use wideband signals VOICE and NOISE as inputs.
%   Can use noise = mixture-voice for slighly worse estimation
%   is_wiener_mask - 1 for IRM, 0 for IBM
%   db - local SNR criterion for IBM
%
% adopted from the DNN toolbox by Wang, Narayanan, and Wang
% http://web.cse.ohio-state.edu/pnl/DNN_toolbox/

SAMPLING_FREQUENCY = fs;

g_voice = gammatone(voice_sig(:,1), NUMBER_CHANNEL, [50 8000], SAMPLING_FREQUENCY);
coch_voice = cochleagram(g_voice, 320);

g_noise = gammatone(noise_sig(:,1), NUMBER_CHANNEL, [50 8000], SAMPLING_FREQUENCY);
coch_noise = cochleagram(g_noise, 320);

if is_wiener_mask == 0
    ideal_mask = ideal(coch_voice, coch_noise, db);
else
    ideal_mask = wiener(coch_voice, coch_noise);
end

ideal_mask = single(ideal_mask);
end
