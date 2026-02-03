% ------------------------------------------------------------------------------
% Get attribute data from variable name and attribute in a
% {var_name}/{var_att}/{att_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)
%
% INPUT PARAMETERS :
%   a_varName : name of the variable
%   a_attName : name of the attribute
%   a_dataList : {var_name}/{var_att}/{att_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_varName, a_dataList(1:3:end)) & strcmp(a_attName, a_dataList(2:3:end)));
if (~isempty(idVal))
   o_dataValues = a_dataList{3*idVal};
end

return
