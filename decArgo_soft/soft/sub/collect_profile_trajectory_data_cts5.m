% ------------------------------------------------------------------------------
% Collect trajectory data from profiles structure.
%
% SYNTAX :
%  [o_tabTrajIndex, o_tabTrajData] = collect_profile_trajectory_data_cts5( ...
%    a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : profile data
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
function [o_tabTrajIndex, o_tabTrajData] = collect_profile_trajectory_data_cts5( ...
   a_tabProfiles)

% output parameters initialization
o_tabTrajIndex = [];
o_tabTrajData = [];


% global measurement codes
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;


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
   if (~isempty(profile.ptsForDoxy))
      datedMeasStruct.ptsForDoxy = profile.ptsForDoxy(idDated, :);
   end
   datedMeasStruct.sensorNumber = profile.sensorNumber;
   
   o_tabTrajIndex = [o_tabTrajIndex;
      measCode  profile.cycleNumber profile.profileNumber profile.phaseNumber];
   o_tabTrajData = [o_tabTrajData; {{datedMeasStruct}}];
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
      
      if (dirNum == 2)
         measCode = g_MC_AscProfDeepestBin;
      else
         measCode = g_MC_DescProfDeepestBin;
      end
      
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
         datedMeasStruct.datesAdj = profile.datesAdj(profInfo(idProfMax, 5));
         datedMeasStruct.data = profile.data(profInfo(idProfMax, 5), :);
         if (~isempty(profile.ptsForDoxy))
            datedMeasStruct.ptsForDoxy = profile.ptsForDoxy(profInfo(idProfMax, 5), :);
         end
         datedMeasStruct.sensorNumber = profile.sensorNumber;
         
         o_tabTrajIndex = [o_tabTrajIndex;
            measCode  cyNum profNum profile.phaseNumber];
         o_tabTrajData = [o_tabTrajData; {{datedMeasStruct}}];
      end
   end
end

return
