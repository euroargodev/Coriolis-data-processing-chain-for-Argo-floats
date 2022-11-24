% ------------------------------------------------------------------------------
% Decode APEX Iridium SBD data.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = decode_apex_iridium_sbd_data( ...
%    a_floatNum, a_decoderId, a_floatImei, ...
%    a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_decoderId       : float decoder Id
%   a_floatImei       : float Rudics Id
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
%   04/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = decode_apex_iridium_sbd_data( ...
   a_floatNum, a_decoderId, a_floatImei, ...
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
   case {1314}
      % APEX APF9 (090215)
      
      [o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal, ...
         o_structConfig] = decode_apex_iridium_sbd_data_1314( ...
         a_floatNum, a_decoderId, a_floatImei, ...
         a_floatLaunchDate, a_floatEndDate);

   case {1321, 1322}
      % APEX APF11 (2.10.1.S, 2.11.1.S, 2.11.3.S)
      
      [o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
         o_structConfig] = decode_apex_iridium_sbd_data_apf11( ...
         a_floatNum, a_decoderId, a_floatImei, ...
         a_floatLaunchDate, a_floatEndDate);
      
   otherwise
      fprintf('ERROR: decode_apex_iridium_sbd_data not defined yet for decId #%d => exit\n', a_decoderId);
      return
end

return
