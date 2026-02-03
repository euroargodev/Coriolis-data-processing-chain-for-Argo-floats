% ------------------------------------------------------------------------------
% Get the basic structure to store PROVOR CTS3 and ARVOR decoded
% information.
%
% SYNTAX :
%  [o_decodeData] = get_decoded_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_decodeData : PROVOR CTS3 and ARVOR decoded structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodeData] = get_decoded_data_init_struct

% output parameter
o_decodeData = struct( ...
   'fileName', '', ... % SBD file name
   'fileDate', '', ... % SBD file date
   'rawData', [], ... % SBD received data
   'decData', [], ... % SBD decoded data
   'cyNumRaw', -1, ... % transmitted cycle number
   'cyNum', -1, ... % adjusted cycle number (corrected from float possible reset during mission)
   'packType', -1, ... % packet type number
   'irSession', -1, ... % Iridium session indicator (0=first session, 1=second session) provided by the float
   'eolFlag', -1, ... % EOL flag provided by the float
   'resetDate', -1, ... % date of the last reset of the float
   'julD2FloatDayOffset', -1, ... % offset between julian day and float day
   'expNbDesc', -1, ... % expected number of packets for descending data
   'expNbDrift', -1, ... % expected number of packets for drift data
   'expNbAsc', -1, ... % expected number of packets for ascending data
   'expNbNearSurface', -1, ... % expected number of measurements for Near Surface data
   'expNbInAir', -1, ... % expected number of measurements for In Air data
   'rankByCycle', -1, ... % number of the decoding buffer (sorted by cycle number)
   'rankByDate', -1, ... % number of the decoding buffer (sorted by SBD transmission date)
   'deep', -1, ... % 1 for a deep cycle, 0 otherwise
   'iceDelayed', -1, ... % 1 for a Ice delayed cycle, 0 otherwise
   'reset', -1, ... % 1 if a reset has been detected, 0 otherwise
   'expNbDesc3T', -1, ... % expected number of 3T packets for descending data
   'expNbDrift3T', -1, ... % expected number of 3T packets for drift data
   'expNbAsc3T', -1, ... % expected number of 3T packets for ascending data
   'expNbDesc2T', -1, ... % expected number of 2T packets for descending data
   'expNbDrift2T', -1, ... % expected number of 2T packets for drift data
   'expNbAsc2T', -1 ... % expected number of 2T packets for ascending data
   );

return
