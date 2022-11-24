% ------------------------------------------------------------------------------
% Merge the profiles of a given sensor (at most 3 profiles can be produced, one
% per treatment type; they should be merged in a unique one).
%
% SYNTAX :
%  [o_tabProfiles] = merge_profile_meas_ir_rudics_sbd2(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/19/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profile_meas_ir_rudics_sbd2(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;


% collect information on not already merged profiles
profInfo = [];
tabProfiles = [];
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   if (profile.merged == 0)
      profInfo = [profInfo;
         idProf profile.sensorNumber profile.cycleNumber profile.profileNumber profile.phaseNumber];
   else
      tabProfiles = [tabProfiles a_tabProfiles(idProf)];
   end
end

if (~isempty(profInfo))
   % identify the profiles to merge
   uSensorNum = unique(profInfo(:, 2));
   uCycleNum = unique(profInfo(:, 3));
   uProfileNum = unique(profInfo(:, 4));
   uPhaseNum = unique(profInfo(:, 5));
   for idS = 1:length(uSensorNum)
      for idC = 1:length(uCycleNum)
         for idP = 1:length(uProfileNum)
            for idH = 1:length(uPhaseNum)
               sensorNum = uSensorNum(idS);
               cycleNum = uCycleNum(idC);
               profileNum = uProfileNum(idP);
               phaseNum = uPhaseNum(idH);
               
               idF = find((profInfo(:, 2) == sensorNum) & ...
                  (profInfo(:, 3) == cycleNum) & ...
                  (profInfo(:, 4) == profileNum) & ...
                  (profInfo(:, 5) == phaseNum));
               if (~isempty(idF))
                  if (length(idF) > 1)
                     % merge the profiles
                     [mergedProfile] = merge_profiles(a_tabProfiles(profInfo(idF, 1)));
                     if (~isempty(mergedProfile))
                        
                        % update the profileCompleted flag
                        if (~isempty(mergedProfile.nbMeas))
                           mergedProfile.profileCompleted = sum(mergedProfile.nbMeas) - size(mergedProfile.data, 1);
                           
                           if (mergedProfile.profileCompleted < 0)
                              %                               techNbMeas = sprintf('%d ', mergedProfile.nbMeas);
                              %                               fprintf('FLOAT_WARNING: Float #%d Cycle #%d Profile #%d: inconsistency in tech vs measurements (in terms of number of sampled measurements: tech = [%s] => %d, sampled = %d) for ''%c'' profile of sensor #%d\n', ...
                              %                                  g_decArgo_floatNum, ...
                              %                                  mergedProfile.cycleNumber, ...
                              %                                  mergedProfile.profileNumber, ...
                              %                                  techNbMeas(1:end-1), sum(mergedProfile.nbMeas), ...
                              %                                  size(mergedProfile.data, 1), ...
                              %                                  mergedProfile.direction, ...
                              %                                  mergedProfile.sensorNumber);
                           end
                        end
                        
                        tabProfiles = [tabProfiles mergedProfile];
                     end
                  else
                     % update the profileCompleted flag
                     if (~isempty(a_tabProfiles(profInfo(idF, 1)).nbMeas))
                        a_tabProfiles(profInfo(idF, 1)).profileCompleted = sum(a_tabProfiles(profInfo(idF, 1)).nbMeas) - size(a_tabProfiles(profInfo(idF, 1)).data, 1);
                        
                        if (a_tabProfiles(profInfo(idF, 1)).profileCompleted < 0)
                           %                            techNbMeas = sprintf('%d ', a_tabProfiles(profInfo(idF, 1)).nbMeas);
                           %                            fprintf('FLOAT_WARNING: Float #%d Cycle #%d Profile #%d: inconsistency in tech vs measurements (in terms of number of sampled measurements: tech = [%s] => %d, sampled = %d) for ''%c'' profile of sensor #%d\n', ...
                           %                               g_decArgo_floatNum, ...
                           %                               a_tabProfiles(profInfo(idF, 1)).cycleNumber, ...
                           %                               a_tabProfiles(profInfo(idF, 1)).profileNumber, ...
                           %                               techNbMeas(1:end-1), sum(a_tabProfiles(profInfo(idF, 1)).nbMeas), ...
                           %                               size(a_tabProfiles(profInfo(idF, 1)).data, 1), ...
                           %                               a_tabProfiles(profInfo(idF, 1)).direction, ...
                           %                               a_tabProfiles(profInfo(idF, 1)).sensorNumber);
                        end
                     end
                     
                     a_tabProfiles(profInfo(idF, 1)).merged = 1;
                     tabProfiles = [tabProfiles a_tabProfiles(profInfo(idF, 1))];
                  end
               end
            end
         end
      end
   end
end

% update output parameters
o_tabProfiles = tabProfiles;

return;

% ------------------------------------------------------------------------------
% Merge the profiles according to the treatment type of each depth zone.
%
% SYNTAX :
%  [o_tabProfile] = merge_profiles(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profiles to merge
%
% OUTPUT PARAMETERS :
%   o_tabProfile : output merged profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/19/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfile] = merge_profiles(a_tabProfiles)

% output parameters initialization
o_tabProfile = [];

% treatment types
global g_decArgo_treatAverageAndStDev;

% current float WMO number
global g_decArgo_floatNum;

% Argos (1), Iridium RUDICS (2), Iridium SBD (3) or Iridium SBD2 (4) float
global g_decArgo_floatTransType;


% anomaly management: check consistancy of paramNumberOfSubLevels
% Ex: 6901440 Cy #9 Prof #0
if (length(unique([a_tabProfiles.paramNumberOfSubLevels])) > 1)
   
   numberOfSubLevelsList = [a_tabProfiles.paramNumberOfSubLevels];
   idDel = find(numberOfSubLevelsList ~= min(numberOfSubLevelsList));
   a_tabProfiles(idDel) = [];
   
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: inconsistency in number of sub-levels for ''%c'' profile of sensor #%d => %d profiles ignored\n', ...
      g_decArgo_floatNum, ...
      a_tabProfiles(1).cycleNumber, ...
      a_tabProfiles(1).profileNumber, ...
      a_tabProfiles(1).direction, ...
      a_tabProfiles(1).sensorNumber, ...
      length(idDel));
   
   if (length(a_tabProfiles) == 1)
      
      % update output parameters
      o_tabProfile = a_tabProfiles;
      o_tabProfile.merged = 1;
      
      return;
   end
end


% we have at most 3 profiles to merge (one for each treatment type)
refProfId = [];
finalDataSize1 = 0;
finalDataSize2 = 0;
finalParamList = [];
finalParamNumberWithSubLevels = [];
finalParamNumberOfSubLevels = [];
finalDateList = [];
treatTypeList = [];
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   % select the reference param and date lists
   if (profile.treatType == g_decArgo_treatAverageAndStDev)
      refProfId = idProf;
      finalParamList = profile.paramList;
      finalDateList = profile.dateList;
      finalParamNumberWithSubLevels = profile.paramNumberWithSubLevels;
      finalParamNumberOfSubLevels = profile.paramNumberOfSubLevels;
      finalDataSize2 = size(profile.data, 2);
   else
      if (isempty(refProfId))
         refProfId = idProf;
         finalParamList = profile.paramList;
         finalDateList = profile.dateList;
         finalParamNumberWithSubLevels = profile.paramNumberWithSubLevels;
         finalParamNumberOfSubLevels = profile.paramNumberOfSubLevels;
         finalDataSize2 = size(profile.data, 2);
      end
   end
   
   finalDataSize1 = finalDataSize1 + size(profile.data, 1);
   treatTypeList = [treatTypeList profile.treatType];
end

% prepare the final data arrays
if (~ismember(0, treatTypeList))
   finalData = ones(finalDataSize1, finalDataSize2)*-1;
   finalDates = ones(finalDataSize1, 1)*finalDateList.fillValue;
else
   % when raw data are transmitted
   % theoretically the measurements of each depth zone should be retrieved
   % using the following rules concerning zone boundaries:
   % Zone 1 : P <= Z1
   % Zone 2 : Z1 < P <= Z2
   % Zone 3 : Z2 < P <= Z3
   % Zone 4 : Z3 < P <= Z4
   % Zone 5 : Z4 < P
   % however, the pressure data are managed in the floats in mbar and stored in
   % the zones according to this unit. But they are transmitted in cbar!
   % Consequently if Z1 = 1 dbar, a measurement at 1.00 dbar is stored in zone 1
   % and a measurement at 1.01 dbar is stored in zone 2 but both are transmitted
   % as 1.0 dbar.
   % To prevent from missing some measurements we need to collect them using the
   % following rules:
   % Zone 1 : P <= Z1
   % Zone 2 : Z1 <= P <= Z2
   % Zone 3 : Z2 <= P <= Z3
   % Zone 4 : Z3 <= P <= Z4
   % Zone 5 : Z4 <= P
   % and then to delete possibly duplicated measurement.
   
   finalData = ones(2*finalDataSize1, finalDataSize2)*-1;
   finalDates = [ones(finalDataSize1, 1)*finalDateList.fillValue; ones(finalDataSize1, 1)*-1];
end
offsetC = 0;
for idP = 1:length(finalParamList)
   
   param = finalParamList(idP);
   idF = find(finalParamNumberWithSubLevels == idP);
   if (isempty(idF))
      nbSubLev = 1;
   else
      nbSubLev = finalParamNumberOfSubLevels(idF);
   end
   finalData(:, idP+offsetC:idP+offsetC+nbSubLev-1) = param.fillValue;
   offsetC = offsetC + (nbSubLev-1);
end

% retieve the treatment types+thicknesses and the corresponding thresholds from
% the configuration
if (g_decArgo_floatTransType == 2)
   
   % Iridium RUDICS floats
   
   [treatTypes, treatThickness, zoneThreshold] = ...
      config_get_treatment_types_ir_rudics(a_tabProfiles(1).sensorNumber, ...
      a_tabProfiles(1).cycleNumber, a_tabProfiles(1).profileNumber);
elseif (g_decArgo_floatTransType == 4)
   
   % Iridium SBD ProvBioII floats
   
   [treatTypes, treatThickness, zoneThreshold] = ...
      config_get_treatment_types_ir_sbd2(a_tabProfiles(1).sensorNumber, ...
      a_tabProfiles(1).cycleNumber, a_tabProfiles(1).profileNumber);
end

% merge the profile measurements
if (a_tabProfiles(1).direction == 'A')
   zoneIdList = 5:-1:1;
else
   zoneIdList = 1:5;
end

if ((length(sort(unique(treatTypes))) == length(sort(unique(treatTypeList)))) && ...
      isempty(find(sort(unique(treatTypes))' - sort(unique(treatTypeList)) ~= 0, 1)))
   
   offsetL = 0;
   for idZ = zoneIdList
      treatT = treatTypes(idZ);
      idF = find(treatTypeList == treatT);
      % idF can be empty because CTD profile has been cut in 2 profiles (for
      % pumped and unpumped CTD data)
      if (~isempty(idF))
         paramList = a_tabProfiles(idF).paramList;
         data = a_tabProfiles(idF).data;
         dates = a_tabProfiles(idF).dates;
         
         % the counts in the depth zone boundaries have been modified on
         % 01/21/2015 according to float #6901865 #0 #0 'A' sensor #3 profile
         % (the Z1/Z2 boundary is 1 dbar and 2 measurements at 1 dbar are taken
         % into account in the Z2 depth zone). A check on the final data (no
         % line with only fillValues) has been also added.
         idData = [];
         if (idZ == 5)
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               (data(:, 1) >= zoneThreshold(idZ-1)));
         elseif (idZ == 1)
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               (data(:, 1) <= zoneThreshold(idZ)));
         else
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               ((data(:, 1) >= zoneThreshold(idZ-1)) & ...
               (data(:, 1) <= zoneThreshold(idZ))));
         end
         
         % copy the measurements in the final data arrays
         if (~isempty(idData))
            offsetC = 0;
            for idP = 1:length(paramList)
               idF = find(strcmp(paramList(idP).name, {finalParamList.name}) == 1);
               
               idF2 = find(finalParamNumberWithSubLevels == idF);
               if (isempty(idF2))
                  nbSubLev = 1;
               else
                  nbSubLev = finalParamNumberOfSubLevels(idF2);
               end
               
               finalData(offsetL+1:offsetL+length(idData), idF+offsetC:idF+offsetC+nbSubLev-1) = ...
                  data(idData, idP+offsetC:idP+offsetC+nbSubLev-1);
               
               offsetC = offsetC + (nbSubLev-1);
            end
            finalDates(offsetL+1:offsetL+length(idData), 1) = ...
               dates(idData, 1);
            offsetL = offsetL + length(idData);
         end
      end
   end
   
else
   
   % sampled data are not consistent with configuration (in terms of treatment
   % type)
   
   if ~((length(unique(treatTypeList)) == 1) && (unique(treatTypeList) == -1))
      %       configTreatList = sprintf('%d ', treatTypes');
      %       collectedTreatList = sprintf('%d ', treatTypeList);
      %       fprintf('FLOAT_WARNING: Float #%d Cycle #%d Profile #%d: inconsistency in conf vs measurements (in terms of treatment types: config [%s], sampled [%s]) for ''%c'' profile of sensor #%d\n', ...
      %          g_decArgo_floatNum, ...
      %          a_tabProfiles(1).cycleNumber, ...
      %          a_tabProfiles(1).profileNumber, ...
      %          configTreatList(1:end-1), collectedTreatList(1:end-1), ...
      %          a_tabProfiles(1).direction, ...
      %          a_tabProfiles(1).sensorNumber);
   end
   
   % nominal case
   offsetL = 0;
   for idZ = zoneIdList
      for idProf = 1:length(a_tabProfiles)
         
         % we don't know in which profile are the measurements of this depth
         % zone
         paramList = a_tabProfiles(idProf).paramList;
         data = a_tabProfiles(idProf).data;
         dates = a_tabProfiles(idProf).dates;
         
         % the counts in the depth zone boundaries have been modified on
         % 01/21/2015 according to float #6901865 #0 #0 'A' sensor #3 profile
         % (the Z1/Z2 boundary is 1 dbar and 2 measurements at 1 dbar are taken
         % into account in the Z2 depth zone). A check on the final data (no
         % line with only fillValues) has been also added.
         idData = [];
         if (idZ == 5)
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               (data(:, 1) >= zoneThreshold(idZ-1)));
         elseif (idZ == 1)
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               (data(:, 1) <= zoneThreshold(idZ)));
         else
            idData = find((data(:, 1) ~= paramList(1).fillValue) & ...
               ((data(:, 1) >= zoneThreshold(idZ-1)) & ...
               (data(:, 1) <= zoneThreshold(idZ))));
         end
         
         % copy the measurements in the final data arrays
         if (~isempty(idData))
            offsetC = 0;
            for idP = 1:length(paramList)
               idF = find(strcmp(paramList(idP).name, {finalParamList.name}) == 1);
               
               idF2 = find(finalParamNumberWithSubLevels == idF);
               if (isempty(idF2))
                  nbSubLev = 1;
               else
                  nbSubLev = finalParamNumberOfSubLevels(idF2);
               end
               
               finalData(offsetL+1:offsetL+length(idData), idF+offsetC:idF+offsetC+nbSubLev-1) = ...
                  data(idData, idP+offsetC:idP+offsetC+nbSubLev-1);
               
               offsetC = offsetC + (nbSubLev-1);
            end
            finalDates(offsetL+1:offsetL+length(idData), 1) = ...
               dates(idData, 1);
            offsetL = offsetL + length(idData);
         end
      end
   end
