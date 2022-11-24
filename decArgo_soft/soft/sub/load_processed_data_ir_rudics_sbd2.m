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
   
   g_decArgo_processedDataLoadedFlag = 1;
end

return;
