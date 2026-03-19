// lib/services/symptom_service.dart
import '../models/models.dart';

class SymptomService {
  static final Map<String, Map<String, dynamic>> _symptomDatabase = {
    'headache': {
      'conditions': [
        'Tension Headache',
        'Migraine',
        'Dehydration',
        'Sinusitis'
      ],
      'severity_weight': 1,
    },
    'fever': {
      'conditions': ['Common Cold', 'Flu (Influenza)', 'Infection', 'COVID-19'],
      'severity_weight': 2,
    },
    'cough': {
      'conditions': [
        'Common Cold',
        'Bronchitis',
        'COVID-19',
        'Allergic Rhinitis'
      ],
      'severity_weight': 1,
    },
    'sore throat': {
      'conditions': ['Strep Throat', 'Common Cold', 'Tonsillitis', 'Flu'],
      'severity_weight': 1,
    },
    'runny nose': {
      'conditions': ['Common Cold', 'Allergic Rhinitis', 'Sinusitis'],
      'severity_weight': 0,
    },
    'fatigue': {
      'conditions': [
        'Anemia',
        'Flu',
        'Hypothyroidism',
        'Depression',
        'Dehydration'
      ],
      'severity_weight': 1,
    },
    'nausea': {
      'conditions': [
        'Gastroenteritis',
        'Food Poisoning',
        'Motion Sickness',
        'Migraine'
      ],
      'severity_weight': 1,
    },
    'vomiting': {
      'conditions': ['Gastroenteritis', 'Food Poisoning', 'Norovirus'],
      'severity_weight': 2,
    },
    'diarrhea': {
      'conditions': ['Gastroenteritis', 'Food Poisoning', 'IBS', 'Infection'],
      'severity_weight': 2,
    },
    'chest pain': {
      'conditions': [
        'Angina',
        'Myocardial Infarction',
        'Costochondritis',
        'Acid Reflux'
      ],
      'severity_weight': 5,
    },
    'shortness of breath': {
      'conditions': [
        'Asthma',
        'Pneumonia',
        'Anxiety',
        'COVID-19',
        'Heart Failure'
      ],
      'severity_weight': 4,
    },
    'back pain': {
      'conditions': [
        'Muscle Strain',
        'Herniated Disc',
        'Sciatica',
        'Kidney Stones'
      ],
      'severity_weight': 2,
    },
    'stomach pain': {
      'conditions': ['Gastritis', 'Appendicitis', 'IBS', 'Ulcers'],
      'severity_weight': 2,
    },
    'rash': {
      'conditions': [
        'Allergic Reaction',
        'Eczema',
        'Psoriasis',
        'Contact Dermatitis'
      ],
      'severity_weight': 1,
    },
    'dizziness': {
      'conditions': ['Vertigo', 'Dehydration', 'Low Blood Pressure', 'Anemia'],
      'severity_weight': 2,
    },
    'insomnia': {
      'conditions': ['Anxiety', 'Stress', 'Depression', 'Sleep Apnea'],
      'severity_weight': 1,
    },
    'joint pain': {
      'conditions': ['Arthritis', 'Gout', 'Lupus', 'Lyme Disease'],
      'severity_weight': 2,
    },
    'eye pain': {
      'conditions': ['Conjunctivitis', 'Glaucoma', 'Eye Strain', 'Migraine'],
      'severity_weight': 2,
    },
    'earache': {
      'conditions': ['Ear Infection', 'Swimmer\'s Ear', 'TMJ', 'Sinusitis'],
      'severity_weight': 1,
    },
    'swelling': {
      'conditions': [
        'Allergic Reaction',
        'Injury',
        'Lymphedema',
        'Kidney Disease'
      ],
      'severity_weight': 2,
    },
  };

