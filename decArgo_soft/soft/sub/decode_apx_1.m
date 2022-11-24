% ------------------------------------------------------------------------------
% Decode APEX Argos messages.
%
% SYNTAX :
%  [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, ...
%    o_timeInfo, o_timeData, o_presOffsetData] = ...
%    decode_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, ...
%    a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_argosDataData  : Argos received message data
%   a_argosDataUsed  : Argos used message data
%   a_argosDataDate  : Argos received message dates
%   a_sensorData     : Argos selected data
%   a_sensorDate     : Argos selected data dates
%   a_cycleNum       : cycle number
%   a_timeData       : input cycle time data structure
%   a_presOffsetData : input pressure offset data structure
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_auxInfo        : auxiliary info from auxiliary engineering data
%   o_profData       : profile data
%   o_parkData       : parking data
%   o_metaData       : meta data
%   o_techData       : technical data
%   o_trajData       : trajectory data
%   o_timeInfo       : time info from test and data messages
%   o_timeData       : updated cycle time data structure
%   o_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, ...
   o_timeInfo, o_timeData, o_presOffsetData] = ...
   decode_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, ...
   a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_auxInfo = [];
o_profData = [];
o_parkData = [];
o_metaData = [];
o_techData = [];
o_trajData = [];
o_timeInfo = [];
o_timeData = a_timeData;
o_presOffsetData = a_presOffsetData;


if (a_cycleNum == 0)
   [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
      decode_test_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
else
   [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
      decode_data_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData);
end

return;
