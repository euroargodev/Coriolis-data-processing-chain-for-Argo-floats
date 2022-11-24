% ------------------------------------------------------------------------------
% Read the metadata.xml file transmitted by CTS5-USEA floats, compare its
% content to the BDD information and store the metadata in the dedicated
% structure.
%
% SYNTAX :
%  [o_metaStruct] = get_meta_data_cts5(...
%    a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, ...
%    a_floatNum, a_outputCsvDirName, a_rtVersionFlag,a_dacFormatId)
%
% INPUT PARAMETERS :
%   a_metaDataXmlFileName : metadata.xml file
%   a_metaStruct          : input meta-data structure
%   a_sensorListNum       : list of CTS5-USEA sensor numbers
%   a_floatNum            : float WMO number
%   a_outputCsvDirName    : output CSV file directory
%   a_rtVersionFlag       : 1 if it is the RT version of the tool, 0 otherwise
%   a_dacFormatId         : DAC version of the float
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/12/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_data_cts5(...
   a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, ...
   a_floatNum, a_outputCsvDirName, a_rtVersionFlag, a_dacFormatId)

% output parameters initialization
o_metaStruct = [];

% retrieve deecId from DAC version
switch (a_dacFormatId)
   case {'7.11'}
      [o_metaStruct] = get_meta_data_cts5_126(...
         a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, ...
         a_floatNum, a_outputCsvDirName, a_rtVersionFlag);
   case {'7.12'}
      [o_metaStruct] = get_meta_data_cts5_127(...
         a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, ...
         a_floatNum, a_outputCsvDirName, a_rtVersionFlag);
   otherwise
      fprintf('ERROR: Cannot find decoderId from DAC version ''%s'' in get_meta_data_cts5\n', ...
         a_dacFormatId);
      return
end

return
