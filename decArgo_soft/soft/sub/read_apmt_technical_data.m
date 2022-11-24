% ------------------------------------------------------------------------------
% Parse APMT technical files.
%
% SYNTAX :
%  read_apmt_technical(a_cyclePatternNumFloat, a_filePrefix, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cyclePatternNumFloat : cycle and pattern numbers
%   a_filePrefix           : prefix of float transmitted files
%   a_decoderId            : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function read_apmt_technical_data(a_cyclePatternNumFloat, a_filePrefix, a_decoderId)

% type of files to consider
global g_decArgo_fileTypeListCts5;

% input data dir
global g_decArgo_archiveDirectory;

% array to store USEA technical data
global g_decArgo_useaTechData;
g_decArgo_useaTechData = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process TECH files (without pattern #)

uCycleList = unique(a_cyclePatternNumFloat(:, 1));
for idCy = 1:length(uCycleList)
   floatCyNum = uCycleList(idCy);

   % '_%03d_autotest_*.txt'
   % '_%03d_%02d_default_*.txt'
   for idType = [3 5]
      idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
      pattern = g_decArgo_fileTypeListCts5{idFL, 5};
      inputFiles = dir([g_decArgo_archiveDirectory '/' a_filePrefix sprintf(pattern, floatCyNum)]);
      for iF = 1:length(inputFiles)
         [apmtTech, apmtTimeFromTech, ...
            ncApmtTech, apmtTrajFromTech, apmtMetaFromTech] = ...
            read_apmt_technical_file([g_decArgo_archiveDirectory '/' inputFiles(iF).name], a_decoderId);
         g_decArgo_useaTechData = [g_decArgo_useaTechData; ...
            [floatCyNum -1 {inputFiles(iF).name} {apmtTech} {apmtTimeFromTech} {ncApmtTech} {apmtTrajFromTech} {apmtMetaFromTech}]];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process TECH files (with pattern #)

for idCyPat = 1:size(a_cyclePatternNumFloat, 1)
   floatCyNum = a_cyclePatternNumFloat(idCyPat, 1);
   floatPtnNum = a_cyclePatternNumFloat(idCyPat, 2);

   % '_%03d_%02d_technical*.txt'
   for idType = [4]
      idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
      pattern = g_decArgo_fileTypeListCts5{idFL, 5};
      inputFiles = dir([g_decArgo_archiveDirectory '/' a_filePrefix sprintf(pattern, floatCyNum, floatPtnNum)]);
      for iF = 1:length(inputFiles)
         [apmtTech, apmtTimeFromTech, ...
            ncApmtTech, apmtTrajFromTech, apmtMetaFromTech] = ...
            read_apmt_technical_file([g_decArgo_archiveDirectory '/' inputFiles(iF).name], a_decoderId);
         g_decArgo_useaTechData = [g_decArgo_useaTechData; ...
            [floatCyNum floatPtnNum {inputFiles(iF).name} {apmtTech} {apmtTimeFromTech} {ncApmtTech} {apmtTrajFromTech} {apmtMetaFromTech}]];
      end
   end
end

return
