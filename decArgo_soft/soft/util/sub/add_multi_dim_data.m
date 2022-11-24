% ------------------------------------------------------------------------------
% Add multi dimentional variables to existing meta-data structure.
%
% SYNTAX :
%  [o_metaStruct] = add_multi_dim_data( ...
%    a_itemList, ...
%    a_metaData, a_idForWmo, a_dimLevlist, ...
%    a_metaStruct, a_mandatoryList1, a_mandatoryList2)
%
% INPUT PARAMETERS :
%   a_itemList       : list of variables to be added
%   a_metaData       : DB meta-data information
%   a_idForWmo       : DB meta-data information
%   a_dimLevlist     : DB meta-data information
%   a_metaStruct     : input meta-data structure
%   a_mandatoryList1 : list of manadatory variables
%   a_mandatoryList2 : list of manadatory variables
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
%   09/01/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function [o_metaStruct] = add_multi_dim_data( ...
   a_itemList, ...
   a_metaData, a_idForWmo, a_dimLevlist, ...
   a_metaStruct, a_mandatoryList1, a_mandatoryList2)

o_metaStruct = a_metaStruct;

dimLevListAll = [];
for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      dimLevListAll = [dimLevListAll a_dimLevlist(a_idForWmo(idF))'];
   end
end
dimLevListAll = sort(unique(dimLevListAll));

for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      val = cell(length(dimLevListAll), 1);
      dimLevList = a_dimLevlist(a_idForWmo(idF));
      for idL = 1:length(dimLevList)
         idLev = find(dimLevListAll == dimLevList(idL));
         val{idLev, 1} = char(a_metaData(a_idForWmo(idF(idL)), 4));
      end
      for idL = 1:length(dimLevListAll)
         if (isempty(val{idL, 1}))
            if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'n/a';
            elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'UNKNOWN';
            end
         end
      end
      o_metaStruct.(a_itemList{idItem}) = val;
   else
      if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'n/a';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'UNKNOWN';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      end
   end
end

% idF = find(strcmp(a_metaData(a_idForWmo, 5), a_item) == 1);
% if (~isempty(idF))
%    dimLev = a_dimLevlist(a_idForWmo(idF));
%    [unused idSort] = sort(dimLev);
%    val = cell(length(dimLev), 1);
%    for id = 1:length(dimLev)
%       val{id, 1} = char(a_metaData(a_idForWmo(idF(idSort(id))), 4));
%    end
%    o_metaStruct = setfield(o_metaStruct, a_item, val);
% end

return;
