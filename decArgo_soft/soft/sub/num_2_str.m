% ------------------------------------------------------------------------------
% Convert number to string so that all available digits are visible.
%
% SYNTAX :
%  [o_valueStr] = num_2_str(a_valueNum)
%
% INPUT PARAMETERS :
%   a_valueNum : input number
%
% OUTPUT PARAMETERS :
%   o_valueStr : output string
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_valueStr] = num_2_str(a_valueNum)

prec = 0;
while (fix(a_valueNum*10^prec) ~= a_valueNum*10^prec)
   prec = prec + 1;
end
if (prec > 0)
   o_valueStr = sprintf(['%.' num2str(prec) 'f'], a_valueNum);
else
   o_valueStr = sprintf('%d', a_valueNum);
end

return;
