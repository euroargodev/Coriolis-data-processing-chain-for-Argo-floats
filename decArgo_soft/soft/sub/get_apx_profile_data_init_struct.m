% ------------------------------------------------------------------------------
% Get the basic structure to store profile data.
%
% SYNTAX :
%  [o_profileDataStruct] = get_apx_profile_data_init_struct()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profileDataStruct : profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profileDataStruct] = get_apx_profile_data_init_struct()

% output parameters initialization
o_profileDataStruct = struct( ...
   'expectedProfileLength', [], ...
   'paramList', [], ...
   'paramDataMode', [], ...
   'paramNumberWithSubLevels', [], ... % position, in the paramList of the parameters with a sublevel
   'paramNumberOfSubLevels', [], ... % number of sublevels for the concerned parameter
   'data', [], ...
   'dataAdj', [], ...
   'dataRed', [], ...
   'dateList', [], ...
   'dates', [], ...
   'datesAdj', [], ...
   'datesStatus', [] ...
   );

return
