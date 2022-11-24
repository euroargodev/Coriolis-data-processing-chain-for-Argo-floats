% ------------------------------------------------------------------------------
% Retrieve already decoded APMT technical data.
%
% SYNTAX :
%  [o_techData, o_timeData, o_ncTechData, o_ncTrajData, o_ncMetaData] = ...
%    get_apmt_technical_file(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT technical file name
%
% OUTPUT PARAMETERS :
%   o_techData   : APMT technical data
%   o_timeData   : APMT time data
%   o_ncTechData : APMT technical data for nc file
%   o_ncTrajData : APMT trajectory data for nc file
%   o_ncMetaData : APMT meta data for nc file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techData, o_timeData, o_ncTechData, o_ncTrajData, o_ncMetaData] = ...
   get_apmt_technical_file(a_inputFilePathName)

% output parameters initialization
o_techData = [];
o_timeData = [];
o_ncTechData = [];
o_ncTrajData = [];
o_ncMetaData = [];

% array to store USEA technical data
global g_decArgo_useaTechData;


% retrieve TECH data from global variable
idFile = find(strcmp(a_inputFilePathName, g_decArgo_useaTechData(:, 3)));
if (isempty(idFile))
   fprintf('ERROR: get_apmt_technical_file: File not found: %s\n', a_inputFilePathName);
   return
end

o_techData = g_decArgo_useaTechData{idFile, 4};
o_timeData = g_decArgo_useaTechData{idFile, 5};
o_ncTechData = g_decArgo_useaTechData{idFile, 6};
o_ncTrajData = g_decArgo_useaTechData{idFile, 7};
o_ncMetaData = g_decArgo_useaTechData{idFile, 8};

return
