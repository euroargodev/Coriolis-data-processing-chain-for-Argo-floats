% ------------------------------------------------------------------------------
% Get the list of primary parameters.
%
% SYNTAX :
%  [o_paramList] = get_primary_parameter_list(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_paramList : primary parameter list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramList] = get_primary_parameter_list(a_decoderId)

% output parameters initialization
o_paramList = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   case {1, 3, 11, 12, 17, 24, 30}
      
      % core Argos floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {4, 19, 25}
      
      % DO Argos floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'MOLAR_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {27, 28, 29, 32}
      
      % DO Argos floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'DOXY'} ...
         ];

   case {105, 106, 107, 109, 110, 111}

      % remocean floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TEMP_STD'} ...
         {'PSAL_STD'} ...
         {'PRES_MED'} ...
         {'TEMP_MED'} ...
         {'PSAL_MED'} ...
         ];
      
   case {121, 122, 123}

      % CTS5 floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {301}

      % INCOIS FLBB floats
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {201, 202, 203, 206, 207, 208, 213, 214, 215, 216, 217}
      
      % Arvor Deep
      % Provor-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      % Arvor-ARN-DO-Ice Iridium 5.46
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'C1PHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {209}
      
      % Arvor-2DO Iridium
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'C1PHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         {'PHASE_DELAY_DOXY'} ...
         {'TEMP_DOXY2'} ...
         {'DOXY2'} ...
         ];
      
   case {204, 205, 210, 211, 212}

      % Arvor Iridium
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {1101}
      
      % Arvor Ir Rudics
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'FREQUENCY_DOXY'} ...
         {'DOXY'} ...
         {'FLUORESCENCE_CHLA'} ...
         {'TEMP_CPU_CHLA'} ...
         {'CHLA'} ...
         {'BETA_BACKSCATTERING700'} ...
         {'BBP700'} ...
         ];
      
   case {1102, 1103, 1106, 1108, 1109, 1314}
      
      % Arvor Ir Rudics & Sbd
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {1104}
      
      % Arvor Ir Rudics
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {1105}
      
      % Arvor Ir Rudics
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         {'FLUORESCENCE_CHLA'} ...
         {'TEMP_CPU_CHLA'} ...
         {'CHLA'} ...
         {'BETA_BACKSCATTERING700'} ...
         {'BBP700'} ...
         ];

   case {1107}
      
      % Arvor Ir Rudics
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {1110, 1111, 1112}
      
      % Arvor Ir Rudics
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         {'FLUORESCENCE_CHLA'} ...
         {'TEMP_CPU_CHLA'} ...
         {'CHLA'} ...
         {'BETA_BACKSCATTERING700'} ...
         {'BBP700'} ...
         ];

   case {1201}
      
      % Navis
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'TPHASE_DOXY'} ...
         {'RPHASE_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         {'PHASE_DELAY_DOXY2'} ...
         {'TEMP_DOXY2'} ...
         {'DOXY2'} ...
         ];

   case {2001, 2003}

      % Nova
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      
   case {2002}
      
      % Dova
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         {'PHASE_DELAY_DOXY'} ...
         {'TEMP_DOXY'} ...
         {'DOXY'} ...
         ];

   otherwise
      fprintf('WARNING: Float #%d: No default primary parameters defined yet for decoderId #%d => using PRES, TEMP, PSAL\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
      o_paramList = [ ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
end

return;
