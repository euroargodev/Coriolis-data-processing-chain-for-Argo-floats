% ------------------------------------------------------------------------------
% Select the most redundant value in a data set.
%
% SYNTAX :
%  [o_selectedValue, o_countSelectedValue] = select_a_value(a_tabValues)
%
% INPUT PARAMETERS :
%   a_tabValues : data set
%
% OUTPUT PARAMETERS :
%   o_selectedValue      : selected value
%   o_countSelectedValue : selected value redundancy
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_selectedValue, o_countSelectedValue] = select_a_value(a_tabValues)

% output parameters initialization
o_selectedValue = [];
o_countSelectedValue = 0;


if (isempty(a_tabValues))
   return
end

tabUniqueValues = unique(a_tabValues, 'first');
count = [];
for id = 1:length(tabUniqueValues)
   count = [count length(find(a_tabValues == tabUniqueValues(id)))];
end

[o_countSelectedValue, idMax] = max(count);
o_selectedValue = tabUniqueValues(idMax(1));

return
