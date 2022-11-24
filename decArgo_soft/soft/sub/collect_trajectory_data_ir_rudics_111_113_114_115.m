% ------------------------------------------------------------------------------
% Collect trajectory data.
%
% SYNTAX :
%  [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_ir_rudics_111_113_114_115( ...
%    a_decoderId, a_tabProfiles, a_tabDrift, ...
%    a_floatPres, a_grounding, a_tabTech, a_refDay, ...
%    a_cycleStartDate, a_buoyancyRedStartDate, ...
%    a_descentToParkStartDate, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_firstEmerAscentDate, ...
%    a_sensorTechCTD, a_deepCycleFlag)
%
% INPUT PARAMETERS :
%   a_decoderId              : float decoder Id
%   a_tabProfiles            : profile data
%   a_tabDrift               : drift measurement data
%   a_floatPres              : float pressure actions
%   a_grounding              : grounding data
%   a_tabTech                : float technical data
%   a_refDay                 : reference day (day of the first descent)
%   a_cycleStartDate         : cycle start date
%   a_buoyancyRedStartDate   : buoyancy reduction start date
%   a_descentToParkStartDate : descent to park start date
%   a_descentToParkEndDate   : descent to park end date
%   a_descentToProfStartDate : descent to profile start date
%   a_descentToProfEndDate   : descent to profile end date
%   a_ascentStartDate        : ascent start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_firstEmerAscentDate    : first emergency ascent date
%   a_sensorTechCTD          : CTD technical data
%   a_deepCycleFlag          : 1 if it is a deep cycle, 0 if it is a surface one
%
% OUTPUT PARAMETERS :
%   o_tabTrajIndex : collected trajectory index information
%   o_tabTrajData  : collected trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_ir_rudics_111_113_114_115( ...
   a_decoderId, a_tabProfiles, a_tabDrift, ...
   a_floatPres, a_grounding, a_tabTech, a_refDay, ...
   a_cycleStartDate, a_buoyancyRedStartDate, ...
   a_descentToParkStartDate, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_firstEmerAscentDate, ...
   a_sensorTechCTD, a_deepCycleFlag)

% output parameters initialization
o_tabTrajIndex = [];
o_tabTrajData = [];

% cycle phases
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseEmergencyAsc;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% phase of received data
global g_decArgo_receivedDataPhase;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


% fill value for JULD parameter
paramJuld = get_netcdf_param_attributes('JULD');

% store DOXY profile data
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   if (profile.sensorNumber == 1)
      
      datedMeasStruct = get_dated_meas_init_struct(profile.cycleNumber, ...
         profile.profileNumber, profile.phaseNumber);
      
      datedMeasStruct.paramList = profile.paramList;
      datedMeasStruct.paramNumberWithSubLevels = profile.paramNumberWithSubLevels;
      datedMeasStruct.paramNumberOfSubLevels = profile.paramNumberOfSubLevels;
      datedMeasStruct.dateList = profile.dateList;
      datedMeasStruct.dates = profile.dates;
      datedMeasStruct.data = profile.data;
      datedMeasStruct.ptsForDoxy = profile.ptsForDoxy;
      datedMeasStruct.sensorNumber = profile.sensorNumber;
      
      if (profile.direction == 'D')
         o_tabTrajIndex = [o_tabTrajIndex;
            2  profile.cycleNumber profile.profileNumber profile.phaseNumber];
      else
         o_tabTrajIndex = [o_tabTrajIndex;
            3  profile.cycleNumber profile.profileNumber profile.phaseNumber];
      end
      o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
      
      % remove temporary PPOX_DOXY
      idPpoxDoxy = find(strcmp({a_tabProfiles(idProf).paramList.name}, 'PPOX_DOXY') == 1);
      if (~isempty(idPpoxDoxy))
         a_tabProfiles(idProf).data(:, idPpoxDoxy) = [];
         if (~isempty(a_tabProfiles(idProf).dataQc))
            a_tabProfiles(idProf).dataQc(:, idPpoxDoxy) = [];
         end
         a_tabProfiles(idProf).paramList(idPpoxDoxy) = [];
      end
   end
end

% retrieve profile dated measurements
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   datedMeasStruct = get_dated_meas_init_struct(profile.cycleNumber, ...
      profile.profileNumber, profile.phaseNumber);
   
   datedMeasStruct.paramList = profile.paramList;
   datedMeasStruct.paramNumberWithSubLevels = profile.paramNumberWithSubLevels;
   datedMeasStruct.paramNumberOfSubLevels = profile.paramNumberOfSubLevels;
   datedMeasStruct.dateList = profile.dateList;
   
   dates = profile.dates;
   idDated = find(dates ~= paramJuld.fillValue);
   
   datedMeasStruct.dates = profile.dates(idDated);
   datedMeasStruct.data = profile.data(idDated, :);
   if (~isempty(profile.ptsForDoxy))
      datedMeasStruct.ptsForDoxy = profile.ptsForDoxy(idDated, :);
   end
   datedMeasStruct.sensorNumber = profile.sensorNumber;
   
   o_tabTrajIndex = [o_tabTrajIndex;
      0  profile.cycleNumber profile.profileNumber profile.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
end

% drift at park measurements
for idDrift = 1:length(a_tabDrift)
   
   drift = a_tabDrift(idDrift);
   
   datedMeasStruct = get_dated_meas_init_struct(drift.cycleNumber, ...
      drift.profileNumber, drift.phaseNumber);
   
   datedMeasStruct.paramList = drift.paramList;
   datedMeasStruct.paramNumberWithSubLevels = drift.paramNumberWithSubLevels;
   datedMeasStruct.paramNumberOfSubLevels = drift.paramNumberOfSubLevels;
   datedMeasStruct.dateList = drift.dateList;
   
   datedMeasStruct.dates = drift.dates;
   datedMeasStruct.data = drift.data;
   datedMeasStruct.ptsForDoxy = drift.ptsForDoxy;
   datedMeasStruct.sensorNumber = drift.sensorNumber;
   
   o_tabTrajIndex = [o_tabTrajIndex;
      0  drift.cycleNumber drift.profileNumber drift.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
end

% compute deepest bin of each profile
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   idPres = find(strcmp({profile.paramList.name}, 'PRES') == 1);
   if (~isempty(idPres))
      if (~isempty(profile.paramNumberWithSubLevels))
         idSub = find(profile.paramNumberWithSubLevels < idPres);
         if (~isempty(idSub))
            idPres = idPres + sum(profile.paramNumberOfSubLevels(idSub)) - length(idSub);
         end
      end
      
      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end
      
      pres = profile.data(:, idPres);
      [~, idMax] = max(pres);
      
      profInfo = [profInfo;
         profile.cycleNumber profile.profileNumber direction max(pres) idMax idProf];
   end
end

if (~isempty(profInfo))
   cycleProfDirList = unique(profInfo(:, 1:3), 'rows');
   for idCyPrDir = 1:size(cycleProfDirList, 1)
      cyNum = cycleProfDirList(idCyPrDir, 1);
      profNum = cycleProfDirList(idCyPrDir, 2);
      dirNum = cycleProfDirList(idCyPrDir, 3);
      
      idProf = find((profInfo(:, 1) == cyNum) & ...
         (profInfo(:, 2) == profNum) & ...
         (profInfo(:, 3) == dirNum));
      if (~isempty(idProf))
         [~, idMax] = max(profInfo(idProf, 4));
         idProfMax = idProf(idMax);
         
         profile = a_tabProfiles(profInfo(idProfMax, 6));
         
         datedMeasStruct = get_dated_meas_init_struct(cyNum, ...
            profNum, profile.phaseNumber);
         
         datedMeasStruct.paramList = profile.paramList;
         datedMeasStruct.paramNumberWithSubLevels = profile.paramNumberWithSubLevels;
         datedMeasStruct.paramNumberOfSubLevels = profile.paramNumberOfSubLevels;
         datedMeasStruct.dateList = profile.dateList;
         
         datedMeasStruct.dates = profile.dates(profInfo(idProfMax, 5));
         datedMeasStruct.data = profile.data(profInfo(idProfMax, 5), :);
         if (~isempty(profile.ptsForDoxy))
            datedMeasStruct.ptsForDoxy = profile.ptsForDoxy(profInfo(idProfMax, 5), :);
         end
         datedMeasStruct.sensorNumber = profile.sensorNumber;
         
         o_tabTrajIndex = [o_tabTrajIndex;
            1  cyNum profNum profile.phaseNumber];
         o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
      end
   end
end

% dated pressures of pump/ev actions

if (~isempty(a_floatPres) && ~isempty(a_cycleStartDate))
   % unpack the input data
   a_floatPresPumpOrEv = a_floatPres{1};
   a_floatPresActPres = a_floatPres{2};
   a_floatPresActTime = a_floatPres{3};
   a_floatPresActDuration = a_floatPres{4};
   
   if (~isempty(a_floatPresPumpOrEv))
      cycleProfPhaseList = unique(a_floatPresPumpOrEv(:, 1:3), 'rows');
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      paramValveFlag = get_netcdf_param_attributes('VALVE_ACTION_FLAG');
      paramPumpFlag = get_netcdf_param_attributes('PUMP_ACTION_FLAG');
      paramValveActionDuration = get_netcdf_param_attributes('VALVE_ACTION_DURATION');
      paramPumpActionDuration = get_netcdf_param_attributes('PUMP_ACTION_DURATION');
      
      for idCyPrPh = 1:size(cycleProfPhaseList, 1)
         cycleNum = cycleProfPhaseList(idCyPrPh, 1);
         profNum = cycleProfPhaseList(idCyPrPh, 2);
         phaseNum = cycleProfPhaseList(idCyPrPh, 3);
         
         if (phaseNum ~= g_decArgo_phaseEmergencyAsc)
            
            idPack = find((a_floatPresPumpOrEv(:, 1) == cycleNum) & ...
               (a_floatPresPumpOrEv(:, 2) == profNum) & ...
               (a_floatPresPumpOrEv(:, 3) == phaseNum));
            
            if (~isempty(idPack))
               
               idTechToUse = find( ...
                  (a_cycleStartDate(:, 1) == cycleNum) & ...
                  (a_cycleStartDate(:, 2) == profNum) & ...
                  (a_cycleStartDate(:, 3) == g_decArgo_phaseSatTrans));
               if (~isempty(idTechToUse))
                  
                  buoyancyRedStartDate = a_buoyancyRedStartDate(idTechToUse, 5);
                  descentToParkStartDate = a_descentToParkStartDate(idTechToUse, 5);
                  descentToParkEndDate = a_descentToParkEndDate(idTechToUse, 5);
                  descentToProfStartDate = a_descentToProfStartDate(idTechToUse, 5);
                  descentToProfEndDate = a_descentToProfEndDate(idTechToUse, 5);
                  ascentStartDate = a_ascentStartDate(idTechToUse, 5);
                  ascentEndDate = a_ascentEndDate(idTechToUse, 5) + 10/1440;
                  transStartDate = a_transStartDate(idTechToUse, 5);

                  for id = 1:length(idPack)
                     idP = idPack(id);
                     
                     floatPresPumpOrEv = a_floatPresPumpOrEv(idP, 4);
                     floatPresActPres = a_floatPresActPres(idP, 4);
                     floatPresActTime = a_floatPresActTime(idP, 4);
                     floatPresActDuration = a_floatPresActDuration(idP, 4);
                     
                     refDate = [];
                     switch (phaseNum)
                        case g_decArgo_phaseBuoyRed
                           refDate = buoyancyRedStartDate;
                        case g_decArgo_phaseDsc2Prk
                           refDate = descentToParkStartDate;
                        case g_decArgo_phaseParkDrift
                           refDate = descentToParkEndDate;
                        case g_decArgo_phaseDsc2Prof
                           refDate = descentToProfStartDate;
                        case g_decArgo_phaseProfDrift
                           refDate = descentToProfEndDate;
                        case g_decArgo_phaseAscProf
                           refDate = ascentStartDate;
                        case g_decArgo_phaseAscEmerg
                           refDate = ascentEndDate;
                        case g_decArgo_phaseSatTrans
                           refDate = transStartDate;
                        otherwise
                           fprintf('DEC_WARNING: Float #%d Cycle #%d: Phase %s not considered in Msg type 252\n', ...
                              g_decArgo_floatNum, ...
                              g_decArgo_cycleNum, ...
                              get_phase_name(phaseNum));
                     end
                     
                     if (~isempty(refDate))
                        
                        datedMeasStruct = get_dated_meas_init_struct(cycleNum, ...
                           profNum, phaseNum);
                        
                        datedMeasStruct.paramList = paramPres;
                        datedMeasStruct.data = floatPresActPres*10;
                        if (floatPresPumpOrEv == 1)
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramPumpFlag];
                           datedMeasStruct.data = [datedMeasStruct.data 1];
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramPumpActionDuration];
                           datedMeasStruct.data = [datedMeasStruct.data floatPresActDuration];
                        else
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramValveFlag];
                           datedMeasStruct.data = [datedMeasStruct.data 1];
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramValveActionDuration];
                           datedMeasStruct.data = [datedMeasStruct.data floatPresActDuration];
                        end
                        
                        datedMeasStruct.dateList = get_netcdf_param_attributes('JULD');
                        datedMeasStruct.dates = refDate + floatPresActTime/1440;
                        
                        o_tabTrajIndex = [o_tabTrajIndex;
                           252 cycleNum profNum phaseNum];
                        o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
                     end
                  end
               end               
            end
         else
            
            idPack = find((a_floatPresPumpOrEv(:, 1) == cycleNum) & ...
               (a_floatPresPumpOrEv(:, 2) == profNum) & ...
               (a_floatPresPumpOrEv(:, 3) == phaseNum));
            
            if (~isempty(idPack))
               
               idTechToUse = find( ...
                  (a_firstEmerAscentDate(:, 1) == cycleNum) & ...
                  (a_firstEmerAscentDate(:, 2) == profNum) & ...
                  ((a_firstEmerAscentDate(:, 3) == g_decArgo_phaseSatTrans) | ...
                  (a_firstEmerAscentDate(:, 3) == g_decArgo_phaseEmergencyAsc)));
               if (~isempty(idTechToUse))
                  
                  firstEmerAscentDate = a_firstEmerAscentDate(idTechToUse, 5);
                  
                  for id = 1:length(idPack)
                     idP = idPack(id);
                     
                     floatPresPumpOrEv = a_floatPresPumpOrEv(idP, 4);
                     floatPresActPres = a_floatPresActPres(idP, 4);
                     floatPresActTime = a_floatPresActTime(idP, 4);
                     floatPresActDuration = a_floatPresActDuration(idP, 4);
                     
                     refDate = [];
                     switch (phaseNum)
                        case g_decArgo_phaseEmergencyAsc
                           refDate = firstEmerAscentDate;
                        otherwise
                           fprintf('DEC_WARNING: Float #%d Cycle #%d: Phase %s not considered in Msg type 252\n', ...
                              g_decArgo_floatNum, ...
                              g_decArgo_cycleNum, ...
                              get_phase_name(phaseNum));
                     end
                     
                     if (~isempty(refDate))
                        
                        datedMeasStruct = get_dated_meas_init_struct(cycleNum, ...
                           profNum, phaseNum);
                        
                        datedMeasStruct.paramList = paramPres;
                        datedMeasStruct.data = floatPresActPres*10;
                        if (floatPresPumpOrEv == 1)
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramPumpFlag];
                           datedMeasStruct.data = [datedMeasStruct.data 1];
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramPumpActionDuration];
                           datedMeasStruct.data = [datedMeasStruct.data floatPresActDuration];
                        else
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramValveFlag];
                           datedMeasStruct.data = [datedMeasStruct.data 1];
                           datedMeasStruct.paramList = [datedMeasStruct.paramList paramValveActionDuration];
                           datedMeasStruct.data = [datedMeasStruct.data floatPresActDuration];
                        end
                        
                        datedMeasStruct.dateList = get_netcdf_param_attributes('JULD');
                        datedMeasStruct.dates = refDate + floatPresActTime/1440;
                        
                        o_tabTrajIndex = [o_tabTrajIndex;
                           252 cycleNum profNum phaseNum];
                        o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
                     end
                  end
               end
            end
         end
      end
   end
