% ------------------------------------------------------------------------------
% Print parameter message data in output CSV file.
%
% SYNTAX :
%  print_param_data_in_csv_30(a_tabParam)
%
% INPUT PARAMETERS :
%   a_tabParam : decoded parameter data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_param_data_in_csv_30(a_tabParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; PARAMETER MESSAGE CONTENTS\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC0: Total number of cycles; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(1));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC1: Number of cycle with “cycle period 1”; %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(2));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC2: Cycle period 1; %d; hours\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(3));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC3: Cycle period 2; %d; hours\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(4));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC4: Reference day; %d; internal day number\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(5));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC5: Estimated time at the surface; %d; hour in the day\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(6));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC6: Delay before mission; %d; minutes\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(7));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC7: Descent sampling period; %d; seconds\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(8));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC8: Drift sampling period; %d; hours\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(9));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC9: Ascent sampling period; %d; seconds\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(10));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC10: Drift depth for “MC1” first cycles; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(11));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC11: Profile depth for “MC1” first cycles; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(12));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC12: Drift depth after “MC1” cycles are done; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(13));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC13: Profile depth after “MC1” cycles are done; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(14));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC14: Threshold surface/intermediate pressure; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(15));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC15: Threshold intermediate/bottom pressure; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(16));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC16: Thickness of the surface slices; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(17));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC17: Thickness of the intermediate slices; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(18));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC18: Thickness of the bottom slices; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(19));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC21: Grounding mode (0: shift, 1: stay grounded); %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(22));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC22: Grouding switch pressure; %d; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(23));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Param; MC24: Optode type (0: none, 1: 4330, 2: 3830); %d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, a_tabParam(25));

return;
