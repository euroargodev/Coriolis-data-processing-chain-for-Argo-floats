% ------------------------------------------------------------------------------
% Lecture des élévations (et des positions associées) dans un fichier STRM30.
%
% SYNTAX :
%   function [o_elev, o_lon , o_lat] = ...
%      get_srtm_data(a_fileNumber, a_lonMin, a_lonMax, a_latMin, a_latMax)
%
% INPUT PARAMETERS :
%   a_fileNumber : numéro du fichier SRTM concerné
%   a_lonMin     : longitude minimale de la zone concernée
%   a_lonMax     : longitude maximale de la zone concernée
%   a_latMin     : latitude minimale de la zone concernée
%   a_latMax     : latitude maximale de la zone concernée
%
% OUTPUT PARAMETERS :
%   o_elev : élévations collectées
%   o_lon  : longitudes des élévations collectées
%   o_lat  : latitudes des élévations collectées
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   20/11/2008 - RNU - creation
% ------------------------------------------------------------------------------
function [o_elev, o_lon , o_lat] = ...
   get_srtm_data(a_fileNumber, a_lonMin, a_lonMax, a_latMin, a_latMax)

global g_elevDef;

% initialisation des valeurs par défaut
init_valdef;

o_elev = [];
o_lon = [];
o_lat = [];

% fichiers binaires relatifs aux données des différentes tuiles
fileName{1} = 'w180n90';
fileName{2} = 'w140n90';
fileName{3} = 'w100n90';
fileName{4} = 'w060n90';
fileName{5} = 'w020n90';
fileName{6} = 'e020n90';
fileName{7} = 'e060n90';
fileName{8} = 'e100n90';
fileName{9} = 'e140n90';
fileName{10} = 'w180n40';
fileName{11} = 'w140n40';
fileName{12} = 'w100n40';
fileName{13} = 'w060n40';
fileName{14} = 'w020n40';
fileName{15} = 'e020n40';
fileName{16} = 'e060n40';
fileName{17} = 'e100n40';
fileName{18} = 'e140n40';
fileName{19} = 'w180s10';
fileName{20} = 'w140s10';
fileName{21} = 'w100s10';
fileName{22} = 'w060s10';
fileName{23} = 'w020s10';
fileName{24} = 'e020s10';
fileName{25} = 'e060s10';
fileName{26} = 'e100s10';
fileName{27} = 'e140s10';
fileName{28} = 'w180s60';
fileName{29} = 'w120s60';
fileName{30} = 'w060s60';
fileName{31} = 'w000s60';
fileName{32} = 'e060s60';
fileName{33} = 'e120s60';
currentFileName  = fileName{a_fileNumber};

% chemin d'accès au fichier demandé
srtmDirName = 'C:\Users\jprannou\_RNU\_ressources\SRTM30+\data/';
srtmFileName = [srtmDirName '/' currentFileName '.Bathymetry.srtm'];

% ouverture du fichier (big-endian format)
fId = fopen(srtmFileName, 'r', 'b');
if (fId == -1)
   fprintf('Erreur ouverture fichier : %s\n', srtmFileName);
   return
end

% nombre de points par ligne du fichier
nbPtsLine = 4800;
if (a_fileNumber > 27)
   nbPtsLine = 7200;
end

% coordonnées du premier point du fichier
factLon = 1;
if (currentFileName(1) == 'w')
   factLon = -1;
end
ficLonMin = str2num(currentFileName(2:4))*factLon;

factLat = 1;
if (currentFileName(5) == 's')
   factLat = -1;
end
ficLatMax = str2num(currentFileName(6:7))*factLat;

% lecture des données dans le fichier demandé
nbLon = round((a_lonMax-a_lonMin)*120+1);
nbLat = round((a_latMax-a_latMin)*120+1);
elev = ones(nbLat, nbLon)*g_elevDef;

idStart = round((ficLatMax-a_latMax)*120*nbPtsLine + (a_lonMin-ficLonMin)*120);
for id = 1:nbLat
   fseek(fId, (idStart+(id-1)*nbPtsLine)*2, 'bof');
   elev(id, :) = fread(fId, [1 nbLon], 'int16');
end

lon = [round(a_lonMin*120):round(a_lonMax*120)]/120;
lat = [round(a_latMax*120):-1:round(a_latMin*120)]/120;

o_elev = elev;
o_lon = lon;
o_lat = lat;

fclose(fId);

return
