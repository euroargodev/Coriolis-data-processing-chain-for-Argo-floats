% ------------------------------------------------------------------------------
% Check if Provor or Arvor hydraulic type is consistent with decoder Id.
%
% SYNTAX :
%  check_provor_arvor_hydraulic_type(a_hydraulicType, a_decoderId, a_floatNum)
%
% INPUT PARAMETERS :
%   a_hydraulicType : float hydraulic type (0: Arvor, 1:Provor)
%   a_decoderId     : decoder id used
%   a_floatNum      : float number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function check_provor_arvor_hydraulic_type(a_hydraulicType, a_decoderId, a_floatNum)

% Provor/Arvor hydraulic type check flag
global g_decArgo_provorArvorHydraulicTypeCheckFlag;


decIdListProvorWithHydraulicTypeInfo = [213, 214, 225];
decIdListArvorWithHydraulicTypeInfo = [210:212, 217, 222:224];

if ((ismember(a_decoderId, decIdListProvorWithHydraulicTypeInfo) && (a_hydraulicType == 0)) || ...
      (ismember(a_decoderId, decIdListArvorWithHydraulicTypeInfo) && (a_hydraulicType == 1)))
   
   if (ismember(a_decoderId, decIdListProvorWithHydraulicTypeInfo))
      fprintf('ERROR: Float #%d: Float decoder (#%d) is for a Provor but ''Hydraulic type'' reported by the float concerns an Arvor\n', ...
      a_floatNum, a_decoderId);
   else
      fprintf('ERROR: Float #%d: Float decoder (#%d) is for an Arvor but ''Hydraulic type'' reported by the float concerns a Provor\n', ...
      a_floatNum, a_decoderId);
   end
else
   g_decArgo_provorArvorHydraulicTypeCheckFlag = 1;
end

return
