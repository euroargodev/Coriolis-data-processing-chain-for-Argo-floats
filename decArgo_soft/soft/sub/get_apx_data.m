% ------------------------------------------------------------------------------
% Read and select data of APEX Argos message.
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataData, o_argosDataUsed, o_argosDataDate, o_sensorData, o_sensorDate] = ...
%    get_apx_data(a_argosFileName, a_cycleNumber, a_decoderId, a_argosId, ...
%    a_frameLength, a_testMsgBytesToFreeze, a_dataMsgBytesToFreeze)
%
% INPUT PARAMETERS :
%   a_argosFileName        : input Argos file path name
%   a_cycleNumber          : cycle number
%   a_decoderId            : float decoder Id
%   a_argosId              : float Argos Id number
%   a_frameLength          : test message length (in bytes)
%   a_testMsgBytesToFreeze : bytes to freeze in the test message during the
%                            redundancy step of the data selection
%   a_dataMsgBytesToFreeze : bytes to freeze in the data message during the
%                            redundancy step of the data selection
%
% OUTPUT PARAMETERS :
%   o_argosLocDate  : Argos location dates
%   o_argosLocLon   : Argos location longitudes
%   o_argosLocLat   : Argos location latitudes
%   o_argosLocAcc   : Argos location classes
%   o_argosLocSat   : Argos location satellite names
%   o_argosDataData : Argos received message data
%   o_argosDataUsed : Argos used message data
%   o_argosDataDate : Argos received message dates
%   o_sensorData    : data of selected messages
%   o_sensorDate    : date of selected messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/27/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataData, o_argosDataUsed, o_argosDataDate, o_sensorData, o_sensorDate] = ...
   get_apx_data(a_argosFileName, a_cycleNumber, a_decoderId, a_argosId, ...
   a_frameLength, a_testMsgBytesToFreeze, a_dataMsgBytesToFreeze)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_argosDataData = [];
o_argosDataUsed = [];
o_argosDataDate = [];
o_sensorData = [];
o_sensorDate = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016, 1021, 1022}
      % 071412 , 062608, 061609, 021009, 061810, 093008, 082213, 021208,
      % 032213, 110613&090413, 121512, 110813, 071807, 082807, 020110, 090810,
      % 2.8.0.A, 2.10.4.A
      
      if (a_cycleNumber == 0)
         nbTestMsg = 2;
         if (ismember(a_decoderId, [1009 1010 1011 1012]))
            nbTestMsg = 3;
         end
         [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
            o_argosDataData, o_argosDataUsed, o_argosDataDate, o_sensorData, o_sensorDate] = ...
            get_apex_test_sensor(a_argosFileName, ...
            a_argosId, a_frameLength, nbTestMsg, a_testMsgBytesToFreeze);
      else
         if (ismember(a_decoderId, [1021 1022]))
            firstDataMsgNum = 10;
         else
            firstDataMsgNum = 1;
         end
         [lastDataMsgNum, ~] = compute_last_apx_argos_msg_number([], a_decoderId);
         [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
            o_argosDataData, o_argosDataUsed, o_argosDataDate, o_sensorData, o_sensorDate] = ...
            get_apex_data_sensor(a_argosFileName, ...
            a_argosId, a_frameLength, a_dataMsgBytesToFreeze, firstDataMsgNum, lastDataMsgNum);
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_apx_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return

