% ------------------------------------------------------------------------------
% Collect trajectory data.
%
% SYNTAX :
%  [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_cts5( ...
%    a_tabProfiles, a_tabDrift, a_tabSurf, a_tabTech, a_subSurfaceMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles    : profile data
%   a_tabDrift       : drift measurement data
%   a_tabSurf        : surface measurement data
%   a_tabTech        : float technical data
%   a_subSurfaceMeas : unique sub surface measurement
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajIndex, o_tabTrajData] = collect_trajectory_data_cts5( ...
   a_tabProfiles, a_tabDrift, a_tabSurf, a_tabTech, a_subSurfaceMeas)
               
% output parameters initialization
o_tabTrajIndex = [];
o_tabTrajData = [];

% cycle phases
global g_decArgo_phaseEndOfLife;

% global measurement codes
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_DriftAtPark;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_InAirSeriesOfMeas;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% decoded event data
global g_decArgo_eventDataTraj;


COMPARISON_FLAG = 0;

% array to store traj data from APMT technical data and from event data
tabTrajIndexAll = [];
tabTrajDataAll = [];

% retrieve trajectory information from APMT technical data
for idPack = 1:size(a_tabTech, 1)
   
   cycleNumber = a_tabTech{idPack, 1};
   profileNumber = a_tabTech{idPack, 2};
   phaseNumber = a_tabTech{idPack, 3};
   techData = a_tabTech{idPack, 4};
   
   groupList = cell2mat(techData)';
   groupList = [groupList.group];
   uGroupList = unique(groupList(find(groupList > 0)));
   for idG = 1:length(uGroupList)
      idF = find(groupList == uGroupList(idG));
      tabTrajIndexAll = [tabTrajIndexAll;
         techData{idF(1)}.measCode cycleNumber profileNumber phaseNumber];
      tabTrajDataAll = [tabTrajDataAll; {techData(idF)}];
   end
   idF = find(groupList == 0);
   for idG = idF
      tabTrajIndexAll = [tabTrajIndexAll;
         techData{idG}.measCode cycleNumber profileNumber phaseNumber];
      tabTrajDataAll = [tabTrajDataAll; {techData(idG)}];
   end
end

% retrieve trajectory information from event data
if (~isempty(g_decArgo_eventDataTraj))
   
   groupList = cell2mat(g_decArgo_eventDataTraj)';
   groupList = [groupList.group];
   uGroupList = unique(groupList(find(groupList > 0)));
   for idG = 1:length(uGroupList)
      idF = find(groupList == uGroupList(idG));
      tabTrajIndexAll = [tabTrajIndexAll;
         g_decArgo_eventDataTraj{idF(1)}.measCode g_decArgo_eventDataTraj{idF(1)}.cycleNumber g_decArgo_eventDataTraj{idF(1)}.patternNumber -1];
      tabTrajDataAll = [tabTrajDataAll; {g_decArgo_eventDataTraj(idF)}];
   end
   idF = find(groupList == 0);
   for idG = idF
      tabTrajIndexAll = [tabTrajIndexAll;
         g_decArgo_eventDataTraj{idG}.measCode g_decArgo_eventDataTraj{idG}.cycleNumber g_decArgo_eventDataTraj{idG}.patternNumber -1];
      tabTrajDataAll = [tabTrajDataAll; {g_decArgo_eventDataTraj(idG)}];
   end
end

if (~isempty(tabTrajIndexAll))
   
   % merge Tech and Event traj information
   idToDel = [];
   idFTraj = find(tabTrajIndexAll(:, 4) ~= -1);
   idFEvt = find(tabTrajIndexAll(:, 4) == -1);
   uEvtTrajMeasCode = unique(tabTrajIndexAll(idFEvt, 1));
   for idTrajMeasCode = 1:length(uEvtTrajMeasCode)
      idT = find(tabTrajIndexAll(idFTraj, 1) == uEvtTrajMeasCode(idTrajMeasCode));
      idE = find(tabTrajIndexAll(idFEvt, 1) == uEvtTrajMeasCode(idTrajMeasCode));
      if (~isempty(idT) && ~isempty(idE))
         idT = idFTraj(idT);
         idE = idFEvt(idE);
         
         if (COMPARISON_FLAG == 1)
            
            % possible parameters for traj data coming from Tech information:
            % JULD, LATITUDE, LONGITUDE, PRES, TEMP
            valTrajJuld = [];
            valTrajJuldAdj = [];
            valTrajLat = [];
            valTrajLon = [];
            valTrajPres = [];
            valTrajTemp = [];
            dataTraj = tabTrajDataAll{idT};
            for id = 1:length(dataTraj)
               data = dataTraj{id};
               switch (data.paramName)
                  case 'JULD'
                     valTrajJuld = julian_2_gregorian_dec_argo(data.value);
                     valTrajJuldAdj = julian_2_gregorian_dec_argo(data.valueAdj);
                  case 'LATITUDE'
                     valTrajLat = sprintf('%.5f', data.value);
                  case 'LONGITUDE'
                     valTrajLon = sprintf('%.5f', data.value);
                  case 'PRES'
                     valTrajPres = sprintf('%.2f', data.value);
                  case 'TEMP'
                     valTrajTemp = sprintf('%.1f', data.value);
               end
            end
            valEvtJuld = [];
            valEvtJuldAdj = [];
            valEvtLat = [];
            valEvtLon = [];
            valEvtPres = [];
            valEvtTemp = [];
            dataEvt = tabTrajDataAll{idE};
            for id = 1:length(dataEvt)
               data = dataEvt{id};
               switch (data.paramName)
                  case 'JULD'
                     valEvtJuld = julian_2_gregorian_dec_argo(data.value);
                     valEvtJuldAdj = julian_2_gregorian_dec_argo(data.valueAdj);
                  case 'LATITUDE'
                     valEvtLat = sprintf('%.5f', data.value);
                  case 'LONGITUDE'
                     valEvtLon = sprintf('%.5f', data.value);
                  case 'PRES'
                     valEvtPres = sprintf('%.2f', data.value);
                  case 'TEMP'
                     valEvtTemp = sprintf('%.1f', data.value);
               end
            end
            
            valJuldDiffer = 0;
            valJuldAdjDiffer = 0;
            valLatDiffer = 0;
            valLonDiffer = 0;
            valPresDiffer = 0;
            valTempDiffer = 0;
            if (~isempty(valTrajJuld) && ~isempty(valEvtJuld))
               if (~strcmp(valTrajJuld, valEvtJuld))
                  valJuldDiffer = 1;
               end
            end
            if (~isempty(valTrajJuldAdj) && ~isempty(valEvtJuldAdj))
               if (~strcmp(valTrajJuldAdj, valEvtJuldAdj))
                  valJuldAdjDiffer = 1;
               end
            end
            if (~isempty(valTrajLat) && ~isempty(valEvtLat))
               if (~strcmp(valTrajLat, valEvtLat))
                  valLatDiffer = 1;
               end
            end
            if (~isempty(valTrajLon) && ~isempty(valEvtLon))
               if (~strcmp(valTrajLon, valEvtLon))
                  valLonDiffer = 1;
               end
            end
            if (~isempty(valTrajPres) && ~isempty(valEvtPres))
               if (~strcmp(valTrajPres, valEvtPres))
                  valPresDiffer = 1;
               end
            end
            if (~isempty(valTrajTemp) && ~isempty(valEvtTemp))
               if (~strcmp(valTrajTemp, valEvtTemp))
                  valTempDiffer = 1;
               end
            end
            differ = valJuldDiffer+valJuldAdjDiffer+valLatDiffer+valLonDiffer+valPresDiffer+valTempDiffer;
            if (differ ~= 0)
               for id = 1:differ
                  if (valJuldDiffer ~= 0)
                     paramName = 'JULD';
                     valJuldDiffer = 0;
                     valTraj = valTrajJuld;
                     valEvt = valEvtJuld;
                  elseif (valJuldAdjDiffer ~= 0)
                     paramName = 'JULD';
                     valJuldAdjDiffer = 0;
                     valTraj = valTrajJuldAdj;
                     valEvt = valEvtJuldAdj;
                  elseif (valLatDiffer ~= 0)
                     paramName = 'LATITUDE';
                     valLatDiffer = 0;
                     valTraj = valTrajLat;
                     valEvt = valEvtLat;
                  elseif (valLonDiffer ~= 0)
                     paramName = 'LONGITUDE';
                     valLonDiffer = 0;
                     valTraj = valTrajLon;
                     valEvt = valEvtLon;
                  elseif (valPresDiffer ~= 0)
                     paramName = 'PRES';
                     valPresDiffer = 0;
                     valTraj = valTrajPres;
                     valEvt = valEvtPres;
                  elseif (valTempDiffer ~= 0)
                     paramName = 'TEMP';
                     valTempDiffer = 0;
                     valTraj = valTrajTemp;
                     valEvt = valEvtTemp;
                  end
                  
                  fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Traj (from tech) and Event data differ for meas code %d and param ''%s'': traj=''%s'' and evt=''%s'' => using the Evt one\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     uEvtTrajMeasCode(idTrajMeasCode), paramName, valTraj, valEvt);
               end
            end
         end
         idToDel = [idToDel idT];
      end
   end
   tabTrajIndexAll(idToDel, :) = [];
   % fill unknown phase numbers
   if (any(tabTrajIndexAll(:, 4) == g_decArgo_phaseEndOfLife))
      % since EOL data could be received with tech file (g_decArgo_phaseSatTrans
      % phase)
      phase = g_decArgo_phaseEndOfLife;
   else
      phase = unique(tabTrajIndexAll(find(tabTrajIndexAll(:, 4) ~= -1), 4));
   end
   tabTrajIndexAll(find(tabTrajIndexAll(:, 4) == -1), 4) = phase;
   tabTrajDataAll(idToDel) = [];
