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
   
elseif (ismember(g_decArgo_floatTransType, [2 3 4]))
   
   % Iridium RUDICS floats
   % Iridium SBD floats
   % Iridium SBD ProvBioII floats
   
   if ((g_decArgo_generateNcMeta == 2) && (g_decArgo_generateNcFlag == 0))
      
      % even if no buffer has been decoded the file should be created if it
      % doesn't exist
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
   
end

return;