  static final Map<String, Map<String, dynamic>> _conditionDatabase = {
    'Common Cold': {
      'description':
          'A viral infection of the upper respiratory tract causing runny nose, sore throat, and cough.',
      'severity': SeverityLevel.low,
      'recommendation':
          'Rest, stay hydrated, and use over-the-counter symptom relief.',
      'actions': [
        'Get plenty of rest (7-9 hours)',
        'Drink warm fluids (tea, broth)',
        'Use saline nasal spray',
        'Take Vitamin C supplements',
        'Use a humidifier',
      ],
      'seeDoctor': false,
    },
    'Flu (Influenza)': {
      'description':
          'A contagious respiratory illness caused by influenza viruses affecting the nose, throat, and lungs.',
      'severity': SeverityLevel.medium,
      'recommendation':
          'Rest at home, stay hydrated. See a doctor if symptoms worsen.',
      'actions': [
        'Rest and avoid physical activity',
        'Drink plenty of fluids',
        'Take antipyretics for fever',
        'Isolate to prevent spread',
        'Monitor temperature regularly',
      ],
      'seeDoctor': false,
    },
    'COVID-19': {
      'description':
          'Coronavirus disease caused by SARS-CoV-2, ranging from mild to severe respiratory illness.',
      'severity': SeverityLevel.medium,
      'recommendation':
          'Isolate and get tested. Seek immediate care if breathing becomes difficult.',
      'actions': [
        'Get a COVID-19 test immediately',
        'Isolate from others',
        'Monitor oxygen levels',
        'Rest and stay hydrated',
        'Contact healthcare provider',
      ],
      'seeDoctor': true,
    },
    'Tension Headache': {
      'description':
          'The most common type of headache, causing mild to moderate pain around the head.',
      'severity': SeverityLevel.low,
      'recommendation':
          'Take over-the-counter pain relievers and rest in a quiet, dark room.',
      'actions': [
        'Take OTC pain relievers',
        'Apply cold or warm compress',
        'Rest in a dark, quiet room',
        'Practice relaxation techniques',
        'Stay hydrated',
      ],
      'seeDoctor': false,
    },
    'Migraine': {
      'description':
          'Intense, throbbing headache often accompanied by nausea and light sensitivity.',
      'severity': SeverityLevel.medium,
      'recommendation':
          'Rest in a dark room. See a doctor if migraines are frequent.',
      'actions': [
        'Rest in a dark, quiet room',
        'Apply ice pack to forehead',
        'Stay hydrated',
        'Avoid triggers (bright lights, strong smells)',
        'Consider prescription migraine medication',
      ],
      'seeDoctor': false,
    },
    'Gastroenteritis': {
      'description':
          'Inflammation of the stomach and intestines, commonly called "stomach flu."',
      'severity': SeverityLevel.medium,
      'recommendation':
          'Stay hydrated with clear fluids. Seek care if symptoms persist beyond 48 hours.',
      'actions': [
        'Drink clear fluids slowly',
        'Follow BRAT diet (Bananas, Rice, Applesauce, Toast)',
        'Avoid dairy and fatty foods',
        'Monitor for dehydration signs',
        'Rest completely',
      ],
      'seeDoctor': false,
    },
    'Angina': {
      'description':
          'Chest pain or discomfort caused by reduced blood flow to the heart muscle.',
      'severity': SeverityLevel.high,
      'recommendation':
          '⚠️ SEEK IMMEDIATE MEDICAL ATTENTION. This could be a cardiac emergency.',
      'actions': [
        '🚨 Call emergency services immediately',
        'Chew aspirin if not allergic',
        'Stop all physical activity',
        'Sit or lie down comfortably',
        'Do not drive yourself to hospital',
      ],
      'seeDoctor': true,
    },
    'Asthma': {
      'description':
          'A condition causing airway inflammation and narrowing, making breathing difficult.',
      'severity': SeverityLevel.high,
      'recommendation':
          'Use your rescue inhaler. Seek emergency care if breathing remains difficult.',
      'actions': [
        'Use prescribed rescue inhaler',
        'Sit upright to ease breathing',
        'Remain calm to slow breathing',
        'Avoid triggers',
        'Seek emergency care if no improvement',
      ],
      'seeDoctor': true,
    },
    'Dehydration': {
      'description':
          'Occurs when your body loses more fluids than it takes in.',
      'severity': SeverityLevel.low,
      'recommendation':
          'Drink water and electrolyte solutions. Avoid strenuous activity.',
      'actions': [
        'Drink water slowly but consistently',
        'Use oral rehydration solutions',
        'Avoid caffeine and alcohol',
        'Rest in a cool environment',
        'Eat water-rich foods',
      ],
      'seeDoctor': false,
    },
    'Allergic Reaction': {
      'description':
          'The immune system\'s response to a substance that is usually harmless.',
      'severity': SeverityLevel.medium,
      'recommendation':
          'Take antihistamines. Seek emergency care if throat swelling occurs.',
      'actions': [
        'Take antihistamine medication',
        'Identify and avoid the allergen',
        'Apply cold compress to rash',
        'Watch for severe symptoms',
        '🚨 Use EpiPen if anaphylaxis symptoms appear',
      ],
      'seeDoctor': false,
    },
  };

