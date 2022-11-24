% ------------------------------------------------------------------------------
% Before creating NetCDF META-DATA file, check if it needs to be updated.
%
% SYNTAX :
%  create_nc_meta_file(a_decoderId, a_structConfig)
%
% INPUT PARAMETERS :
%   a_decoderId    : float decoder Id
%   a_structConfig : float configuration
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/31/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_meta_file(a_decoderId, a_structConfig)

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcMeta;

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% generate nc flag
global g_decArgo_generateNcFlag;


if (g_decArgo_floatTransType == 1)
   
   % Argos floats
   
   if (g_decArgo_generateNcMeta == 2)
      
      % check if the NetCDF META-DATA file already exists
      floatNumStr = num2str(g_decArgo_floatNum);
      ncDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
      ncFileName = [floatNumStr '_meta.nc'];
      ncPathFileName = [ncDirName ncFileName];
      
      if (exist(ncPathFileName, 'file') == 2)
         
         % the file is not updated if it already exists
         return;
      end
   end
      
   create_nc_meta_file_3_1(a_decoderId, a_structConfig);
   
elseif (g_decArgo_floatTransType == 2)
   
   % Iridium RUDICS floats
   
   if ((g_decArgo_generateNcMeta == 1) || ...
         ((g_decArgo_generateNcMeta == 2) && (g_decArgo_generateNcFlag == 1)))
            
      create_nc_meta_file_3_1(a_decoderId, a_structConfig);
   end
   
elseif (g_decArgo_floatTransType == 3)
   
   % Iridium SBD floats
   
   if ((g_decArgo_generateNcMeta == 1) || ...
         ((g_decArgo_generateNcMeta == 2) && (g_decArgo_generateNcFlag == 1)))
            
      create_nc_meta_file_3_1(a_decoderId, a_structConfig);
   end
   
elseif (g_decArgo_floatTransType == 4)
   
   % Iridium SBD ProvBioII floats
   
   if ((g_decArgo_generateNcMeta == 1) || ...
         ((g_decArgo_generateNcMeta == 2) && (g_decArgo_generateNcFlag == 1)))
            
      create_nc_meta_file_3_1(a_decoderId, a_structConfig);
   end
   
end

return;
