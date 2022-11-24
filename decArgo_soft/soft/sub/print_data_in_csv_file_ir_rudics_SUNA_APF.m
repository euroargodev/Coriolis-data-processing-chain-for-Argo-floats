% ------------------------------------------------------------------------------
% Print SUNA (APF frame) sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_SUNA_APF( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataSUNAAPF, a_info)
%
% INPUT PARAMETERS :
%   a_cycleNum    : cycle number of the packet
%   a_profNum     : profile number of the packet
%   a_phaseNum    : phase number of the packet
%   a_dataSUNAAPF : SUNA (APF frame) data
%   a_info        : number of the APF frame
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_SUNA_APF( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataSUNAAPF, a_info)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;
global g_decArgo_concNitraCountsDef;


% unpack the input data
a_dataSUNAAPFDate = a_dataSUNAAPF{1};
a_dataSUNAAPFDateTrans = a_dataSUNAAPF{2};
a_dataSUNAAPFCTDPres = a_dataSUNAAPF{3};
a_dataSUNAAPFCTDTemp = a_dataSUNAAPF{4};
a_dataSUNAAPFCTDSal = a_dataSUNAAPF{5};
a_dataSUNAAPFIntTemp = a_dataSUNAAPF{6};
a_dataSUNAAPFSpecTemp = a_dataSUNAAPF{7};
a_dataSUNAAPFIntRelHumidity = a_dataSUNAAPF{8};
a_dataSUNAAPFDarkSpecMean = a_dataSUNAAPF{9};
a_dataSUNAAPFDarkSpecStd = a_dataSUNAAPF{10};
a_dataSUNAAPFSensorNitra = a_dataSUNAAPF{11};
a_dataSUNAAPFAbsFitRes = a_dataSUNAAPF{12};
a_dataSUNAAPFOutSpec = a_dataSUNAAPF{13};

% select the data (according to cycleNum, profNum and phaseNum)
idDataAPF = find((a_dataSUNAAPFDate(:, 1) == a_cycleNum) & ...
   (a_dataSUNAAPFDate(:, 2) == a_profNum) & ...
   (a_dataSUNAAPFDate(:, 3) == a_phaseNum));

if (isempty(idDataAPF))
   return;
end

fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; %s; Date; ' ...
   'PRES (dbar); TEMP (°C); PSAL (PSU); ' ...
   'TEMP_NITRATE (°C); TEMP_SPECTROPHOTOMETER_NITRATE (°C); HUMIDITY_NITRATE (percent); ' ...
   'UV_INTENSITY_DARK_NITRATE (count); UV_INTENSITY_DARK_NITRATE_STD(count); ' ...
   'MOLAR_NITRATE (micromole/l); FIT_ERROR_NITRATE (dimensionless); NITRATE (micromole/kg)'], ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), a_info);
fprintf(g_decArgo_outputCsvFileId, '; UV_INTENSITY_NITRATE_%d (count)', 1:45);
fprintf(g_decArgo_outputCsvFileId, '\n');

dataAPF = [];
for idL = 1:length(idDataAPF)
   dataAPF = [dataAPF; ...
      a_dataSUNAAPFDate(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFDateTrans(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFCTDPres(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFCTDTemp(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFCTDSal(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFIntTemp(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFSpecTemp(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFIntRelHumidity(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFDarkSpecMean(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFDarkSpecStd(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFSensorNitra(idDataAPF(idL), 4:end)' ...
      a_dataSUNAAPFAbsFitRes(idDataAPF(idL), 4:end)];
end

paramNITRATE = get_netcdf_param_attributes('NITRATE');
dataAPF(:, 13) = compute_profile_NITRATE_from_MOLAR_NI_105_to_109_111_121_122(dataAPF(:, 11), ...
   g_decArgo_concNitraCountsDef, paramNITRATE.fillValue, ...
   dataAPF(:, 3), dataAPF(:, 3:5), ...
   g_decArgo_concNitraCountsDef, ...
   g_decArgo_concNitraCountsDef, ...
   g_decArgo_concNitraCountsDef);

for idL = 1:size(dataAPF, 1)
   if (dataAPF(idL, 1) ~= g_decArgo_dateDef)
      if (dataAPF(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(double(dataAPF(idL, 1))) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(double(dataAPF(idL, 1))) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; %s; %s; %g; %g; %g; %g; %g; %g; %g; %g; %g; %g; %g', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), a_info, ...
         date, dataAPF(idL, 3:13));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; %s raw; ; %g; %g; %g; %g; %g; %g; %g; %g; %g; %g; %g', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), a_info, ...
         dataAPF(idL, 3:13));
   end
   dataOutSpec = a_dataSUNAAPFOutSpec(idDataAPF(idL), 4:end);
   fprintf(g_decArgo_outputCsvFileId, '; %d', ...
      dataOutSpec(1:45));
   fprintf(g_decArgo_outputCsvFileId, '\n');
end

return;
