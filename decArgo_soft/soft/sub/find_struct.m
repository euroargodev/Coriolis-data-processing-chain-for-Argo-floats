% ------------------------------------------------------------------------------
% Find a structure in a cell array of structures (and if found, retrieve the
% value of a given field name).
%
% SYNTAX :
%  [o_id, o_value] = find_struct(a_structList, a_field1Name, a_field1Value, a_field2Name)
%
% INPUT PARAMETERS :
%   a_structList  : cell array of structures
%   a_field1Name  : field name used to find the wanted structure
%   a_field1Value : field value (of the a_field1Name field) used to find the
%                   wanted structure
%   a_field2Name  : field name of the found structure we want to retrieve the
%                   field value
%
% OUTPUT PARAMETERS :
%   o_id    : Id of the wanted structure in the cell array of structures
%   o_value : filed value of the a_field2Name field retrieved from the found
%             structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_id, o_value] = find_struct(a_structList, a_field1Name, a_field1Value, a_field2Name)

% output parameters initialization
o_id = [];
o_value = [];

for id = 1:length(a_structList)
   if (strcmp(a_structList{id}.(a_field1Name), a_field1Value))
      o_id = id;
      if (~isempty(a_field2Name))
         o_value = a_structList{id}.(a_field2Name);
      end
      break
   end
end

return
