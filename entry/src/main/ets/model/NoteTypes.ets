export class Note {
  id: string = '';
  title: string = '';
  body: string = '';
  pinned: boolean = false;
  createdAt: string = '';
  updatedAt: string = '';
}

export function localIso(now: Date): string {
  let offset = -now.getTimezoneOffset();
  let sign = '+';
  if (offset < 0) {
    sign = '-';
    offset = -offset;
  }
  return now.getFullYear().toString() + '-' + pad2(now.getMonth() + 1) + '-' +
    pad2(now.getDate()) + 'T' + pad2(now.getHours()) + ':' +
    pad2(now.getMinutes()) + ':' + pad2(now.getSeconds()) +
    sign + pad2(Math.floor(offset / 60)) + ':' + pad2(offset % 60);
}

function pad2(value: number): string {
  if (value < 10) {
    return '0' + value.toString();
  }
  return value.toString();
}

function pad3(value: number): string {
  if (value < 10) {
    return '00' + value.toString();
  }
  if (value < 100) {
    return '0' + value.toString();
  }
  return value.toString();
}

export function newNoteId(used: string[]): string {
  for (let attempt = 0; attempt < 8; attempt++) {
    let suffix = Math.floor(Math.random() * 1000);
    let id = Date.now().toString() + pad3(suffix);
    if (used.indexOf(id) < 0) {
      used.push(id);
      return id;
    }
  }
  let base = Date.now().toString();
  for (let suffix = 0; suffix < 1000; suffix++) {
    let id = base + pad3(suffix);
    if (used.indexOf(id) < 0) {
      used.push(id);
      return id;
    }
  }
  let extra = base + '000';
  while (used.indexOf(extra) >= 0) {
    extra = extra + '0';
  }
  used.push(extra);
  return extra;
}

export function parseNoteList(text: string): Note[] {
  let trimmed = text.trim();
  if (trimmed.length === 0) {
    return [];
  }
  try {
    let raw = JSON.parse(trimmed) as Note[];
    if (!Array.isArray(raw)) {
      return [];
    }
    let notes: Note[] = [];
    for (let i = 0; i < raw.length; i++) {
      let copied = copyNote(raw[i]);
      if (copied !== undefined) {
        notes.push(copied);
      }
    }
    return notes;
  } catch (err) {
    return [];
  }
}

function copyNote(raw: Note): Note | undefined {
  if (!hasNoteFields(raw)) {
    return undefined;
  }
  if (typeof raw.id !== 'string' || typeof raw.title !== 'string' || typeof raw.body !== 'string') {
    return undefined;
  }
  let note = new Note();
  note.id = raw.id;
  note.title = raw.title;
  note.body = raw.body;
  note.pinned = raw.pinned === true;
  note.createdAt = typeof raw.createdAt === 'string' ? raw.createdAt : '';
  note.updatedAt = typeof raw.updatedAt === 'string' ? raw.updatedAt : '';
  return note;
}

function hasNoteFields(raw: Note): boolean {
  try {
    return typeof raw === 'object' && raw.id !== undefined;
  } catch (err) {
    return false;
  }
}
