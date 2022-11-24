% ------------------------------------------------------------------------------
% Selection (d�placement) des fichiers Argos associ�es � une liste de
% flotteurs.
%
% SYNTAX :
%   select_argos_files_in_archive_cycle ou
%   select_argos_files_in_archive_cycle(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : �ventuellement la liste des num�ros de flotteurs � traiter
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : get_config
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   18/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function select_argos_files_in_archive_cycle(varargin)

% lecture du fichier de configuration
configVar = [];
configVar{end+1} = 'FLOAT_LIST';
configVar{end+1} = 'ARGO_DISP_DIRECTORY';
configVar{end+1} = 'WMO_ARGOS_LIST';
[floatListFileName, argoDispDirectory, wmoToArgosFileName] = get_config(configVar);

if (nargin == 0)
   % les fichiers pris en compte sont ceux d'une liste de flotteurs pr�d�finie
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('Fichier introuvable: %s\n', floatListFileName);
      return;
   end

   fprintf('Flotteurs de la liste: %s\n', floatListFileName);
   floatList = textread(floatListFileName, '%d');
else
   % les fichiers pris en compte sont ceux fournis en param�tre
   floatList = cell2mat(varargin);
end

% r�pertoire source
inputDirName = 'E:\archive_cycle_20130121/';

% cr�ation du r�pertoire de destination
outputDirName = [inputDirName '../selected/'];
if (exist(outputDirName, 'dir') == 7)
   fprintf('Le r�pertoire %s existe d�j�, arr�t du programme\n', outputDirName);
   return;
else
   mkdir(outputDirName);
end

% lecture de la table de correspondance: num�ro WMO <-> num�ro de plate-forme
% Argos
[numWmo numArgos] = get_wmo_num_vs_argos_num(wmoToArgosFileName);
numWmo = str2num(char(numWmo));
numArgos = str2num(char(numArgos));
if (isempty(numWmo))
   return;
end

% d�placement des fichiers Argos des flotteurs de la liste
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % recherche du num�ro Argos de ce flotteur
   [argosId] = find_argosId(floatNum, numWmo, numArgos);
   if (isempty(argosId))
      return;
   end
   
   argosFile = dir([inputDirName '/' sprintf('*%d*%d*.txt', argosId, floatNum)]);
   if (isempty(argosFile))
      fprintf('Pas de donn�es\n');
   end
   for idFile = 1:length(argosFile)
      argosFileName = argosFile(idFile).name;
      argosFilePathName = [inputDirName '/' argosFileName];
      if ((~strcmp(argosFileName, '.')) && (~strcmp(argosFileName, '..')))

         if (exist(argosFilePathName, 'file') == 2)
            movefile(argosFilePathName, outputDirName);
         else
            fprintf(': r�pertoire absent: %s\n', argosFilePathName);
         end
      end
   end
end

return;
