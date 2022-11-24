% ------------------------------------------------------------------------------
% Create a technical or configuration name by replacing <info> templates with
% additional information.
%
% SYNTAX :
%  [o_paramName] = create_param_name_ir_rudics_sbd2(a_paramName, a_addInfo)
%
% INPUT PARAMETERS :
%   a_paramName : parameter original name
%   a_addInfo   : additional information
%
% OUTPUT PARAMETERS :
%   o_paramName : parameter final name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/15/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramName] = create_param_name_ir_rudics_sbd2(a_paramName, a_addInfo)

% output parameters initialization
o_paramName = [];


% replace the <info> by their content in the additionnal information
for idInfo = 1:2:length(a_addInfo)
   info = a_addInfo{idInfo};
   
   idPos = strfind(a_paramName, info);
   if (~isempty(idPos))
      a_paramName = [a_paramName(1:idPos-1) a_addInfo{idInfo+1} a_paramName(idPos+length(info):end)];
   end
end

% output data
o_paramName = a_paramName;

return
