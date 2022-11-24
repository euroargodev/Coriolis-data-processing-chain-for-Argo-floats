% ------------------------------------------------------------------------------
% Process technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_technical_data_ir_sbd2( ...
%    a_decoderId, a_cyProfPhaseList, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
%    a_tabTech, a_refDay)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_cyProfPhaseList  : information (cycle #, prof #, phase #) on each
%                        received packet
%   a_sensorTechCTD    : decoded CTD technical data
%   a_sensorTechOPTODE : decoded OXY technical data
%   a_sensorTechFLBB   : decoded FLBB technical data
%   a_sensorTechFLNTU  : decoded FLNTU technical data
%   a_tabTech          : decoded float technical data
%   a_refDay           : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function process_technical_data_ir_sbd2( ...
   a_decoderId, a_cyProfPhaseList, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
   a_sensorTechCYCLOPS, a_sensorTechSEAPOINT, ...
   a_tabTech, a_refDay)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_cyProfPhaseList))
   return;
end

% consecutive identical packet types are processed together
typePacklist = a_cyProfPhaseList(:, 1);
tabStart = [];
tabStop = [];
trans = find(diff(typePacklist) ~= 0);
idStart = 1;
for id = 1:length(trans)+1
   if (id <= length(trans))
      idStop = trans(id);
   else
      idStop = length(typePacklist);
   end
   
   tabStart = [tabStart; idStart];
   tabStop = [tabStop; idStop];
   
   if (id <= length(trans))
      idStart = trans(id)+1;
   end
end
tabType = typePacklist(tabStart);

% print technical and sensor data
for id = 1:length(tabStart)
   
   switch (tabType(id))
      
      case 0
         % data packets
         % no technical data to process
         
      case 250
         % sensor technical data packets
         process_sensor_tech_data_ir_sbd2( ...
            a_decoderId, a_cyProfPhaseList, tabStart(id):tabStop(id), ...
            a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
            a_sensorTechCYCLOPS, a_sensorTechSEAPOINT);
         
      case 251
         % sensor parameter data packets
         % no technical data to process (only configuration)
         
      case 252
         % float pressure data packets
         % unused because stored in TRAJ file (with MC of spy data)
         
      case 253
         % float technical data packets
         process_float_tech_data_ir_rudics_105_to_110_sbd2( ...
            a_cyProfPhaseList, tabStart(id):tabStop(id), ...
            a_tabTech, a_refDay);
         
      case 254
         % float technical programmed data packets
         % no technical data to process (only configuration)
         
      case 255
         % float param programmed data packets
         % no technical data to process (only configuration)
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for printing packet type #%d contents\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            tabType(id));
   end
   
end

return;
