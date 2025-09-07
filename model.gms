
$ontext
* Descriptive section about the analysis

*************** India's Hybrid Solar-Wind-BESS Project Analysis ******************
********************************* February 2022 *************************************
Description: This analysis aims to evaluate the financial viability and market potential of various energy 
storage options in India, including Battery Energy Storage Systems (BESS), Pumped Storage Hydro Plants (PSP), 
and Run-of-the-River (ROR) hydro schemes. The study leverages an optimization model to assess energy arbitrage 
opportunities, revenue from ancillary services, and risk hedging strategies, considering critical drivers 
such as price variability and hydrological risks. It compares the economic performance of notional unit MWs 
of each storage option using historical spot prices and other publicly available data, to understand their 
relative merits and support for integrating variable renewable energy (VRE) into India's grid. 
$offtext

* Set options for the GAMS solver to handle large-scale problems efficiently
* Resource limit - maximum allowed resources (e.g., memory)
Option RESLIM=1000000000;      
* Iteration limit - maximum allowed solver iterations
Option ITERLIM=100000000;      
* Solution print - disable printing of solution reports to reduce clutter
Option Solprint=off;   
* System output - disable printing of system output for cleaner logs        
Option Sysout=off;     

* Configuration flags
*$SET GDX_ONLY 0               * Flag to control GDX output only mode
*$SET READ_PREVIOUS_DATA 1     * Flag to enable reading data from previous runs
*$SET FOLDER MainResults       * Specify the folder to store main results

* Disable inline comments to avoid conflicts with data definitions
$inlinecom { }

***************************************************************************************************************
***************************************** SETS INITIALIZATION *************************************************
***************************************************************************************************************


* Define sets used in the model for various dimensions like time, generators, etc.
Sets
y                       Dispatch years
m                       Dispatch months
d                       Days within the dispatch period
n                       Time periods within a day for dispatch
g                       Generators included in the analysis
z                       Zones or regions within the country
f                       Types of fuels used by generators
tc                      Different energy technologies
hy                      Hydrology data for historical analysis
* Set of renewable energy sources considered
RE_SET /PV, WIND/       

* Scalars and parameters defining various economic and technical aspects of the project
ScalarsSet           /VOLL, Duration, PricePPA, PPAshare, Bcapex, BCpxRed, FCAS, MaxBESS, BESSDuration, ROR, PSP, BuyPrice/
GenDataSet           /Capacity, Type, Fuel, HeatRate, VOM, FOM, RampUpRate, RampDnRate, PricePPA, Duration, Efficiency, WACC, FCAS, CAPEX, PPAShare, Lifetime/

* Define mappings and other sets necessary for calculations
zprices
zpricesmap(z,zprices)          Map zones to their corresponding price data
mainset(y,m,d,n,z)             Main set combining all dimensions for the analysis
* Define a set for years, allowing for up to 50 years in future analysis
yy /1*50/                      
;

SINGLETON SET
    sFirstYear(y)          First year in the simulation period,
    sFinalYear(y)          Last year in the simulation period;

Parameter 
    pDays(m)               Days in a month for time-series analysis;

* For zones, enabling inter-zone comparisons or mappings,
alias(z,z2); 
* For time periods within a day, aiding in temporal analysis,
alias(n,n2);                 
* For year comparisons or sequences in multi-year analyses;
alias(y,y2);                

***************************************************************************************************************
***************************************** PARAMETERS INITIALIZATION *******************************************
***************************************************************************************************************


* General Parameters
Parameters
    pScalars(ScalarsSet)   Needed scalar values for the model,
    pZoneIndex(z)          Zone index read from zone data to identify different zones
    pDurationIndex         Time series duration index {1=Hourly 2=30-min 4=15-min}
    pWeight                Weight based on time series duration for calculations

* Generator Specific Parameters
    pGenData(g,GenDataSet) Generator data including capacit type fuel etc
    pTechIndex(tc)         Index for generation technologies mapping them to attributes

* Market Parameters
    pSpotPriceBidZones(m,d,n,y,zprices) Spot price per period for bidding zones
    pSpotPrice(m,d,n,y,z)  Spot price per period crucial for market analysis
    pHydroAF(m,d,n,y,z)    Hydro availability factor per period influences generation potential

* Fuel and Demand Parameters
    pFuelIndex(f)          Fuel Index categorizes fuels for generators,

* Renewables and Storage Parameters
    pREProfile(m,d,n,RE_SET,z) RE generation profile by site normalized per MW capacity
    pHydroData(hy,m)       Hydro generation potential for months based on historical data
    pHyProb(hy)            Probability of hydrology scenarios affects generation from hydro sources

* Economic Parameters
    pVOLL                  Value of lost load
    pPPAshare              Minimum share of total generation committed to PPA agreements
    pBESSCapex             BESS capex in Rs per MW initial cost for battery storage systems
    pBCpxRed               BESS capex reduction per unit reflects cost improvements over time
    pFCASprice             Ancillary services price in Rs per MWh for services like frequency control
    pMaxBESSCap            Maximum size of BESS in MWh dictates storage capacity limits
    pPPAprice(g)           PPA price in Rs per MWh agreed price for power purchase agreements;

***************************************************************************************************************
***************************************** IMPORTING FROM EXCEL ************************************************
***************************************************************************************************************

