import processing.sound.*;

final float C=261.626, C_SHARP=277.184, D=293.665, D_SHARP=311.127, E=329.628, F=349.228, F_SHARP=369.994, G=391.995, G_SHARP=415.305, A=440, A_SHARP=466.164, B=493.883;
final float[] circle_of_fifths = {C, G, D, A, E, B, F_SHARP, C_SHARP, G_SHARP, D_SHARP, A_SHARP, F};
final float[] chromatic_scale = {C, C_SHARP, D, D_SHARP, E, F, F_SHARP, G, G_SHARP, A, A_SHARP, B};
final String[] NOTE_NAMES = {
  "C", "C#", "D", "D#", "E", "F",
  "F#", "G", "G#", "A", "A#", "B"
};
final String[] CHORD_NAMES = {
  "", "m", " maj7", " min7", "7", " add6", " add2", " add4"
};

String current_chord="";

final float[] next_bass_prob = {8.4, 25.2, 37.8, 46.2, 48.7, 53.7, 54.7, 59.7, 62.2, 70.6, 83.2, 100};

final int[] MAJOR = {0, 4, 7};
final int[] MINOR = {0, 3, 7};
final int[] DOM7 = {0,4,7,10};
final int[] MAJ7 = {0,4,7,11};
final int[] MIN7 = {0,3,7,10};
final int[] ADD6 = {0, 4, 7,9};
final int[] ADD6MIN = {0, 3, 7,9};
final int[] ADD2 = {0, 2, 4, 7};
final int[] ADD4 = {0, 4,5, 7};

final int[][] chords = {MAJOR, MINOR, MAJ7, MIN7, DOM7, ADD6, ADD2, ADD4};

final int CHORD_NOTES = 8;

int[] current_notes = new int[CHORD_NOTES];

int current_note_index  =0;

Env[] leadEnvs = new Env[CHORD_NOTES];



SinOsc[] bass = new SinOsc[10];
Env[] bassEnv = new Env[10];
float[] bass_harmonics = {
  1.0, // fundamental
  0.3, // 2º armónico
  0.15, // 3º armónico
  0.1, // 4º armónico
  0.05, // 5º armónico
  0.03, // 6º armónico
  0.02, // 7º armónico
  0.01, // 8º armónico
  0.005, // 9º armónico
  0.002   // 10º armónico
};

TriOsc[] leads = new TriOsc[CHORD_NOTES];

float attackTime = 0.001;
float sustainTime = 0.1;
float sustainLevel = 0.7;
float releaseTime = 0.8;

int lastTriggerTime = 0;
int interval = 300;  // milisegundos por paso
int step = 0;
int totalSteps = 8;  // por ejemplo, 8 pasos por compás
boolean[] kickPattern = {true, false, false, false,false, false, false, false};
boolean[] snarePattern = {false, false, false, false,true, false, false, false};
boolean[] hihatPattern = {true, false, true, false,true, false, true, false};

SoundFile kick;
SoundFile snare;
SoundFile hihat;


void setup_sound() {
  for (int i = 0; i<bass.length; i++) {
    bass[i] = new SinOsc(this);
    bassEnv[i] = new Env(this);
    bass[i].amp(bass_harmonics[i]*0.7);
  }
  for (int i=0; i<leads.length; i++) {
    leads[i] = new TriOsc(this);
    //leads[i].amp(0);
    //lead_env.play(leads[lead_index], attackTime,sustainTime, sustainLevel, releaseTime);
    leads[i].amp(0.5);
  
  leadEnvs[i] = new Env(this);
}
  kick = new SoundFile(this, "data/kick.wav");
  snare = new SoundFile(this, "data/snare.wav");
  hihat = new SoundFile(this, "data/hi-hat.wav");
}
void play_bass_note() {
  current_note_index=get_next_note();
  for (int i = 0; i<bass.length; i++) {
    bass[i].freq(circle_of_fifths[(current_note_index)]*(i+1)/4);
    bass[i].play();
    //bassEnv[i].play(bass[i], attackTime,sustainTime, sustainLevel, releaseTime);
  }


  int[] chord = calculate_chord();
  Note[] chord_notes = new Note[chord.length];
  chord_notes[0] = new Note();
  chord_notes[0].note = chord[0];
  current_notes[0] = chord_notes[0].note;
  leads[0].freq(chord_notes[0].get_frequency());
  leads[0].play();

  for (int i=1; i<chord.length; i++) {
    chord_notes[i] = new Note();
    chord_notes[i].note = chord[i];
    current_notes[i] = chord_notes[i].note;
    leads[i].freq(chord_notes[i].get_frequency());
    //leads[i].play();
  }
}

