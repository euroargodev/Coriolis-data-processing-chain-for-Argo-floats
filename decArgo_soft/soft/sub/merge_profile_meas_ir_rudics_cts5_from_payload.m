% ------------------------------------------------------------------------------
% Merge the profiles of a given payload sensor.
%
% SYNTAX :
%  [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_from_payload(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_from_payload(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];


if (isempty(a_tabProfiles))
   return;
end

% collect information on profiles to be merged
profInfo = [
   (1:length(a_tabProfiles))', ...
   [a_tabProfiles.sensorNumber]', ...
   [a_tabProfiles.cycleNumber]', ...
   [a_tabProfiles.profileNumber]', ...
   [a_tabProfiles.phaseNumber]', ...
   cellfun(@length, {a_tabProfiles.paramList})']; % needed for SUNA split profiles

tabProfiles = [];
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
               nbLoop = 1;
               if (sensorNum == 6)
                  nbLoop = 1:2;
               end
               for idL = nbLoop
                  
                  if (sensorNum ~= 6)
                     idF = find((profInfo(:, 2) == sensorNum) & ...
                        (profInfo(:, 3) == cycleNum) & ...
                        (profInfo(:, 4) == profileNum) & ...
                        (profInfo(:, 5) == phaseNum));
                  else
                     if (idL == 1) % to get SUNA CTD split profile
                        idF = find((profInfo(:, 2) == sensorNum) & ...
                           (profInfo(:, 3) == cycleNum) & ...
                           (profInfo(:, 4) == profileNum) & ...
                           (profInfo(:, 5) == phaseNum) & ...
                           (profInfo(:, 6) == 3));
                     else
                        idF = find((profInfo(:, 2) == sensorNum) & ...
                           (profInfo(:, 3) == cycleNum) & ...
                           (profInfo(:, 4) == profileNum) & ...
                           (profInfo(:, 5) == phaseNum) & ...
                           (profInfo(:, 6) ~= 3));
                     end
                  end
                  if (~isempty(idF))
                     if (length(idF) > 1)
                        % merge the profiles
                        [mergedProfile] = merge_profiles(a_tabProfiles(profInfo(idF, 1)));
                        if (~isempty(mergedProfile))
                           tabProfiles = [tabProfiles mergedProfile];
                        end
                     else
                        a_tabProfiles(profInfo(idF, 1)).merged = 1;
                        tabProfiles = [tabProfiles a_tabProfiles(profInfo(idF, 1))];
                     end
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
% Merge the profiles.
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profiles(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


% collect information on profiles to be merged
direction = repmat(' ', length(a_tabProfiles), 1);
startPres = ones(length(a_tabProfiles), 1)*-1;
stopPres = ones(length(a_tabProfiles), 1)*-1;
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction(idProf) = profile.direction;
   if (profile.direction == 'A')
      startPres(idProf) = max(profile.data(:, 1));
      stopPres(idProf) = min(profile.data(:, 1));
   elseif (profile.direction == 'D')
      startPres(idProf) = min(profile.data(:, 1));
      stopPres(idProf) = max(profile.data(:, 1));
   end
end

% create final profile(s)
uDir = unique(direction);
for idDir = 1:length(uDir)
   idProfForDir = find(direction == uDir(idDir));
   if (uDir(idDir) == 'A')
      [startPresForDir, idSort] = sort(startPres(idProfForDir), 'descend');
   elseif (uDir(idDir) == 'D')
      [startPresForDir, idSort] = sort(startPres(idProfForDir), 'ascend');
   end
   stopPresForDir = stopPres(idProfForDir(idSort));
   idProfForDir = idProfForDir(idSort);
   
   % for CTS5 floats, some profiles to be merged could have derived parameters
   % => if the profiles don't have the same number of parameter, the last
   % additional ones are ignored
   tabNbParam = [];
   for idPrf = 1:length(idProfForDir)
      tabNbParam = [tabNbParam length(a_tabProfiles(idProfForDir(idPrf)).paramList)];
   end
   if (length(unique(tabNbParam)) > 1)
      nbParam = min(tabNbParam);
      for idPrf = 1:length(idProfForDir)
         if (length(a_tabProfiles(idProfForDir(idPrf)).paramList) > nbParam)
            nbDel = length(a_tabProfiles(idProfForDir(idPrf)).paramList) - nbParam;
            a_tabProfiles(idProfForDir(idPrf)).paramList(end-nbDel+1:end) = [];
            a_tabProfiles(idProfForDir(idPrf)).data(:, end-nbDel+1:end) = [];
            if (~isempty(a_tabProfiles(idProfForDir(idPrf)).dataQc))
               a_tabProfiles(idProfForDir(idPrf)).dataQc(:, end-nbDel+1:end) = [];
            end
         end
      end
   end
   
   % create data array and parameter list
   finalParamList = [];
   finalParamNumberWithSubLevels = [];
   finalParamNumberOfSubLevels = [];
   finalParamColumnNumber = [];
   finalData = [];
   finalDates = [];
   finalDatesAdj = [];
   for idPrf = 1:length(idProfForDir)
      idProf = idProfForDir(idPrf);
      
      paramList = a_tabProfiles(idProf).paramList;
      paramNumberWithSubLevel = a_tabProfiles(idProf).paramNumberWithSubLevels;
      paramNumberOfSubLevels = a_tabProfiles(idProf).paramNumberOfSubLevels;
      paramColumnNumber = 1:length(paramList); % because 'UV_INTENSITY_NITRATE' is always the last parameter in the input profiles
      dates = a_tabProfiles(idProf).dates;
      datesAdj = a_tabProfiles(idProf).datesAdj;
      data = a_tabProfiles(idProf).data;
      
      if (idPrf == 1)
         finalParamList = paramList;
         finalParamNumberWithSubLevels = paramNumberWithSubLevel;
         finalParamNumberOfSubLevels = paramNumberOfSubLevels;
         finalParamColumnNumber = paramColumnNumber;
         finalData = data;
         finalDates = dates;
         finalDatesAdj = datesAdj;
      else
         
         % initialize data array
         newData = [];
         nbLev = size(data, 1);
         for idPrm = 1:length(finalParamList)
            if (isempty(paramNumberWithSubLevel))
               newData = [newData nan(nbLev, 1)];
            else
               if (ismember(idPrm, paramNumberWithSubLevel))
                  idF = find(paramNumberWithSubLevel == idPrm, 1);
                  nbValues = paramNumberOfSubLevels(idF);
                  newData = [newData nan(nbLev, nbValues)];
               else
                  newData = [newData nan(nbLev, 1)];
               end
            end
         end
         
         % fill data array
         finalParamName = {finalParamList.name};
         for idPrm = 1:length(paramList)
            param = paramList(idPrm);
            paramName = param.name;
            
            idF = find(strcmp(paramName, finalParamName), 1);
            if (~isempty(idF))
               outPutColumnNumber = finalParamColumnNumber(idF);
               if (isempty(paramNumberWithSubLevel))
                  newData(:, outPutColumnNumber) = data(:, idPrm);
               else
                  if (ismember(idPrm, paramNumberWithSubLevel))
                     idF2 = find(paramNumberWithSubLevel == idPrm, 1);
                     nbValues = paramNumberOfSubLevels(idF2);
                     newData(:, outPutColumnNumber:outPutColumnNumber+nbValues-1) = data(:, idPrm:idPrm+nbValues-1); % remember that 'UV_INTENSITY_NITRATE' appear once and at the last place in the input profiles
                  else
                     newData(:, outPutColumnNumber) = data(:, idPrm); % remember that 'UV_INTENSITY_NITRATE' appear once and at the last place in the input profiles
                  end
               end
            else
               finalParamList = [finalParamList paramList(idPrm)];
               paramColumnNumber = [paramColumnNumber size(newData, 2)+1];
               if (isempty(paramNumberWithSubLevel))
                  newData = [newData data(:, idPrm)];
               else
                  if (ismember(idPrm, paramNumberWithSubLevel))
                     idF2 = find(paramNumberWithSubLevel == idPrm, 1);
                     nbValues = paramNumberOfSubLevels(idF2);
                     finalParamNumberWithSubLevels = [finalParamNumberWithSubLevels length(finalParamList)];
                     finalParamNumberOfSubLevels = [finalParamNumberOfSubLevels nbValues];
                     newData = [newData data(:, idPrm:idPrm+nbValues-1)];
                  else
                     newData = [newData data(:, idPrm)];
                  end
               end
            end
         end
         
         % check if the data are from a second subsampling
         startPresCurrent = startPresForDir(idPrf);
         stopPresCurrent = stopPresForDir(idPrf);
         secondSubSampling = 0;
         if (uDir(idDir) == 'A')
            if (stopPresForDir(idProfForDir(idPrf-1)) < stopPresCurrent)
               secondSubSampling = 1;
            end
         elseif (uDir(idDir) == 'D')
            if (stopPresForDir(idProfForDir(idPrf-1)) > stopPresCurrent)
               secondSubSampling = 1;
            end
         end

         if (secondSubSampling == 0)
            
            % append the new data to existing ones
            finalData = [finalData; newData];
            finalDates = [finalDates; dates];
            finalDatesAdj = [finalDatesAdj; datesAdj];
         else
            
            % merge the new data with existing ones at the same levels (at the
            % same levels because we cannot sort all pressures because they are
            % not necessarily ordered)
            if (uDir(idDir) == 'A')
               idLevels = find((finalData(:, 1) <= startPresCurrent) & ...
                  (finalData(:, 1) >= stopPresCurrent));
            elseif (uDir(idDir) == 'D')
               idLevels = find((finalData(:, 1) >= startPresCurrent) & ...
                  (finalData(:, 1)<= stopPresCurrent));
            end
            
            fromFinalData = finalData(idLevels, :);
            fromFinalDates = finalDates(idLevels);
            fromFinalDatesAdj = finalDatesAdj(idLevels);
            
            fromFinalData = [fromFinalData; newData];
            fromFinalDates = [fromFinalDates; dates];
            fromFinalDatesAdj = [fromFinalDatesAdj; datesAdj];
            
            % sort from pressures
            if (uDir(idDir) == 'A')
               [~, idSort] = sort(fromFinalData(:, 1), 'descend');
            elseif (uDir(idDir) == 'D')
               [~, idSort] = sort(fromFinalData(:, 1), 'ascend');
            end
            fromFinalData = fromFinalData(idSort);
            fromFinalDates = fromFinalData(idSort);
            fromFinalDatesAdj = fromFinalDatesAdj(idSort);
            
            % remove possible duplicates in pressure (depends on subsampling #1
            % and #2 characteristics)
            idEqualPres = find(diff(fromFinalData(:, 1)) == 0);
            if (~isempty(idEqualPres))
               idToDel = [];
               for idEq = 1:length(idEqualPres)
                  id1 = idEqualPres(idEq);
                  id2 = idEqualPres(idEq)+1;
                  for idCol = 2:size(fromFinalData, 2)
                     if (~isnan(fromFinalData(idCol, id2)))
                        if (~isnan(fromFinalData(idCol, id1)))
                           fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistency encountered while merging data profile for sensor #%d and phase #%d\n', ...
                              g_decArgo_floatNum, ...
                              g_decArgo_cycleNum, ...
                              g_decArgo_cycleNumFloat, ...
                              g_decArgo_patternNumFloat, ...
                              a_tabProfiles(idProf).sensorNumber, a_tabProfiles(idProf).phaseNumber);
                        end
                        fromFinalData(idCol, id1) = fromFinalData(idCol, id2);
                     end
                  end
                  idToDel = [idToDel id2];
               end
               fromFinalData(idToDel, :) = [];
               fromFinalDates(idToDel, :) = [];
               fromFinalDatesAdj(idToDel, :) = [];
            end
            
            % insert the new data into existing ones
            finalData = [finalData(1:min(idLevels)-1, :); ...
               fromFinalData; ...
               finalData(max(idLevels)+1:end, :)];
            finalDates = [finalDates(1:min(idLevels)-1); ...
               fromFinalDates; ...
               finalDates(max(idLevels)+1:end)];
            finalDatesAdj = [finalDatesAdj(1:min(idLevels)-1); ...
               fromFinalDatesAdj; ...
               finalDatesAdj(max(idLevels)+1:end)];
         end
      end
   end
   
   newProfile = a_tabProfiles(idProf);
   
   newProfile.paramList = finalParamList;
   newProfile.data = finalData;
   newProfile.dates = finalDates;
   newProfile.datesAdj = finalDatesAdj;
   
   newProfile.merged = 1;
   
   % measurement dates
   newProfile.minMeasDate = min(newProfile.datesAdj);
   newProfile.maxMeasDate = max(newProfile.datesAdj);
   
   o_tabProfiles = [o_tabProfiles newProfile];
   
end

return;