* Prepare the GDXXRW tool command file to specify the data ranges in the Excel file to import into GAMS.
$onecho > gdxxrwCM1.in
set=y                   Rdim=1            rng=SetDefinitions!A6:A1000 
set=m                   Rdim=1            rng=SetDefinitions!B6:B1000 
set=d                   Rdim=1            rng=SetDefinitions!C6:C1000 
set=n                   Rdim=1            rng=SetDefinitions!E6:E1000 
set=g                   Rdim=1            rng=GenData!A6:A1000 
set=hy                  Rdim=1            rng=SetDefinitions!F6:F1000 
set=z                   Rdim=1            rng=ZoneFuelTech!A6:A1000 
set=f                   Rdim=1            rng=ZoneFuelTech!E6:E1000 
set=tc                  Rdim=1            rng=ZoneFuelTech!I6:I1000 
par=pZoneIndex          Rdim=1            rng=ZoneFuelTech!A6:B100 
par=pFuelIndex          Rdim=1            rng=ZoneFuelTech!E6:F100 
par=pTechIndex          Rdim=1            rng=ZoneFuelTech!I6:J100 
par=pHyProb             Rdim=1            rng=ZoneFuelTech!L6:M100 
par=pGenData            Rdim=1 Cdim=1     rng=GenData!A5:AZ9000
set=zprices             Rdim=1            rng=ZoneFuelTech!O6:O1000    Values=NoData
set=zpricesmap          Rdim=2            rng=ZoneFuelTech!R6:S1000    Values=NoData
*par=pHydroData          Rdim=1 Cdim=1     rng=HydroData!A3:ZZ30000
par=pREProfile          Rdim=3 Cdim=2     rng=REProfile!A5:ZZ30000
par=pSpotPriceBidZones  Rdim=3 Cdim=2     rng=SpotPrice!A5:ZZ30000
par=pHydroAF            Rdim=3 Cdim=2     rng=HydroAF!A5:ZZ30000
$offecho

* Execute GDXXRW command if GDX_ONLY is not set to import data from the specified Excel file into GDX format.
$if not set GDX_ONLY $Call GDXXRW Input_India_Model_SP.xlsx @gdxxrwCM1.in
* Load the imported data into GAMS for use in the model.
$GDXIN Input_India_Model_SP.gdx
$LOAD y m d n g hy z f tc pZoneIndex pFuelIndex pTechIndex pHyProb pGenData zprices
$LOAD zpricesmap pREProfile pSpotPriceBidZones pHydroAF
$GDXIN

***************************************************************************************************************
***************************************** RECALCULATIONS BASED ON INPUTS **************************************
***************************************************************************************************************

* Calculate the spot price from the mapped zones and bidding zones
pSpotPrice(m,d,n,y,z) = sum(zprices$(zpricesmap(z,zprices)), pSpotPriceBidZones(m,d,n,y,zprices));

* Define main set for analysis based on availability of spot price data
mainset(y,m,d,n,z) = YES$(pSpotPrice(m,d,n,y,z));

* Include additional GAMS file if INC_NUM is set
$if set INC_NUM $include inc_file%INC_NUM%.inc

* Define sets for different generator types and iteration sets
Sets
    wi(g)                        Wind power generators,
    so(g)                        Solar power generators,
    st(g)                        Storage units,
    hg(g)                        Hydro power units,
    z_iter(z)                    Zones iteration set,
    y_iter(y)                    Years iteration set,
    g_iter(g)                    Generators iteration set,
    m_iter(m)                    Months iteration set;

* Classification of generators based on their types
* Solar generators
so(g) = YES$(pGenData(g,"Type") = 1); 
* Wind generators
wi(g) = YES$(pGenData(g,"Type") = 2); 
* Storage units
st(g) = YES$((pGenData(g,"Type") = 3) OR (pGenData(g,"Type") = 4) OR (pGenData(g,"Type") = 5) OR (pGenData(g,"Type") = 6)); 
* Hydro generators
hg(g) = YES$(pGenData(g,"Type") = 7); 

* Set scalar values from the pScalars parameter
pDurationIndex = 1;

* Calculate weight based on the duration index
pWeight = (1/pDurationIndex);

* Mark the first and last years for analysis
sFirstYear(y) = y.first;
sFinalYear(y) = y.last;

* Calculate price index and contract price based on spot prices
Parameter PriceIndex(y,z), ContractPrice(g,y,z);
PriceIndex(y,z) = (sum((m,d,n), pSpotPrice(m,d,n,y,z))/(8760)) / (sum((m,d,n), pSpotPrice(m,d,n,sFinalYear,z))/(8760));
ContractPrice(g,y,z) = PriceIndex(y,z)*pGenData(g,"PricePPA");


* Calculate the number of days in each month based on available spot price data
pDays(m) = sum(d$(sum((n,y,z),pSpotPrice(m,d,n,y,z))), 1);

***************************************************************************************************************
***************************************** EQUATIONS AND VARIABLES *********************************************
***************************************************************************************************************

* Variable declarations for model analysis
Variable
    vNetRev                  Estimated revenue for selling and buying in the IEX market;
* Declaration of positive variables representing various power outputs and capacities
Positive Variables
    vPwrOut(z,g,m,d,n,y,hy)  Generators output in MW - contract plus spot,
    vPwrSpot(z,g,m,d,n,y,hy) Generators output in MW - Spot,
    vPwrContract(z,g,m,n,y,hy) Contracted power output,
    vBatteryCap(y)           Battery capacity installed in MWh [differentiated for each year],
    vBStorage(z,g,m,d,n,y,hy) Battery Storage level (MWh),
    vBStorInj(z,g,m,d,n,y,hy) Battery Storage injection (MW),
    vMonthContract(z,g,m)    Total MWh volume per month that should be on contract for all price years priced at PPA,
    vBStorBuild(y)           Build Storage capacity variable (MW),
    vFCAS(z,g,m,d,n,y,hy)    FCAS provision from hydro,
    vSpotBuy(z,g,m,d,n,y,hy) Power purchased from the spot market;

