% ------------------------------------------------------------------------------
% Assign a transmission number to file dates according to a given min
% transmission delay.
%
% SYNTAX :
%  [o_fileTransNum] = set_file_trans_num(a_fileDate, a_delay)
%
% INPUT PARAMETERS :
%   a_fileDate : list of file dates
%   a_delay    : min delay between transmissions
%
% OUTPUT PARAMETERS :
%   o_fileTransNum : list of transmissions
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileTransNum] = set_file_trans_num(a_fileDate, a_delay)

% output parameters initialization
o_fileTransNum = ones(size(a_fileDate))*-1;


if (length(a_fileDate) == 1)
   o_fileTransNum = 1;
else
   idF = find(diff(a_fileDate) > a_delay);
   idStart = 1;
   transNum = 1;
   for id = 1:length(idF)
      o_fileTransNum(idStart:idF(id)) = transNum;
      idStart = idF(id) + 1;
      transNum = transNum + 1;
   end
   o_fileTransNum(idStart:end) = transNum;
end

return;