end

if (ismember(0, treatTypeList))
   idToDel = find(finalDates == -1);
   finalData(idToDel, :) = [];
   finalDates(idToDel, :) = [];
   
   if (size(finalData, 1) ~= finalDataSize1)
      idToDel = [];
      for idZ = 1:length(zoneThreshold)
         boundary = zoneThreshold(idZ);
         idFPres = find(finalData(:, 1) == boundary);
         for idL1 = 1:length(idFPres)
            if (~ismember(idFPres(idL1), idToDel))
               ref = finalData(idFPres(idL1), :);
               for idL2 = 1:length(idFPres)
                  if ((idL1 ~= idL2) && (~ismember(idFPres(idL2), idToDel)))
                     res = unique(ref - finalData(idFPres(idL2), :));
                     if ((length(res) == 1) && (res == 0))
                        idToDel = [idToDel; idFPres(idL2)];
                     end
                  end
               end
            end
         end
      end
      finalData(idToDel, :) = [];
      finalDates(idToDel, :) = [];
   end
end

% chronologically sort drift measurement
if (~isempty(finalDates) && (a_tabProfiles(1).phaseNumber == 6))
   [finalDates, idSort] = sort(finalDates);
   finalData = finalData(idSort, :);
end

% check that all lines of the final data array have at least one useful column
checkData = zeros(size(finalData));
fillValAll = unique([finalParamList.fillValue]);
if (length(fillValAll) == 1)
   checkData(find(finalData == fillValAll)) = 1;
   sumByLine = sum(checkData, 2);
   if (~isempty(find(sumByLine == size(finalData, 2), 1)))
      fprintf('ERROR: Float #%d Cycle #%d Profile #%d: anomaly detected while merging profiles for ''%c'' profile of sensor #%d\n', ...
         g_decArgo_floatNum, ...
         a_tabProfiles(1).cycleNumber, ...
         a_tabProfiles(1).profileNumber, ...
         a_tabProfiles(1).direction, ...
         a_tabProfiles(1).sensorNumber);
   end
