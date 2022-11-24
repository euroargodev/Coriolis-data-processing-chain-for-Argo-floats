% ------------------------------------------------------------------------------
% Sort trajectory data structures according to a predefined measurement code
% order
%
% SYNTAX :
%  [o_tabTrajNMeas] = sort_trajectory_data(a_tabTrajNMeas, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : input N_MEASUREMENT trajectory data
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = sort_trajectory_data(a_tabTrajNMeas, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;


% sort the N_MEASUREMENT data structures according to the predefined measurement
% code order
if (~isempty(o_tabTrajNMeas))
   
   apexApf11IrDecoderIdList = [1321 1322];
   if (~ismember(a_decoderId, apexApf11IrDecoderIdList))
      
      mcOrderList = get_mc_order_list(a_decoderId);
      if (~isempty(mcOrderList))
         
         cycleNumList = unique([o_tabTrajNMeas.cycleNumber]);
         for idC = 1:length(cycleNumList)
            cycleNum = cycleNumList(idC);
            
            idTrajNMeasStruct = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
            tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;
            
            measCodeList = [tabMeas.measCode];
            if (~isempty(setdiff(measCodeList, mcOrderList)))
               fprintf('WARNING: Float #%d Cycle #%d: some MC are not in predefined ordered list (check get_mc_order_list)\n', ...
                  g_decArgo_floatNum, ...
                  cycleNum);
            end
            newList = [];
            for iMC = 1:length(mcOrderList)
               idForMeasCode = find(measCodeList == mcOrderList(iMC));
               newList = [newList idForMeasCode];
            end
            if (length(newList) == length(tabMeas))
               tabMeas = tabMeas(newList);
            else
               fprintf('WARNING: Float #%d Cycle #%d: MC not sorted\n', ...
                  g_decArgo_floatNum, ...
                  cycleNum);
            end
            
            o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeas;
            
         end
      end
      
   else
      
      % for Apex APF11 Iridium: since most of the N_MEAS are dated we first sort
      % the dated MCs of a given cycle in chronological order and then insert
      % the remaining MCs (sorted according to their value).
      
      cycleNumList = unique([o_tabTrajNMeas.cycleNumber]);
      for idC = 1:length(cycleNumList)
         cycleNum = cycleNumList(idC);
         
         % N_MEAS of the current cycle
         idTrajNMeasStruct = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
         tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;
         
         % create the array of dates of MCs
         tabDates = ones(size(tabMeas))*g_decArgo_dateDef;
         idDate1 = find(~cellfun(@isempty, {tabMeas.juld}));
         idDate2 = find([tabMeas(idDate1).juld] ~= g_decArgo_dateDef);
         tabDates(idDate1(idDate2)) = [tabMeas(idDate1(idDate2)).juld];
         if (any(tabDates == g_decArgo_dateDef))
            idF = find(tabDates == g_decArgo_dateDef);
            idDate1 = find(~cellfun(@isempty, {tabMeas(idF).juldAdj}));
            idDate2 = find([tabMeas(idF(idDate1)).juldAdj] ~= g_decArgo_dateDef);
            tabDates(idF(idDate1(idDate2))) = [tabMeas(idF(idDate1(idDate2))).juld];
         end
         
         % sort dated MCs
         idF = find(tabDates ~= g_decArgo_dateDef);
         [~, idSort] = sort(tabDates(idF));
         tabMeasNew = tabMeas(idF(idSort));
         
         % insert remaining MCs
         idF = find(tabDates == g_decArgo_dateDef);
         for idM = 1:length(idF)
            idIn = idF(idM);
            idOut = find([tabMeasNew.measCode] > tabMeas(idIn).measCode, 1, 'first');
            tabMeasNew(idOut+1:end+1) = tabMeasNew(idOut:end);
            tabMeasNew(idOut) = tabMeas(idIn);
         end
         
         o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeasNew;
         clear tabMeas;
      end
      
   end
end

return;

% ------------------------------------------------------------------------------
% Retrieve MC measurements order assigned to a give decoder Id.
%
% SYNTAX :
%  [o_mcOrderList] = get_mc_order_list(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_mcOrderList : MCs ordering list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mcOrderList] = get_mc_order_list(a_decoderId)

% output parameters initialization
o_mcOrderList = [];

% current float WMO number
global g_decArgo_floatNum;

% global measurement codes
global g_MC_FillValue;
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_DownTimeEnd;
global g_MC_AST_Float;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_MedianValueInAscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_ContinuousProfileStartOrStop;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_SpyAtSurface;
global g_MC_NearSurfaceSeriesOfMeas;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_SingleMeasToTET;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InAirSingleMeas;
global g_MC_InAirSeriesOfMeas;


switch (a_decoderId)

   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      % Provor/Arvor Argos pre-Naos 2013
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {30}
      % Provor/Arvor Argos post-Naos 2013 PTS
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
   
   case {32}
      % Provor/Arvor Argos post-Naos 2013 PTSO => with g_MC_InAirSeriesOfMeas
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];

   case {201, 202, 203, 215, 216}
      % Arvor Deep
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
   
   case {204, 205, 206, 207, 208}
      % Provor/Arvor Iridium
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {209}
      % Provor/Arvor Iridium
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {210, 211, 212, 213, 214, 217}
      % Arvor-ARN Iridium
      % Arvor-ARN-Ice Iridium
      % Provor-ARN-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      % Arvor-ARN-DO-Ice Iridium 5.46
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];     
   
   case {105, 106, 107, 108, 109, 110, 111, 301, 302, 303}
      % Provor Remocean & Arvor CM
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];

   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016, 1021, 1022}
      % Apex Argos
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DET ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkMeanOfDiff ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_MedianValueInAscProf ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1314}
      % Apex Iridium Rudics & Sbd
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_PST ...
         g_MC_DET ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_Surface ...
         g_MC_TST ...
         g_MC_TET ...
         ];
      
   case {1201}
      % Navis
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_PST ...
         g_MC_DET ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_NearSurfaceSeriesOfMeas ...
         g_MC_InAirSeriesOfMeas ...
         g_MC_Surface ...
         g_MC_TST ...
         g_MC_TET ...
         ];

   case {2001, 2002, 2003}
      % Nova/Dova
      o_mcOrderList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_SpyInDescToPark ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_Surface ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   otherwise
      fprintf('WARNING: Float #%d: No MC order list assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

o_mcOrderList = unique(o_mcOrderList, 'stable');

return;
