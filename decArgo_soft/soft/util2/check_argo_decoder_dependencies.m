% ------------------------------------------------------------------------------
% Check that all dependency files of the Argo package are in their expected
% directories.
% Count the number of Matlab code lines.
%
% SYNTAX :
%   check_argo_decoder_dependencies
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/20/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_argo_decoder_dependencies

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% directories to check
SOFT_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\';
SOFT_SUB_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\sub\';
SOFT_SUB_FOREIGN_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\sub_foreign\';

SOFT_UTIL_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\';
SOFT_UTIL_SUB_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\sub\';
SOFT_UTIL_SUB_FOREIGN_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\sub_foreign\';

SOFT_UTIL2_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\';
SOFT_UTIL2_SUB_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\sub\';
SOFT_UTIL2_SUB_FOREIGN_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\sub_foreign\';

M_MAP_DIR = 'C:\Program Files\MATLAB\pourArgo\m_map\m_map1.4e\';
M_MAP_DIR2 = 'C:\Program Files\MATLAB\pourArgo\m_map\m_map1.4e\private\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'check_argo_decoder_dependencies_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

if (exist('argo_decoder_dependencies.mat', 'file') == 2)
   
   fprintf('\nREMOVE ''argo_decoder_dependencies.mat'' FILE TO UPDATE IT (IF NEEDED)\n');
   
   fprintf('\nLOADING DEPENDENCIES IN ''argo_decoder_dependencies.mat'' file\n');
   load('argo_decoder_dependencies.mat');
else
   fprintf('\nRETRIEVING DECODERS DEPENDENCIES:\n');
   decList = dir([SOFT_DIR '*.m']);
   decName = [];
   decDependencies = [];
   for idDec = 1:length(decList)
      decoder = decList(idDec).name;
      fprintf('- %s\n', decoder);
      decFiles = matlab.codetools.requiredFilesAndProducts(decoder);
      decName{end+1} = decoder;
      decDependencies{end+1} = decFiles;
   end
   
   fprintf('\nRETRIEVING TOOLS #1 DEPENDENCIES:\n');
   utilList = dir([SOFT_UTIL_DIR '*.m']);
   utilName = [];
   utilDependencies = [];
   for idUtil = 1:length(utilList)
      util = utilList(idUtil).name;
      fprintf('- %s\n', util);
      utilFiles = matlab.codetools.requiredFilesAndProducts(util);
      utilName{end+1} = util;
      utilDependencies{end+1} = utilFiles;
   end
   
   fprintf('\nRETRIEVING TOOLS #2 DEPENDENCIES:\n');
   util2List = dir([SOFT_UTIL2_DIR '*.m']);
   util2Name = [];
   util2Dependencies = [];
   for idUtil2 = 1:length(util2List)
      util2 = util2List(idUtil2).name;
      fprintf('- %s\n', util2);
      util2Files = matlab.codetools.requiredFilesAndProducts(util2);
      util2Name{end+1} = util2;
      util2Dependencies{end+1} = util2Files;
   end
   
   fprintf('\nSAVING DEPENDENCIES IN ''argo_decoder_dependencies.mat'' file\n');
   save('argo_decoder_dependencies.mat', ...
      'decName', 'decDependencies', ...
      'utilName', 'utilDependencies', ...
      'util2Name', 'util2Dependencies');
end

fprintf('\n');

% retrieve file list of sub directories

