import { Note, parseNoteList } from '../main/ets/model/NoteTypes';
import { NoteQuery } from '../main/ets/model/NoteQuery';

function note(id: string, pinned: boolean, updatedAt: string): Note {
  let item = new Note();
  item.id = id;
  item.title = id;
  item.body = id;
  item.pinned = pinned;
  item.createdAt = updatedAt;
  item.updatedAt = updatedAt;
  return item;
}

export function checkNoteQuery(): string[] {
  let failures: string[] = [];
  let expectEqual = (actual: string, wanted: string, name: string): void => {
    if (actual !== wanted) {
      failures.push(name + ' actual=' + actual);
    }
  };
  expectEqual(NoteQuery.summary('1234567890123'), '123456789012…', 'summary truncates');
  expectEqual(NoteQuery.summary('123456789012'), '123456789012', 'summary exact');
  expectEqual(NoteQuery.summary('ab\r\n其余'), 'ab', 'summary crlf');
  expectEqual(NoteQuery.summary('ab\n其余'), 'ab', 'summary lf');
  expectEqual(NoteQuery.latestUpdatedAt([]), '', 'latest empty');

  let older = note('older', false, '2026-01-01T00:00:00+08:00');
  let newer = note('newer', false, '2026-02-01T00:00:00+08:00');
  let sameA = note('same-a', false, '2026-03-01T00:00:00+08:00');
  let sameB = note('same-b', false, '2026-03-01T00:00:00+08:00');
  let pinned = note('pinned', true, '2026-01-01T00:00:00+08:00');
  let source = [older, newer, sameA, sameB, pinned];
  let sorted = NoteQuery.sort(source);
  if (source[0].id !== 'older' || source.length !== 5) {
    failures.push('sort mutated input');
  }
  if (sorted[0].id !== 'pinned' || sorted[1].id !== 'same-a' || sorted[2].id !== 'same-b' ||
    sorted[3].id !== 'newer' || sorted[4].id !== 'older') {
    failures.push('sort order ' + sorted[0].id + ',' + sorted[1].id + ',' + sorted[2].id + ',' +
      sorted[3].id + ',' + sorted[4].id);
  }

  let wifi = new Note();
  wifi.id = 'wifi';
  wifi.title = '会议室 Wi-Fi';
  wifi.body = '访客网络';
  let notes = [wifi];
  let found = NoteQuery.search(notes, 'wi-fi');
  if (found.length !== 1 || found[0].id !== 'wifi') {
    failures.push('search case');
  }
  let copied = NoteQuery.search(notes, '   ');
  if (copied === notes || copied.length !== 1 || copied[0] !== wifi) {
    failures.push('search blank keyword');
  }
  if (NoteQuery.search(notes, '不存在').length !== 0) {
    failures.push('search miss');
  }

  let parsed = parseNoteList('[{"id":"1","title":"买菜清单","body":"鸡蛋、青菜、米","pinned":false,"createdAt":"","updatedAt":""},null]');
  if (parsed.length !== 1 || parsed[0].title !== '买菜清单' || parsed[0].pinned !== false) {
    failures.push('null item');
  }
  if (parseNoteList('').length !== 0 || parseNoteList('[]').length !== 0 || parseNoteList('   ').length !== 0) {
    failures.push('empty json');
  }
  if (parseNoteList('{"id":"1"}').length !== 0) {
    failures.push('non array');
  }
  return failures;
}
