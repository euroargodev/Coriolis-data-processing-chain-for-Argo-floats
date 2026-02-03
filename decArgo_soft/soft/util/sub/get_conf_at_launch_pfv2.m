% ------------------------------------------------------------------------------
% Read the predeployment configuration XML file to get the configuration at launch.
%
% SYNTAX :
%  [o_confParamNames, o_confParamValues] = get_conf_at_launch_pfv2( ...
%    a_confFilePathName, a_floatWmo)
%
% INPUT PARAMETERS :
%   a_confFilePathName : predeployment configuration XML file name
%   a_floatWmo         : float WMO number
%
% OUTPUT PARAMETERS :
%   o_confParamNames  : configuration parameter names
%   o_confParamValues : configuration parameter values at launch
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confParamNames, o_confParamValues] = get_conf_at_launch_pfv2( ...
   a_confFilePathName, a_floatWmo)

% output parameters initialization
o_confParamNames = [];
o_confParamValues = [];

% current float WMO number
global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatWmo;


% read configuration file
[o_confParamNames, o_confParamValues] = read_config_file_pfv2(a_confFilePathName);

return
