const int pinAudio = A0;

// Pinos digitais conectados à FPGA (Barramento de 3 bits)
const int PIN_BIT_0 = 2; // LSB
const int PIN_BIT_1 = 3;
const int PIN_BIT_2 = 4; // MSB

const int SAMPLE_RATE = 4000; 
const int BUFFER_SIZE = 256;
const unsigned long SAMPLE_INTERVAL = 1000000UL / SAMPLE_RATE;

int audioBuffer[BUFFER_SIZE];
// CORREÇÃO: yinBuffer mudou para float para suportar o cálculo de threshold
float yinBuffer[BUFFER_SIZE / 2]; 

void setup() {
  Serial.begin(115200);
  
  pinMode(PIN_BIT_0, OUTPUT);
  pinMode(PIN_BIT_1, OUTPUT);
  pinMode(PIN_BIT_2, OUTPUT);
}

void loop() {
  captureAudio();

  float frequency = detectPitchYIN();

  if (frequency >= 80.0 && frequency <= 1000.0) {
    sendNoteToFPGA(frequency);
  } else {
    // IMPORTANTE: Agora envia 7 quando não há som ou é ruído
    sendToFPGA(7); 
  }
}

void captureAudio() {
  // OTIMIZAÇÃO: Evita o acúmulo de atrasos calculando o próximo tempo exato
  unsigned long nextSampleTime = micros();
  
  for (int i = 0; i < BUFFER_SIZE; i++) {
    audioBuffer[i] = analogRead(pinAudio) - 512;
    nextSampleTime += SAMPLE_INTERVAL;
    
    while (micros() < nextSampleTime) {
      // Aguarda o momento exato da próxima amostra
    }
  }
}

float detectPitchYIN() {
  int tauMax = BUFFER_SIZE / 2;

  // STEP 1
  for (int tau = 1; tau < tauMax; tau++) {
    long sum = 0; 
    for (int i = 0; i < tauMax; i++) {
      long delta = audioBuffer[i] - audioBuffer[i + tau]; 
      sum += delta * delta;
    }
    yinBuffer[tau] = (float)sum; // Salva como float
  }

  // STEP 2
  yinBuffer[0] = 1.0;
  float runningSum = 0.0; // CORREÇÃO: Agora é float

  for (int tau = 1; tau < tauMax; tau++) {
    runningSum += yinBuffer[tau];
    if (runningSum != 0.0) {
      yinBuffer[tau] = (yinBuffer[tau] * tau) / runningSum;
    }
  }

  // STEP 3
  const float threshold = 0.15;
  int tauEstimate = -1;

  for (int tau = 2; tau < tauMax; tau++) {
    if (yinBuffer[tau] < threshold) {
      while (tau + 1 < tauMax && yinBuffer[tau + 1] < yinBuffer[tau]) {
        tau++;
      }
      tauEstimate = tau;
      break;
    }
  }

  if (tauEstimate == -1) return 0.0;

  // STEP 4
  return (float)SAMPLE_RATE / tauEstimate;
}

void sendNoteToFPGA(float freq) {
  // Calcula o número exato da nota MIDI (considerando a oitava)
  int midiNote = round(69 + 12 * log(freq / 440.0) / log(2.0));

  byte fpgaCode = 7; // 7 significa "Nada" na sua LUT

  // Mapeia exatamente as notas usadas em Sweden
  switch(midiNote) {
    case 59: fpgaCode = 0; break; // B3  (246.94 Hz) -> Binário 000
    case 42: fpgaCode = 1; break; // F#2 ( 92.50 Hz) -> Binário 001
    case 66: fpgaCode = 2; break; // F#4 (369.99 Hz) -> Binário 010
    case 43: fpgaCode = 3; break; // G2  ( 98.00 Hz) -> Binário 011
    case 61: fpgaCode = 4; break; // C#4 (277.18 Hz) -> Binário 100
    case 45: fpgaCode = 5; break; // A2  (110.00 Hz) -> Binário 101
    case 64: fpgaCode = 6; break; // E4  (329.63 Hz) -> Binário 110
    default: fpgaCode = 7; break; // Qualquer outra nota envia Nada (111)
  }

  sendToFPGA(fpgaCode);
}

void sendToFPGA(byte code) {
  digitalWrite(PIN_BIT_0, bitRead(code, 0));
  digitalWrite(PIN_BIT_1, bitRead(code, 1));
  digitalWrite(PIN_BIT_2, bitRead(code, 2));
}
