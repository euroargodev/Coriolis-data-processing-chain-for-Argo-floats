% ------------------------------------------------------------------------------
% Selection (d�placement) des r�pertoires de fichiers trait�s associ�s � une
% liste de flotteurs.
%
% SYNTAX :
%   select_data_files ou select_data_files(6900189,7900118)
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
%   26/05/2008 - RNU - creation
% ------------------------------------------------------------------------------
function select_data_files()

floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_36.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

inputDirName = 'C:\Users\jprannou\_DATA\201905-ArgoData\coriolis\';
inputDirName = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';

fprintf('Floats from list: %s\n', floatListFileName);
floatList = load(floatListFileName);

% cr�ation du r�pertoire de destination
outputDirName = [inputDirName '/selected/'];
if (exist(outputDirName, 'dir') == 7)
   fprintf('Le r�pertoire %s existe d�j�, arr�t du programme\n', outputDirName);
   return
else
   mkdir(outputDirName);
end

% d�placement des r�pertoires de fichiers TXT associ�s aux flotteurs de la liste
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   floatNum = floatList(idFloat);

   txtDirName = [inputDirName num2str(floatNum) '/'];

   fprintf('%03d/%03d %d', idFloat, nbFloats, floatNum);

   if ~(exist(txtDirName, 'dir') == 7)
      fprintf(': r�pertoire absent: %s\n', txtDirName);
   else
      move_file(txtDirName, outputDirName);
      fprintf('\n');
   end
end

return
