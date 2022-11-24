% ------------------------------------------------------------------------------
% Collect trajectory data.
%
% SYNTAX :
%  [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_ir_rudics_sbd2( ...
%    a_tabProfiles, a_tabDrift, ...
%    a_floatProgTech, a_floatProgParam, ...
%    a_floatPres, a_tabTech, a_refDay, ...
%    a_cycleStartDate, a_buoyancyRedStartDate, ...
%    a_descentToParkStartDate, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_firstEmerAscentDate, ...
%    a_sensorTechCTD)
%
% INPUT PARAMETERS :
%   a_tabProfiles            : profile data
%   a_tabDrift               : drift measurement data
%   a_floatProgTech          : float prog technical data
%   a_floatProgParam         : float prog param data
%   a_floatPres              : float pressure actions
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
%   a_firstEmerAscentDate    : first emergency ascent date
%   a_sensorTechCTD          : CTD technical data
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
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_ir_rudics_sbd2( ...
   a_tabProfiles, a_tabDrift, ...
   a_floatProgTech, a_floatProgParam, ...
   a_floatPres, a_tabTech, a_refDay, ...
   a_cycleStartDate, a_buoyancyRedStartDate, ...
   a_descentToParkStartDate, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_firstEmerAscentDate, ...
   a_sensorTechCTD)
               
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
global g_decArgo_phaseEmergencyAsc;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% fill value for JULD parameter
paramJuld = get_netcdf_param_attributes('JULD');

% retrieve dated measurements
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
   datedMeasStruct.sensorNumber = profile.sensorNumber;
   
   o_tabTrajIndex = [o_tabTrajIndex;
      0  profile.cycleNumber profile.profileNumber profile.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
end

for idDrift = 1:length(a_tabDrift)
   
   drift = a_tabDrift(idDrift);
      
   datedMeasStruct = get_dated_meas_init_struct(drift.cycleNumber, ...
      drift.profileNumber, drift.phaseNumber);
   
   datedMeasStruct.paramList = drift.paramList;
   datedMeasStruct.paramNumberWithSubLevels = drift.paramNumberWithSubLevels;
   datedMeasStruct.paramNumberOfSubLevels = drift.paramNumberOfSubLevels;
   datedMeasStruct.dateList = drift.dateList;
   
   dates = drift.dates;
   idDated = find(dates ~= paramJuld.fillValue);
   
   datedMeasStruct.dates = drift.dates(idDated);
   datedMeasStruct.data = drift.data(idDated, :);
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
      offset = 0;
      idSub = find(idPres > profile.paramNumberWithSubLevels);
      if (~isempty(idSub))
         subOffset = profile.paramNumberOfSubLevels;
         offset = sum(idSub) - length(idSub);
      end
            
      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end

      pres = profile.data(:, idPres+offset);
      [unused, idMax] = max(pres);

      profInfo = [profInfo;
         profile.cycleNumber profile.profileNumber direction max(pres) idMax idProf];
   end
end

if (~isempty(profInfo))
   uCycle = sort(unique(profInfo(:, 1)));
   uProf = sort(unique(profInfo(:, 2)));
   uDir = sort(unique(profInfo(:, 3)));
   for idC = 1:length(uCycle)
      cyNum = uCycle(idC);
      for idP = 1:length(uProf)
         profNum = uProf(idP);
         for idD = 1:length(uDir)
            dirNum = uDir(idD);
            
            idProf = find((profInfo(:, 1) == cyNum) & ...
               (profInfo(:, 2) == profNum) & ...
               (profInfo(:, 3) == dirNum));
            if (~isempty(idProf))
               [unused, idMax] = max(profInfo(idProf, 4));
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
               datedMeasStruct.sensorNumber = profile.sensorNumber;
               
               o_tabTrajIndex = [o_tabTrajIndex;
                  1  cyNum profNum profile.phaseNumber];
               o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
            end
         end
      end
   end
end

% dated pressures of pump/ev actions

if (~isempty(a_floatPres) && ~isempty(a_cycleStartDate))
   % unpack the input data
   a_floatPresPumpOrEv = a_floatPres{1};
   a_floatPresActPres = a_floatPres{2};
   a_floatPresTime = a_floatPres{3};
   
   if (~isempty(a_floatPresPumpOrEv))
      cyleList = unique(a_floatPresPumpOrEv(:, 1));
      profList = unique(a_floatPresPumpOrEv(:, 2));
      phaseList = unique(a_floatPresPumpOrEv(:, 3));
      
      for idCy = 1:length(cyleList)
         cycleNum = cyleList(idCy);
         for idProf = 1:length(profList)
            profNum = profList(idProf);
            for idPhase = 1:length(phaseList)
               phaseNum = phaseList(idPhase);
               
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
                        
                        for id = 1:length(idPack)
                           idP = idPack(id);
                           
                           floatPresActPres = a_floatPresActPres(idP, 4);
                           floatPresTime = a_floatPresTime(idP, 4);
                           
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
                              otherwise
                                 fprintf('DEC_WARNING: Float #%d Cycle #%d: Phase %s not considered in Msg type 252\n', ...
                                    g_decArgo_floatNum, ...
                                    g_decArgo_cycleNum, ...
                                    get_phase_name(phaseNum));
                           end
                           
                           if (~isempty(refDate))
                              
                              datedMeasStruct = get_dated_meas_init_struct(cycleNum, ...
                                 profNum, phaseNum);
                              
                              paramPres = get_netcdf_param_attributes('PRES');
                              paramPres.resolution = single(10);
                              datedMeasStruct.paramList = paramPres;
                              datedMeasStruct.dateList = get_netcdf_param_attributes('JULD');
                              
                              datedMeasStruct.dates = refDate + floatPresTime/1440;
                              datedMeasStruct.data = floatPresActPres*10;
                              
                              o_tabTrajIndex = [o_tabTrajIndex;
                                 252  cycleNum profNum phaseNum];
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
                           
                           floatPresActPres = a_floatPresActPres(idP, 4);
                           floatPresTime = a_floatPresTime(idP, 4);
                           
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
                              
                              paramPres = get_netcdf_param_attributes('PRES');
                              paramPres.resolution = single(10);
                              datedMeasStruct.paramList = paramPres;
                              datedMeasStruct.dateList = get_netcdf_param_attributes('JULD');
                              
                              datedMeasStruct.dates = refDate + floatPresTime/1440;
                              datedMeasStruct.data = floatPresActPres*10;
                              
                              o_tabTrajIndex = [o_tabTrajIndex;
                                 252  cycleNum profNum phaseNum];
                              o_tabTrajData = [o_tabTrajData; {datedMeasStruct}];
                              
                           end
                        end
                     end
                  end                  
               end
            end
         end
      end
   end
end

% % retrieve packet dates for packet types 254
% for idPack = 1:size(a_floatProgTech, 1)
%    
%    packCycleNumber = a_floatProgTech(idPack, 2);
%    packProfileNumber = a_floatProgTech(idPack, 3);
%    packJuld = a_floatProgTech(idPack, 1);
%    
%    packDateStruct = get_pack_date_init_struct(packCycleNumber, ...
%       packProfileNumber);
% 
%    packDateStruct.packetTime = packJuld;
% 
%    o_tabTrajIndex = [o_tabTrajIndex;
%       254  packCycleNumber packProfileNumber -1];
%    o_tabTrajData = [o_tabTrajData; {packDateStruct}];
% end

% % retrieve packet dates for packet types 255
% for idPack = 1:size(a_floatProgParam, 1)
%    
%    packCycleNumber = a_floatProgParam(idPack, 2);
%    packProfileNumber = a_floatProgParam(idPack, 3);
%    packJuld = a_floatProgParam(idPack, 1);
%    
%    packDateStruct = get_pack_date_init_struct(packCycleNumber, ...
%       packProfileNumber);
% 
%    packDateStruct.packetTime = packJuld;
% 
%    o_tabTrajIndex = [o_tabTrajIndex;
%       255  packCycleNumber packProfileNumber -1];
%    o_tabTrajData = [o_tabTrajData; {packDateStruct}];
% end

% retrieve trajectory information from float technical packets
for idPack = 1:size(a_tabTech, 1)
   
   packCycleNumber = a_tabTech(idPack, 4);
   packProfileNumber = a_tabTech(idPack, 5);
   packPhaseNumber = a_tabTech(idPack, 8);

   trajFromTechStruct = get_traj_from_tech_init_struct(packCycleNumber, ...
      packProfileNumber, packPhaseNumber);

   [trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_sbd2( ...
      trajFromTechStruct, a_tabTech(idPack, :), a_refDay);

   o_tabTrajIndex = [o_tabTrajIndex;
      253  packCycleNumber packProfileNumber packPhaseNumber];
   o_tabTrajData = [o_tabTrajData; {trajFromTechStruct}];
end

% retrieve trajectory information from CTD technical packets
sensorTechCTDSubPres = a_sensorTechCTD{17};
sensorTechCTDSubTemp = a_sensorTechCTD{18};
sensorTechCTDSubSal = a_sensorTechCTD{19};
for idPack = 1:size(sensorTechCTDSubPres, 1)
   
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

return;

% ------------------------------------------------------------------------------
% Get the basic structure to store packet dates.
%
% SYNTAX :
%  [o_packDateStruct] = get_pack_date_init_struct(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%
% OUTPUT PARAMETERS :
%   o_packDateStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_packDateStruct] = get_pack_date_init_struct(a_cycleNum, a_profNum)

% output parameters initialization
o_packDateStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'packetTime', '');

return;

% ------------------------------------------------------------------------------
% Get the basic structure to store dated measurements.
%
% SYNTAX :
%  [o_datedMeasStruct] = get_dated_meas_init_struct(a_cycleNum, a_profNum, a_phaseNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%   a_phaseNum : phase number
%
% OUTPUT PARAMETERS :
%   o_datedMeasStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_datedMeasStruct] = get_dated_meas_init_struct(a_cycleNum, a_profNum, a_phaseNum)

% output parameters initialization
o_datedMeasStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'phaseNumber', a_phaseNum, ...
   'paramList', '', ...
   'paramNumberWithSubLevels', '', ... % position, in the paramList of the parameters with a sublevel
   'paramNumberOfSubLevels', '', ... % number of sublevels for the concerned parameter
   'data', '', ...
   'dateList', '', ...
   'dates', '', ...
   'sensorNumber', -1);

return;

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

return;

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

return;

