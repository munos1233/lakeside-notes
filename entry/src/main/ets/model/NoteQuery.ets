import { Note } from './NoteTypes';

const SUMMARY_LIMIT: number = 12;

export class NoteQuery {
  static summary(body: string): string {
    let line = NoteQuery.firstLine(body);
    if (line.length <= SUMMARY_LIMIT) {
      return line;
    }
    return line.substring(0, SUMMARY_LIMIT) + '…';
  }

  static search(notes: Note[], keyword: string): Note[] {
    let needle = keyword.trim().toLowerCase();
    if (needle.length === 0) {
      return notes.slice();
    }
    let matched: Note[] = [];
    for (let i = 0; i < notes.length; i++) {
      let note = notes[i];
      if (note.title.toLowerCase().includes(needle) || note.body.toLowerCase().includes(needle)) {
        matched.push(note);
      }
    }
    return matched;
  }

  static sort(notes: Note[]): Note[] {
    let order: number[] = [];
    for (let i = 0; i < notes.length; i++) {
      order.push(i);
    }
    order.sort((leftIndex: number, rightIndex: number): number => {
      let left = notes[leftIndex];
      let right = notes[rightIndex];
      if (left.pinned !== right.pinned) {
        if (left.pinned) {
          return -1;
        }
        return 1;
      }
      if (left.updatedAt === right.updatedAt) {
        return leftIndex - rightIndex;
      }
      if (left.updatedAt < right.updatedAt) {
        return 1;
      }
      return -1;
    });
    let ordered: Note[] = [];
    for (let i = 0; i < order.length; i++) {
      ordered.push(notes[order[i]]);
    }
    return ordered;
  }

  static latestUpdatedAt(notes: Note[]): string {
    let latest = '';
    for (let i = 0; i < notes.length; i++) {
      let updatedAt = notes[i].updatedAt;
      if (updatedAt.length === 0) {
        continue;
      }
      if (latest.length === 0 || updatedAt > latest) {
        latest = updatedAt;
      }
    }
    return latest;
  }

  private static firstLine(body: string): string {
    let newline = body.indexOf('\n');
    let carriage = body.indexOf('\r');
    let breakAt = -1;
    if (newline >= 0 && carriage >= 0) {
      breakAt = newline < carriage ? newline : carriage;
    } else if (newline >= 0) {
      breakAt = newline;
    } else {
      breakAt = carriage;
    }
    if (breakAt < 0) {
      return body;
    }
    return body.substring(0, breakAt);
  }
}