end

% grounding data

if (~isempty(a_grounding))
   % unpack the input data
   a_groundingDate = a_grounding{1};
   a_groundingPres = a_grounding{2};
   a_groundingSetPoint = a_grounding{3};
   a_groundingIntVacuum = a_grounding{4};
   
   cycleProfPhaseList = unique(a_groundingDate(:, 1:3), 'rows');
   
   paramPres = get_netcdf_param_attributes('PRES');
   paramSetPoint = get_netcdf_param_attributes('SET_POINT');
   paramInternalVacuum = get_netcdf_param_attributes('INTERNAL_VACUUM');

   for idCyPrPh = 1:size(cycleProfPhaseList, 1)
      cycleNum = cycleProfPhaseList(idCyPrPh, 1);
      profNum = cycleProfPhaseList(idCyPrPh, 2);
      phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
      idPack = find((a_groundingDate(:, 1) == cycleNum) & ...
         (a_groundingDate(:, 2) == profNum) & ...
         (a_groundingDate(:, 3) == phaseNum));
      
      if (~isempty(idPack))
      
         for id = 1:length(idPack)
            idP = idPack(id);
            
            groundingDate = a_groundingDate(idP, 4);
            groundingPres = a_groundingPres(idP, 4);
            groundingSetPoint = a_groundingSetPoint(idP, 4);
            groundingIntVacuum = a_groundingIntVacuum(idP, 4);

            datedMeasStruct = get_dated_meas_init_struct(cycleNum, ...
               profNum, phaseNum);
            
            datedMeasStruct.paramList = [paramPres paramSetPoint paramInternalVacuum];
            datedMeasStruct.data = [groundingPres groundingSetPoint groundingIntVacuum];
            
            datedMeasStruct.dateList = get_netcdf_param_attributes('JULD');
            datedMeasStruct.dates = groundingDate;
            
            o_tabTrajIndex = [o_tabTrajIndex;
               247 cycleNum profNum phaseNum];
            o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
         end
      end
   end
