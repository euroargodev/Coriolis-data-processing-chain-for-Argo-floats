% ------------------------------------------------------------------------------
% Read one cycle Argos file(s).
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataDate, o_argosDataData] = read_argos_file(a_argosFileName, a_argosId, a_frameLength)
%
% INPUT PARAMETERS :
%   a_fileName    : Argos file name(s)
%   a_argosId     : Argos Id
%   a_frameLength : Argos data frame length
%
% OUTPUT PARAMETERS :
%   o_argosLocDate  : Argos location dates
%   o_argosLocLon   : Argos location longitudes
%   o_argosLocDate  : Argos location latitudes
%   o_argosLocAcc   : Argos location classes
%   o_argosLocSat   : Argos location satellite names
%   o_argosDataDate : Argos message dates
%   o_argosDataData : Argos message data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataDate, o_argosDataData] = read_argos_file(a_argosFileName, a_argosId, a_frameLength)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_argosDataDate = [];
o_argosDataData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% configuration values
global g_decArgo_hexArgosFileFormat;


% read the Argos file(s) according to the configurated format
if (g_decArgo_hexArgosFileFormat == 1)
   if (length(a_argosFileName) > 1)
      fprintf('INFO: Float #%d Cycle #%d: %d Argos file for this cycle (their contents are concatenated)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(a_argosFileName));
   end

   [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
      o_argosDataDate, o_argosDataData] = read_argos_file_fmt1(a_argosFileName, a_argosId, a_frameLength);
elseif (g_decArgo_hexArgosFileFormat == 2)
   if (length(a_argosFileName) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: More than one Argos file (only the first one is used)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end

   [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
      o_argosDataDate, o_argosDataData] = read_argos_file_fmt2(char(a_argosFileName{1}), a_frameLength);
end

return

