// ALL UNITS IN MILS (1/1000in)

// How high off the base of the container the PCB should sit
standheight = 250;
// The PCB/joysticks accept an M2 screw
// https://www.engineersedge.com/hardware/metric-external-thread-sizes1.htm
screwhole=75;
// The distance from the base of the joystick to the rounded top (NOT the stick itself)
joyheight = 175;
// The positions of the joysticks as placed in the PCB CAD
joypositions = [ [400,-800], [1400, -500], [2400, -800], [3400, -1900] ];
// How much space to leave between the walls of the container and the PCB
boxbuffer = 10;
// Where the USB port is positioned according to the PCB CAD
usbplace = 3400;
// How thick to make the walls of the container
wallsize=50;
// How many extra stands to print (for help with soldering the PCB)
extrastands = 4;
// The path to the DXF file (if rendering the PCB - do not enable this during the final render)
dxf_file = undef; // "drill_map.dxf"
// Calculations for the size of the PCB, taken from the PCB CAD
pcbsize = [3850,2350];
// 62mil is 1.6mm which is "standard" PCB thickness
pcbthickness = 62;

pcbposition = [boxbuffer,boxbuffer];
boxsize=pcbsize+[boxbuffer*2,boxbuffer*2];
boxheight = standheight+pcbthickness+joyheight;

$fn=64;

// The pcb itself, for reference (do not include in the final render)
module pcb(dxf_file) {
    scale(1000) {
        translate([-1,1,0]) {
            intersection() {
                translate([0,-3.36,-0.53]) cube(10);
                linear_extrude(height = pcbthickness/1000, convexity = 10) import(dxf_file);
            }
        }
    }
}

// A single stand for the PCB
module stand(diameter) {
    cylinder(standheight, 100, 100);
    cylinder(boxheight, diameter/2, diameter/2);
}
// A pair of stands that supports one joystick
module standpair() {
    translate([290,396]) stand(screwhole);
    translate([350,-354]) stand(screwhole);
}

// The case itself
module case() {
    difference() {
        translate([-wallsize,-wallsize,-wallsize]){
            cube([boxsize[0]+wallsize*2,boxsize[1]+wallsize*2,boxheight+wallsize]);
        }
        union() {
            cube([boxsize[0],boxsize[1],boxheight+1]);
        }
        translate([boxbuffer+usbplace-200,boxsize[1]-1,standheight]) {
            cube([400,102,10000]);
        }
    }
    for (i = joypositions) {
        translate(pcbposition+[0,pcbsize[1]]+i) standpair();
    }
}
case();

// Loose parts to help with assembly
for (i = [1:1:extrastands]) translate([-100+250*i,boxsize[1]+wallsize+200,0]) stand(screwhole);

// The PCB (for reference - do not use in the final render)
if (dxf_file != undef) translate([pcbposition[0],pcbposition[1]+pcbsize[1],standheight]) pcb(dxf_file);
