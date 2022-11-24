% ------------------------------------------------------------------------------
% Print decoded data in output CSV file.
%
% SYNTAX :
%  print_info_in_csv_file_ir_rudics_cts4_111_113( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, ...
%    a_dataCTD, a_dataOXY, a_dataOCR, ...
%    a_dataECO2, a_dataECO3, a_dataFLNTU, ...
%    a_dataCROVER, a_dataSUNA, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechOCR, ...
%    a_sensorTechECO2, a_sensorTechECO3, ...
%    a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA, ...
%    a_tabTech, a_floatPres, ...
%    a_floatProgRudics, a_floatProgTech, a_floatProgParam, a_floatProgSensor)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_cyProfPhaseList  : information (cycle #, prof #, phase #) on each
%                        received packet
%   a_dataCTD          : decoded CTD data
%   a_dataOXY          : decoded OXY data
%   a_dataOCR          : decoded OCR data
%   a_dataECO2         : decoded ECO2 data
%   a_dataECO3         : decoded ECO3 data
%   a_dataFLNTU        : decoded FLNTU data
%   a_dataCROVER       : decoded cROVER data
%   a_dataSUNA         : decoded SUNA data
%   a_sensorTechCTD    : decoded CTD technical data
%   a_sensorTechOPTODE : decoded OXY technical data
%   a_sensorTechOCR    : decoded OCR technical data
%   a_sensorTechECO2   : decoded ECO2 technical data
%   a_sensorTechECO3   : decoded ECO3 technical data
%   a_sensorTechFLNTU  : decoded FLNTU technical data
%   a_sensorTechCROVER : decoded cROVER technical data
%   a_sensorTechSUNA   : decoded SUNA technical data
%   a_tabTech          : decoded float technical data
%   a_floatPres        : decoded float pressure actions
%   o_floatProgRudics  : decoded float Iridium config (PI) data (type 248)
%   o_floatProgTech    : decoded float Tech config (PT and PG) data (type 254)
%   o_floatProgParam   : decoded float Vector & Mission config (PV and PM) data (type 255)
%   o_floatProgSensor  : decoded float Sensor config (PC) data (type 249)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_info_in_csv_file_ir_rudics_cts4_111_113( ...
   a_decoderId, ...
   a_cyProfPhaseList, ...
   a_dataCTD, a_dataOXY, a_dataOCR, ...
   a_dataECO2, a_dataECO3, a_dataFLNTU, ...
   a_dataCROVER, a_dataSUNA, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechOCR, ...
   a_sensorTechECO2, a_sensorTechECO3, ...
   a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA, ...
   a_tabTech, a_floatPres, ...
   a_floatProgRudics, a_floatProgTech, a_floatProgParam, a_floatProgSensor)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% consecutive identical packet types are processed together
if (~isempty(a_cyProfPhaseList))
   % set identical packet types together but keep transmission ordering (of
   % first packet of each type)
   uTypePacklist = unique(a_cyProfPhaseList(:, 1), 'stable');
   cyProfPhaseList = [];
   for idT = 1:length(uTypePacklist)
      cyProfPhaseList = [cyProfPhaseList; ...
         a_cyProfPhaseList(find(a_cyProfPhaseList(:, 1) == uTypePacklist(idT)), :)];
   end
   typePacklist = cyProfPhaseList(:, 1);
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
            print_data_in_csv_file_ir_rudics_cts4_111_113( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_dataCTD, a_dataOXY, ...
               a_dataECO2, a_dataECO3, ...
               a_dataOCR, a_dataFLNTU, ...
               a_dataCROVER, a_dataSUNA);
            
         case 252
            % float pressure data packets
            print_float_pressure_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatPres);
            
         case 250
            % sensor technical data packets
            print_sensor_tech_data_in_csv_file_ir_rudics_cts4_111_113( ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_sensorTechCTD, a_sensorTechOPTODE, ...
               a_sensorTechECO2, a_sensorTechECO3, ...
               a_sensorTechOCR, a_sensorTechFLNTU, ...
               a_sensorTechCROVER, a_sensorTechSUNA);
            
         case 253
            % float technical data packets
            print_float_tech_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_tabTech);

         case 248
            % RUDICS parameters packets
            print_float_prog_rudics_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgRudics);
            
         case 254
            % float technical and ice programmed data packets
            print_float_prog_tech_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgTech);
            
         case 255
            % float param programmed data packets
            print_float_prog_param_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgParam);

         case 249
            % sensor parameter programmed data packets
            print_sensor_prog_param_data_in_csv_file_ir_rudics( ...
               a_decoderId, ...
               cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgSensor);

         otherwise
            fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for printing packet type #%d contents\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               tabType(id));
      end
      
   end
end

return
