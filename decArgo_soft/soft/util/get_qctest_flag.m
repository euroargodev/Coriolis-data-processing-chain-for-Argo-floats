% ------------------------------------------------------------------------------
% Decode RTQC results HEX code to get individual test results.
%
% SYNTAX :
%  get_qctest_flag(varargin)
%
% INPUT PARAMETERS :
%   varargin : HEX code
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%   get_qctest_flag('FA00000000600A40')
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2019 - RNU - creation
% ------------------------------------------------------------------------------
function get_qctest_flag(varargin)

qcTestHex = varargin{:};
qcTestFlag = [];
for id = 1:length(qcTestHex)
   qcTestFlag = [qcTestFlag dec2bin(hex2dec(qcTestHex(id)), 4)];
end

qcTestFlag = fliplr(qcTestFlag);
qcTestFlag(1) = [];

fprintf('Input HEX: %s\n', qcTestHex);
fprintf('Output test flag: %s\n', qcTestFlag);
fprintf('Activated tests:\n');
for id = 1:length(qcTestFlag)
   if (qcTestFlag(id) == '1')
      fprintf('   Test #%d\n', id);
   end
end

return
