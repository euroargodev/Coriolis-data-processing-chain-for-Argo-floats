% ------------------------------------------------------------------------------
% Retrieve C and FORTRAN format of a given parameter.
%
% SYNTAX :
%  [o_cFormat, o_fortranFormat] = get_param_output_format(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : parameter name
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cFormat       : parameter C format
%   o_fortranFormat : parameter FORTRAN format
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cFormat, o_fortranFormat] = get_param_output_format(a_paramName, a_decoderId)

% output parameter initialization
o_cFormat = [];
o_fortranFormat = [];


switch (a_decoderId)
   
   case {121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133}
      % PROVOR CTS5
      switch (a_paramName)
         case {'PRES', 'PRES_ADJUSTED', 'PRES_ADJUSTED_ERROR'}
            
            o_cFormat = '%8.2f';
            o_fortranFormat = 'F8.2';
      end
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1314}
      % Apex Iridium Rudics & Sbd
      switch (a_paramName)
         case {'PRES', 'PRES_ADJUSTED', 'PRES_ADJUSTED_ERROR'}
            
            o_cFormat = '%8.2f';
            o_fortranFormat = 'F8.2';
      end
      
   case {1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, 1129, 1130, 1321, 1322, 1323}
      % Apex APF11 Iridium
      switch (a_paramName)
         case {'PRES', 'PRES_ADJUSTED', 'PRES_ADJUSTED_ERROR'}
            
            o_cFormat = '%8.2f';
            o_fortranFormat = 'F8.2';
            
         case {'PSAL', 'PSAL_ADJUSTED', 'PSAL_ADJUSTED_ERROR'}
            
            o_cFormat = '%10.4f';
            o_fortranFormat = 'F10.4';
            
         case {'TEMP', 'TEMP_ADJUSTED', 'TEMP_ADJUSTED_ERROR'}
            
            o_cFormat = '%10.4f';
            o_fortranFormat = 'F10.4';
      end
      
   case {1201}
      % Navis
      switch (a_paramName)
         case {'PRES', 'PRES_ADJUSTED', 'PRES_ADJUSTED_ERROR'}
            
            o_cFormat = '%8.2f';
            o_fortranFormat = 'F8.2';
      end
end

return
