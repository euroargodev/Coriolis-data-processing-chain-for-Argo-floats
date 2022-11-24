% ------------------------------------------------------------------------------
% Read a PROVOR Argos file and select the data to decode.
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataDate, o_argosDataData, o_sensors, o_sensorDates, ...
%    o_lastArgosCtdMsgDate, ...
%    o_surfTempDate, o_surfTempVal] = ...
%    get_prv_data(a_argosFileName, a_argosId, a_frameLength, a_bitsToFreeze, a_decoderId)
%
% INPUT PARAMETERS :
%   a_argosFileName : Argos file name
%   a_argosId       : Argos Id
%   a_frameLength   : Argos data frame length
%   a_bitsToFreeze  : bits to freeze for each message type before the
%                     redundancy step
%                     contents of "a_bitsToFreeze" array:
%                     column #1: concerned message type
%                     column #2: first bit to freeze
%                     column #3: number of bits to freeze
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_argosLocDate        : Argos location dates
%   o_argosLocLon         : Argos location longitudes
%   o_argosLocDate        : Argos location latitudes
%   o_argosDataDate       : Argos message dates
%   o_argosDataData       : original Argos data
%   o_argosLocAcc         : Argos location classes
%   o_argosLocSat         : Argos location satellite names
%   o_sensors             : selected data
%                           contents of "o_sensors" array:
%                           column #1                      : message type
%                           column #2                      : message redundancy
%                           column #3 to #(a_frameLength+2): message data frame
%   o_sensorDates         : Argos message dates of selected data
%   o_lastArgosCtdMsgDate : date of the last Argos CTD message received
%   o_surfTempDate        : dates of surface temperature measurements
%   o_surfTempVal         : surface temperature measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataDate, o_argosDataData, o_sensors, o_sensorDates, ...
   o_lastArgosCtdMsgDate, ...
   o_surfTempDate, o_surfTempVal] = ...
   get_prv_data(a_argosFileName, a_argosId, a_frameLength, a_bitsToFreeze, a_decoderId)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_sensors = [];
o_sensorDates = [];
o_lastArgosCtdMsgDate = [];
o_surfTempDate = [];
o_surfTempVal = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      % float versions with one technical message
      [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
         o_argosDataDate, o_argosDataData, o_sensors, o_sensorDates, ...
         o_lastArgosCtdMsgDate, ...
         o_surfTempDate, o_surfTempVal] = ...
         get_prv_data_one_tech_msg( ...
         a_argosFileName, a_argosId, a_frameLength, a_bitsToFreeze, a_decoderId);
      
   case {30}
      % float versions with two technical messages
      [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
         o_argosDataDate, o_argosDataData, o_sensors, o_sensorDates, ...
         o_lastArgosCtdMsgDate] = ...
         get_prv_data_two_tech_msg( ...
         a_argosFileName, a_argosId, a_frameLength, a_bitsToFreeze, a_decoderId);

   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_prv_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);

end