end

o_tabTrajIndex = tabTrajIndexAll;
o_tabTrajData = tabTrajDataAll;

% fill value for JULD parameter
paramJuld = get_netcdf_param_attributes('JULD');

% retrieve dated measurements

% don't consider profiles from raw data
if (~isempty(a_tabProfiles))
   idDel = find([a_tabProfiles.sensorNumber] > 1000);
   a_tabProfiles(idDel) = [];
end

for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   if (profile.direction == 'A')
      measCode = g_MC_AscProf;
   else
      measCode = g_MC_DescProf;
   end

   datedMeasStruct = get_dated_meas_init_struct(profile.cycleNumber, ...
      profile.profileNumber, profile.phaseNumber);
   
   datedMeasStruct.paramList = profile.paramList;
   datedMeasStruct.paramNumberWithSubLevels = profile.paramNumberWithSubLevels;
   datedMeasStruct.paramNumberOfSubLevels = profile.paramNumberOfSubLevels;
   datedMeasStruct.dateList = profile.dateList;
   
   dates = profile.dates;
   idDated = find(dates ~= paramJuld.fillValue);

   datedMeasStruct.dates = profile.dates(idDated);
   datedMeasStruct.datesAdj = profile.datesAdj(idDated);
   datedMeasStruct.data = profile.data(idDated, :);
   datedMeasStruct.sensorNumber = profile.sensorNumber;
   
   o_tabTrajIndex = [o_tabTrajIndex;
      measCode  profile.cycleNumber profile.profileNumber profile.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {{datedMeasStruct}}];