* Binary variables to model on/off decisions
Binary Variables
    vBin(z,g,m,d,n,y,hy);

* Parameter for average PPA price across different zones
Parameter pPPPAveragePrice(g,z);
pPPPAveragePrice(g,z) = 0;

* Equations to model the system constraints and objective function
Equations
    eObj                               Objective function,
    eFCAS(z,g,m,d,n,y,hy)              Joint FCAS and energy constraint,
    eFCASStorage(z,g,m,d,n,y,hy)       FCAS constraint for units with storage
    eWindProfile(z,g,m,d,n,y,hy)       Generation from wind farms,
    eSolarProfile(z,g,m,d,n,y,hy)      Generation from solar PV,
    eBStorBal(z,g,m,d,n,y,hy)          Battery storage balance for hours > 1,
    eBStorBal1(z,g,m,d,n,y,hy)         Battery storage balance for hour 1 of each day,
    eBStorBal2(z,g,m,d,n,y,hy)         Battery storage balance adjustment for the first hour of simulation,
    eBStorageCap(z,g,m,d,n,y,hy)       Battery storage energy limit throughout the simulation,
    eBStorageCap1(z,g,m,d,n,y,hy)      Battery storage capacity limit ensuring it does not exceed installed capacity,
    ePwrOutCap(z,g,m,d,n,y,hy)         Limit on the total power output
    eRampDownInjLimit(z,g,m,d,n,y,hy)  Ramp-down limits for power injections to ensure grid stability,
    eRampUpInjLimit(z,g,m,d,n,y,hy)    Ramp-up limits for power injections to meet sudden demand surges,
    eBalance(z,g,m,d,n,y,hy)           Power balance equation to ensure supply meets demand in every period,
*    eHydroEnergy(z,g,m,y,hy)           Monthly hydro energy limit ensuring hydro generation stays within water availability,
*    eHydroEnergyDaily(z,g,m,d,y,hy)    Daily hydro energy limit for more granular water usage management,
    eMinMonthContract(z,g,m,y,hy)      Ensures a minimum volume of electricity is contracted monthly reflecting PPA commitments,
    eMinPPAShare(z,g,m,y,hy)           Guarantees a minimum share of generation is sold through PPAs as per contracts;

***************************************************************************************************************
***************************** INITIAL LIMITS AND CALCULATIONS *************************************************
***************************************************************************************************************

* Define auxiliary parameters for annual, monthly hours, and number of years of analysis
Parameter
    AnnualNumberOfHours(z,y)     Total hours available annually per zone,
    MonthlyNumberOfHours(z,m,y)  Total hours available monthly per zone,
    NumberOfYears(z)             Total years of simulation per zone;

* Calculation of annual, monthly hours, and number of simulation years
AnnualNumberOfHours(z,y) = sum((m,d,n)$pSpotPrice(m,d,n,y,z), 1);
MonthlyNumberOfHours(z,m,y) = sum((d,n)$pSpotPrice(m,d,n,y,z), 1);
NumberOfYears(z) = sum(y$(sum((m,d,n),pSpotPrice(m,d,n,y,z))), 1);


* Fix FCAS provision to 0 for solar (Type 1) and wind (Type 2) generators as they typically do not provide FCAS.
vFCAS.fx(z,g,m,d,n,y,hy)$(pGenData(g,"Type") = 1) = 0; 
vFCAS.fx(z,g,m,d,n,y,hy)$(pGenData(g,"Type") = 2) = 0;

* Commented out constraints - possibly for future use or scenarios where battery storage constraints are considered.
*vBStorage.fx(z,g,m,d,n,y)=0;
*vBStorInj.fx(z,g,m,d,n,y)=0;

* Commented out constraint - for scenarios considering upper limits on battery capacity.
*vBatteryCap.up(y,hy)=0;

* Set upper limits on power output variables to generator capacities, ensuring they do not exceed their maximum potential.
vPwrOut.UP(z,g,m,d,n,y,hy)       =  pGenData(g,"Capacity");
vPwrSpot.UP(z,g,m,d,n,y,hy)      =  pGenData(g,"Capacity");
vPwrContract.UP(z,g,m,n,y,hy)    =  pGenData(g,"Capacity");

* For periods not within the main analysis set, fix power outputs and FCAS provisions to 0, ensuring no activity outside the scope of the analysis.
vPwrOut.UP(z,g,m,d,n,y,hy)$(NOT mainset(y,m,d,n,z)) = 0;
vPwrSpot.UP(z,g,m,d,n,y,hy)$(NOT mainset(y,m,d,n,z)) = 0;
vFCAS.fx(z,g,m,d,n,y,hy)$(NOT mainset(y,m,d,n,z)) = 0;

* Specifically fix battery storage injections to 0 for periods not in the main analysis set, and for certain storage types.
vBStorInj.fx(z,g,m,d,n,y,hy)$(NOT mainset(y,m,d,n,z)) = 0;
vBStorInj.fx(z,g,m,d,n,y,hy)$((pGenData(g,"Type") = 5) OR (pGenData(g,"Type") = 6)) = 0;

