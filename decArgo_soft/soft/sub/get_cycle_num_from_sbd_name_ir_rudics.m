% ------------------------------------------------------------------------------
% Retrieve the cycle numbers from a list of SBD file names.
%
% SYNTAX :
%  [o_cyNumList] = get_cycle_num_from_sbd_name_ir_rudics(a_fileNameleList)
%
% INPUT PARAMETERS :
%   a_fileNameleList : list of SBD file names
%
% OUTPUT PARAMETERS :
%   o_cyNumList : associated cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyNumList] = get_cycle_num_from_sbd_name_ir_rudics(a_fileNameleList)

% output parameters initialization
o_cyNumList = [];


% process the file names
for idFile = 1:length(a_fileNameleList)
   fileName = a_fileNameleList{idFile};
   if (strcmp(fileName(end-3:end), '.b64'))
      [id, count, errmsg, nextIndex] = sscanf(fileName, '%d_%d_%10c_%d.b64');
   else
      [id, count, errmsg, nextIndex] = sscanf(fileName, '%d_%d_%10c_%d.bin');
   end
   if (isempty(errmsg))
      o_cyNumList(end+1) = id(end);
   end
end

return;
