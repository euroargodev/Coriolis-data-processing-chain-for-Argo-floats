% ------------------------------------------------------------------------------
% Before creating NetCDF TRAJECTORY file, check if it needs to be updated.
%
% SYNTAX :
%  create_nc_traj_file( ...
%    a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabTrajNMeas     : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle    : N_CYCLE trajectory data
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
function create_nc_traj_file( ...
   a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcTraj;

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% Argos existing files
global g_decArgo_existingArgosFileCycleNumber;
global g_decArgo_existingArgosFileSystemDate;

% default values
global g_decArgo_janFirst1950InMatlab;

% generate nc flag
global g_decArgo_generateNcFlag;


% no data to save
if (isempty(a_tabTrajNMeas) && isempty(a_tabTrajNCycle))
   return;
end

if (g_decArgo_floatTransType == 1)
   
   % Argos floats
   
   if (g_decArgo_generateNcTraj == 2)
      
      % check if the NetCDF TRAJECTORY file already exists
      floatNumStr = num2str(g_decArgo_floatNum);
      ncDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
      ncFileName = [floatNumStr '_Rtraj.nc'];
      ncPathFileName = [ncDirName ncFileName];
      
      if (exist(ncPathFileName, 'file') == 2)
         
         % TRAJ variables to retrieve
         wantedTrajVars = [ ...
            {'DATE_UPDATE'} ...
            {'CYCLE_NUMBER'} ...
            {'CYCLE_NUMBER_INDEX'} ...
            ];
         
         % retrieve information from TRAJ netCDF file
         [trajData] = get_data_from_nc_file(ncPathFileName, wantedTrajVars);
         
         % the file is not updated if:
         % - all Argos cycle file numbers are in the current TRAJ netCDF file
         % and
         % - none of the Argos cycle files has been updated since the TRAJ
         % NetCDF file update date
         ncCycleNumber = [];
         idVal = find(strcmp('CYCLE_NUMBER', trajData) == 1);
         if (~isempty(idVal))
            ncCycleNumber = [ncCycleNumber; unique(trajData{idVal+1})];
         end
         idVal = find(strcmp('CYCLE_NUMBER_INDEX', trajData) == 1);
         if (~isempty(idVal))
            ncCycleNumber = unique([ncCycleNumber; unique(trajData{idVal+1})]);
         end
         
         if (isempty(setdiff(g_decArgo_existingArgosFileCycleNumber, ncCycleNumber)))
            
            % if none of the Argos cycle files has been updated since the NetCDF
            % file update date, we do not update the file
            idVal = find(strcmp('DATE_UPDATE', trajData) == 1);
            if (~isempty(idVal))
               ncFileUpdateDate = trajData{idVal+1};
               ncFileUpdateDate = datenum(ncFileUpdateDate', 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
               
               idF = find(g_decArgo_existingArgosFileSystemDate >= ncFileUpdateDate, 1);
               if (isempty(idF))
                  return;
               end
            end
         end
      end
   end
   
   create_nc_traj_file_3_1(a_decoderId, ...
      a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);
   
elseif (g_decArgo_floatTransType == 2)
   
   % Iridium RUDICS floats
   
   if ((g_decArgo_generateNcTraj == 1) || ...
         ((g_decArgo_generateNcTraj == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_traj_file_3_1(a_decoderId, ...
         a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);
   end
   
elseif (g_decArgo_floatTransType == 3)
   
   % Iridium SBD floats
   
   if ((g_decArgo_generateNcTraj == 1) || ...
         ((g_decArgo_generateNcTraj == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_traj_file_3_1(a_decoderId, ...
         a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);
   end
   
elseif (g_decArgo_floatTransType == 4)
   
   % Iridium SBD ProvBioII floats
   
   if ((g_decArgo_generateNcTraj == 1) || ...
         ((g_decArgo_generateNcTraj == 2) && (g_decArgo_generateNcFlag == 1)))
      
      create_nc_traj_file_3_1(a_decoderId, ...
         a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);
   end
   
end

return;
