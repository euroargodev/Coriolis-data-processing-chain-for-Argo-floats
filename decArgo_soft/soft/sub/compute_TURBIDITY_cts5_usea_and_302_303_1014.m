% ------------------------------------------------------------------------------
% Compute TURBIDITY from SIDE_SCATTERING_TURBIDITY provided by the FLNTU sensor.
%
% SYNTAX :
%  [o_TURBIDITY] = compute_TURBIDITY_cts5_usea_and_302_303_1014(a_SIDE_SCATTERING_TURBIDITY, ...
%    a_SIDE_SCATTERING_TURBIDITY_fill_value, a_TURBIDITY_fill_value)
%
% INPUT PARAMETERS :
%   a_SIDE_SCATTERING_TURBIDITY            : input SIDE_SCATTERING_TURBIDITY data
%   a_SIDE_SCATTERING_TURBIDITY_fill_value : fill value for input
%                                            SIDE_SCATTERING_TURBIDITY data
%   a_TURBIDITY_fill_value                 : fill value for output TURBIDITY data
%
% OUTPUT PARAMETERS :
%   o_TURBIDITY : output TURBIDITY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_TURBIDITY] = compute_TURBIDITY_cts5_usea_and_302_303_1014(a_SIDE_SCATTERING_TURBIDITY, ...
   a_SIDE_SCATTERING_TURBIDITY_fill_value, a_TURBIDITY_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% output parameters initialization
o_TURBIDITY = ones(length(a_SIDE_SCATTERING_TURBIDITY), 1)*a_TURBIDITY_fill_value;


if (ismember('FLNTU', g_decArgo_sensorMountedOnFloat))

   % FLNTU sensor

   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'FLNTU'))
      fprintf('WARNING: Float #%d Cycle #%d: FLNTU sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif ((isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactTurbi')) && ...
         (isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountTurbi')))
      scaleFactTurbi = double(g_decArgo_calibInfo.FLNTU.ScaleFactTurbi);
      darkCountTurbi = double(g_decArgo_calibInfo.FLNTU.DarkCountTurbi);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent FLNTU sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

elseif (ismember('ECO_FLNTU', g_decArgo_sensorMountedOnFloat))

   % ECO_FLNTU sensor

   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'ECO_FLNTU'))
      fprintf('WARNING: Float #%d Cycle #%d: ECO_FLNTU sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif ((isfield(g_decArgo_calibInfo.ECO_FLNTU, 'ScaleFactTurbi')) && ...
         (isfield(g_decArgo_calibInfo.ECO_FLNTU, 'DarkCountTurbi')))
      scaleFactTurbi = double(g_decArgo_calibInfo.ECO_FLNTU.ScaleFactTurbi);
      darkCountTurbi = double(g_decArgo_calibInfo.ECO_FLNTU.DarkCountTurbi);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent ECO_FLNTU sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

end

% compute output data
idNoDef = find(a_SIDE_SCATTERING_TURBIDITY ~= a_SIDE_SCATTERING_TURBIDITY_fill_value);
o_TURBIDITY(idNoDef) = (a_SIDE_SCATTERING_TURBIDITY(idNoDef) - darkCountTurbi)*scaleFactTurbi;

return