% SOFT_SUB_DIR
subList = dir([SOFT_SUB_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_SUB_DIR, length(subList));
subListFiles = [];
subListFileLines = [];
for idSub = 1:length(subList)
   subListFiles{end+1} = [SOFT_SUB_DIR subList(idSub).name];
   subListFileLines(end+1) = sloc(subListFiles{end});
end

% SOFT_SUB_FOREIGN_DIR
subList = dir([SOFT_SUB_FOREIGN_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_SUB_FOREIGN_DIR, length(subList));
subFListFiles = [];
subFListFileLines = [];
for idSub = 1:length(subList)
   subFListFiles{end+1} = [SOFT_SUB_FOREIGN_DIR subList(idSub).name];
   subFListFileLines(end+1) = sloc(subFListFiles{end});
end

% SOFT_UTIL_SUB_DIR
subUtilList = dir([SOFT_UTIL_SUB_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_UTIL_SUB_DIR, length(subUtilList));
subUtilListFiles = [];
subUtilListFileLines = [];
for idSubUtil = 1:length(subUtilList)
   subUtilListFiles{end+1} = [SOFT_UTIL_SUB_DIR subUtilList(idSubUtil).name];
   subUtilListFileLines(end+1) = sloc(subUtilListFiles{end});
end

% SOFT_UTIL_SUB_FOREIGN_DIR
subUtilList = dir([SOFT_UTIL_SUB_FOREIGN_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_UTIL_SUB_FOREIGN_DIR, length(subUtilList));
subUtilFListFiles = [];
subUtilFListFileLines = [];
for idSubUtil = 1:length(subUtilList)
   subUtilFListFiles{end+1} = [SOFT_UTIL_SUB_FOREIGN_DIR subUtilList(idSubUtil).name];
   subUtilFListFileLines(end+1) = sloc(subUtilFListFiles{end});
end


% SOFT_UTIL2_SUB_DIR
subUtil2List = dir([SOFT_UTIL2_SUB_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_UTIL2_SUB_DIR, length(subUtil2List));
subUtil2ListFiles = [];
subUtil2ListFileLines = [];
for idSubUtil2 = 1:length(subUtil2List)
   subUtil2ListFiles{end+1} = [SOFT_UTIL2_SUB_DIR subUtil2List(idSubUtil2).name];
   subUtil2ListFileLines(end+1) = sloc(subUtil2ListFiles{end});
end

% SOFT_UTIL2_SUB_FOREIGN_DIR
subUtil2List = dir([SOFT_UTIL2_SUB_FOREIGN_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', SOFT_UTIL2_SUB_FOREIGN_DIR, length(subUtil2List));
subUtil2FListFiles = [];
subUtil2FListFileLines = [];
for idSubUtil2 = 1:length(subUtil2List)
   subUtil2FListFiles{end+1} = [SOFT_UTIL2_SUB_FOREIGN_DIR subUtil2List(idSubUtil2).name];
   subUtil2FListFileLines(end+1) = sloc(subUtil2FListFiles{end});
end


% M_MAP_DIR
mMapList = dir([M_MAP_DIR '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', M_MAP_DIR, length(mMapList));
mMapFListFiles = [];
for idmMap = 1:length(mMapList)
   mMapFListFiles{end+1} = [M_MAP_DIR mMapList(idmMap).name];
end

% M_MAP_DIR2
mMap2List = dir([M_MAP_DIR2 '*.m']);
fprintf('Getting information on ''%s'' directory: %d files\n', M_MAP_DIR2, length(mMap2List));
mMap2FListFiles = [];
for idmMap2 = 1:length(mMap2List)
   mMap2FListFiles{end+1} = [M_MAP_DIR2 mMap2List(idmMap2).name];
end


% DECODERS
fprintf('\nCHECKING DECODERS:\n');
nbLines = 0;
subListFileHits = zeros(size(subListFiles));
subFListFileHits = zeros(size(subFListFiles));
for id = 1:length(decDependencies)
   dependency = decDependencies{id};
   for id2 = 1:length(dependency)
      found = 0;
      idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subListFiles));
      if (~isempty(idF))
         if (subListFileHits(idF) == 0)
            nbLines = nbLines + subListFileLines(idF);
         end
         subListFileHits(idF) = subListFileHits(idF) + 1;
         found = 1;
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subFListFiles));
         if (~isempty(idF))
            if (subFListFileHits(idF) == 0)
               nbLines = nbLines + subFListFileLines(idF);
            end
            subFListFileHits(idF) = subFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         [~, name, ext] = fileparts(dependency{id2});
         idF = find(cellfun(@(x) strcmp(x, [name ext]), decName), 1);
         if (isempty(idF))
            fprintf('File in an unexpected directory: %s\n', dependency{id2});
         else
            nbLines = nbLines + sloc(dependency{id2});
         end
      end
   end
end

fprintf('Nb lines for decoders: %d\n', nbLines);

idF = find(subListFileHits == 0);
if (~isempty(idF))
   fprintf('Unused files:\n%s', sprintf('%s\n', subListFiles{idF}));
end
idF2 = find(subFListFileHits == 0);
if (~isempty(idF2))
   if (isempty(idF))
      fprintf('Unused files:\n%s', sprintf('%s\n', subFListFiles{idF2}));
   else
      fprintf('\n%s', sprintf('%s\n', subFListFiles{idF2}));
   end
end
   
% TOOLS #1
fprintf('\nCHECKING TOOLS #1:\n');
nbLines = 0;
subListFileHits = zeros(size(subListFiles));
subFListFileHits = zeros(size(subFListFiles));
subUtilListFileHits = zeros(size(subUtilListFiles));
subUtilFListFileHits = zeros(size(subUtilFListFiles));
for id = 1:length(utilDependencies)
   dependency = utilDependencies{id};
   for id2 = 1:length(dependency)
      found = 0;
      idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subListFiles));
      if (~isempty(idF))
         if (subListFileHits(idF) == 0)
            nbLines = nbLines + subListFileLines(idF);
         end
         subListFileHits(idF) = subListFileHits(idF) + 1;
         found = 1;
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subFListFiles));
         if (~isempty(idF))
            if (subFListFileHits(idF) == 0)
               nbLines = nbLines + subFListFileLines(idF);
            end
            subFListFileHits(idF) = subFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilListFiles));
         if (~isempty(idF))
            if (subUtilListFileHits(idF) == 0)
               nbLines = nbLines + subUtilListFileLines(idF);
            end
            subUtilListFileHits(idF) = subUtilListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilFListFiles));
         if (~isempty(idF))
            if (subUtilFListFileHits(idF) == 0)
               nbLines = nbLines + subUtilFListFileLines(idF);
            end
            subUtilFListFileHits(idF) = subUtilFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMapFListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMap2FListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         [~, name, ext] = fileparts(dependency{id2});
         idF = find(cellfun(@(x) strcmp(x, [name ext]), utilName), 1);
         if (isempty(idF))
            fprintf('File in an unexpected directory: %s\n', dependency{id2});
         else
            nbLines = nbLines + sloc(dependency{id2});
         end
      end
   end