* Ensure the hydro availability factor (HydroAF) is set to 0 for periods outside the main analysis set to avoid unrealistic hydro generation forecasting.
pHydroAF(m,d,n,y,z) $(NOT mainset(y,m,d,n,z)) = 0;


***************************************************************************************************************
**************************************** MODEL DEFINITION *****************************************************
***************************************************************************************************************

* Define the objective function to maximize net revenue from selling electricity in the market, accounting for the costs associated with battery storage injections and the revenue from fixed contracts.
eObj..
     vNetRev =e= 
     (Sum(hy, pHyProb(hy)*
        (Sum((z_iter,g_iter,m_iter,d,n,y_iter)$(mainset(y_iter,m_iter,d,n,z_iter)), 
            vPwrSpot(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pSpotPrice(m_iter,d,n,y_iter,z_iter)*pWeight) 
        - Sum((z_iter,g_iter,m_iter,d,n,y_iter)$(mainset(y_iter,m_iter,d,n,z_iter)),
            vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pSpotPrice(m_iter,d,n,y_iter,z_iter)*pWeight)))
     + Sum((z_iter,g_iter,m_iter,y_iter), 
        vMonthContract(z_iter,g_iter,m_iter)*pPPPAveragePrice(g_iter,z_iter))
     + Sum(hy, pHyProb(hy)*
        (Sum((z_iter,g_iter,m_iter,d,n,y_iter),  
            vFCAS(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pGenData(g_iter,"FCAS"))))*pWeight
    )/1e6;

* Enforce that the combined output for energy and FCAS does not exceed the generator's capacity.
eFCAS(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy) + vFCAS(z_iter,g_iter,m_iter,d,n,y_iter,hy) =l= pGenData(g_iter,"Capacity")*(1-vBin(z_iter,g_iter,m_iter,d,n,y_iter,hy));

* Limit the FCAS provision to the available battery storage level.
eFCASStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vFCAS(z_iter,g_iter,m_iter,d,n,y_iter,hy) =l= vBStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy);

* Define generation profiles for wind and solar based on capacity and renewable energy profiles.
eWindProfile(z_iter,wi,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vPwrOut(z_iter,wi,m_iter,d,n,y_iter,hy) =e= pGenData(wi,"Capacity")*pREProfile(m_iter,d,n,'WIND',z_iter);

eSolarProfile(z_iter,so,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vPwrOut(z_iter,so,m_iter,d,n,y_iter,hy) =e= pGenData(so,"Capacity")*pREProfile(m_iter,d,n,"PV",z_iter);

* Manage battery storage balance, accounting for efficiency, injections, and hydro availability for certain storage types.
eBStorBal(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(ord(n)>1 AND mainset(y_iter,m_iter,d,n,z_iter)).. 
    vBStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy) =e= 
    vBStorage(z_iter,g_iter,m_iter,d,n-1,y_iter,hy) + pGenData(g_iter,"efficiency")*vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy) - 
    vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy) + (pGenData(g_iter,"Capacity")*pHydroAF(m_iter,d,n,y_iter,z_iter))$((pGenData(g_iter,"Type") = 5) OR (pGenData(g_iter,"Type") = 6));

* Special battery storage balance constraints for the start of the simulation and subsequent days.
eBStorBal1(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(ord(n)=1 and ord(d)=1 AND mainset(y_iter,m_iter,d,n,z_iter)).. 
    vBStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy) =e= 
    pGenData(g_iter,"efficiency")*vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy) - 
    vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy) + (pGenData(g_iter,"Capacity")*pHydroAF(m_iter,d,n,y_iter,z_iter))$((pGenData(g_iter,"Type") = 5) OR (pGenData(g_iter,"Type") = 6));

eBStorBal2(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(ord(n)=1 and ord(d)>1 AND mainset(y_iter,m_iter,d,n,z_iter))..
    VBStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy) =e= pGenData(g_iter,"efficiency")*vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy) 
    - vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy) + sum(n2$(ord(n2)=card(n)),vBStorage(z_iter,g_iter,m_iter,d-1,n2,y_iter,hy)) 
    + (pGenData(g_iter,"Capacity")*pHydroAF(m_iter,d,n,y_iter,z_iter))$((pGenData(g_iter,"Type") = 5) OR (pGenData(g_iter,"Type") = 6));

