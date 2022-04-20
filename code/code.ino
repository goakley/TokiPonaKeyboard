/*
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. 
*/
#include <Keyboard.h>

#define ANALOG_MAX 1023
#define ANALOG_THRESHOLD 0.33
#define MAG_THRESHOLD 0.5
#define ANG_THRESHOLD 0.7
#define PINLEN sizeof(pins)/sizeof(pins[0])
//define MUXLEN sizeof(muxvalues)/sizeof(muxvalues[0])
#define MUXLEN 8

#define KEYBRD 0
#if KEYBRD
#define WRITE Keyboard.write
#else
#define WRITE Serial.write
#endif

// MUX LOGIC
const byte pins[4] = {A3,A2,A1,A0};
const byte inpin = 10;
const byte muxtable[16][4] = {
  // {s0, s1, s2, s3}, // channel
  {0,  0,  0,  0}, // 0
  {1,  0,  0,  0}, // 1
  {0,  1,  0,  0}, // 2
  {1,  1,  0,  0}, // 3
  {0,  0,  1,  0}, // 4
  {1,  0,  1,  0}, // 5
  {0,  1,  1,  0}, // 6
  {1,  1,  1,  0}, // 7
  {0,  0,  0,  1}, // 8
  {1,  0,  0,  1}, // 9
  {0,  1,  0,  1}, // 10
  {1,  1,  0,  1}, // 11
  {0,  0,  1,  1}, // 12
  {1,  0,  1,  1}, // 13
  {0,  1,  1,  1}, // 14
  {1,  1,  1,  1}  // 15
};
int calibration[16] = {102,922,102,922,200,940,160,900,102,922,102,922,200,940,160,900};
int records[16] = {9999,-1,9999,-1,9999,-1,9999,-1,9999,-1,9999,-1,9999,-1,9999,-1};
//int calibration[16] = {410,614,410,614,410,614,410,614,410,614,410,614,410,614,410,614};
bool recalibrate = false;
float muxvalues[16];
// fill muxvalues with values in the range [-1,1] (probably) for each channel
void refreshMux() {
  for (int i = 0; i < MUXLEN; i++) {
    digitalWrite(pins[0], muxtable[i][0]);
    digitalWrite(pins[1], muxtable[i][1]);
    digitalWrite(pins[2], muxtable[i][2]);
    digitalWrite(pins[3], muxtable[i][3]);
    delayMicroseconds(4);
    int value = analogRead(inpin);
    records[i*2] = min(records[i*2], value);
    records[i*2+1] = max(records[i*2+1], value);
    int minv = calibration[i*2];
    int maxv = calibration[i*2+1];
    //muxvalues[i] = (2 * ((float)value) / ((float)ANALOG_MAX)) - 1;
    muxvalues[i] = (2 * ((float)(value - minv)) / ((float)(maxv - minv))) - 1;
  }
}

bool state[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
char keysPressed[17];
char keysPressedI = 0;
char keysReleased[17];
char keysReleasedI = 0;

// vowel-cluster mapping
//const char keymap[16] = {'e',0,'n','i','o',0,'a','u','l','s','k','p','m','t','w','j'};
// vowel-pair mapping (o floating)
//const char keymap[16] = {'a','i','l','n','e','u','k','t','o',0,'s','p','j',0,'m','w'};
// vowel-pair mapping (u floating)
const char keymap[16] = {'a','i','l','n','e','o','k','t','u',0,'s','p','j',0,'m','w'};

void refreshFromMuxIndex(int index, bool active) {
  if (keymap[index]) {
    if (active) {
      if (!state[index]) {
        keysPressed[keysPressedI++] = keymap[index];
      }
      state[index] = 1;
    } else {
      if (state[index]) {
        keysReleased[keysReleasedI++] = keymap[index];
      }
      state[index] = 0;
    }
  }
}

void refreshFromMux() {
  refreshMux();
  keysPressedI = 0;
  keysReleasedI = 0;
  for (int i = 0; i < MUXLEN / 2; i++) {
    float ud = muxvalues[i*2];
    float lr = muxvalues[i*2+1];
    float len = sqrt(ud * ud + lr * lr);
    ud = ud / len;
    lr = lr / len;
    refreshFromMuxIndex(i*4+0, len > MAG_THRESHOLD && ud > ANG_THRESHOLD);
    refreshFromMuxIndex(i*4+1, len > MAG_THRESHOLD && ud < -ANG_THRESHOLD);
    refreshFromMuxIndex(i*4+2, len > MAG_THRESHOLD && lr > ANG_THRESHOLD);
    refreshFromMuxIndex(i*4+3, len > MAG_THRESHOLD && lr < -ANG_THRESHOLD);
  }
  //Serial.println("");
  keysPressed[keysPressedI] = 0;
  keysReleased[keysReleasedI] = 0;
}

void setup() {
  for (int i = 0; i < PINLEN; i++) {
    pinMode(pins[i], OUTPUT);
  }
  pinMode(inpin, INPUT);
  Serial.begin(9600);
  delay(128);
  while (!Serial) ;
  #if KEYBRD
  Keyboard.begin();
  #endif
}

unsigned long lastRecord = 0;
unsigned long loops = 0;

void debug(unsigned long duration) {
  Serial.println();
  for (int i =0; i < MUXLEN; i++) {
    Serial.print(records[i*2]);
    Serial.print(" ");
    Serial.print(records[i*2+1]);
    Serial.print(" ");
  }
  Serial.print("| ");
  Serial.print(((float)duration) / ((float)loops));
  Serial.println();
}

void loop() {
  refreshFromMux();

  unsigned long now = millis();
  if (now - lastRecord > 1000) {
    int inp = Serial.read();
    if (inp == 'd') {
      debug(now - lastRecord);
    }
    loops = 0;
    lastRecord = now;
  }
  
  int i = 0;
  while (i < keysPressedI) {
    WRITE(keysPressed[i]);
    i++;
  }
  if (i > 0) {
    Serial.flush();
  }
  loops++;
}