end

for idDrift = 1:length(a_tabDrift)
   
   drift = a_tabDrift(idDrift);
      
   datedMeasStruct = get_dated_meas_init_struct(drift.cycleNumber, ...
      drift.profileNumber, drift.phaseNumber);
   
   datedMeasStruct.paramList = drift.paramList;
   datedMeasStruct.paramNumberWithSubLevels = drift.paramNumberWithSubLevels;
   datedMeasStruct.paramNumberOfSubLevels = drift.paramNumberOfSubLevels;
   datedMeasStruct.dateList = drift.dateList;
   datedMeasStruct.dates = drift.dates;
   datedMeasStruct.datesAdj = drift.datesAdj;
   datedMeasStruct.data = drift.data;
   datedMeasStruct.sensorNumber = drift.sensorNumber;

   o_tabTrajIndex = [o_tabTrajIndex;
      g_MC_DriftAtPark  drift.cycleNumber drift.profileNumber drift.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {{datedMeasStruct}}];
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
            if (dirNum == 2)
               measCode = g_MC_AscProfDeepestBin;
            else
               measCode = g_MC_DescProfDeepestBin;
            end
   
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
               datedMeasStruct.datesAdj = profile.datesAdj(profInfo(idProfMax, 5));
               datedMeasStruct.data = profile.data(profInfo(idProfMax, 5), :);
               datedMeasStruct.sensorNumber = profile.sensorNumber;
               
               o_tabTrajIndex = [o_tabTrajIndex;
                  measCode  cyNum profNum profile.phaseNumber];
               o_tabTrajData = [o_tabTrajData; {{datedMeasStruct}}];
            end
         end
      end
   end
