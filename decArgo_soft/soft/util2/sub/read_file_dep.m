% ------------------------------------------------------------------------------
% Lecture du contenu d'un fichier DEP.
%
% SYNTAX :
%  [o_depCycle, o_depType, o_depDate, o_depDateFlag, o_depOrdre, ...
%    o_depLon, o_depLat, o_depPosFlag, o_depPosQc, o_depSatName, ...
%    o_depPres, o_depPresFlag, ...
%    o_depTemp, o_depTempFlag, ...
%    o_depSal, o_depSalFlag, ...
%    o_depGrd, o_depEtat, o_depUpdate, o_depProfNum] = read_file_dep(a_depFileName)
%
% INPUT PARAMETERS :
%   a_depFileName : nom du fichier DEP
%
% OUTPUT PARAMETERS :
%   données de chaque colonne
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2012 - RNU - creation
% ------------------------------------------------------------------------------
function [o_depNumWmo, o_depCycle, o_depType, ...
   o_depDate, o_depDateFlag, o_depDateGregDay, o_depDateGregHour, o_depOrdre, ...
   o_depLon, o_depLat, o_depPosFlag, o_depPosQc, o_depSatName, ...
   o_depPres, o_depPresFlag, ...
   o_depTemp, o_depTempFlag, ...
   o_depSal, o_depSalFlag, ...
   o_depGrd, o_depEtat, o_depUpdate, o_depProfNum] = read_file_dep(a_depFileName)

o_depNumWmo = [];
o_depCycle = [];
o_depType = [];
o_depDate = [];
o_depDateFlag = [];
o_depDateGregDay = [];
o_depDateGregHour = [];
o_depOrdre = [];
o_depLon = [];
o_depLat = [];
o_depPosFlag = [];
o_depPosQc = [];
o_depSatName = [];
o_depPres = [];
o_depPresFlag = [];
o_depTemp = [];
o_depTempFlag = [];
o_depSal = [];
o_depSalFlag = [];
o_depGrd = [];
o_depEtat = [];
o_depUpdate = [];
o_depProfNum = [];

% ouverture du fichier DEP
fId = fopen(a_depFileName, 'r');
if (fId == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_depFileName);
   return;
end

% lecture et stockage des données du fichier DEP
dataDep = textscan(fId, '%u %d %u %f %u %s %s %u %f %f %u %c %c %f %u %f %u %f %u %u %u %s %d');

o_depNumWmo = dataDep{1}(:);
o_depCycle = dataDep{2}(:);
o_depType = dataDep{3}(:);
o_depDate = dataDep{4}(:);
o_depDateFlag = dataDep{5}(:);
o_depDateGregDay = dataDep{6}(:);
o_depDateGregHour = dataDep{7}(:);
o_depOrdre = dataDep{8}(:);
o_depLon = dataDep{9}(:);
o_depLat = dataDep{10}(:);
o_depPosFlag = dataDep{11}(:);
o_depPosQc = dataDep{12}(:);
o_depSatName = dataDep{13}(:);
o_depPres = dataDep{14}(:);
o_depPresFlag = dataDep{15}(:);
o_depTemp = dataDep{16}(:);
o_depTempFlag = dataDep{17}(:);
o_depSal = dataDep{18}(:);
o_depSalFlag = dataDep{19}(:);
o_depGrd = dataDep{20}(:);
o_depEtat = dataDep{21}(:);
o_depUpdate = dataDep{22}(:);
o_depProfNum = dataDep{23}(:);
   
fclose(fId);

return;
