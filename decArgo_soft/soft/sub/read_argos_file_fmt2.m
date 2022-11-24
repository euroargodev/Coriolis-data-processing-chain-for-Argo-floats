% ------------------------------------------------------------------------------
% Read format #2 Argos file.
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataDate, o_argosDataData] = read_argos_file_fmt2(a_fileName, a_frameLength)
%
% INPUT PARAMETERS :
%   a_fileName     : format #2 Argos file name
%   a_frameLength  : Argos data frame length
%
% OUTPUT PARAMETERS :
%   o_argosLocDate  : Argos location dates
%   o_argosLocLon   : Argos location longitudes
%   o_argosLocLat   : Argos location latitudes
%   o_argosLocAcc   : Argos location classes
%   o_argosLocSat   : Argos location satellite names
%   o_argosDataDate : Argos message dates
%   o_argosDataData : Argos message data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataDate, o_argosDataData] = read_argos_file_fmt2(a_fileName, a_frameLength)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_argosDataDate = [];
o_argosDataData = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef
global g_decArgo_argosLatDef;


if ~(exist(a_fileName, 'file') == 2)
   fprintf('ERROR: Argos file not found: %s\n', a_fileName);
   return
end

fId = fopen(a_fileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening Argos file: %s\n', a_fileName);
   return
end

% read the Argos file
dataArgos = textscan(fId, '%u %u %u %u %u %u %u %f %f %u %u %c %c %u %s');

year = dataArgos{2}(:);
month = dataArgos{3}(:);
day = dataArgos{4}(:);
hour = dataArgos{5}(:);
minute = dataArgos{6}(:);
second = dataArgos{7}(:);
argosLat = dataArgos{8}(:);
argosLon = dataArgos{9}(:);
argosOcc = dataArgos{10}(:);
argosSat = dataArgos{12}(:);
argosAcc = dataArgos{13}(:);
argosdata = dataArgos{15}(:);

fclose(fId);

% store the Argos locations
idLoc = find((argosLat ~= g_decArgo_argosLatDef) & (argosLon ~= g_decArgo_argosLonDef));

nbLoc = length(idLoc);
o_argosLocDate = ones(nbLoc, 1)*g_decArgo_dateDef;
o_argosLocAcc = [];
o_argosLocSat = [];
for idL = 1:nbLoc
   id = idLoc(idL);
   o_argosLocDate(idL) = gregorian_2_julian_dec_argo( ...
      sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
      year(id), month(id), day(id), ...
      hour(id), minute(id), second(id)));
   o_argosLocAcc = [o_argosLocAcc argosAcc(id)];
   o_argosLocSat = [o_argosLocSat argosSat(id)];
end

o_argosLocLon = argosLon(idLoc);
id = find(o_argosLocLon >= 180);
o_argosLocLon(id) = o_argosLocLon(id) - 360;

o_argosLocLat = argosLat(idLoc);         
         
% store the data
idData = setdiff([1:size(argosdata, 1)], idLoc);

nbData = length(idData);
o_argosDataDate = ones(nbData, 1)*g_decArgo_dateDef;
nbBytes = length(char(argosdata(1, :)))/2;
o_argosDataData = zeros(nbData, nbBytes);
for idD = 1:nbData
   id = idData(idD);
   o_argosDataDate(idD) = gregorian_2_julian_dec_argo( ...
      sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
      year(id), month(id), day(id), ...
      hour(id), minute(id), second(id)));
   dataHex = sscanf(char(argosdata(id, :)), '%2x');
   o_argosDataData(idD, :) = dataHex';
end
o_argosDataData(:, a_frameLength+1:end) = [];

% duplicate data according to redundancy coefficient
idDataMulti = find(argosOcc(idData) ~= 1);
if (~isempty(idDataMulti))
   for idD = 1:length(idDataMulti);
      occCoef = argosOcc(idData(idDataMulti(idD)));
      for id = 1:occCoef-1
         o_argosDataDate(end+1) = o_argosDataDate(idDataMulti(idD));
         o_argosDataData(end+1, :) = o_argosDataData(idDataMulti(idD), :);
      end
   end
   [o_argosDataDate, idSort] = sort(o_argosDataDate);
   o_argosDataData = o_argosDataData(idSort, :);
end

return