else
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: check after merge not implemented yet for ''%c'' profile of sensor #%d\n', ...
      g_decArgo_floatNum, ...
      a_tabProfiles(1).cycleNumber, ...
      a_tabProfiles(1).profileNumber, ...
      a_tabProfiles(1).direction, ...
      a_tabProfiles(1).sensorNumber);
end

if (size(finalData, 1) > finalDataSize1)
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: inconsistency in final data size for ''%c'' profile of sensor #%d (%d level measurements are missing)\n', ...
      g_decArgo_floatNum, ...
      a_tabProfiles(1).cycleNumber, ...
      a_tabProfiles(1).profileNumber, ...
      a_tabProfiles(1).direction, ...
      a_tabProfiles(1).sensorNumber, ...
      size(finalData, 1) - finalDataSize1);
elseif (size(finalData, 1) < finalDataSize1)
   fprintf('INFO: Float #%d Cycle #%d Profile #%d: inconsistency in final data size for ''%c'' profile of sensor #%d (%d duplicated level measurements have been deleted during the merge process)\n', ...
      g_decArgo_floatNum, ...
      a_tabProfiles(1).cycleNumber, ...
      a_tabProfiles(1).profileNumber, ...
      a_tabProfiles(1).direction, ...
      a_tabProfiles(1).sensorNumber, ...
      finalDataSize1 - size(finalData, 1));
end

% update output parameters
o_tabProfile = a_tabProfiles(refProfId);

o_tabProfile.data = finalData;
o_tabProfile.dates = finalDates;

dates = finalDates;
dates(find(dates == finalDateList(1).fillValue)) = [];
o_tabProfile.minMeasDate = min(dates);
o_tabProfile.maxMeasDate = max(dates);

o_tabProfile.merged = 1;

return;
