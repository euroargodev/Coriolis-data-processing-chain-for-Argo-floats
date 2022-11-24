% ------------------------------------------------------------------------------
% Compute the Argos frequency for Apex APF11 floats.
% 
% SYNTAX :
%  [a_outputFreq] = compute_apex_apf11_argos_frequency(a_inputFreq)
% 
% INPUT PARAMETERS :
%   a_inputFreq : input frequency
% 
% OUTPUT PARAMETERS :
%   a_outputFreq : output frequency
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [a_outputFreq] = compute_apex_apf11_argos_frequency(a_inputFreq)

if (a_inputFreq > 127)
   a_outputFreq = ((256 - a_inputFreq)*(-1));
else
   a_outputFreq = a_inputFreq;
end
a_outputFreq = a_outputFreq/1000.0 + 401.65;

return
