% ------------------------------------------------------------------------------
% Compute the HEX code of a given list of test numbers.
%
% SYNTAX :
%  [o_qcTestHex] = compute_qctest_hex(a_testNumList)
%
% INPUT PARAMETERS :
%   a_testNumList : list of test numbers
%
% OUTPUT PARAMETERS :
%   o_qcTestHex : HEX code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcTestHex] = compute_qctest_hex(a_testNumList)

% output parameters initialization
o_qcTestHex = '';


% hex output value is computed by parts to avoid interger value overflow
tabDec = zeros(1, 16);
for idTest = 1:length(a_testNumList)
   if (a_testNumList(idTest) > 63)
      fprintf('RTQC_ERROR: Unable to manage test numbers > 63 => test number ignored\n');
   else
      id = floor(a_testNumList(idTest)/4) + 1;
      tabDec(id) = tabDec(id) + 2^(a_testNumList(idTest)-(id-1)*4);
   end
end
tabDec = fliplr(tabDec);
o_qcTestHex = dec2hex(tabDec)';

% BE CAREFUL
% we cannot use dec2hex(sum(2^testNumber)) because, even if it seems to work,
% it overflows integer max value
%
% dec2hex(2^53)
% Warning: At least one of the input numbers is larger than the largest
%integer-valued floating-point number (2^52). Results may be unpredictable. 
% > In dec2hex at 29 
% 
% ans =
% 
% 20000000000000

return;