end

fprintf('Nb lines for tools #1: %d\n', nbLines);

idF = find(subUtilListFileHits == 0);
if (~isempty(idF))
   fprintf('Unused files:\n%s', sprintf('%s\n', subUtilListFiles{idF}));
end
idF2 = find(subUtilFListFileHits == 0);
if (~isempty(idF2))
   if (isempty(idF))
      fprintf('Unused files:\n%s', sprintf('%s\n', subUtilFListFiles{idF2}));
   else
      fprintf('\n%s', sprintf('%s\n', subUtilFListFiles{idF2}));
   end
end

% TOOLS #2
fprintf('\nCHECKING TOOLS #2:\n');
nbLines = 0;
subListFileHits = zeros(size(subListFiles));
subFListFileHits = zeros(size(subFListFiles));
subUtilListFileHits = zeros(size(subUtilListFiles));
subUtilFListFileHits = zeros(size(subUtilFListFiles));
subUtil2ListFileHits = zeros(size(subUtil2ListFiles));
subUtil2FListFileHits = zeros(size(subUtil2FListFiles));
for id = 1:length(util2Dependencies)
   dependency = util2Dependencies{id};
   for id2 = 1:length(dependency)
      found = 0;
      idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subListFiles));
      if (~isempty(idF))
         if (subListFileHits(idF) == 0)
            nbLines = nbLines + subListFileLines(idF);
         end
         subListFileHits(idF) = subListFileHits(idF) + 1;
         found = 1;
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subFListFiles));
         if (~isempty(idF))
            if (subFListFileHits(idF) == 0)
               nbLines = nbLines + subFListFileLines(idF);
            end
            subFListFileHits(idF) = subFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilListFiles));
         if (~isempty(idF))
            if (subUtilListFileHits(idF) == 0)
               nbLines = nbLines + subUtilListFileLines(idF);
            end
            subUtilListFileHits(idF) = subUtilListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilFListFiles));
         if (~isempty(idF))
            if (subUtilFListFileHits(idF) == 0)
               nbLines = nbLines + subUtilFListFileLines(idF);
            end
            subUtilFListFileHits(idF) = subUtilFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtil2ListFiles));
         if (~isempty(idF))
            if (subUtil2ListFileHits(idF) == 0)
               nbLines = nbLines + subUtil2ListFileLines(idF);
            end
            subUtil2ListFileHits(idF) = subUtil2ListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtil2FListFiles));
         if (~isempty(idF))
            if (subUtil2FListFileHits(idF) == 0)
               nbLines = nbLines + subUtil2FListFileLines(idF);
            end
            subUtil2FListFileHits(idF) = subUtil2FListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMapFListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMap2FListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         [~, name, ext] = fileparts(dependency{id2});
         idF = find(cellfun(@(x) strcmp(x, [name ext]), util2Name), 1);
         if (isempty(idF))
            fprintf('File in an unexpected directory: %s\n', dependency{id2});
         else
            nbLines = nbLines + sloc(dependency{id2});
         end
      end
   end
end

fprintf('Nb lines for tools #2: %d\n', nbLines);

idF = find(subUtil2ListFileHits == 0);
if (~isempty(idF))
   fprintf('Unused files:\n%s', sprintf('%s\n', subUtil2ListFiles{idF}));
