% ------------------------------------------------------------------------------
% Before creating NetCDF MONO-PROFILE files, delete profiles that do not need to
% be updated.
%
% SYNTAX :
%  create_nc_mono_prof_files( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/31/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_mono_prof_files( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson)

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcMonoProf;

% RT processing flag
global g_decArgo_realtimeFlag;

% global input parameter information
global g_decArgo_processModeAll;

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% Argos existing files
global g_decArgo_existingArgosFileCycleNumber;
global g_decArgo_existingArgosFileSystemDate;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;

% generate nc flag
global g_decArgo_generateNcFlag;


% no data to save
if (isempty(a_tabProfiles))
   return;
end

if (g_decArgo_floatTransType == 1)
   
   % Argos floats
   
   if (g_decArgo_generateNcMonoProf == 2)
      
      if ((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))
         
         % only completed profiles are preserved
         idDel = [];
         for idProf = 1:length(a_tabProfiles)
            profile = a_tabProfiles(idProf);
            if (isempty(profile.profileCompleted))
               idDel = [idDel idProf];
            elseif (profile.profileCompleted > 0)
               idDel = [idDel idProf];
            end
         end
         a_tabProfiles(idDel) = [];
      else
         
         % expected output dir name
         floatNumStr = num2str(g_decArgo_floatNum);
         ncDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/profiles/'];
         if (exist(ncDirName, 'dir') == 7)
            
            % preserve only the profiles that have to be updated
            idDel = [];
            for idProf = 1:length(a_tabProfiles)
               profile = a_tabProfiles(idProf);
               cycleNumber = profile.cycleNumber;
               
               if (profile.direction == 'D')
                  ncFileName = sprintf('R%d_%03dD.nc', ...
                     g_decArgo_floatNum, cycleNumber);
               else
                  ncFileName = sprintf('R%d_%03d.nc', ...
                     g_decArgo_floatNum, cycleNumber);
               end
               ncPathFileName = [ncDirName ncFileName];
               
               if (exist(ncPathFileName, 'file') == 2)
                  
                  % PROF variables to retrieve
                  wantedProfVars = [ ...
                     {'DATE_UPDATE'} ...
                     {'JULD_LOCATION'} ...
                     ];
                  
                  % retrieve information from PROF netCDF file
                  [profData] = get_data_from_nc_file(ncPathFileName, wantedProfVars);
                  
                  idF = find(g_decArgo_existingArgosFileCycleNumber == cycleNumber);
                  if (length(idF) == 1)
                     
                     % for each mono-profile file, compare Argos cycle file
                     % system date with the update date of the NetCDF file
                     idVal = find(strcmp('DATE_UPDATE', profData) == 1);
                     if (~isempty(idVal))
                        ncFileUpdateDate = profData{idVal+1};
                        ncFileUpdateDate = datenum(ncFileUpdateDate', 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
                        
                        if (g_decArgo_existingArgosFileSystemDate(idF) < ncFileUpdateDate)
                           
                           % if the profile location date is missing in the nc
                           % file but not in the decoded data, the profile need
                           % to be updated (the profile location has probably
                           % been created from an interpolation of following
                           % profile location)

                           idVal = find(strcmp('JULD_LOCATION', profData) == 1);
                           if (~isempty(idVal))
                              julDLocation = profData{idVal+1};
                              
                              if ~((length(unique(julDLocation)) == 1) && ...
                                    (unique(julDLocation) == g_decArgo_ncDateDef) && ...
                                    (profile.locationDate ~= g_decArgo_dateDef))
                                 idDel = [idDel idProf];
                              end
                           else
                              idDel = [idDel idProf];
                           end
                        end
                     end
                  elseif (length(idF) > 1)
                     fprintf('WARNING: Float #%d: %d Argos cycle files for cycle #%d\n', ...
                        g_decArgo_floatNum, length(idF), cycleNumber);
                  else
                     fprintf('WARNING: Float #%d: Argos cycle cycle #%d file does not exist anymore\n', ...
                        g_decArgo_floatNum, cycleNumber);
                  end
                  
               end
            end
            a_tabProfiles(idDel) = [];
         end
      end
   end
   
   create_nc_mono_prof_files_3_1(a_decoderId, ...
      a_tabProfiles, a_metaDataFromJson);
      
elseif (g_decArgo_floatTransType == 2)
   
   % Iridium RUDICS floats
   
   if ((g_decArgo_generateNcMonoProf == 1) || ...
         ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_mono_prof_files_3_1(a_decoderId, ...
         a_tabProfiles, a_metaDataFromJson);
   end
   
elseif (g_decArgo_floatTransType == 3)
   
   % Iridium SBD floats
   
   if ((g_decArgo_generateNcMonoProf == 1) || ...
         ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_mono_prof_files_3_1(a_decoderId, ...
         a_tabProfiles, a_metaDataFromJson);
   end
   
elseif (g_decArgo_floatTransType == 4)
   
   % Iridium SBD ProvBioII floats
   
   if ((g_decArgo_generateNcMonoProf == 1) || ...
         ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_mono_prof_files_3_1(a_decoderId, ...
         a_tabProfiles, a_metaDataFromJson);
   end
   
end

return;
