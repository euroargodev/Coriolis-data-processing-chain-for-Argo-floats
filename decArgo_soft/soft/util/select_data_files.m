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

floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_36.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nova.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nke_atlantos.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_argos_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_sbd_090215.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-sbd_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nemo_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\lists_20230316\list_decId_2xx_all.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_C_all.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_all_decId_2xx.txt';

inputDirName = 'C:\Users\jprannou\_DATA\201905-ArgoData\coriolis\';
inputDirName = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';
inputDirName = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
inputDirName = 'E:\work_traj_32\nc_output_decArgo_traj_32\';

fprintf('Floats from list: %s\n', floatListFileName);
floatList = load(floatListFileName);

% création du répertoire de destination
outputDirName = [inputDirName '/selected/'];
if (exist(outputDirName, 'dir') == 7)
   fprintf('Le répertoire %s existe déjà, arrêt du programme\n', outputDirName);
   return
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
      move_file(txtDirName, outputDirName);
      fprintf('\n');
   end
end

return
