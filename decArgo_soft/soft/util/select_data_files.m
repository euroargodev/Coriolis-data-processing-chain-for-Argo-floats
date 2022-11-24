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
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nova.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nke_atlantos.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_argos_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_sbd_090215.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-sbd_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nemo_all.txt';
floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\_arvor_deep_all.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_C_all.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% floatListFileName = '\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_all_decId_2xx.txt';

inputDirName = 'C:\Users\jprannou\_DATA\201905-ArgoData\coriolis\';
inputDirName = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';
inputDirName = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
inputDirName = 'C:\Users\jprannou\Contacts\Desktop\TEST_NR\TEST_NR_APRES\Nke_2xx\';

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
