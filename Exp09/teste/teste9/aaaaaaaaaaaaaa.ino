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

  byte fpgaCode = 0; // 0 significa "Nothing" na sua LUT original do VHDL

  // Mapeia exatamente as notas de Sweden seguindo a LUT do seu VHDL
  switch(midiNote) {
    case 59: fpgaCode = 1; break; // B3  (246.94 Hz) -> Índice 1
    case 42: fpgaCode = 2; break; // F#2 ( 92.50 Hz) -> Índice 2
    case 66: fpgaCode = 3; break; // F#4 (369.99 Hz) -> Índice 3
    case 43: fpgaCode = 4; break; // G2  ( 98.00 Hz) -> Índice 4
    case 61: fpgaCode = 5; break; // C#4 (277.18 Hz) -> Índice 5
    case 45: fpgaCode = 6; break; // A2  (110.00 Hz) -> Índice 6
    case 64: fpgaCode = 7; break; // E4  (329.63 Hz) -> Índice 7
    default: fpgaCode = 0; break; // Qualquer outra nota envia Silêncio (Índice 0)
  }

  sendToFPGA(fpgaCode);
}

// Implementação com LÓGICA NEGATIVA nos pinos de saída
void sendToFPGA(byte code) {
  // O operador '!' inverte o estado lógico de cada bit enviado:
  // Se o bit lido for 1, o Arduino manda LOW (0)
  // Se o bit lido for 0, o Arduino manda HIGH (1)
  digitalWrite(PIN_BIT_0, !bitRead(code, 0));
  digitalWrite(PIN_BIT_1, !bitRead(code, 1));
  digitalWrite(PIN_BIT_2, !bitRead(code, 2));
}