int get_next_note() {
  int interval=0;
  float[] prob_array = next_bass_prob;
  float random = random(101);
  for (int i = 0; i<12; i++) {
    if (random<prob_array[i]) {
      interval = i;
      break;
    }
  }
  return (current_note_index+interval)%12;
}

void plonk() {
  SinOsc sin = new SinOsc(this);
  Note note = new Note();
  note.note = 0;
  sin.freq(note.get_frequency());
  sin.play();
}

int circle_of_fifths_to_chromatic(int i) {
  if (i%2==0) return i;
  return (i+6)%12;
}

int[] calculate_chord() {
  int[][] candidates = new int[chords.length][CHORD_NOTES];
  int chord[] = new int[CHORD_NOTES];
  int bass_note = circle_of_fifths_to_chromatic(current_note_index);
  int candidate_index = 0;
  int current_note = 43;  //43=G3
  for (int i=0; i<candidates.length;i++){
    current_note = 43;
    candidate_index = 0;
    while(candidate_index<chord.length){
      
      if(is_note_in_chord(current_note, bass_note, chords[i])){
        candidates[i][candidate_index] = current_note;
        candidate_index++;
      }
      current_note++;
    }
  }
  
  int best_chord_index = get_best_chord(candidates);
  
  current_chord = NOTE_NAMES[bass_note] + CHORD_NAMES[best_chord_index];
  return candidates[best_chord_index];
}

int get_best_chord(int[][] candidates) {
  float chaosProbability = 0.25;  // 15% de caos
  if (random(1) < chaosProbability) {
    // Devuelve un índice aleatorio
    return int(random(candidates.length));
  }

  // Comportamiento normal: busca el más cercano
  int best_index = 0;
  int min_distance = Integer.MAX_VALUE;

  for (int i = 0; i < candidates.length; i++) {
    int distance = 0;
    for (int j = 0; j < candidates[i].length; j++) {
      distance += abs(candidates[i][j] - current_notes[j]);
    }

    if (distance < min_distance) {
      min_distance = distance;
      best_index = i;
    }
  }
  if(min_distance == 0){
  int result = int(random(candidates.length));
  while(result==best_index)  result = int(random(candidates.length));
  return result;
  }

  return best_index;
}

  

boolean is_note_in_chord(int note, int bass_note, int[] chord){
  boolean result = false;
  int cont = 0;
  while(!result&&cont<chord.length){
    result = note%12==(bass_note+chord[cont])%12;
    cont++;
  }
  return result;
}

void play_random_lead_note() {
  int lead_index = int(random(CHORD_NOTES)); // elige uno aleatorio

  leads[lead_index].play(); // asegura que esté activo
  leadEnvs[lead_index].play(leads[lead_index], attackTime, sustainTime, sustainLevel, releaseTime);
}



void rhythm_manager() {
  if (millis() - lastTriggerTime >= interval) {
    lastTriggerTime += interval;

    if (kickPattern[step]) kick.play();
    if (snarePattern[step]) snare.play();
    if (hihatPattern[step]) hihat.play();
    play_random_lead_note();

    step = (step + 1) % totalSteps;
  }
}



class Note {
  //0 = C4
  public int note;

  Note() {
  }

  float get_frequency() {
    int oct = note/12-4;
    float freq =chromatic_scale[note%12];
    return freq*pow(2, oct);
  }
}