* Constraints to ensure battery storage does not exceed its energy capacity and respects injection limitations.
eBStorageCap(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vBStorage(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pWeight =l= pGenData(g_iter,"Capacity")*pGenData(g_iter,"Duration");

eBStorageCap1(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pWeight =l= pGenData(g_iter,"Capacity")*vBin(z_iter,g_iter,m_iter,d,n,y_iter,hy);

* Additional battery capacity constraints, possibly to enforce specific operational scenarios or technical limits.
ePwrOutCap(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy) =l= pGenData(g_iter,"Capacity");

* Ramp down and up injection limits for batteries to model physical ramping capabilities and constraints.
eRampDownInjLimit(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(ord(n)>1 AND mainset(y_iter,m_iter,d,n,z_iter))..
    vBStorInj(z_iter,g_iter,m_iter,d,n-1,y_iter,hy) - vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy) =l= pGenData(g_iter,'RampDnRate')*pGenData(g_iter,'Capacity');

eRampUpInjLimit(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(ord(n)>1 AND mainset(y_iter,m_iter,d,n,z_iter))..
    vBStorInj(z_iter,g_iter,m_iter,d,n,y_iter,hy) - vBStorInj(z_iter,g_iter,m_iter,d,n-1,y_iter,hy) =l= pGenData(g_iter,'RampUpRate')*pGenData(g_iter,'Capacity');

* Ensure the balance of power production, including both spot market sales and contracted volumes, adheres to capacity limits.
eBalance(z_iter,g_iter,m_iter,d,n,y_iter,hy)$(mainset(y_iter,m_iter,d,n,z_iter))..
    vPwrSpot(z_iter,g_iter,m_iter,d,n,y_iter,hy) + vPwrContract(z_iter,g_iter,m_iter,n,y_iter,hy) =e= vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy);


* Enforce minimum monthly contracted volumes and PPA share obligations, ensuring compliance with contractual agreements and regulatory requirements.
eMinMonthContract(z_iter,g_iter,m_iter,y_iter,hy)..
    vMonthContract(z_iter,g_iter,m_iter) =l= Sum((d,n)$(mainset(y_iter,m_iter,d,n,z_iter)), vPwrContract(z_iter,g_iter,m_iter,n,y_iter,hy)*pWeight);

eMinPPAShare(z_iter,g_iter,m_iter,y_iter,hy)$(pGenData(g_iter,'PPAShare'))..
    vMonthContract(z_iter,g_iter,m_iter) =G= Sum((d,n)$(mainset(y_iter,m_iter,d,n,z_iter)), vPwrOut(z_iter,g_iter,m_iter,d,n,y_iter,hy)*pWeight)*pGenData(g_iter,'PPAShare');

* UNUSED CONSTRAINTS

*eTotalPower(m_iter,y_iter,hy).. Sum((g_iter,d,n),vPwrOut(g_iter,m_iter,d,n,y_iter,hy)*pWeight) =e= Sum(g_iter,vMonthContract(g_iter,m_iter,y_iter)) + Sum((g_iter,d,n),vPwrSpot(g_iter,m_iter,d,n,y_iter,hy)*pWeight)

* Hydro power generation is constrained by the monthly and daily hydro energy potential, reflecting water availability and hydrological conditions.
* eHydroEnergy(z_iter,hg,m_iter,y_iter,hy)$(pHydroData(hy,m_iter))..
*     Sum((d,n)$(mainset(y_iter,m_iter,d,n,z_iter)), vPwrOut(z_iter,hg,m_iter,d,n,y_iter,hy)*pWeight) =l= pHydroData(hy,m_iter)*1000;

* eHydroEnergyDaily(z_iter,hg,m_iter,d,y_iter,hy)$(pHydroData(hy,m_iter))..
*     Sum((n)$(mainset(y_iter,m_iter,d,n,z_iter)), vPwrOut(z_iter,hg,m_iter,d,n,y_iter,hy)*pWeight) =l= pHydroData(hy,m_iter)*1000*1.30/pDays(m_iter);


***************************************************************************************************************
**************************************** SOLVER CONFIGURATION *************************************************
***************************************************************************************************************

* Define the model and specify all equations and variables included in the model.
Model HybridProject /all/;

* Set option file for the solver and adjust solver output settings

* Use the first option file..
Hybridproject.optfile=1;

* Moderate level of solution printing.
Hybridproject.solprint=2;

* Parameter declarations for storing various types of results from the model solution.
Parameter
    Profit(z,g,m,d,n,y,hy)           Revenue minus costs for each scenario,
    StorLevel(z,g,m,d,n,y,hy)        Battery storage level at each time period,
    StorInjection(z,g,m,d,n,y,hy)    Power injected into the grid from storage,
    Generation(z,g,m,d,n,y,hy)       Power generation by each generator type,
    FCASdual(m,d,n,y,hy)             Dual values associated with FCAS constraints,
    FCASPrice(m,d,n,y,hy)            Prices associated with FCAS provision,
    HourlyRev(*,z,g,m,d,n,y,hy)      Hourly revenue for each generator,
    AnnualRev(*,z,g,y,hy)            Annual revenue for each generator,
    AnnualNetRev(*,z,g,y)            Net annual revenue after costs,
    TotalAnnualRevenue(z,g,y)        Total annual revenue for each generator,
    TotalAnnualCost(z,g,y)           Total annual costs for each generator,
    TotalAnnualProfit(z,g,y)         Total annual profit for each generator,
    SpotSupply(z,g,m,d,n,y,hy)       Power supplied to the spot market,
    ContractSupply(z,g,m,n,y,hy)     Power supplied under contract,
    FCASSupply(z,g,m,d,n,y,hy)       Power supplied for FCAS,
    SpotBuy(z,g,m,d,n,y,hy)          Power purchased from the spot market,
    Status(*,z,y)                    Model and solver status indicators,
    CRF(g)                           Capital recovery factor for each generator,
    Totals(*,z,g,y)                  Total values for various metrics,
    MonthlyRev(*,z,g,m,y)            Monthly revenue for each generator,
    MonthlyGen(*,z,g,m,y)            Monthly generation amounts

* Parameters for annual and monthly analysis.
    AnnualParameters(*,*,*,z,g,y)
    MonthlyParameters(*,*,*,z,g,y,m)

* Financial metrics to be calculated based on the model results.
    IRR(z)       Internal rate of return for each zone.
    FV(z,g,yy)   Future value of investments.
;


* CPLEX solver options customized through an option file.
*$onecho > cplex.opt 
*startalg 4  
*scaind  1  
*lpmethod 4  
*threads 8
*mipstart 1
*$offEcho 


***************************************************************************************************************
**************************************** MODEL EXECUTION LOOP *************************************************
***************************************************************************************************************

* Nested loops to iterate over generators, zones, and months to calculate average PPA prices and solve the model.
* Looping over months, zones, and generator types significantly reduces computational complexity and speeds up solution time. 

loop(g,
    loop(z,
        loop(m,
* Activate only years with positive spot price sum to calculate average PPA price.
            y_iter(y) = YES$((sum((d,n),pSpotPrice(m,d,n,y,z))>0));
            z_iter(z) = YES;
            g_iter(g) = YES;
            m_iter(m) = YES;
            pPPPAveragePrice(g,z) = sum(y2$(y_iter(y2)), ContractPrice(g,y2,z))/card(y_iter);

* Set the optimality criterion for the solver.
            Option  Optcr = 0.02;

* Set the maximum allowed solution time.
            option reslim=2000;

* Solve the HybridProject model as a Mixed Integer Program (MIP) to maximize net revenue.
            Solve HybridProject using MIP max vNetRev;

* Store the solution results in parameters for further analysis.
            StorLevel(z,g,m,d,n,y,hy)      = vBStorage.l(z,g,m,d,n,y,hy);
            StorInjection(z,g,m,d,n,y,hy)  = vBStorInj.l(z,g,m,d,n,y,hy);
            Generation(z,g,m,d,n,y,hy)     = vPwrOut.l(z,g,m,d,n,y,hy);
            SpotSupply(z,g,m,d,n,y,hy)     = vPwrSpot.L(z,g,m,d,n,y,hy);
            ContractSupply(z,g,m,n,y,hy)   = vPwrContract.L(z,g,m,n,y,hy);
            FCASSupply(z,g,m,d,n,y,hy)     = vFCAS.L(z,g,m,d,n,y,hy);

* Reset iteration flags after each loop cycle.
            y_iter(y) = NO;
            z_iter(z) = NO;
            g_iter(g) = NO;
            m_iter(m) = NO;

* Record the model and solver statuses to monitor solution outcomes.
            Status('Model',z,y) = HybridProject.Modelstat;
            Status('Solver',z,y) = HybridProject.solvestat;
        );
    );
);

***************************************************************************************************************
**************************************** RESULTS PROCESSING AND EXPORT ****************************************
***************************************************************************************************************

* Calculate the hourly revenue from various activities: energy sales, FCAS provision, and PPA contracts. 
HourlyRev('Energy',z,g,m,d,n,y,hy)$(mainset(y,m,d,n,z)) = SpotSupply(z,g,m,d,n,y,hy)*pSpotPrice(m,d,n,y,z) - StorInjection(z,g,m,d,n,y,hy)*pSpotPrice(m,d,n,y,z);
HourlyRev('FCAS',z,g,m,d,n,y,hy)$(mainset(y,m,d,n,z)) = FCASSupply(z,g,m,d,n,y,hy)*pGenData(g,"FCAS");
HourlyRev('PPA',z,g,m,d,n,y,hy)$(mainset(y,m,d,n,z)) = pPPPAveragePrice(g,z)*ContractSupply(z,g,m,n,y,hy);

* Aggregate revenue over different time frames and sources for detailed financial analysis.
AnnualRev('Energy',z,g,y,hy) = sum((m,d,n), HourlyRev('Energy',z,g,m,d,n,y,hy));
AnnualRev('FCAS',z,g,y,hy) = sum((m,d,n), HourlyRev('FCAS',z,g,m,d,n,y,hy));
AnnualRev('PPA',z,g,y,hy) = sum((m,d,n), HourlyRev('PPA',z,g,m,d,n,y,hy));

* Monthly revenues from energy sales, FCAS provision, and PPAs provide insight into temporal financial performance.
MonthlyRev('Energy',z,g,m,y) = sum((d,n), Sum(hy, HourlyRev('Energy',z,g,m,d,n,y,hy)));
MonthlyRev('FCAS',z,g,m,y) = sum((d,n), Sum(hy, HourlyRev('FCAS',z,g,m,d,n,y,hy)));
MonthlyRev('PPA',z,g,m,y) = sum((d,n), Sum(hy, HourlyRev('PPA',z,g,m,d,n,y,hy)));

* Generation metrics by month give an operational overview, essential for system planning and efficiency evaluation.
MonthlyGen('Spot supply',z,g,m,y) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)));
MonthlyGen('FCAS supply',z,g,m,y) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)));
MonthlyGen('Contract supply',z,g,m,y) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)));
MonthlyGen('Storage injection',z,g,m,y) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * StorInjection(z,g,m,d,n,y,hy) * pGenData(g,"efficiency")));

