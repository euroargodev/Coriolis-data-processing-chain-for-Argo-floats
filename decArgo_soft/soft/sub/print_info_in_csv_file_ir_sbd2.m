% ------------------------------------------------------------------------------
% Print decoded data in output CSV file.
%
% SYNTAX :
%  print_info_in_csv_file_ir_sbd2( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, ...
%    a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
%    a_sensorTechCYCLOPS, a_sensorTechSEAPOINT, ...
%    a_sensorParam, ...
%    a_floatPres, ...
%    a_tabTech, a_floatProgTech, a_floatProgParam)
%
% INPUT PARAMETERS :
%   a_decoderId          : float decoder Id
%   a_cyProfPhaseList    : information (cycle #, prof #, phase #) on each
%                         received packet
%   a_dataCTD            : decoded CTD data
%   a_dataOXY            : decoded OXY data
%   a_dataFLBB           : decoded FLBB data
%   a_dataFLNTU          : decoded FLNTU data
%   a_dataCYCLOPS        : decoded CYCLOPS data
%   a_dataSEAPOINT       : decoded SEAPOINT data
%   a_sensorTechCTD      : decoded CTD technical data
%   a_sensorTechOPTODE   : decoded OXY technical data
%   a_sensorTechFLBB     : decoded FLBB technical data
%   a_sensorTechFLNTU    : decoded FLNTU technical data
%   a_sensorTechCYCLOPS  : decoded CYCLOPS technical data
%   a_sensorTechSEAPOINT : decoded SEAPOINT technical data
%   a_sensorParam        : decoded modified sensor data
%   a_floatPres          : decoded float pressure actions
%   a_tabTech            : decoded float technical data
%   a_floatProgTech      : decoded float technical programmed data
%   a_floatProgParam     : decoded float parameter programmed data
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
function print_info_in_csv_file_ir_sbd2( ...
   a_decoderId, ...
   a_cyProfPhaseList, ...
   a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
   a_sensorTechCYCLOPS, a_sensorTechSEAPOINT, ...
   a_sensorParam, ...
   a_floatPres, ...
   a_tabTech, a_floatProgTech, a_floatProgParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% consecutive identical packet types are processed together
if (~isempty(a_cyProfPhaseList))
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
   
   % sometimes, part of sampled data are received after msg type 250. To prevent
   % duplicating associated profiles in CSV file we must delete these packets
   % from the list (because the data are printed by cycle, profile and phase).
   stop = 0;
   while(~stop)
      idDel = [];
      for id1 = 2:length(tabType)
         if (tabType(id1) == 0)
            for id2 = 1:id1-1
               if (tabType(id2) == tabType(id1))
                  % compare the list contents without the last column (the date)
                  info2 = unique(a_cyProfPhaseList(tabStart(id2):tabStop(id2), 1:5), 'rows');
                  idDel = [];
                  for id = tabStart(id1):tabStop(id1)
                     if (ismember(a_cyProfPhaseList(id, 1:5), info2, 'rows'))
                        idDel = [idDel; id1 id];
                     end
                  end
                  if (~isempty(idDel))
                     break;
                  end
               end
            end
            if (~isempty(idDel))
               break;
            end
         end
      end
      if (~isempty(idDel))
         newId = setdiff(tabStart(idDel(1, 1)):tabStop(idDel(1, 1)), idDel(:, 2));
         if (isempty(newId))
            % all the items (tabStart(idDel(1, 1)):tabStop(idDel(1, 1))) of the
            % have already been considered in a previous set => delete the
            % idDel(1, 1) index information
            tabStart(idDel(1, 1)) = [];
            tabStop(idDel(1, 1)) = [];
            tabType(idDel(1, 1)) = [];
         else
            % only some of the items have been considered, check that the
            % remaining indexes are contiguous
            if ((length(unique(diff(newId))) == 1) && (unique(diff(newId)) == 1))
               % update the list
               tabStart(idDel(1, 1)) = newId(1);
               tabStop(idDel(1, 1)) = newId(end);
            else
               % the remaining ids are not contiguous (not processed yet)
               fprintf('ERROR: Float #%d Cycle #%d: Not contiguous indexes => nothing done (TO BE DONE)\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               stop = 1;
            end
         end
      else
         stop = 1;
      end
   end
   
   % print technical and sensor data
   for id = 1:length(tabStart)

      switch (tabType(id))
         
         case 0
            % data packets
            print_data_in_csv_file_ir_sbd2( ...
               a_decoderId, ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT);
            
         case 250
            % sensor technical data packets
            print_sensor_tech_data_in_csv_file_ir_sbd2( ...
               a_decoderId, ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
               a_sensorTechCYCLOPS, a_sensorTechSEAPOINT);
            
         case 251
            % sensor parameter data packets
            print_sensor_param_data_in_csv_file_ir_sbd2( ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_sensorParam);
            
         case 252
            % float pressure data packets
            print_float_pressure_data_in_csv_file_ir_sbd2( ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatPres);
            
         case 253
            % float technical data packets
            print_float_tech_data_in_csv_file_ir_sbd2( ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_tabTech);
            
         case 254
            % float technical programmed data packets
            print_float_prog_tech_data_in_csv_file_ir_sbd2( ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgTech);
            
         case 255
            % float param programmed data packets
            print_float_prog_param_data_in_csv_file_ir_sbd2( ...
               a_cyProfPhaseList, tabStart(id):tabStop(id), ...
               a_floatProgParam);
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for printing packet type #%d contents\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               tabType(id));
      end
      
   end
end

return;