end
idF2 = find(subUtil2FListFileHits == 0);
if (~isempty(idF2))
   if (isempty(idF))
      fprintf('Unused files:\n%s', sprintf('%s\n', subUtil2FListFiles{idF2}));
   else
      fprintf('\n%s', sprintf('%s\n', subUtil2FListFiles{idF2}));
   end
end

% ARGO DECODER PACKAGE
fprintf('\nCHECKING ARGO DECODER PACKAGE:\n');
nbLines = 0;
subListFileHits = zeros(size(subListFiles));
subFListFileHits = zeros(size(subFListFiles));
subUtilListFileHits = zeros(size(subUtilListFiles));
subUtilFListFileHits = zeros(size(subUtilFListFiles));
subUtil2ListFileHits = zeros(size(subUtil2ListFiles));
subUtil2FListFileHits = zeros(size(subUtil2FListFiles));
argoPackageName = [decName utilName util2Name];
argoPackageDependencies = [decDependencies utilDependencies util2Dependencies];
for id = 1:length(argoPackageDependencies)
   dependency = argoPackageDependencies{id};
   for id2 = 1:length(dependency)
      found = 0;
      idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subListFiles));
      if (~isempty(idF))
         if (subListFileHits(idF) == 0)
            nbLines = nbLines + subListFileLines(idF);
         end
         subListFileHits(idF) = subListFileHits(idF) + 1;
         found = 1;
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subFListFiles));
         if (~isempty(idF))
            if (subFListFileHits(idF) == 0)
               nbLines = nbLines + subFListFileLines(idF);
            end
            subFListFileHits(idF) = subFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilListFiles));
         if (~isempty(idF))
            if (subUtilListFileHits(idF) == 0)
               nbLines = nbLines + subUtilListFileLines(idF);
            end
            subUtilListFileHits(idF) = subUtilListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtilFListFiles));
         if (~isempty(idF))
            if (subUtilFListFileHits(idF) == 0)
               nbLines = nbLines + subUtilFListFileLines(idF);
            end
            subUtilFListFileHits(idF) = subUtilFListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtil2ListFiles));
         if (~isempty(idF))
            if (subUtil2ListFileHits(idF) == 0)
               nbLines = nbLines + subUtil2ListFileLines(idF);
            end
            subUtil2ListFileHits(idF) = subUtil2ListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), subUtil2FListFiles));
         if (~isempty(idF))
            if (subUtil2FListFileHits(idF) == 0)
               nbLines = nbLines + subUtil2FListFileLines(idF);
            end
            subUtil2FListFileHits(idF) = subUtil2FListFileHits(idF) + 1;
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMapFListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         idF = find(cellfun(@(x) strcmp(x, dependency{id2}), mMap2FListFiles));
         if (~isempty(idF))
            found = 1;
         end
      end
      if (~found)
         [~, name, ext] = fileparts(dependency{id2});
         idF = find(cellfun(@(x) strcmp(x, [name ext]), argoPackageName), 1);
         if (isempty(idF))
            fprintf('File in an unexpected directory: %s\n', dependency{id2});
         else
            nbLines = nbLines + sloc(dependency{id2});
         end
      end
   end
end

fprintf('Nb lines for Argo decoder package: %d\n', nbLines);

idF = find(subListFileHits == 0);
idF2 = find(subFListFileHits == 0);
idF3 = find(subUtilListFileHits == 0);
idF4 = find(subUtilFListFileHits == 0);
idF5 = find(subUtil2ListFileHits == 0);
idF6 = find(subUtil2FListFileHits == 0);
if (~isempty(idF) || ~isempty(idF2) || ~isempty(idF3) || ~isempty(idF4) || ~isempty(idF5) || ~isempty(idF6))
   fprintf('Unused files:\n');
end
if (~isempty(idF))
   fprintf('\n%s', sprintf('%s\n', subListFiles{idF}));
end
if (~isempty(idF2))
   fprintf('\n%s', sprintf('%s\n', subFListFiles{idF2}));
end
if (~isempty(idF3))
   fprintf('\n%s', sprintf('%s\n', subUtilListFiles{idF3}));
end
if (~isempty(idF4))
   fprintf('\n%s', sprintf('%s\n', subUtilFListFiles{idF4}));
end
if (~isempty(idF5))
   fprintf('\n%s', sprintf('%s\n', subUtil2ListFiles{idF5}));
end
if (~isempty(idF6))
   fprintf('\n%s', sprintf('%s\n', subUtil2FListFiles{idF6}));
end

ellapsedTime = toc;
fprintf('\ndone (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
