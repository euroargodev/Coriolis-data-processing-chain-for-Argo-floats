% ------------------------------------------------------------------------------
% Merge the profiles of a given CTS5-USEA sensor.
%
% SYNTAX :
%  [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black(a_tabProfiles)
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];


if (isempty(a_tabProfiles))
   return
end

% collect information on profiles to be merged
profInfo = [
   (1:length(a_tabProfiles))', ...
   [a_tabProfiles.sensorNumber]', ...
   [a_tabProfiles.cycleNumber]', ...
   [a_tabProfiles.profileNumber]', ...
   [a_tabProfiles.phaseNumber]'];

tabProfiles = [];
if (~isempty(profInfo))
   % identify the profiles to merge
   sensorCycleProfPhaseList = unique(profInfo(:, 2:5), 'rows');
   for idSenCyPrPh = 1:size(sensorCycleProfPhaseList, 1)
      sensorNum = sensorCycleProfPhaseList(idSenCyPrPh, 1);
      cycleNum = sensorCycleProfPhaseList(idSenCyPrPh, 2);
      profileNum = sensorCycleProfPhaseList(idSenCyPrPh, 3);
      phaseNum = sensorCycleProfPhaseList(idSenCyPrPh, 4);
      
      idF = find((profInfo(:, 2) == sensorNum) & ...
         (profInfo(:, 3) == cycleNum) & ...
         (profInfo(:, 4) == profileNum) & ...
         (profInfo(:, 5) == phaseNum));
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

% update output parameters
o_tabProfiles = tabProfiles;

return

% ------------------------------------------------------------------------------
% Merge the profiles according to the treatment type of each depth zone.
%
% SYNTAX :
%  [o_tabProfile] = merge_profiles(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profiles to merge
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = merge_profiles(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatDecimatedRaw;


% collect information on profiles to be merged
direction = repmat(' ', length(a_tabProfiles), 1);
minDate = ones(length(a_tabProfiles), 1)*-1;
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction(idProf) = profile.direction;
   minDate(idProf) = min(profile.datesAdj);
end

% create parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramBlackTempParticles = get_netcdf_param_attributes('BLACK_TEMP_PARTICLES');
paramBlackNbSizeSpecPart = get_netcdf_param_attributes('BLACK_NB_SIZE_SPECTRA_PARTICLES');

% create final profile(s)
uDir = unique(direction);
for idDir = 1:length(uDir)
   idProfForDir = find(direction == uDir(idDir));
   [~, idSort] = sort(minDate);
   idProfForDir = idProfForDir(idSort);
   
   % create data array and parameter list
   finalDates = [];
   finalDatesAdj = [];
   finalData = [];
   for idP = 1:length(idProfForDir)
      idProf = idProfForDir(idP);
      
      dates = a_tabProfiles(idProf).dates;
      datesAdj = a_tabProfiles(idProf).datesAdj;
      data = a_tabProfiles(idProf).data;
      
      finalDates = [finalDates; dates];
      finalDatesAdj = [finalDatesAdj; datesAdj];
      
      switch (a_tabProfiles(idProf).treatType)
         case {g_decArgo_treatRaw, g_decArgo_treatDecimatedRaw}
            % UVP-BLACK (raw) (decimated raw)
            
            finalData = [finalData; ...
               data];
      end
   end
   
   paramList = [ ...
      paramPres paramBlackTempParticles paramBlackNbSizeSpecPart ...
      ];
      
   newProfile = a_tabProfiles(idProfForDir(1));
   
   newProfile.paramList = paramList;
   newProfile.paramNumberWithSubLevels = [3];
   newProfile.paramNumberOfSubLevels = [5];
   newProfile.treatType = '';
   newProfile.dateList = paramJuld;
   
   newProfile.data = finalData;
   newProfile.dates = finalDates;
   newProfile.datesAdj = finalDatesAdj;
   
   newProfile.merged = 1;
   
   % measurement dates
   newProfile.minMeasDate = min(newProfile.datesAdj);
   newProfile.maxMeasDate = max(newProfile.datesAdj);
   
   o_tabProfiles = [o_tabProfiles newProfile];
   
end

return
