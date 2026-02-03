% ------------------------------------------------------------------------------
% Decode configuration file.
%
% SYNTAX :
% [o_confData] = decode_pfv2_config_file(a_fileName)
%
% INPUT PARAMETERS :
%   a_fileName : configuration file name
%
% OUTPUT PARAMETERS :
%   o_confData : decoded configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/02/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confData] = decode_pfv2_config_file(a_fileName)

% output parameters initialization
o_confData = [];

% SBD sub-directories
global g_decArgo_archiveDataDirectory;

% default values
global g_decArgo_janFirst1950InMatlab;


% retrieve information from file name
fileType = 30;
missionNum = nan;
cycleNum = nan;
settingDate = datenum(a_fileName(1:14), 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;

% read config file
filePathName = [g_decArgo_archiveDataDirectory '/' a_fileName];
[confLabels, confValues] = read_config_file_pfv2(filePathName);

if (~isempty(confLabels))
   o_confData = [fileType missionNum cycleNum {a_fileName} settingDate {confLabels} {confValues}];
end

return