  static SymptomAnalysisResult analyzeSymptoms(List<String> userSymptoms) {
    final normalizedSymptoms =
        userSymptoms.map((s) => s.toLowerCase().trim()).toList();

    // Count condition matches
    final Map<String, int> conditionScores = {};
    final Map<String, List<String>> conditionMatchedSymptoms = {};

    int totalSeverityWeight = 0;

    for (final symptom in normalizedSymptoms) {
      // Find matching symptom in database (fuzzy matching)
      for (final dbSymptom in _symptomDatabase.keys) {
        if (symptom.contains(dbSymptom) ||
            dbSymptom.contains(symptom) ||
            _isSimilar(symptom, dbSymptom)) {
          final data = _symptomDatabase[dbSymptom]!;
          totalSeverityWeight += data['severity_weight'] as int;

          for (final condition in data['conditions'] as List<String>) {
            conditionScores[condition] = (conditionScores[condition] ?? 0) + 1;
            if (!conditionMatchedSymptoms.containsKey(condition)) {
              conditionMatchedSymptoms[condition] = [];
            }
            conditionMatchedSymptoms[condition]!.add(dbSymptom);
          }
        }
      }
    }

    // Sort conditions by score
    final sortedConditions = conditionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build diagnosis items
    final diagnoses = <DiagnosisItem>[];
    final totalMatches = normalizedSymptoms.length;

    for (int i = 0; i < sortedConditions.length && i < 4; i++) {
      final entry = sortedConditions[i];
      final condData = _conditionDatabase[entry.key];

      if (condData != null) {
        final confidence =
            ((entry.value / totalMatches.clamp(1, 10)) * 100).clamp(20.0, 95.0);
        diagnoses.add(DiagnosisItem(
          condition: entry.key,
          description: condData['description'] as String,
          confidence: confidence,
          matchedSymptoms: conditionMatchedSymptoms[entry.key] ?? [],
        ));
      }
    }

    // If no matches found, provide generic diagnosis
    if (diagnoses.isEmpty) {
      diagnoses.add(DiagnosisItem(
        condition: 'General Discomfort',
        description:
            'Your symptoms may indicate a minor ailment. Monitor your condition and consult a doctor if symptoms persist.',
        confidence: 60,
        matchedSymptoms: normalizedSymptoms,
      ));
    }

    // Determine severity
    SeverityLevel severity;
    bool shouldSeeDoctor;

    if (totalSeverityWeight >= 8 ||
        normalizedSymptoms.any((s) =>
            s.contains('chest') ||
            s.contains('breathing') ||
            s.contains('unconscious'))) {
      severity = SeverityLevel.high;
      shouldSeeDoctor = true;
    } else if (totalSeverityWeight >= 4) {
      severity = SeverityLevel.medium;
      shouldSeeDoctor = diagnoses.any((d) =>
          (_conditionDatabase[d.condition]?['seeDoctor'] as bool?) == true);
    } else {
      severity = SeverityLevel.low;
      shouldSeeDoctor = false;
    }

    // Get recommendation and actions from top condition
    final topCondition =
        diagnoses.isNotEmpty ? diagnoses.first.condition : 'General Discomfort';
    final topCondData = _conditionDatabase[topCondition];

    String recommendation;
    List<String> actions;
    List<String> warnings;

    if (topCondData != null) {
      recommendation = topCondData['recommendation'] as String;
      actions = List<String>.from(topCondData['actions'] as List);
    } else {
      recommendation = shouldSeeDoctor
          ? 'Based on your symptoms, we recommend consulting a healthcare professional.'
          : 'Monitor your symptoms. Rest and stay hydrated. Consult a doctor if symptoms worsen.';
      actions = [
        'Rest and get adequate sleep',
        'Stay well hydrated',
        'Monitor your symptoms',
        'Avoid strenuous activity',
        'Contact a doctor if symptoms worsen',
      ];
    }

    warnings = shouldSeeDoctor
        ? ['Please consult a healthcare professional as soon as possible.']
        : [];

    return SymptomAnalysisResult(
      symptoms: normalizedSymptoms,
      possibleConditions: diagnoses,
      severity: severity,
      recommendation: recommendation,
      suggestedActions: actions,
      warningSignals: warnings,
      shouldSeeDoctor: shouldSeeDoctor,
      analyzedAt: DateTime.now(),
    );
  }

