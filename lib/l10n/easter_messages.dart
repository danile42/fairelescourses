import 'package:flutter/widgets.dart';

const _messagesEn = <String>[
  // Warm & uplifting
  'Your friends love you.',
  'You are stronger than you think.',
  'Something wonderful is about to happen.',
  'The world is better with you in it.',
  'You have already survived 100\u202f% of your bad days.',
  'You matter more than you know.',
  'Somewhere, someone is thinking of you with a smile.',
  'You are doing better than you feel right now.',
  'Every expert was once a beginner — keep going.',
  'Your kindness makes a difference, even when you can\'t see it.',
  'Hard times are temporary; your strength is permanent.',
  'You deserve rest, not just productivity.',
  'Small steps still move you forward.',
  'The fact that you care so much shows how good you are.',
  'You are allowed to take up space.',
  'There is only one you, and that is your superpower.',
  'Tea, coffee, or a nap — you deserve whichever you need.',
  'You have faced hard things before, and you rose each time.',
  'Someone out there wishes they had your courage.',
  'Today is not the whole story — the best chapters are ahead.',
  // Grounded & realistic
  'Not every day needs to be great. Today just needs to be okay.',
  'You don\'t have to fix everything today.',
  'Progress isn\'t always visible — but it\'s still happening.',
  'It\'s okay to ask for help. That\'s what people are for.',
  'You are allowed to change your mind.',
  'Feeling overwhelmed just means you care deeply.',
  'Rest is not giving up — it\'s how you keep going.',
  'Some days the win is just getting through it. That counts.',
  'You don\'t have to be cheerful all the time. You just have to keep showing up.',
  'The messy middle is still part of the story.',
];

const _messagesDe = <String>[
  // Warm & aufbauend
  'Deine Freunde lieben dich.',
  'Du bist stärker, als du denkst.',
  'Gleich passiert etwas Wunderbares.',
  'Die Welt ist besser mit dir drin.',
  'Du hast schon 100\u202f% deiner schlechten Tage überstanden.',
  'Du bedeutest mehr, als du weißt.',
  'Irgendwo denkt jemand mit einem Lächeln an dich.',
  'Du machst das besser, als du dich gerade fühlst.',
  'Jeder Experte war mal Anfänger – mach weiter.',
  'Deine Freundlichkeit macht einen Unterschied, auch wenn du es nicht siehst.',
  'Schwere Zeiten sind vorübergehend; deine Stärke ist beständig.',
  'Du verdienst Erholung, nicht nur Leistung.',
  'Kleine Schritte bringen dich trotzdem voran.',
  'Dass du so viel Mühe gibst, zeigt, wie gut du bist.',
  'Du darfst Raum einnehmen.',
  'Es gibt nur ein einziges Exemplar von dir – das ist deine Superkraft.',
  'Tee, Kaffee oder ein Nickerchen – du verdienst, was du brauchst.',
  'Du hast schon schwere Dinge gemeistert und bist jedes Mal wieder aufgestanden.',
  'Jemand da draußen wünscht sich, er hätte deinen Mut.',
  'Heute ist nicht die ganze Geschichte – die besten Kapitel kommen noch.',
  // Geerdet & realistisch
  'Nicht jeder Tag muss toll sein. Heute muss nur okay sein.',
  'Du musst heute nicht alles in Ordnung bringen.',
  'Fortschritt ist nicht immer sichtbar – aber er passiert trotzdem.',
  'Um Hilfe zu bitten ist okay. Dafür sind Menschen da.',
  'Du darfst deine Meinung ändern.',
  'Überwältigt zu sein zeigt nur, dass dir vieles am Herzen liegt.',
  'Ausruhen ist kein Aufgeben – so machst du weiter.',
  'Manchmal ist der Erfolg des Tages einfach, ihn zu überstehen. Das zählt.',
  'Du musst nicht immer fröhlich sein. Du musst einfach nur weitermachen.',
  'Das chaotische Mittelstück gehört trotzdem zur Geschichte.',
];

List<String> easterMessages(BuildContext context) {
  final lang = Localizations.localeOf(context).languageCode;
  return lang == 'de' ? _messagesDe : _messagesEn;
}