* The Capital Recovery Factor (CRF) helps in assessing the feasibility and sustainability of capital investments in generators.
CRF(g) = (pGenData(g, "WACC") / (1 - (1 / ((1 + pGenData(g,"WACC")) ** pGenData(g,'Lifetime')))));

* Total annual revenues, costs, and profits provide a snapshot of the project's financial health and profitability.
TotalAnnualRevenue(z,g,y) = Sum(hy, pHyProb(hy) * (AnnualRev('Energy',z,g,y,hy) + AnnualRev('FCAS',z,g,y,hy) + AnnualRev('PPA',z,g,y,hy)));
TotalAnnualCost(z,g,y) = (pGenData(g,"CAPEX") * CRF(g) + pGenData(g,"FOM")) * pGenData(g,"Capacity") + sum(hy, pHyProb(hy) * sum((m,d,n)$(mainset(y,m,d,n,z)), Generation(z,g,m,d,n,y,hy) * pGenData(g,"VOM")));
TotalAnnualProfit(z,g,y) = TotalAnnualRevenue(z,g,y) - TotalAnnualCost(z,g,y);

* Net revenues from energy, FCAS, and PPAs after accounting for costs offer insights into specific revenue streams.
AnnualNetRev('Energy',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Energy',z,g,y,hy));
AnnualNetRev('FCAS',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('FCAS',z,g,y,hy));
AnnualNetRev('PPA',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('PPA',z,g,y,hy));
AnnualNetRev('Buy spot',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Buy spot',z,g,y,hy));
AnnualNetRev('Cost',z,g,y) = TotalAnnualCost(z,g,y); 

* Detailed parameters for annual financial and operational reporting, allowing for comprehensive analysis and decision support.
AnnualParameters('Profits and costs','Revenue','INR',z,g,y) = TotalAnnualRevenue(z,g,y);
AnnualParameters('Profits and costs','Revenue','million INR',z,g,y) = TotalAnnualRevenue(z,g,y)/1000000;
AnnualParameters('Profits and costs','Cost','INR',z,g,y) = TotalAnnualCost(z,g,y);
AnnualParameters('Profits and costs','Cost','million INR',z,g,y) = TotalAnnualCost(z,g,y)/1000000;
AnnualParameters('Profits and costs','Profit','INR',z,g,y) = TotalAnnualProfit(z,g,y);
AnnualParameters('Profits and costs','Profit','million INR',z,g,y) = TotalAnnualProfit(z,g,y)/1000000;

* Capturing supply metrics to evaluate the operational performance of storage, FCAS provision, and contractual obligations.
AnnualParameters('Supply','Storage injection','MWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * pGenData(g,"efficiency") * StorInjection(z,g,m,d,n,y,hy)));
AnnualParameters('Supply','Storage injection','GWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * pGenData(g,"efficiency") * StorInjection(z,g,m,d,n,y,hy)))/1000;
AnnualParameters('Supply','FCAS supply','MWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)));
AnnualParameters('Supply','FCAS supply','GWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)))/1000;
AnnualParameters('Supply','Spot supply','MWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)));
AnnualParameters('Supply','Spot supply','GWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)))/1000;
AnnualParameters('Supply','Contract supply','MWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)));
AnnualParameters('Supply','Contract supply','GWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)))/1000;
AnnualParameters('Supply','Total generation','MWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * Generation(z,g,m,d,n,y,hy)));
AnnualParameters('Supply','Total generation','GWh',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * Generation(z,g,m,d,n,y,hy)))/1000;

* Revenue metrics, both at the granular and aggregated level, highlight financial performance 
AnnualParameters('Revenue','Energy','INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Energy',z,g,y,hy));
AnnualParameters('Revenue','Energy','million INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Energy',z,g,y,hy))/1000000;
AnnualParameters('Revenue','FCAS','INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('FCAS',z,g,y,hy));
AnnualParameters('Revenue','FCAS','million INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('FCAS',z,g,y,hy))/1000000;
AnnualParameters('Revenue','PPA','INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('PPA',z,g,y,hy));
AnnualParameters('Revenue','PPA','million INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('PPA',z,g,y,hy))/1000000;
AnnualParameters('Revenue','Buy spot','INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Buy spot',z,g,y,hy));
AnnualParameters('Revenue','Buy spot','million INR',z,g,y) = Sum(hy, pHyProb(hy) * AnnualRev('Buy spot',z,g,y,hy))/1000000;
AnnualParameters('Revenue','Cost','INR',z,g,y) = TotalAnnualCost(z,g,y);
AnnualParameters('Revenue','Cost','million INR',z,g,y) = TotalAnnualCost(z,g,y)/1000000;

* Evaluating the average revenue per generated unit offers insights into the profitability 
AnnualParameters('Revenue','Average revenue per generation','INR/MWh',z,g,y) = 
    Sum(hy, pHyProb(hy) * (AnnualRev('Energy',z,g,y,hy) + AnnualRev('FCAS',z,g,y,hy) + AnnualRev('PPA',z,g,y,hy) + AnnualRev('Buy spot',z,g,y,hy))) / 
    sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * Generation(z,g,m,d,n,y,hy)));
AnnualParameters('Revenue','Average revenue per generation','INR/kWh',z,g,y) = 
    (Sum(hy, pHyProb(hy) * (AnnualRev('Energy',z,g,y,hy) + AnnualRev('FCAS',z,g,y,hy) + AnnualRev('PPA',z,g,y,hy) + AnnualRev('Buy spot',z,g,y,hy))) / 
    sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * Generation(z,g,m,d,n,y,hy)))/1000);

* Average annual spot price and capacity factor (CF) are critical for assessing market conditions and operational performance.
AnnualParameters('Average Annual','Spot Price','INR/MWh',z,g,y) = 
    sum((m,d,n)$(mainset(y,m,d,n,z)), pSpotPrice(m,d,n,y,z)) / AnnualNumberOfHours(z,y);
AnnualParameters('Average Annual','Spot Price','INR/kWh',z,g,y) = 
    (sum((m,d,n)$(mainset(y,m,d,n,z)), pSpotPrice(m,d,n,y,z)) / AnnualNumberOfHours(z,y))/1000;

AnnualParameters('Average Annual','CF','%',z,g,y) = 
    (sum((m,d,n)$(mainset(y,m,d,n,z)), pHydroAF(m,d,n,y,z)) / AnnualNumberOfHours(z,y)) * 100;

* Monthly revenue and supply metrics offer a closer look at the financial and operational dynamics over shorter time frames.
MonthlyParameters('Revenue','Energy','INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('Energy',z,g,m,d,n,y,hy)));
MonthlyParameters('Revenue','Energy','million INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('Energy',z,g,m,d,n,y,hy)))/1000000;
MonthlyParameters('Revenue','FCAS','INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('FCAS',z,g,m,d,n,y,hy)));
MonthlyParameters('Revenue','FCAS','million INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('FCAS',z,g,m,d,n,y,hy)))/1000000;
MonthlyParameters('Revenue','PPA','INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('PPA',z,g,m,d,n,y,hy)));
MonthlyParameters('Revenue','PPA','million INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('PPA',z,g,m,d,n,y,hy)))/1000000;
MonthlyParameters('Revenue','Buy spot','INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('Buy spot',z,g,m,d,n,y,hy)));
MonthlyParameters('Revenue','Buy spot','million INR',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, HourlyRev('Buy spot',z,g,m,d,n,y,hy)))/1000000;

* Monthly supply metrics detail the physical operations, providing a comprehensive view of generation and storage behavior.
MonthlyParameters('Supply','Spot supply','MWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)));
MonthlyParameters('Supply','Spot supply','GWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)))/1000;
MonthlyParameters('Supply','FCAS supply','MWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)));
MonthlyParameters('Supply','FCAS supply','GWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)))/1000;
MonthlyParameters('Supply','Contract supply','MWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)));
MonthlyParameters('Supply','Contract supply','GWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)))/1000;
MonthlyParameters('Supply','Storage injection','MWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * StorInjection(z,g,m,d,n,y,hy) * pGenData(g,"efficiency")));
MonthlyParameters('Supply','Storage injection','GWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * StorInjection(z,g,m,d,n,y,hy) * pGenData(g,"efficiency")))/1000;

* Capture average monthly spot prices and capacity factors (CF) to assess market conditions and operational efficiency.
MonthlyParameters('Average Monthly','Spot Price','INR/MWh',z,g,y,m) = sum((d,n)$(mainset(y,m,d,n,z)), pSpotPrice(m,d,n,y,z)) / MonthlyNumberOfHours(z,m,y); 
MonthlyParameters('Average Monthly','Spot Price','INR/kWh',z,g,y,m) = (sum((d,n)$(mainset(y,m,d,n,z)), pSpotPrice(m,d,n,y,z)) / MonthlyNumberOfHours(z,m,y))/1000; 
MonthlyParameters('Average Monthly','CF','%',z,g,y,m) = (sum((d,n)$(mainset(y,m,d,n,z)), pHydroAF(m,d,n,y,z)) / MonthlyNumberOfHours(z,m,y)) * 100; 

* Totals provide an aggregate view of financial and operational metrics, important for strategic decision-making.
Totals('Revenue',z,g,y) = TotalAnnualRevenue(z,g,y);
Totals('Cost',z,g,y) = TotalAnnualCost(z,g,y);
Totals('Profit',z,g,y) = TotalAnnualProfit(z,g,y);
Totals('Generation',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * Generation(z,g,m,d,n,y,hy)));
Totals('Storage injection',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * StorInjection(z,g,m,d,n,y,hy) * pGenData(g,"efficiency")));
Totals('FCAS supply',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * FCASSupply(z,g,m,d,n,y,hy)));
Totals('Spot supply',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * SpotSupply(z,g,m,d,n,y,hy)));
Totals('Contract supply',z,g,y) = sum((m,d,n)$(mainset(y,m,d,n,z)), Sum(hy, pHyProb(hy) * ContractSupply(z,g,m,n,y,hy)));

* Financial viability assessment through Future Value calculation considering revenues, operational costs, and initial capital expenditure.
FV(z,g,yy)$(ord(yy)>1) = sum(y$(mod(ord(yy)-2,card(y))+1=ord(y)), TotalAnnualRevenue(z,g,y) - pGenData(g,"FOM") * pGenData(g,"Capacity") - sum(hy, pHyProb(hy) * sum((m,d,n), Generation(z,g,m,d,n,y,hy)) * pGenData(g,"VOM")));
FV(z,g,yy)$(ord(yy)=1) = -(pGenData(g,"CAPEX")) * pGenData(g,"Capacity");
FV(z,g,yy)$(ord(yy) > pGenData(g,"Lifetime")+1) = 0;

* Data export to GDX for further analysis or reporting.
execute_unload 'FV.gdx' FV, AnnualParameters, pPPPAveragePrice, ContractPrice, vPwrOut, vBin, vPwrSpot, vPwrContract, vBStorage, vBStorInj, vMonthContract;

* Optional: Export additional model results and parameters for comprehensive analysis.
* execute_unload 'Results.gdx' pHydroAF, pSpotPrice, HourlyRev, AnnualRev, StorLevel, StorInjection, Generation, TotalAnnualRevenue, TotalAnnualCost, TotalAnnualProfit, Status, SpotSupply, ContractSupply, FCASSupply, SpotBuy, ContractPrice, Totals, AnnualNetRev, MonthlyRev, MonthlyGen, AnnualParameters, MonthlyParameters, FV;

execute_unload 'All.gdx' 

$exit



