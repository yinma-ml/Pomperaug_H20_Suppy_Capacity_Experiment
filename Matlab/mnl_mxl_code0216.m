%2020 twcc analysis, using 0623data_agree_02162020modified.dta, convert to
%xls, then convert to mat:  %save twcc2020.mat

%based on czh 2019 recycling paper #3, 2019-06-15, czaj.org
% The script requires:
% https://github.com/czaj/dce
% https://github.com/czaj/tools

clear all
clc

global B_backup; % this one is for storing B in case iterations are interrupted with ctrl-c


%% ****************************  loading data  ****************************

%need to load data each time(seems the original code doesn't work)
load('twcc2020.mat')

EstimOpt.fnameinput = ('twcc2020.mat');
DATA = load(EstimOpt.fnameinput);


%% ****************************  data transformations  ****************************
%not necessary in this project
%% ****************************  model specification  ****************************
DATA.Y = DATA.chosen;

DATA.Xa = [DATA.sq_all, DATA.incpp_50k, DATA.incpp_75k, DATA.incpp_75km, DATA.f1_flow, DATA.f3_protup, DATA.f4_CTh2O, DATA.taxgrt, ... %covariates
    DATA.nzone1, DATA.nzone2, DATA.nzone3,DATA.towndown,DATA.townmid, DATA.townup, DATA.eco,DATA.rec,DATA.dry,...    %attributes
   -DATA.tax];  %cost attributes
 EstimOpt.NamesA = {'AllSQ', 'Income/pp25~50k','Income/pp50~75k', 'Income/pp>75k','F1_flow','F3_protect upstream','F4_CT has enough H2O','Tax usage is guaranteed', ...    
    'Zone_sensitive', 'Zone_ordinary','Zone_resilient',...
    'Shift_down','Shift_mid','Shift_up',...
    'Ecological score', 'Recreation score','Dry river miles',...
    '- Extra tax/household/month'};

%scale covariates
DATA.Xs = [DATA.T1,DATA.ascend,DATA.descend,DATA.block1];
EstimOpt.NamesS = {'Treatment_1','Ascending','Descending','Block_1'};


EstimOpt.ProjectName = 'mnl_scale0216';


%% ****************************  specifying input ****************************

    
INPUT.Y = DATA.Y;
INPUT.Xa = DATA.Xa;
INPUT.Xs = DATA.Xs;


%% ****************************  sample characteristics ****************************


EstimOpt.NCT = 8; % Number of choice tasks per person 
EstimOpt.NAlt = 3; % Number of alternatives
EstimOpt.NP = length(INPUT.Y)/EstimOpt.NCT/EstimOpt.NAlt; % numel(unique(DATA.nr))

%% **************************** estimation and optimization options ****************************

[INPUT, Results, EstimOpt, OptimOpt] = DataCleanDCE(INPUT,EstimOpt);

EstimOpt.NRep = 1e4; % number of draws for numerical simulation




%% **************************** MNL ****************************
%basic mnl, no scale
%provide starting values for the MNL model
%Results.MNL.b0 = [-0.0601;-0.0223;-0.0277;-0.0473;0.2342;0.2027;0.061;0.0088;-0.1588;-0.0215];

Results.MNL = MNL(INPUT,Results,EstimOpt,OptimOpt);

%EstimOpt.WTP_space = 1;
%EstimOpt.NumGrad = 1;%numerical gradient
OptimOpt.Algorithm = 'trust-region'; % advised to use this one other than 'quasi-newton' (dce demo2015);
OptimOpt.Hessian = 'user-supplied'; % 'off'


% provide starting values for the MNL model
Results.MNL.b0 = [-127.4712;6.2289;1.7817;2.232;-1.6209;-0.868;0.5357;1.3945;-0.0601;-0.0223;-0.0277;-0.0473;0.2342;0.2027;0.061;0.0088;-0.1588;-0.0215;-0.0353;0.1139;0.0141;0];

Results.MNL = MNL(INPUT,Results,EstimOpt,OptimOpt);



%% **************************** MXL_d ****************************


EstimOpt.Dist = [zeros(size(INPUT.Xa,2)-1,1); 1];

OptimOpt.Algorithm = 'trust-region'; % 'quasi-newton';
OptimOpt.Hessian = 'user-supplied'; % 'off'

Results.MXL_d = MXL(INPUT,Results,EstimOpt,OptimOpt);



%% ************************** MXL *******************************


EstimOpt.FullCov = 1;

OptimOpt.Algorithm = 'trust-region'; % 'quasi-newton';
OptimOpt.Hessian = 'user-supplied'; % 'off'

Results.MXL = MXL(INPUT,Results,EstimOpt,OptimOpt);