end

% retrieve trajectory information from float technical packets
for idPack = 1:size(a_tabTech, 1)
   
   packCycleNumber = a_tabTech(idPack, 4);
   packProfileNumber = a_tabTech(idPack, 5);
   packPhaseNumber = a_tabTech(idPack, 8);
   
   % set the current reference day
   refDay = a_refDay;
   if (~isempty(g_decArgo_julD2FloatDayOffset))
      idF = find((g_decArgo_julD2FloatDayOffset(:, 1) == packCycleNumber) & ...
         (g_decArgo_julD2FloatDayOffset(:, 2) == packProfileNumber));
      if (~isempty(idF))
         refDay = g_decArgo_julD2FloatDayOffset(idF, 3);
      else
         refDay = g_decArgo_julD2FloatDayOffset(end, 3);
      end
   end
   
   trajFromTechStruct = get_traj_from_tech_init_struct(packCycleNumber, ...
      packProfileNumber, packPhaseNumber);
   
   [trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_111_113_114_115( ...
      trajFromTechStruct, a_tabTech(idPack, :), refDay);
   
   o_tabTrajIndex = [o_tabTrajIndex;
      253  packCycleNumber packProfileNumber packPhaseNumber];
   o_tabTrajData = [o_tabTrajData; {trajFromTechStruct}];
end

% retrieve trajectory information from CTD technical packets
if (a_deepCycleFlag) % to ignore packets 250 transmitted during PRELUDE or SURF_WAIT phases
   sensorTechCTDSubPres = a_sensorTechCTD{17};
   sensorTechCTDSubTemp = a_sensorTechCTD{18};
   sensorTechCTDSubSal = a_sensorTechCTD{19};
   for idPack = 1:size(sensorTechCTDSubPres, 1)
      
      if (any([sensorTechCTDSubPres(idPack, 3) ...
            sensorTechCTDSubTemp(idPack, 3) ...
            sensorTechCTDSubSal(idPack, 3)] ~= 0))
         
         packCycleNumber = sensorTechCTDSubPres(idPack, 1);
         packProfileNumber = sensorTechCTDSubPres(idPack, 2);
         
         trajFromCtdTechStruct = get_traj_from_ctd_tech_init_struct(packCycleNumber, ...
            packProfileNumber);
         
         trajFromCtdTechStruct.subsurface_pres = sensorTechCTDSubPres(idPack, 3);
         trajFromCtdTechStruct.subsurface_temp = sensorTechCTDSubTemp(idPack, 3);
         trajFromCtdTechStruct.subsurface_psal = sensorTechCTDSubSal(idPack, 3);
         
         o_tabTrajIndex = [o_tabTrajIndex;
            250  packCycleNumber packProfileNumber -1];
         o_tabTrajData = [o_tabTrajData; {trajFromCtdTechStruct}];
      end
   end
end

% the unpumped part of the profile should not be duplicated in the TRAJ file
% anymore (whatever the value of CONFIG_OptodeMeasurementsInAir_LOGICAL is)
% see specification in "NOTE ON “NEAR SURFACE” AND “IN AIR” DATA PROCESSING IN
% THE CORIOLIS MATLAB DECODER" (V1.0 dated 29/06/2018)

% create IN AIR measurement profile (PPOX_DOXY)
% if (~isempty(a_tabProfiles))
%    cyNumList = unique([a_tabProfiles.cycleNumber]);
%    profNumList = unique([a_tabProfiles.profileNumber]);
%    for idCyN = 1:length(cyNumList)
%       for idProfN = 1:length(profNumList)
%          idFCtd = find(([a_tabProfiles.cycleNumber] == cyNumList(idCyN)) & ...
%             ([a_tabProfiles.profileNumber] == profNumList(idCyN)) & ...
%             ([a_tabProfiles.direction] == 'A') & ...
%             ([a_tabProfiles.sensorNumber] == 0));
%          idFDo = find(([a_tabProfiles.cycleNumber] == cyNumList(idCyN)) & ...
%             ([a_tabProfiles.profileNumber] == profNumList(idCyN)) & ...
%             ([a_tabProfiles.direction] == 'A') & ...
%             ([a_tabProfiles.sensorNumber] == 1));
%          if ((length(idFCtd) == 1) && (length(idFDo) == 1))
%
%             [inAirMeasProfile] = create_in_air_meas_profile_ir_rudics_sbd2(a_decoderId, ...
%                a_tabProfiles(idFCtd), a_tabProfiles(idFDo));
%
%             if (~isempty(inAirMeasProfile))
%                datedMeasStruct = get_dated_meas_init_struct( ...
%                   inAirMeasProfile.cycleNumber, ...
%                   inAirMeasProfile.profileNumber, ...
%                   inAirMeasProfile.phaseNumber);
%
%                datedMeasStruct.paramList = inAirMeasProfile.paramList;
%                datedMeasStruct.paramNumberWithSubLevels = inAirMeasProfile.paramNumberWithSubLevels;
%                datedMeasStruct.paramNumberOfSubLevels = inAirMeasProfile.paramNumberOfSubLevels;
%                datedMeasStruct.dateList = inAirMeasProfile.dateList;
%
%                datedMeasStruct.dates = inAirMeasProfile.dates;
%                datedMeasStruct.data = inAirMeasProfile.data;
%
%                o_tabTrajIndex = [o_tabTrajIndex;
%                   2  inAirMeasProfile.cycleNumber inAirMeasProfile.profileNumber inAirMeasProfile.phaseNumber];
%                o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
%             end
%          end
%       end
%    end
% end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store trajectory data collected from tech data.
%
% SYNTAX :
%  [o_trajFromTechStruct] = get_traj_from_tech_init_struct(a_cycleNum, a_profNum, a_phaseNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%   a_phaseNum : phase number
%
% OUTPUT PARAMETERS :
%   o_trajFromTechStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajFromTechStruct] = get_traj_from_tech_init_struct(a_cycleNum, a_profNum, a_phaseNum)

% output parameters initialization
o_trajFromTechStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'phaseNumber', a_phaseNum, ...
   'packetTime', '', ...
   'rtcState', '', ...
   'cycleStartDate', '', ...
   'buoyancyRedStartDate', '', ...
   'descentToParkStartDate', '', ...
   'firstStabDate', '', ...
   'firstStabPres', '', ...
   'descentToParkEndDate', '', ...
   'maxPDuringDescentToPark', '', ...
   'minPDuringDriftAtPark', '', ...
   'maxPDuringDriftAtPark', '', ...
   'descentToProfStartDate', '', ...
   'descentToProfEndDate', '', ...
   'maxPDuringDescentToProf', '', ...
   'minPDuringDriftAtProf', '', ...
   'maxPDuringDriftAtProf', '', ...
   'ascentStartDate', '', ...
   'ascentEndDate', '', ...
   'transStartDate', '', ...
   'groundingDate', '', ...
   'groundingPres', '', ...
   'firstEmergencyAscentDate', '', ...
   'firstEmergencyAscentpres', '', ...
   'gpsDate', '', ...
   'gpsLon', '', ...
   'gpsLat', '', ...
   'gpsQc', '', ...
   'gpsAccuracy', '');

return

% ------------------------------------------------------------------------------
% Get the basic structure to store trajectory data collected from CTD tech data.
%
% SYNTAX :
%  [o_trajFromCtdTechStruct] = get_traj_from_ctd_tech_init_struct(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%
% OUTPUT PARAMETERS :
%   o_trajFromCtdTechStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajFromTechStruct] = get_traj_from_ctd_tech_init_struct(a_cycleNum, a_profNum)

% output parameters initialization
o_trajFromTechStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'subsurface_pres', '', ...
   'subsurface_temp', '', ...
   'subsurface_psal', '');

return