end

% retrieve subsurface measurement
if (~isempty(a_subSurfaceMeas))
   
   subSurfMeas = get_sub_surface_meas_init_struct(g_decArgo_cycleNumFloat, ...
      g_decArgo_patternNumFloat);

   subSurfMeas.juld = a_subSurfaceMeas(1);
   subSurfMeas.juldAdj = adjust_time_cts5(subSurfMeas.juld);
   subSurfMeas.pres = a_subSurfaceMeas(2);
   subSurfMeas.temp = a_subSurfaceMeas(3);
   subSurfMeas.psal = a_subSurfaceMeas(4);

   o_tabTrajIndex = [o_tabTrajIndex;
      g_MC_LastAscPumpedCtd  g_decArgo_cycleNumFloat g_decArgo_patternNumFloat -1];
   o_tabTrajData = [o_tabTrajData; {{subSurfMeas}}];
end

% IN AIR measurements
for idSurf = 1:length(a_tabSurf)
   
   surf = a_tabSurf(idSurf);
      
   surfMeasStruct = get_dated_meas_init_struct(surf.cycleNumber, ...
      surf.profileNumber, surf.phaseNumber);
   
   surfMeasStruct.paramList = surf.paramList;
   surfMeasStruct.paramNumberWithSubLevels = surf.paramNumberWithSubLevels;
   surfMeasStruct.paramNumberOfSubLevels = surf.paramNumberOfSubLevels;
   surfMeasStruct.dateList = surf.dateList;
   surfMeasStruct.dates = surf.dates;
   surfMeasStruct.datesAdj = surf.datesAdj;
   surfMeasStruct.data = surf.data;
   surfMeasStruct.sensorNumber = surf.sensorNumber;

   o_tabTrajIndex = [o_tabTrajIndex;
      g_MC_InAirSeriesOfMeas  surf.cycleNumber surf.profileNumber surf.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {{surfMeasStruct}}];
end

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
%   02/20/2017 - RNU - creation
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
   'datesAdj', '', ...
   'sensorNumber', -1);

return;

% ------------------------------------------------------------------------------
% Get the basic structure to store unique sub surface measurement.
%
% SYNTAX :
%  [o_subSurfaceMeasStruct] = get_sub_surface_meas_init_struct(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%
% OUTPUT PARAMETERS :
%   o_subSurfaceMeasStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_subSurfaceMeasStruct] = get_sub_surface_meas_init_struct(a_cycleNum, a_profNum)

% output parameters initialization
o_subSurfaceMeasStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'juld', '', ...
   'juldAdj', '', ...
   'pres', '', ...
   'temp', '', ...
   'psal', '');

return;
