% ------------------------------------------------------------------------------
% Print grounding data in output CSV file.
%
% SYNTAX :
%  print_grounding_data_in_csv_file_ir_rudics( ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_grounding)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_grounding            : float grounding data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_grounding_data_in_csv_file_ir_rudics( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_grounding)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% unpack the input data
o_groundingDate = a_grounding{1};
o_groundingPres = a_grounding{2};
o_groundingSetPoint = a_grounding{3};
o_groundingIntVacuum = a_grounding{4};

% packet type 247
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (length(cycleList) > 1)
   fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the grounding data SBD files\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

% index list of the data
typeDataList = find(a_cyProfPhaseList(:, 1) == 247);
dataIndexList = [];
for id = 1:length(a_cyProfPhaseIndexList)
   dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(id))];
end

% print the grounding data
cycleProfPhaseList = unique(dataCyProfPhaseList(:, 3:5), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   idPack = find((o_groundingDate(dataIndexList, 1) == cycleNum) & ...
      (o_groundingDate(dataIndexList, 2) == profNum) & ...
      (o_groundingDate(dataIndexList, 3) == phaseNum));
   
   if (~isempty(idPack))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; grounding data; Date; Pres (dbar); Set point (dbar); Int vacuum (mbar)\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(phaseNum));
      
      for id = 1:length(idPack)
         idP = dataIndexList(idPack(id));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; grounding data; %s; %d; %d; %d\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(phaseNum), ...
            julian_2_gregorian_dec_argo(o_groundingDate(idP, 4)), o_groundingPres(idP, 4), o_groundingSetPoint(idP, 4), o_groundingIntVacuum(idP, 4));
      end
   end
end

return
