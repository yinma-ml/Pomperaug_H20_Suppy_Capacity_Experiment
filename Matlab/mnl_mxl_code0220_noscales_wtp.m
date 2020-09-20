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

EstimOpt.fnameinput = ('twcc2020new.mat');
DATA = load(EstimOpt.fnameinput);


%% ****************************  data transformations  ****************************
%not necessary in this project
%% ****************************  model specification  ****************************


%***********asc+attribute only
DATA.Y = DATA.chosen;
DATA.Xa = [DATA.alt==1, ...
    DATA.nzone1, DATA.nzone2, DATA.nzone3,DATA.towndown,DATA.townmid, DATA.townup, DATA.eco,DATA.rec,DATA.dry,...    %attributes
   -DATA.tax/10];  %rescaled cost attributes
EstimOpt.NamesA = {'ASC SQ', ...    
   'Zone_sensitive', 'Zone_ordinary','Zone_resilient',...
    'Shift_down','Shift_mid','Shift_up',...
    'Ecological score', 'Recreation score','Dry river miles',...
    '- Extra $10 tax/household/month'};
%DATA.Xs = [DATA.T1,DATA.ascend,DATA.descend,DATA.block1]; %scale covariates
%EstimOpt.NamesS = {'Treatment_1','Ascending','Descending','Block_1'};

%EstimOpt.ProjectName = '02202020_noscale_pref';
EstimOpt.ProjectName = '02202020_noscale_wtp';

%***************asc+attribute, scale covariates, partial
%DATA.Y = DATA.chosen;
% DATA.Xa = [DATA.alt==1, DATA.incpp_50k, DATA.incpp_75k, DATA.incpp_75km, ... %covariates
%     DATA.nzone1, DATA.nzone2, DATA.nzone3,DATA.towndown,DATA.townmid, DATA.townup, DATA.eco,DATA.rec,DATA.dry,...    %attributes
%   -DATA.tax];  %cost attributes
%EstimOpt.NamesA = {'ASC SQ', 'Income/pp25~50k','Income/pp50~75k', 'Income/pp>75k', ...    
%     'Zone_sensitive', 'Zone_ordinary','Zone_resilient',...
%     'Shift_down','Shift_mid','Shift_up',...
%     'Ecological score', 'Recreation score','Dry river miles',...
%     '- Extra tax/household/month'};
%DATA.Xs = [DATA.T1,DATA.ascend,DATA.descend,DATA.block1]; %scale covariates
%EstimOpt.NamesS = {'Treatment_1','Ascending','Descending','Block_1'};

%EstimOpt.ProjectName = '02182020_covar';

%***************asc+attribute, scale covariates, all
%DATA.Y = DATA.chosen;
%DATA.Xa = [DATA.alt==1, DATA.incpp_50k, DATA.incpp_75k, DATA.incpp_75km,DATA.f1_flow, DATA.f3_protup, DATA.f4_CTh2O,DATA.taxgrt,  ... %covariates
%    DATA.nzone1, DATA.nzone2, DATA.nzone3,DATA.towndown,DATA.townmid, DATA.townup, DATA.eco,DATA.rec,DATA.dry,...    %attributes
%   -DATA.tax];  %cost attributes
% EstimOpt.NamesA = {'AllSQ', 'Income/pp25~50k','Income/pp50~75k', 'Income/pp>75k','F1_flow','F3_protect upstream','F4_CT has enough H2O','Tax usage is guaranteed', ...    
%    'Zone_sensitive', 'Zone_ordinary','Zone_resilient',...
%    'Shift_down','Shift_mid','Shift_up',...
%    'Ecological score', 'Recreation score','Dry river miles',...
%    '- Extra tax/household/month'};
%DATA.Xs = [DATA.T1,DATA.ascend,DATA.descend,DATA.block1]; %scale covariates
%EstimOpt.NamesS = {'Treatment_1','Ascending','Descending','Block_1'};

%EstimOpt.ProjectName = '02182020_covar_1';
%% ****************************  specifying input ****************************

    
INPUT.Y = DATA.Y;
INPUT.Xa = DATA.Xa;
%INPUT.Xs = DATA.Xs;


%% ****************************  sample characteristics ****************************


EstimOpt.NCT = 8; % Number of choice tasks per person 
EstimOpt.NAlt = 3; % Number of alternatives
EstimOpt.NP = length(INPUT.Y)/EstimOpt.NCT/EstimOpt.NAlt; % numel(unique(DATA.nr))

%% **************************** estimation and optimization options ****************************

[INPUT, Results, EstimOpt, OptimOpt] = DataCleanDCE(INPUT,EstimOpt);

% INPUT.Xa(INPUT.MissingInd==1,:) = [];
% INPUT.Y(INPUT.MissingInd==1,:) = [];
% mean(INPUT.Xa)

% INPUT.MissingInd(any(isnan(DATA.Xa))) = 1;

EstimOpt.NRep = 1e4; % number of draws for numerical simulation



%% **************************** MNL ****************************

EstimOpt.WTP_space = 1;

% OptimOpt.Algorithm = 'trust-region'; % advised to use this one other than 'quasi-newton' (dce demo2015);
% OptimOpt.Hessian = 'user-supplied'; % 'off'



Results.MNL = MNL(INPUT,Results,EstimOpt,OptimOpt);

%method for caculating se: Standard errors can be calculated as the square root of the diagonal of the inverse of the Hessian 
%(square matrix of second-order partial derivatives of a function).
%fmincon.m returns the numerically calculated Hessian (HES)

%% **************************** MXL_d ****************************


EstimOpt.WTP_space = 1;
% EstimOpt.Dist = [zeros(size(INPUT.Xa,2)-1,1); 1];
% 
 OptimOpt.Algorithm = 'trust-region'; % 'quasi-newton';
 OptimOpt.Hessian = 'user-supplied'; % 'off'

 Results.MXL_d = MXL(INPUT,Results,EstimOpt,OptimOpt);
 
%around 10 min to run this model with full variables in preference space
%%by default, coeff of tax is lognormally distributed, 
%suppose that the reported coeff and sd are b and s, then the
%mean=exp(b+(s^2)/2), and population variance=exp(2b+s^2)(exp(s^2)-1)
% 
%% ************************** MXL *******************************
% 

EstimOpt.WTP_space = 1;
 EstimOpt.FullCov = 1;
% 
 OptimOpt.Algorithm = 'trust-region'; % 'quasi-newton';
 OptimOpt.Hessian = 'user-supplied'; % 'off'
% 
 Results.MXL = MXL(INPUT,Results,EstimOpt,OptimOpt);
%it took 4 hours 12 minutes to run this model with full variables in preference space
