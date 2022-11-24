% ------------------------------------------------------------------------------
% Load the processed data stored in the (last) temporary file.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal] = load_processed_data_ir_rudics_sbd2
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : decoded profiles
%   o_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : decoded technical index information
%   o_tabNcTechVal   : decoded technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal] = load_processed_data_ir_rudics_sbd2

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];

% current float WMO number
global g_decArgo_floatNum;

% processed data directory
global g_decArgo_tmpDirectory;

% default values
global g_decArgo_janFirst1950InMatlab;

% processed data loaded flag
global g_decArgo_processedDataLoadedFlag;


% look for the last processed data .mat file
dataFiles = dir([g_decArgo_tmpDirectory '/' sprintf('processed_data_%d_*.mat', g_decArgo_floatNum)]);
if (~isempty(dataFiles))
   fileName = [];
   fileDate = [];
   for idFile = 1:length(dataFiles)
      
      dataFileName = dataFiles(idFile).name;
      dataFileDate = datenum(dataFileName(end-18:end-4), 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      fileName{end+1} = dataFileName;
      fileDate(end+1) = dataFileDate;
   end
   
   % chronologically sort the files
   [fileDate, idSort] = sort(fileDate);
   fileName = fileName(idSort);
   
   % load the data
   load([g_decArgo_tmpDirectory '/' fileName{end}]);
   
   % output data
   o_tabProfiles = a_tabProfiles;
   if (~isempty(o_tabProfiles))
      [o_tabProfiles.updated] = deal(0);
   end
   o_tabTrajNMeas = a_tabTrajNMeas;
   o_tabTrajNCycle = a_tabTrajNCycle;
   o_tabNcTechIndex = a_tabNcTechIndex;
   o_tabNcTechVal = a_tabNcTechVal;
   
   % to reduce the amount of data to be stored in the .mat file, we only keep
   % parameter names (instead of the entire parameter structure)
   % before using it we should then replace the parameter names by their
   % structure information
   [o_tabProfiles, o_tabTrajNMeas] = increase_param_info(o_tabProfiles, o_tabTrajNMeas);
   
   g_decArgo_processedDataLoadedFlag = 1;
end

return;

% ------------------------------------------------------------------------------
% For each parameter, replace parameter name by structure parameter information.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas] = increase_param_info(a_tabProfiles, a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles  : input profile data
%   a_tabTrajNMeas : input trajectory N_MEASUREMENT data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : output profile data
%   o_tabTrajNMeas : output trajectory N_MEASUREMENT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas] = increase_param_info(a_tabProfiles, a_tabTrajNMeas)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;


% process profile parameters
for idProf = 1:length(o_tabProfiles)
   if (~isempty(o_tabProfiles(idProf).paramList))
      if (iscell(o_tabProfiles(idProf).paramList))
         paramListIn = o_tabProfiles(idProf).paramList;
         paramListOut = [];
         for idParam = 1:length(paramListIn)
            param = get_netcdf_param_attributes(paramListIn{idParam});
            paramListOut = [paramListOut param];
         end
         o_tabProfiles(idProf).paramList = paramListOut;
      end
   end
   if (~isempty(o_tabProfiles(idProf).dateList))
      if (iscell(o_tabProfiles(idProf).dateList))
         dateListIn = o_tabProfiles(idProf).dateList;
         dateListOut = [];
         for idParam = 1:length(dateListIn)
            param = get_netcdf_param_attributes(dateListIn{idParam});
            dateListOut = [dateListOut param];
         end
         o_tabProfiles(idProf).dateList = dateListOut;
      end
   end
end

% process trajectory parameters
for idTrajNMeas = 1:length(o_tabTrajNMeas)
   for idMeas = 1:length(o_tabTrajNMeas(idTrajNMeas).tabMeas)
      if (~isempty(o_tabTrajNMeas(idTrajNMeas).tabMeas(idMeas).paramList))
         if (iscell(o_tabTrajNMeas(idTrajNMeas).tabMeas(idMeas).paramList))
            paramListIn = o_tabTrajNMeas(idTrajNMeas).tabMeas(idMeas).paramList;
            paramListOut = [];
            for idParam = 1:length(paramListIn)
               param = get_netcdf_param_attributes(paramListIn{idParam});
               paramListOut = [paramListOut param];
            end
            o_tabTrajNMeas(idTrajNMeas).tabMeas(idMeas).paramList = paramListOut;
         end
      end
   end
end

return;
