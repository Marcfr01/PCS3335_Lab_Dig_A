const int pinAudio = A0;

// Mantemos 4000Hz. Para 880Hz, o período (tau) será pequeno,
// o que significa que o YIN vai rodar até mais rápido (vai achar o pitch logo no início).
const int SAMPLE_RATE = 4000; 
const int BUFFER_SIZE = 256;

int audioBuffer[BUFFER_SIZE];

// Mudamos o buffer do YIN para unsigned long para acelerar o processamento (Removido Float)
unsigned long yinBuffer[BUFFER_SIZE / 2];

const char* noteNames[] = {
  "C", "C#", "D", "D#", "E", "F",
  "F#", "G", "G#", "A", "A#", "B"
};

void setup() {
  Serial.begin(115200);
}

void loop() {
  captureAudio();

  float frequency = detectPitchYIN();

  // ALTERAÇÃO: Filtro ajustado para a quarta oitava (com uma leve margem de segurança)
  if (frequency >= 400.0 && frequency <= 900.0) {
    printNote(frequency);
  }
  
  // Delay removido para garantir o tempo de resposta do seu jogo!
}

void captureAudio() {
  for (int i = 0; i < BUFFER_SIZE; i++) {
    unsigned long t0 = micros();

    audioBuffer[i] = analogRead(pinAudio) - 512;

    // Aguarda o tempo exato do sample rate (250 microssegundos para 4000Hz)
    while (micros() - t0 < (1000000UL / SAMPLE_RATE)) {
    }
  }
}

float detectPitchYIN() {
  int tauMax = BUFFER_SIZE / 2;

  // STEP 1: OTIMIZADO PARA INTEIROS (LONG)
  for (int tau = 1; tau < tauMax; tau++) {
    unsigned long sum = 0; // Mudado de float para unsigned long

    for (int i = 0; i < tauMax; i++) {
      long delta = audioBuffer[i] - audioBuffer[i + tau]; // Mudado para long
      sum += delta * delta;
    }
    yinBuffer[tau] = sum;
  }

  // STEP 2: Normalização
  yinBuffer[0] = 1;
  unsigned long runningSum = 0;

  for (int tau = 1; tau < tauMax; tau++) {
    runningSum += yinBuffer[tau];
    if (runningSum != 0) {
      // Cálculo aproximado por inteiros para evitar divisões flutuantes pesadas
      yinBuffer[tau] = (yinBuffer[tau] * tau) / runningSum;
    }
  }

  // STEP 3: Absolute threshold
  const float threshold = 0.15;
  int tauEstimate = -1;

  // Como as frequências de 440Hz a 880Hz são altas, o 'tau' (período)
  // vai ser bem pequeno (entre 4 e 9 amostras de distância).
  for (int tau = 2; tau < tauMax; tau++) {
    if ((float)yinBuffer[tau] < threshold) {
      while (tau + 1 < tauMax && yinBuffer[tau + 1] < yinBuffer[tau]) {
        tau++;
      }
      tauEstimate = tau;
      break;
    }
  }

  if (tauEstimate == -1) return 0;

  // STEP 4: Cálculo da Frequência final
  return (float)SAMPLE_RATE / tauEstimate;
}

void printNote(float freq) {
  int midiNote = round(69 + 12 * log(freq / 440.0) / log(2.0));
  int noteIndex = midiNote % 12;
  int octave = (midiNote / 12) - 1;

  // Simplificado o print para não engasgar a porta serial no meio do jogo
  Serial.print("Freq: ");
  Serial.print(freq, 1);
  Serial.print(" Hz -> ");
  Serial.print(noteNames[noteIndex]);
  Serial.println(octave);
}
