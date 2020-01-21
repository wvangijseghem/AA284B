clear all, clc
filePath = 'C:\Users\tommc\Desktop\Stanford Courses\AA284B\CEA Run Directory';
fileName = 'Rocket284.inp';
fileName = strcat(filePath,'\',fileName);

% Mision Requirements

Th=100; % Initial thrust in lbf             INPUT
t1=10; % First burn time in sec             INPUT
t2=10; % Second burn time in sec            INPUT

Th=Th*4.4482; % Convert thrust to N

% Design Parameters

Pc=350; % Chamber pressure in psi           INPUT
PcSI=Pc*6894.76; % Convert Pc to Pa
Alt=10000; % Design altitude in ft          INPUT
Alt=Alt*0.3048; % Convert altitude to m

% Use atmospheric model to find atmospheric pressure at altitude
% Source: https://www.grc.nasa.gov/WWW/K-12/airplane/atmosmet.html
% Outputs atmospheric pressure in kPa
Pamb=0;
if Alt > 25000
    Tamb = -131.21+.00299*Alt;
    Pamb = 2.488*(((Tamb+273.1)/216.6)^-11.388);
end
if Alt > 11000 && Alt <= 25000
    Tamb = -56.46;
    Pamb = 22.65*exp(1.73-.000157*Alt);
end
if Alt <= 11000
    Tamb = 15.04-.00649*Alt;
    Pamb = 101.29*((Tamb+273.1)/288.08)^5.256;
end
Prat = PcSI/(1000*Pamb); % Chamber/Exit Pressure Ratio

OF_lower = 0.5; % Lower bound for O/F plot     INPUT
OF_upper = 9; % Upper bound for O/F plot       INPUT
OF = linspace(OF_lower,OF_upper,25);
for i=1:length(OF)
    OF(i)=round(OF(i),1);
end

oxOptions = {'Air' 'CL2' 'CL2(L)' 'F2' 'F2(L)' 'H2O2(L)' 'N2H4(L)' 'N2O' 'NH4NO3(I)' 'O2' 'O2(L)'};
oxidizerOption = 11; % Index of the oxidizer you want in the list above      INPUT
oxTemp = 90.17; % Temperature of the oxidizer  in K (has to be 90.17 for O2(L))    INPUT

fuelOptions = {'CH4','CH4(L)','H2','RP-1'};
fuelOption = 4; % Index of the fuel you want in the list above               INPUT
fuelTemp = 299; % Temperature of the fuel in K                               INPUT

% Write CEA input file
fileID=fopen(fileName,'wt');
fprintf(fileID,'prob case=_______________3885 ro equilibrium  ions\n\n');
fprintf(fileID,'p,psia= '); fprintf(fileID,num2str(Pc)); fprintf(fileID,'\n');
fprintf(fileID,'pi/p= '); fprintf(fileID,num2str(Prat)); fprintf(fileID,'\n\n');
fprintf(fileID,'o/f= ');
for i=1:length(OF)
    fprintf(fileID,'%.1f',OF(i)); fprintf(fileID,', ');
end
fprintf(fileID,'\n\n');
fprintf(fileID,'reac\n');
fprintf(fileID,'fuel '); fprintf(fileID,fuelOptions{fuelOption}); fprintf(fileID,'\t\twt%%=100.0000\t');
fprintf(fileID,'t,k= '); fprintf(fileID,num2str(fuelTemp)); fprintf(fileID,'\n');
fprintf(fileID,'oxid '); fprintf(fileID,oxOptions{oxidizerOption}); fprintf(fileID,'\t\twt%%=100.0000\t');
fprintf(fileID,'t,k= '); fprintf(fileID,num2str(oxTemp)); fprintf(fileID,'\n\n');
fprintf(fileID,'output short\n');
fprintf(fileID,'output massf\n');
fprintf(fileID,'output siunits\n');
fprintf(fileID,'output transport\n\n');
fprintf(fileID,'output plot isp cf pip mach ivac ae gam t\n\n\n');
fprintf(fileID,'end');
fclose(fileID); clear fileID


cont=0;
while cont==0
    usrIpt = input('Run CEA!!!!\nDid you run CEA? (y/n)\n','s');
    if usrIpt == 'y'
        cont=1;
    end
end

% Open CEA output file

fileName(end-3:end)='.out';
fileID=fopen(fileName);

% Set up data arrays
Arat=zeros(1,length(OF)); Acnt=0;  % Area Ratio
Cstar=zeros(1,length(OF)); Cscnt=0; % c*
Cf=zeros(1,length(OF)); Cfcnt=0; % Cf
Ivac=zeros(1,length(OF)); Ivcnt=0;
Isp=zeros(1,length(OF)); Iscnt=0; % Specific impulse (m/s)
Me=zeros(1,length(OF)); Mecnt=0; % Exit mach number
Pe=zeros(1,length(OF)); Pecnt=0; % Exit pressure in bar
Te=zeros(1,length(OF)); Tecnt=0; % Exit temperature
GamE=zeros(1,length(OF)); Gecnt=0; % Gamma at exit
MWe=zeros(1,length(OF)); MWecnt=0; % MW at exit
Rhoe=zeros(1,length(OF)); Rhocnt=0; % density at exit in kg/m3

% Read file and extract important data
stop=0;
while stop==0;
    line=fgetl(fileID);
    if length(line)==0
        continue
    end
    if length(line)>=6 && strcmp(line(2:6),'Ae/At')
        Acnt=Acnt+1;
        Arat(Acnt)=str2double(line(end-7:end));
    end
    if length(line)>=6 && strcmp(line(2:6),'CSTAR')
        Cscnt=Cscnt+1;
        Cstar(Cscnt)=str2double(line(end-7:end));
    end
    if length(line)>=6 && strcmp(line(2:3),'CF')
        Cfcnt=Cfcnt+1;
        Cf(Cfcnt)=str2double(line(end-7:end));
    end
    if length(line)>=6 && strcmp(line(2:5),'Ivac')
        Ivcnt=Ivcnt+1;
        Ivac(Ivcnt)=str2double(line(end-7:end));
    end
    if length(line)>=6 && strcmp(line(2:4),'Isp')
        Iscnt=Iscnt+1;
        Isp(Iscnt)=str2double(line(end-7:end));
    end
    if length(line)>=7 && strcmp(line(2:7),'P, BAR')
        Pecnt=Pecnt+1;
        Pe(Pecnt)=str2double(line(end-7:end));
    end
    if length(line)>=7 && strcmp(line(2:5),'T, K')
        Tecnt=Tecnt+1;
        Te(Tecnt)=str2double(line(end-7:end));
    end
    if length(line)>=12 && strcmp(line(2:12),'MACH NUMBER')
        Mecnt=Mecnt+1;
        Me(Mecnt)=str2double(line(end-7:end));
    end
    if length(line)>=7 && strcmp(line(2:7),'GAMMAs')
        Gecnt=Gecnt+1;
        GamE(Gecnt)=str2double(line(end-7:end));
    end
    if length(line)>=11 && strcmp(line(2:11),'MW, MOL WT')
        MWecnt=MWecnt+1;
        MWe(MWecnt)=str2double(line(end-7:end));
    end
    if length(line)>=13 && strcmp(line(2:13),'RHO, KG/CU M')
        Rhocnt=Rhocnt+1;
        if line(end-1)=='-'
            line=[line(end-8:end-2),'e',line(end-1:end)];
        end
        Rhoe(Rhocnt)=str2double(line);
    end
    if line==-1
        stop=1;
    end
end
Isp=Isp/9.81; % Include gravitational acceleration to make Isp in units of sec
Pe=Pe*100000; % Convert exit pressure output from Bar to Pa

% figure
% plot(OF,Arat)
% title('Area Ratio vs. O/F')
% 
% figure
% plot(OF,Cstar)
% title('c* vs. O/F')
% 
% figure
% plot(OF,Cf)
% title('Cf vs. O/F')
% 
% figure
% plot(OF,Ivac)
% title('Ivac vs. O/F')
% 
% figure
% plot(OF,Isp)
% title('Isp vs. O/F')
% 
% figure
% plot(OF,Pe)
% title('Pe vs. O/F')
% 
% figure
% plot(OF,Te)
% title('Te vs. O/F')
% 
% figure
% plot(OF,GamE)
% title('GamE vs. O/F')
% 
% figure
% plot(OF,Me)
% title('Me vs. O/F')
% 
% figure
% plot(OF,MWe)
% title('MWe vs. O/F')
% 
% figure
% plot(OF,Rhoe)
% title('Rhoe vs. O/F')


fclose(fileID); clear fileID

[maxIsp,idx]=max(Isp); % Find maximum Isp and its index in list
optArat=Arat(idx); % Find Ae/At corresponding to max Isp
exitT = Te(idx);
exitP = Pe(idx);
exitM = Me(idx);
exitGam = GamE(idx);
exitMW = MWe(idx); % MW at exit (WARNING THIS MIGHT BE WRONG)
exitRho = Rhoe(idx);

Rexit=8314/exitMW; % Calculate gas constant at exit
ae = sqrt(exitGam*Rexit*exitT); % Speed of sound at exit
ve = ae*exitM; % Velocity at exit
mdot=Th/(maxIsp*9.81); % total mass flow in kg/sec

Ae = mdot/(exitRho*ve); % exit area of nozzle in m2
At = Ae/optArat; % throat are in m2

NozEdia = sqrt(4*Ae/pi)*100; % nozzle exit diameter in cm
NozTdia = sqrt(4*At/pi)*100; % nozzle throat diameter in cm

massP = mdot*(t1+t2); % total mass propellent needed

massOx = massP/(1+1/OF(idx)); % total oxidizer mass kg
mdotOx = mdot/(1+1/OF(idx)); % oxidizer mass flow kg/sec
massFuel = massP/(OF(idx)+1); % total fuel mass kg
mdotFuel = mdot/(OF(idx)+1); % fuel mass flow kg/sec

% Display Results

fprintf('\n\nInputs: \n');
fprintf('Fuel: '); fprintf(fuelOptions{fuelOption}); fprintf('\n');
fprintf('Oxidizer: '); fprintf(oxOptions{oxidizerOption}); fprintf('\n');
fprintf('Thrust (N): '); fprintf(num2str(Th)); fprintf('\n');
fprintf('Altitude (m): '); fprintf(num2str(Alt)); fprintf('\n');
fprintf('Chamber pressure (psi): '); fprintf(num2str(Pc)); fprintf('\n');
fprintf('First burn duration (sec): '); fprintf(num2str(t1)); fprintf('\n');
fprintf('Second burn duration (sec): '); fprintf(num2str(t2)); fprintf('\n');

fprintf('\n\nOutputs: \n');
fprintf('Isp (sec): '); fprintf(num2str(maxIsp)); fprintf('\n');
fprintf('Ae/At: '); fprintf(num2str(optArat)); fprintf('\n');
fprintf('Nozzle throat diameter (cm): '); fprintf(num2str(NozTdia)); fprintf('\n');
fprintf('Nozzle exit diameter (cm): '); fprintf(num2str(NozEdia)); fprintf('\n');
fprintf('Total mass flow (kg/sec): '); fprintf(num2str(mdot)); fprintf('\n');
fprintf('O/F ratio: '); fprintf(num2str(OF(idx))); fprintf('\n');
fprintf('Oxidizer mass flow (kg/sec): '); fprintf(num2str(mdotOx)); fprintf('\n');
fprintf('Fuel mass flow (kg/sec): '); fprintf(num2str(mdotFuel)); fprintf('\n');
fprintf('Total oxidizer mass (kg): '); fprintf(num2str(massOx)); fprintf('\n');
fprintf('Total fuel mass (kg): '); fprintf(num2str(massFuel)); fprintf('\n');

















































