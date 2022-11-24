% ------------------------------------------------------------------------------
% Process float pressure packets.
%
% SYNTAX :
%  process_float_pressure_data_ir_rudics( ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_floatPres, ...
%    a_cycleStartDate, a_buoyancyRedStartDate, ...
%    a_descentToParkStartDate, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList         : information (cycle #, prof #, phase #) on each
%                               received packet
%   a_cyProfPhaseIndexList    : index list of the data to print
%   a_floatPres               : float pressure data
%   a_cycleStartDate          : cycle start date
%   a_buoyancyRedStartDate    : buoyancy reduction start date
%   a_descentToParkStartDate  : descent to park start date
%   a_descentToParkEndDate    : descent to park end date
%   a_descentToProfStartDate  : descent to profile start date
%   a_descentToProfEndDate    : descent to profile end date
%   a_ascentStartDate         : ascent start date
%   a_ascentEndDate           : ascent end date
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_pressure_data_ir_rudics( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_floatPres, ...
   a_cycleStartDate, a_buoyancyRedStartDate, ...
   a_descentToParkStartDate, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabelBis;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;

% cycle phases
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseSatTrans;


% unpack the input data
a_floatPresPumpOrEv = a_floatPres{1};
a_floatPresActPres = a_floatPres{2};
a_floatPresTime = a_floatPres{3};

% packet type 252
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cyleList = unique(dataCyProfPhaseList(:, 3));
profList = unique(dataCyProfPhaseList(:, 4));
phaseList = unique(dataCyProfPhaseList(:, 5));

if (~isempty(cyleList))
   if (length(cyleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the float pressure data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (cyleList(1) ~= g_decArgo_cycleNum)
         fprintf('WARNING: Float #%d Cycle #%d: data cycle number (%d) differs from float pressure data SBD file name cycle number (%d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            cyleList(1), g_decArgo_cycleNum);
      end
   end
end

% index list of the data
typeDataList = find(a_cyProfPhaseList(:, 1) == 252);
dataIndexList = [];
for id = 1:length(a_cyProfPhaseIndexList)
   dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(id))];
end

% print the float pressure data
for idCy = 1:length(cyleList)
   cycleNum = cyleList(idCy);
   for idProf = 1:length(profList)
      profNum = profList(idProf);
      for idPhase = 1:length(phaseList)
         phaseNum = phaseList(idPhase);

         idPack = find((a_floatPresPumpOrEv(dataIndexList, 1) == cycleNum) & ...
            (a_floatPresPumpOrEv(dataIndexList, 2) == profNum) & ...
            (a_floatPresPumpOrEv(dataIndexList, 3) == phaseNum));
         
         if (~isempty(idPack))
            
            idTechToUse = find( ...
               (a_cycleStartDate(:, 1) == cycleNum) & ...
               (a_cycleStartDate(:, 2) == profNum) & ...
               (a_cycleStartDate(:, 3) == g_decArgo_phaseSatTrans));
            if (~isempty(idTechToUse))
              
               cycleStartDate = a_cycleStartDate(idTechToUse, 5);
               buoyancyRedStartDate = a_buoyancyRedStartDate(idTechToUse, 5);
               descentToParkStartDate = a_descentToParkStartDate(idTechToUse, 5);
               descentToParkEndDate = a_descentToParkEndDate(idTechToUse, 5);
               descentToProfStartDate = a_descentToProfStartDate(idTechToUse, 5);
               descentToProfEndDate = a_descentToProfEndDate(idTechToUse, 5);
               ascentStartDate = a_ascentStartDate(idTechToUse, 5);
               ascentEndDate = a_ascentEndDate(idTechToUse, 5);
               
               valveActionNum = 0;
               pumpActionNum = 0;
               for id = 1:length(idPack)
                  idP = dataIndexList(idPack(id));
                  
                  floatPresPumpOrEv = a_floatPresPumpOrEv(idP, 4);
                  floatPresActPres = a_floatPresActPres(idP, 4);
                  floatPresTime = a_floatPresTime(idP, 4);
                  
                  pumpOrEv = [];
                  if (floatPresPumpOrEv == 0)
                     pumpOrEv = 'Valve';
                     valveActionNum = valveActionNum + 1;
                     actionNum = valveActionNum;
                  elseif (floatPresPumpOrEv == 1)
                     pumpOrEv = 'Pump';
                     pumpActionNum = pumpActionNum + 1;
                     actionNum = pumpActionNum;
                  end
                  
                  phase = [];
                  refDate = [];
                  switch (phaseNum)
                     case g_decArgo_phaseBuoyRed
                        phase = 'BuoyancyReduction';
                        refDate = buoyancyRedStartDate;
                     case g_decArgo_phaseDsc2Prk
                        phase = 'DescentToParkDepth';
                        refDate = descentToParkStartDate;
                     case g_decArgo_phaseParkDrift
                        phase = 'DriftAtParkDepth';
                        refDate = descentToParkEndDate;
                     case g_decArgo_phaseDsc2Prof
                        phase = 'DescentToProfDepth';
                        refDate = descentToProfStartDate;
                     case g_decArgo_phaseProfDrift
                        phase = 'DriftAtProfDepth';
                        refDate = descentToProfEndDate;
                     case g_decArgo_phaseAscProf
                        phase = 'AscentToSurface';
                        refDate = ascentStartDate;
                     case g_decArgo_phaseAscEmerg
                        phase = 'BuoyancyInflation';
                        refDate = ascentEndDate;
                     otherwise
                        fprintf('DEC_WARNING: Float #%d Cycle #%d: Phase %s not considered in Msg type 252\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_cycleNum, ...
                           get_phase_name(phaseNum));
                  end
                  
                  if ((~isempty(pumpOrEv)) && (~isempty(phase)))
                     ncParamName = sprintf('PRES_%sAction#%dDuring%s_dBAR', ...
                        pumpOrEv, actionNum, phase);
                     
                     g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
                        252 cycleNum profNum -1 length(g_decArgo_outputNcParamLabelBis)+1];
                     g_decArgo_outputNcParamLabelBis{end+1} = ncParamName;
                     g_decArgo_outputNcParamValue{end+1} = floatPresActPres*10;
                     
                     ncParamName = sprintf('CLOCK_%sAction#%dDuring%s_YYYYMMDDHHMMSS', ...
                        pumpOrEv, actionNum, phase);
                     ncParamValue = refDate + floatPresTime/1440;
                     
                     g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
                        252 cycleNum profNum -1 length(g_decArgo_outputNcParamLabelBis)+1];
                     g_decArgo_outputNcParamLabelBis{end+1} = ncParamName;
                     g_decArgo_outputNcParamValue{end+1} = ...
                        datestr(ncParamValue + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
                  end
               end
            end
         end
      end
   end
end

return;