  static bool _isSimilar(String a, String b) {
    if (a.length < 4 || b.length < 4) return false;
    final prefix = a.substring(0, (a.length * 0.7).round());
    return b.startsWith(prefix) ||
        a.startsWith(b.substring(0, (b.length * 0.7).round()));
  }

  static List<String> getSymptomSuggestions() {
    return _symptomDatabase.keys.toList();
  }
}

// lib/services/medicine_service.dart
class MedicineService {
  static final List<MedicineModel> _medicines = [
    MedicineModel(
      id: '1',
      name: 'Paracetamol',
      genericName: 'Acetaminophen',
      category: 'Analgesic / Antipyretic',
      description:
          'A common pain reliever and fever reducer used for mild to moderate pain and temperature control.',
      usage:
          'Often used for headache, muscle aches, dental pain, period pain, back pain, and fever.',
      dosage:
          'Adults: 500mg to 1000mg every 4 to 6 hours as needed. Do not exceed 4000mg in 24 hours unless a clinician advises otherwise.',
      howToTake:
          'Swallow tablets with water. It may be taken with or without food. Check other cold or flu medicines to avoid accidental double dosing.',
      warnings: [
        'Do not exceed the recommended total daily dose.',
        'Use extra caution if you have liver disease or drink alcohol regularly.',
        'Check combination products because many already contain acetaminophen.',
      ],
      sideEffects: [
        'Nausea',
        'Skin rash',
        'Mild stomach discomfort',
        'Rare allergic reaction',
        'Liver injury with overdose',
      ],
      ingredients: ['Acetaminophen', 'Microcrystalline cellulose', 'Starch'],
      allergens: [],
      contraindications: [
        'Severe liver disease',
        'Heavy alcohol use',
        'Acetaminophen allergy',
      ],
      interactions: [
        'Warfarin with frequent long-term use',
        'Alcohol',
        'Other acetaminophen-containing products',
      ],
      storageInstructions:
          'Store at room temperature in a dry place away from heat and humidity.',
      pregnancyBreastfeeding:
          'Usually considered compatible in pregnancy and breastfeeding when taken at standard doses, but confirm with your clinician if you need repeated use.',
      whenToSeeDoctor:
          'See a doctor if pain or fever lasts more than a few days, symptoms worsen, or you need the medicine regularly.',
      emergencyWarning:
          'Get urgent help immediately if too much was taken, severe vomiting develops, or the person becomes confused, sleepy, or jaundiced.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
    MedicineModel(
      id: '2',
      name: 'Ibuprofen',
      genericName: 'Ibuprofen',
      category: 'NSAID / Anti-inflammatory',
      description:
          'A non-steroidal anti-inflammatory drug used to reduce pain, fever, and inflammation.',
      usage:
          'Commonly used for headache, menstrual pain, dental pain, muscle injury, and inflammatory pain.',
      dosage:
          'Adults: 200mg to 400mg every 4 to 6 hours as needed. Follow the pack instructions and avoid high daily doses without medical advice.',
      howToTake:
          'Take with food, milk, or a full glass of water to reduce stomach irritation. Avoid taking more than one NSAID at the same time.',
      warnings: [
        'May irritate the stomach and increase bleeding risk.',
        'Can worsen kidney function, especially during dehydration.',
        'Use caution if you have heart disease, high blood pressure, or ulcers.',
      ],
      sideEffects: [
        'Stomach upset',
        'Heartburn',
        'Dizziness',
        'Swelling',
        'Bleeding risk',
      ],
      ingredients: ['Ibuprofen', 'Lactose', 'Microcrystalline cellulose'],
      allergens: ['NSAID class allergens'],
      contraindications: [
        'Aspirin sensitivity',
        'Active stomach ulcer',
        'Severe kidney disease',
        'Late pregnancy without medical advice',
      ],
      interactions: [
        'Blood thinners',
        'Aspirin',
        'Steroids',
        'ACE inhibitors and diuretics',
      ],
      storageInstructions:
          'Store in the original pack at room temperature and keep out of reach of children.',
      pregnancyBreastfeeding:
          'Avoid in the third trimester unless specifically prescribed. Ask a clinician before use in pregnancy or during breastfeeding.',
      whenToSeeDoctor:
          'Seek medical advice if pain lasts more than a few days, if black stools develop, or if swelling and shortness of breath appear.',
      emergencyWarning:
          'Get urgent help for vomiting blood, severe stomach pain, wheezing, facial swelling, or chest pain after taking ibuprofen.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
    MedicineModel(
      id: '3',
      name: 'Amoxicillin',
      genericName: 'Amoxicillin',
      category: 'Antibiotic (Penicillin)',
      description:
          'A penicillin antibiotic used to treat bacterial infections such as ear, throat, sinus, chest, skin, and urinary infections.',
      usage:
          'Used only for infections likely caused by bacteria and should be taken exactly as prescribed.',
      dosage:
          'Adults commonly take 250mg to 500mg every 8 hours or 500mg to 875mg every 12 hours, depending on the infection and clinician instructions.',
      howToTake:
          'Take at evenly spaced intervals and finish the full course even if you start to feel better. It may be taken with food if nausea occurs.',
      warnings: [
        'Do not use if you have had a serious penicillin allergy.',
        'Stopping early can allow infection to return.',
        'Antibiotics do not treat colds or most viral illnesses.',
      ],
      sideEffects: [
        'Diarrhea',
        'Nausea',
        'Rash',
        'Thrush or yeast infection',
        'Allergic reaction',
      ],
      ingredients: [
        'Amoxicillin trihydrate',
        'Magnesium stearate',
        'Sodium starch glycolate',
      ],
      allergens: ['Penicillin', 'Cephalosporins (cross-reactivity)'],
      contraindications: [
        'Penicillin allergy',
        'Previous severe beta-lactam reaction',
        'Infectious mononucleosis',
      ],
      interactions: [
        'Warfarin',
        'Methotrexate',
        'Allopurinol',
        'Some oral contraceptive counseling considerations',
      ],
      storageInstructions:
          'Store tablets or capsules at room temperature. Liquid suspension may have separate label instructions and may require refrigeration.',
      pregnancyBreastfeeding:
          'Commonly used in pregnancy and breastfeeding when prescribed, but any rash or diarrhea in parent or baby should be discussed with a clinician.',
      whenToSeeDoctor:
          'See a doctor if symptoms are not improving after a few days, if severe diarrhea develops, or if new rash appears.',
      emergencyWarning:
          'Call emergency services for breathing difficulty, face swelling, severe blistering rash, or fainting after taking amoxicillin.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: true,
    ),
    MedicineModel(
      id: '4',
      name: 'Loratadine',
      genericName: 'Loratadine',
      category: 'Antihistamine',
      description:
          'A usually non-drowsy antihistamine that helps relieve sneezing, runny nose, itchy eyes, and hives.',
      usage:
          'Used for seasonal allergies, pet allergies, mild skin allergy symptoms, and hives.',
      dosage:
          'Adults: 10mg once daily. Follow child dosing instructions on the product label or from your clinician.',
      howToTake:
          'Take once a day with or without food. Try to take it at the same time each day during allergy season.',
      warnings: [
        'Use caution in significant liver impairment.',
        'Although usually non-drowsy, some people may still feel sleepy.',
      ],
      sideEffects: ['Headache', 'Dry mouth', 'Fatigue', 'Sleepiness'],
      ingredients: ['Loratadine', 'Lactose monohydrate', 'Corn starch'],
      allergens: [],
      contraindications: ['Severe liver disease', 'Loratadine allergy'],
      interactions: ['Alcohol may worsen drowsiness', 'Certain antifungals'],
      storageInstructions: 'Store below excessive heat and moisture.',
      pregnancyBreastfeeding:
          'Discuss with a clinician if you are pregnant or breastfeeding before using regularly.',
      whenToSeeDoctor:
          'See a doctor if breathing symptoms, facial swelling, or persistent rash continue despite treatment.',
      emergencyWarning:
          'Get urgent help for swelling of the lips or throat, severe wheezing, or collapse.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
    MedicineModel(
      id: '5',
      name: 'Omeprazole',
      genericName: 'Omeprazole',
      category: 'Proton Pump Inhibitor',
      description:
          'A proton pump inhibitor that reduces stomach acid and helps control reflux, heartburn, and ulcer symptoms.',
      usage:
          'Used for reflux, gastritis plans made by a clinician, ulcer care, and acid-related irritation.',
      dosage:
          'Adults often take 20mg once daily before food for a limited course unless a clinician recommends another plan.',
      howToTake:
          'Take 30 to 60 minutes before a meal and swallow the capsule whole unless your pharmacist gives different instructions.',
      warnings: [
        'Long-term use may be associated with low magnesium, low vitamin B12, or bone issues.',
        'Persistent symptoms may need medical evaluation.',
      ],
      sideEffects: [
        'Headache',
        'Nausea',
        'Diarrhea',
        'Abdominal discomfort',
        'Vitamin B12 deficiency with long-term use',
      ],
      ingredients: ['Omeprazole', 'Hydroxypropyl cellulose', 'Mannitol'],
      allergens: [],
      contraindications: [
        'Hypersensitivity to PPIs',
        'Severe liver impairment'
      ],
      interactions: ['Clopidogrel', 'Warfarin', 'Methotrexate', 'Diazepam'],
      storageInstructions:
          'Keep in a dry place below high heat. Protect capsules from moisture.',
      pregnancyBreastfeeding:
          'Check with a clinician if pregnant or breastfeeding before starting a new reflux medicine.',
      whenToSeeDoctor:
          'See a doctor if you have trouble swallowing, weight loss, black stools, or chest pain.',
      emergencyWarning:
          'Get urgent care for vomiting blood, black tarry stools, severe chest pain, or fainting.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
    MedicineModel(
      id: '6',
      name: 'Metformin',
      genericName: 'Metformin HCl',
      category: 'Antidiabetic',
      description:
          'A first-line medicine for type 2 diabetes that helps improve insulin sensitivity and lower blood glucose.',
      usage:
          'Used as part of a diabetes treatment plan together with nutrition, activity, and regular blood sugar monitoring.',
      dosage:
          'Adults often start with 500mg once or twice daily with meals, then the dose may be increased gradually by a clinician.',
      howToTake:
          'Take with meals to reduce stomach side effects. Extended-release tablets should usually be swallowed whole.',
      warnings: [
        'Temporary stomach upset is common when starting treatment.',
        'Kidney function should be reviewed before and during treatment.',
        'The medicine may need to be paused around some scans or surgeries.',
      ],
      sideEffects: [
        'Nausea',
        'Diarrhea',
        'Metallic taste',
        'Stomach upset',
        'Vitamin B12 deficiency with long-term use',
      ],
      ingredients: [
        'Metformin hydrochloride',
        'Povidone',
        'Magnesium stearate'
      ],
      allergens: [],
      contraindications: [
        'Advanced kidney disease',
        'Metabolic acidosis',
        'Severe dehydration without medical review',
      ],
      interactions: ['Alcohol', 'Iodinated contrast dye', 'Some diuretics'],
      storageInstructions:
          'Store at room temperature, tightly closed, away from moisture.',
      pregnancyBreastfeeding:
          'Pregnancy diabetes care should be individualized by a clinician. Discuss plans for pregnancy or breastfeeding before continuing or changing dose.',
      whenToSeeDoctor:
          'See a doctor if blood sugars stay high, vomiting or dehydration occurs, or severe diarrhea does not settle.',
      emergencyWarning:
          'Get urgent help for extreme weakness, trouble breathing, unusual sleepiness, or symptoms of severe low blood sugar if used with other diabetes medicines.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: true,
    ),
    MedicineModel(
      id: '7',
      name: 'Cetirizine',
      genericName: 'Cetirizine HCl',
      category: 'Antihistamine',
      description:
          'An antihistamine that helps relieve allergic rhinitis symptoms and itchy skin reactions.',
      usage:
          'Commonly used for sneezing, runny nose, itching, watery eyes, and hives.',
      dosage:
          'Adults usually take 10mg once daily. Lower doses may be recommended in kidney impairment or for some children.',
      howToTake:
          'Take once daily with or without food. If it makes you sleepy, consider evening dosing unless advised otherwise.',
      warnings: [
        'May cause drowsiness in some people.',
        'Use caution before driving if you are taking it for the first time.',
      ],
      sideEffects: ['Drowsiness', 'Dry mouth', 'Headache', 'Dizziness'],
      ingredients: [
        'Cetirizine hydrochloride',
        'Lactose',
        'Microcrystalline cellulose'
      ],
      allergens: [],
      contraindications: ['Kidney disease', 'Hydroxyzine allergy'],
      interactions: ['Alcohol', 'Sedating antihistamines', 'Sleep medicines'],
      storageInstructions: 'Keep below excessive heat in the original package.',
      pregnancyBreastfeeding:
          'Discuss regular use in pregnancy or breastfeeding with a clinician, especially if symptoms are ongoing.',
      whenToSeeDoctor:
          'See a doctor if allergy symptoms remain severe, wheezing starts, or facial swelling appears.',
      emergencyWarning:
          'Seek urgent help for breathing difficulty, throat swelling, or widespread blistering rash.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
    MedicineModel(
      id: '8',
      name: 'Aspirin',
      genericName: 'Acetylsalicylic Acid',
      category: 'NSAID / Antiplatelet',
      description:
          'A salicylate medicine used for pain, fever, inflammation, and low-dose cardiovascular protection in selected patients.',
      usage:
          'Depending on the dose, it may be used for pain relief or as part of a clinician-guided heart or stroke prevention plan.',
      dosage:
          'Pain or fever doses differ from low-dose antiplatelet therapy. Follow the exact product label or clinician instructions.',
      howToTake:
          'Take with food or a full glass of water. Do not start daily aspirin for heart protection unless a clinician has advised it.',
      warnings: [
        'Can increase bleeding risk.',
        'Not generally recommended for children with viral illnesses.',
        'May trigger asthma symptoms in sensitive patients.',
      ],
      sideEffects: [
        'Stomach irritation',
        'Bleeding',
        'Heartburn',
        'Tinnitus at high doses',
        'Nausea',
      ],
      ingredients: ['Acetylsalicylic acid', 'Cornstarch', 'Hypromellose'],
      allergens: ['Salicylate', 'NSAID class'],
      contraindications: [
        'Aspirin allergy',
        'Active bleeding disorder',
        'Children with viral illness',
        'Recent stomach bleeding',
      ],
      interactions: ['Blood thinners', 'Ibuprofen', 'Steroids', 'Alcohol'],
      storageInstructions:
          'Store in a cool, dry place and keep tablets tightly sealed.',
      pregnancyBreastfeeding:
          'Avoid use in pregnancy unless a clinician specifically recommends it. Ask for advice before use while breastfeeding.',
      whenToSeeDoctor:
          'See a doctor if you bruise easily, have persistent stomach pain, or notice black stools.',
      emergencyWarning:
          'Get urgent help for vomiting blood, sudden severe wheezing, fainting, or signs of stroke or serious bleeding.',
      manufacturer: 'Various manufacturers',
      requiresPrescription: false,
    ),
  ];

  static List<MedicineModel> searchMedicines(String query) {
    if (query.isEmpty) return _medicines;
    final q = query.toLowerCase();
    return _medicines
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.genericName.toLowerCase().contains(q) ||
              m.category.toLowerCase().contains(q) ||
              m.description.toLowerCase().contains(q) ||
              m.usage.toLowerCase().contains(q) ||
              m.howToTake.toLowerCase().contains(q),
        )
        .toList();
  }

  static MedicineModel? getMedicineById(String id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<MedicineModel> getAllMedicines() => _medicines;

  static AllergyCheckResult checkAllergyRisk(
      MedicineModel medicine, List<String> userAllergies) {
    final risks = <String>[];
    final lowerAllergies = userAllergies.map((a) => a.toLowerCase()).toList();

    for (final allergen in medicine.allergens) {
      for (final userAllergen in lowerAllergies) {
        if (allergen.toLowerCase().contains(userAllergen) ||
            userAllergen.contains(allergen.toLowerCase())) {
          risks.add(allergen);
        }
      }
    }

    for (final contraindication in medicine.contraindications) {
      for (final userAllergen in lowerAllergies) {
        if (contraindication.toLowerCase().contains(userAllergen)) {
          risks.add(contraindication);
        }
      }
    }

    return AllergyCheckResult(
      medicine: medicine,
      isRisky: risks.isNotEmpty,
      risks: risks.toSet().toList(),
    );
  }
}

class AllergyCheckResult {
  final MedicineModel medicine;
  final bool isRisky;
  final List<String> risks;

  AllergyCheckResult({
    required this.medicine,
    required this.isRisky,
    required this.risks,
  });
}
