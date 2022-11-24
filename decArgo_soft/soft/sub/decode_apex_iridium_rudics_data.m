% ------------------------------------------------------------------------------
% Decode APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = decode_apex_iridium_rudics_data( ...
%    a_floatNum, a_cycleList, ...
%    a_decoderId, a_floatRudicsId, ...
%    a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_cycleList       : list of cycles to be decoded
%   a_decoderId       : float decoder Id
%   a_floatRudicsId   : float Rudics Id
%   a_floatLaunchDate : float launch date
%   a_floatEndDate    : float end decoding date
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : decoded profiles
%   o_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : decoded technical index information
%   o_tabNcTechVal   : decoded technical data
%   o_tabTechNMeas   : decoded technical N_MEASUREMENT data
%   o_structConfig   : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/29/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = decode_apex_iridium_rudics_data( ...
   a_floatNum, a_cycleList, ...
   a_decoderId, a_floatRudicsId, ...
   a_floatLaunchDate, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = [];
o_structConfig = [];

switch (a_decoderId)
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, ...
         1201}
      % APEX APF9 & NAVIS
      
      [o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal, ...
         o_structConfig] = decode_apex_iridium_rudics_data_apf9_navis( ...
         a_floatNum, a_cycleList, ...
         a_decoderId, str2num(a_floatRudicsId), ...
         a_floatLaunchDate, a_floatEndDate);

   case {1121, 1122, 1123, 1124, 1125, 1126, 1127}
      % APEX APF11 RUDICS
      
      [o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
         o_structConfig] = decode_apex_iridium_rudics_data_apf11( ...
         a_floatNum, a_cycleList, ...
         a_decoderId, a_floatRudicsId, ...
         a_floatLaunchDate, a_floatEndDate);
      
   otherwise
      fprintf('ERROR: decode_apex_iridium_rudics_data not defined yet for decId #%d - exit\n', a_decoderId);
      return
end

return
