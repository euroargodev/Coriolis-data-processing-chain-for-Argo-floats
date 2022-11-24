% ------------------------------------------------------------------------------
% Selection (déplacement) des répertoires de fichiers traités associés à une
% liste de flotteurs.
%
% SYNTAX :
%   select_data_files ou select_data_files(6900189,7900118)
%
% INPUT PARAMETERS :
%   varargin : éventuellement la liste des numéros de flotteurs à traiter
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

% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/_nke_ir_sbd_rem_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/nke_all_with_DM.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/arvor_ir_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/new_argos.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/provor_do_ir.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\nke_all_with_DM_bis_20151003.txt';

% inputDirName = 'E:\archive_201510\201510-ArgoData\coriolis\';
% inputDirName = 'E:\archive_201510\201510-ArgoData\incois\';
% inputDirName = 'E:\archive_201510\201510-ArgoData\bodc\';
% inputDirName = 'C:\Users\jprannou\_RNU\Andro\data\juste_dep_20140218\';
inputDirName = 'E:\archive_201505\coriolis\';
% inputDirName = 'E:\archive_201510\201510-ArgoData\DATA\coriolis\';


fprintf('Floats from list: %s\n', floatListFileName);
floatList = load(floatListFileName);

% création du répertoire de destination
outputDirName = [inputDirName '/selected/'];
if (exist(outputDirName, 'dir') == 7)
   fprintf('Le répertoire %s existe déjà, arrêt du programme\n', outputDirName);
   return;
else
   mkdir(outputDirName);
end

% déplacement des répertoires de fichiers TXT associés aux flotteurs de la liste
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   floatNum = floatList(idFloat);

   txtDirName = [inputDirName num2str(floatNum) '/'];

   fprintf('%03d/%03d %d', idFloat, nbFloats, floatNum);

   if ~(exist(txtDirName, 'dir') == 7)
      fprintf(': répertoire absent: %s\n', txtDirName);
   else
      movefile(txtDirName, outputDirName);
      fprintf('\n');
   end
end

return;
